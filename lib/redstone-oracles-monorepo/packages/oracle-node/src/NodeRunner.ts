import git from "git-last-commit";
import { ethers } from "ethers";
import { Consola } from "consola";
import aggregators from "./aggregators";
import ManifestHelper, { TokensBySource } from "./manifest/ManifestParser";
import ArweaveService from "./arweave/ArweaveService";
import { promiseTimeout, TimeoutError } from "./utils/promise-timeout";
import { mergeObjects } from "./utils/objects";
import { ExpressAppRunner } from "./ExpressAppRunner";
import {
  printTrackingState,
  trackEnd,
  trackStart,
} from "./utils/performance-tracker";
import PricesService, {
  PricesBeforeAggregation,
  PricesDataFetched,
} from "./fetchers/PricesService";
import {
  Broadcaster,
  HttpBroadcaster,
  StreamrBroadcaster,
} from "./broadcasters";
import {
  Manifest,
  NodeConfig,
  PriceDataAfterAggregation,
  PriceDataBeforeSigning,
} from "./types";
import { fetchIp } from "./utils/ip-fetcher";
import { ArweaveProxy } from "./arweave/ArweaveProxy";
import {
  DataPackage,
  DataPoint,
  NumericDataPoint,
  SignedDataPackage,
} from "redstone-protocol";
import { config } from "./config";

const logger = require("./utils/logger")("runner") as Consola;
const pjson = require("../package.json") as any;

const MANIFEST_LOAD_TIMEOUT_MS = 25 * 1000;
const DIAGNOSTIC_INFO_PRINTING_INTERVAL = 60 * 1000;
const DEFAULT_HTTP_BROADCASTER_URLS = [
  "https://direct-1.cache-service.redstone.finance",
  "https://direct-2.cache-service.redstone.finance",
  "https://direct-3.cache-service.redstone.finance",
];

export default class NodeRunner {
  private readonly version: string;

  private lastManifestLoadTimestamp?: number;
  // note: all below '?' class fields have to be re-initialized after reading
  // new manifest in this.useNewManifest(manifest); - as they depend on the current manifest.
  private currentManifest?: Manifest;
  private pricesService?: PricesService;
  private tokensBySource?: TokensBySource;
  private newManifest: Manifest | null = null;
  private httpBroadcaster: Broadcaster;
  private streamrBroadcaster: Broadcaster;

  private constructor(
    private readonly arweaveService: ArweaveService,
    private readonly providerAddress: string,
    private readonly nodeConfig: NodeConfig,
    initialManifest: Manifest
  ) {
    const ethereumPrivKey = nodeConfig.privateKeys.ethereumPrivateKey;
    this.version = getVersionFromPackageJSON();
    this.useNewManifest(initialManifest);
    this.lastManifestLoadTimestamp = Date.now();
    const httpBroadcasterURLs =
      config.overrideDirectCacheServiceUrls ??
      initialManifest?.httpBroadcasterURLs ??
      DEFAULT_HTTP_BROADCASTER_URLS;
    this.httpBroadcaster = new HttpBroadcaster(
      httpBroadcasterURLs,
      ethereumPrivKey
    );
    this.streamrBroadcaster = new StreamrBroadcaster(ethereumPrivKey);

    // https://www.freecodecamp.org/news/the-complete-guide-to-this-in-javascript/
    // alternatively use arrow functions...
    this.runIteration = this.runIteration.bind(this);
    this.handleLoadedManifest = this.handleLoadedManifest.bind(this);
  }

  static async create(nodeConfig: NodeConfig): Promise<NodeRunner> {
    // Running a simple web server
    // It should be called as early as possible
    // Otherwise App Runner crashes ¯\_(ツ)_/¯
    new ExpressAppRunner(nodeConfig).run();

    const arweave = new ArweaveProxy(nodeConfig.privateKeys.arweaveJwk);
    const providerAddress = await arweave.getAddress();
    const arweaveService = new ArweaveService();

    let manifestData = null;
    if (nodeConfig.overrideManifestUsingFile) {
      manifestData = nodeConfig.overrideManifestUsingFile;
    } else {
      while (true) {
        logger.info("Fetching manifest data.");
        try {
          manifestData = await arweaveService.getCurrentManifest();
        } catch (e: any) {
          logger.error("Initial manifest read failed.", e.stack || e);
        }
        if (manifestData !== null) {
          logger.info("Fetched manifest", manifestData);
          break;
        }
      }
    }

    return new NodeRunner(
      arweaveService,
      providerAddress,
      nodeConfig,
      manifestData
    );
  }

  async run(): Promise<void> {
    await this.printInitialNodeDetails();
    this.maybeRunDiagnosticInfoPrinting();

    try {
      await this.runIteration(); // Start immediately then repeat in manifest.interval
      setInterval(this.runIteration, this.currentManifest!.interval);
    } catch (e: any) {
      NodeRunner.reThrowIfManifestConfigError(e);
    }
  }

  private async printInitialNodeDetails() {
    const evmPrivateKey = this.nodeConfig.privateKeys.ethereumPrivateKey;
    const evmAddress = new ethers.Wallet(evmPrivateKey).address;
    const ipAddress = await fetchIp();
    logger.info(`Node evm address: ${evmAddress}`);
    logger.info(`Node arweave address: ${this.providerAddress}`);
    logger.info(`Version from package.json: ${this.version}`);
    logger.info(`Node's IP address: ${ipAddress}`);
    logger.info(
      `Initial node manifest:
      ${JSON.stringify(this.currentManifest)}
    `
    );

    // Printing git details
    git.getLastCommit((err, commit) => {
      if (err) {
        logger.error(err);
      } else {
        logger.info(
          `Git details: ${commit.hash} (latest commit), ` +
            `${commit.branch} (branch), ` +
            `${commit.subject} (latest commit message)`
        );
      }
    });
  }

  private maybeRunDiagnosticInfoPrinting() {
    if (this.nodeConfig.printDiagnosticInfo) {
      const printDiagnosticInfo = () => {
        const memoryUsage = process.memoryUsage();
        const activeRequests = (process as any)._getActiveRequests();
        const activeHandles = (process as any)._getActiveHandles();
        logger.info(
          `Diagnostic info: ` +
            `Active requests count: ${activeRequests.length}. ` +
            `Active handles count: ${activeHandles.length}. ` +
            `Memory usage: ${JSON.stringify(memoryUsage)}. `
        );
        console.log({ activeRequests });
      };

      printDiagnosticInfo();
      setInterval(printDiagnosticInfo, DIAGNOSTIC_INFO_PRINTING_INTERVAL);
    }
  }

  private async runIteration() {
    logger.info("Running new iteration.");

    if (this.newManifest !== null) {
      logger.info("Using new manifest: ", this.newManifest.txId);
      this.useNewManifest(this.newManifest);
    }

    this.maybeLoadManifestFromSmartContract();
    await this.safeProcessManifestTokens();

    printTrackingState();
  }

  private async safeProcessManifestTokens() {
    const processingAllTrackingId = trackStart("processing-all");
    try {
      await this.doProcessTokens();
    } catch (e: any) {
      NodeRunner.reThrowIfManifestConfigError(e);
    } finally {
      trackEnd(processingAllTrackingId);
    }
  }

  private async doProcessTokens(): Promise<void> {
    logger.info("Processing tokens");

    // Fetching and aggregating
    const aggregatedPrices: PriceDataAfterAggregation[] =
      await this.fetchPrices();
    const pricesReadyForSigning = this.pricesService!.preparePricesForSigning(
      aggregatedPrices,
      "",
      this.providerAddress
    );

    // Signing
    const signedDataPackages = this.signPrices(
      pricesReadyForSigning,
      pricesReadyForSigning[0].timestamp
    );

    // Broadcasting
    await this.broadcastDataPackages(signedDataPackages);
  }

  private signPrices(
    prices: PriceDataBeforeSigning[],
    timestamp: number
  ): SignedDataPackage[] {
    const ethPrivKey = this.nodeConfig.privateKeys.ethereumPrivateKey;

    // Prepare data points
    const dataPoints: DataPoint[] = [];
    for (const price of prices) {
      try {
        const dataPoint = priceToDataPoint(price);
        dataPoints.push(dataPoint);
      } catch (e) {
        logger.error(
          `Failed to convert price object to data point for ${price.symbol} (${price.value})`
        );
      }
    }

    // Prepare signed data packages with single data point
    const signedDataPackages = dataPoints.map((dataPoint) => {
      const dataPackage = new DataPackage([dataPoint], timestamp);
      return dataPackage.sign(ethPrivKey);
    });

    // Adding a data package with all data points
    const bigDataPackage = new DataPackage(dataPoints, timestamp);
    const signedBigDataPackage = bigDataPackage.sign(ethPrivKey);
    signedDataPackages.push(signedBigDataPackage);

    return signedDataPackages;
  }

  private async fetchPrices(): Promise<PriceDataAfterAggregation[]> {
    const fetchingAllTrackingId = trackStart("fetching-all");

    const fetchTimestamp = Date.now();
    const fetchedPrices = await this.pricesService!.fetchInParallel(
      this.tokensBySource!
    );
    const pricesData: PricesDataFetched = mergeObjects(fetchedPrices);
    const pricesBeforeAggregation: PricesBeforeAggregation =
      PricesService.groupPricesByToken(
        fetchTimestamp,
        pricesData,
        this.version
      );

    const aggregatedPrices: PriceDataAfterAggregation[] =
      this.pricesService!.calculateAggregatedValues(
        Object.values(pricesBeforeAggregation), // what is the advantage of using lodash.values?
        aggregators[this.currentManifest!.priceAggregator]
      );
    NodeRunner.printAggregatedPrices(aggregatedPrices);
    trackEnd(fetchingAllTrackingId);
    return aggregatedPrices;
  }

  private async broadcastDataPackages(signedDataPackages: SignedDataPackage[]) {
    logger.info("Broadcasting prices");
    const broadcastingTrackingId = trackStart("broadcasting");
    try {
      const promises = [];
      promises.push(this.httpBroadcaster.broadcast(signedDataPackages));
      const enableStreamrBroadcaster =
        !!this.currentManifest?.enableStreamrBroadcaster;
      if (enableStreamrBroadcaster) {
        promises.push(this.streamrBroadcaster.broadcast(signedDataPackages));
      }
      const results = await Promise.allSettled(promises);

      // Check if all promises resolved
      const failedBroadcastersCount = results.filter(
        (res) => res.status === "rejected"
      ).length;
      if (failedBroadcastersCount > 0) {
        throw new Error(`${failedBroadcastersCount} broadcasters failed`);
      }

      logger.info("Broadcasting completed");
    } catch (e: any) {
      if (e.response !== undefined) {
        logger.error("Broadcasting failed: " + e.response.data, e.stack);
      } else {
        logger.error("Broadcasting failed", e.stack);
      }
    } finally {
      trackEnd(broadcastingTrackingId);
    }
  }

  private static printAggregatedPrices(
    prices: PriceDataAfterAggregation[]
  ): void {
    for (const price of prices) {
      const sourcesData = JSON.stringify(price.source);
      logger.info(
        `Fetched price : ${price.symbol} : ${price.value} | ${sourcesData}`
      );
    }
  }

  private static reThrowIfManifestConfigError(e: Error) {
    if (e.name == "ManifestConfigError") {
      throw e;
    } else {
      logger.error(e.stack);
    }
  }

  // TODO: refactor to a separate service?
  private maybeLoadManifestFromSmartContract() {
    if (this.nodeConfig.overrideManifestUsingFile) {
      return;
    }

    const now = Date.now();
    const timeDiff = now - this.lastManifestLoadTimestamp!;
    logger.info("Checking time since last manifest load", {
      timeDiff,
      manifestRefreshInterval: this.nodeConfig.manifestRefreshInterval,
    });
    if (timeDiff >= this.nodeConfig.manifestRefreshInterval) {
      this.lastManifestLoadTimestamp = now;
      logger.info("Trying to fetch new manifest version.");
      const manifestFetchTrackingId = trackStart("Fetching manifest.");
      // note: not using "await" here, as loading manifest's data takes about 6 seconds and we do not want to
      // block standard node processing for so long (especially for nodes with low "interval" value)
      promiseTimeout(
        () => this.arweaveService.getCurrentManifest(),
        MANIFEST_LOAD_TIMEOUT_MS
      )
        .then((value) => {
          this.handleLoadedManifest(value as Manifest);
        })
        .catch((error) => {
          if (error instanceof TimeoutError) {
            logger.warn("Manifest load promise timeout");
          } else {
            logger.info("Error while calling manifest load function");
          }
        })
        .finally(() => {
          trackEnd(manifestFetchTrackingId);
        });
    } else {
      logger.info("Skipping manifest download in this iteration run.");
    }
  }

  private handleLoadedManifest(loadedManifest: Manifest | null) {
    if (!loadedManifest) {
      return;
    }
    logger.info("Manifest successfully loaded", {
      loadedManifestTxId: loadedManifest.txId,
      currentTxId: this.currentManifest?.txId,
    });
    if (loadedManifest.txId != this.currentManifest?.txId) {
      logger.info(
        "Loaded and current manifest differ, updating on next runIteration call."
      );
      // we're temporarily saving loaded manifest on a separate "newManifest" field
      // - calling "this.useNewManifest(this.newManifest)" here could cause that
      // that different manifests would be used by different services during given "runIteration" execution.
      this.newManifest = loadedManifest;
      loadedManifest = null;
    } else {
      logger.info("Loaded manifest same as current, not updating.");
    }
  }

  private useNewManifest(newManifest: Manifest) {
    this.currentManifest = newManifest;
    this.pricesService = new PricesService(
      newManifest,
      this.nodeConfig.credentials
    );
    this.tokensBySource = ManifestHelper.groupTokensBySource(newManifest);
    this.newManifest = null;
  }
}

function priceToDataPoint(price: PriceDataBeforeSigning): NumericDataPoint {
  return new NumericDataPoint({
    dataFeedId: price.symbol,
    value: price.value,
  });
}

function getVersionFromPackageJSON() {
  const [major, minor] = pjson.version.split(".");
  return major + "." + minor;
}
