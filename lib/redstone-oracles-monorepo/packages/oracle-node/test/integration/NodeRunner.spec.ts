import NodeRunner from "../../src/NodeRunner";
import { JWKInterface } from "arweave/node/lib/wallet";
import { mocked } from "ts-jest/utils";
import { ArweaveProxy } from "../../src/arweave/ArweaveProxy";
import fetchers from "../../src/fetchers";
import axios from "axios";
import ArweaveService from "../../src/arweave/ArweaveService";
import { any } from "jest-mock-extended";
import { timeout } from "../../src/utils/promise-timeout";
import { MOCK_NODE_CONFIG } from "../helpers";
import { NodeConfig } from "../../src/types";

/****** MOCKS START ******/
const mockArProxy = {
  getAddress: () => Promise.resolve("mockArAddress"),
};
jest.mock("../../src/arweave/ArweaveProxy", () => {
  return {
    ArweaveProxy: jest.fn().mockImplementation(() => mockArProxy),
  };
});

jest.mock("../../src/signers/EvmPriceSignerOld", () => {
  return jest.fn().mockImplementation(() => {
    return {
      signPricePackage: (pricePackage: any) => ({
        liteSignature: "mock_evm_signed_lite",
        signerAddress: "mock_evm_signer_address",
        pricePackage,
      }),
    };
  });
});

jest.mock("../../src/fetchers/coingecko/CoingeckoFetcher");
jest.mock("../../src/fetchers/uniswap/UniswapFetcher");

jest.mock("axios");
const mockedAxios = axios as jest.Mocked<typeof axios>;
mockedAxios.post.mockImplementation((url) => {
  if (url == "https://api.redstone.finance/metrics") {
    return Promise.resolve();
  }
  return Promise.reject(
    `mock for ${url} not available and should not be called`
  );
});

let manifest: any = null;

jest.mock("../../src/utils/objects", () => ({
  // @ts-ignore
  ...jest.requireActual("../../src/utils/objects"),
  readJSON: () => null,
}));

jest.mock("uuid", () => ({ v4: () => "00000000-0000-0000-0000-000000000000" }));
/****** MOCKS END ******/

describe("NodeRunner", () => {
  const jwk: JWKInterface = {
    e: "e",
    kty: "kty",
    n: "n",
  };

  const nodeConfig: NodeConfig = {
    ...MOCK_NODE_CONFIG,
    useNewSigningAndBroadcasting: true,
  };

  beforeEach(() => {
    jest.useFakeTimers();
    mockedAxios.post.mockClear();

    jest.spyOn(global.Date, "now").mockImplementation(() => 111111111);

    fetchers["coingecko"] = {
      fetchAll: jest.fn().mockResolvedValue([{ symbol: "BTC", value: 444 }]),
    };
    fetchers["uniswap"] = {
      fetchAll: jest.fn().mockResolvedValue([
        { symbol: "BTC", value: 445 },
        {
          symbol: "ETH",
          value: 42,
        },
      ]),
    };

    manifest = {
      defaultSource: ["uniswap"],
      interval: 10000,
      maxPriceDeviationPercent: 25,
      priceAggregator: "median",
      sourceTimeout: 2000,
      evmChainId: 1,
      enableArweaveBackup: true,
      tokens: {
        BTC: {
          source: ["coingecko"],
        },
        ETH: {},
      },
      httpBroadcasterURLs: ["http://localhost:9000"],
    };
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  it("should create node instance", async () => {
    // given
    const mockedArProxy = mocked(ArweaveProxy, true);

    const sut = await NodeRunner.create({
      ...nodeConfig,
      overrideManifestUsingFile: manifest,
    });

    // then
    expect(sut).not.toBeNull();
    expect(mockedArProxy).toHaveBeenCalledWith(jwk);
  });

  it("should throw if no maxDeviationPercent configured for token", async () => {
    // given
    manifest = JSON.parse(`{
        "defaultSource": ["uniswap"],
        "interval": 0,
        "priceAggregator": "median",
        "sourceTimeout": 2000,
        "tokens": {
          "BTC": {
           "source": ["coingecko"]
          },
          "ETH": {}
        }
      }`);

    const sut = await NodeRunner.create({
      ...nodeConfig,
      overrideManifestUsingFile: manifest,
    });

    await expect(sut.run()).rejects.toThrowError(
      "Could not determine maxPriceDeviationPercent"
    );
  });

  it("should throw if no sourceTimeout", async () => {
    // given
    manifest = JSON.parse(`{
        "defaultSource": ["uniswap"],
        "interval": 0,
        "priceAggregator": "median",
        "maxPriceDeviationPercent": 25,
        "evmChainId": 1,
        "tokens": {
          "BTC": {
           "source": ["coingecko"]
          },
          "ETH": {}
        }
      }`);
    const sut = await NodeRunner.create({
      ...nodeConfig,
      overrideManifestUsingFile: manifest,
    });

    await expect(sut.run()).rejects.toThrowError("No timeout configured for");
  });

  it("should broadcast fetched and signed prices", async () => {
    const sut = await NodeRunner.create({
      ...nodeConfig,
      overrideManifestUsingFile: {
        ...manifest,
        enableArweaveBackup: false,
      },
    });

    await sut.run();

    expect(axios.post).toHaveBeenCalledWith(
      "http://localhost:9000/data-packages/bulk",
      {
        requestSignature:
          "0xdd8c162ee49b5a506cc6afbe5d0d9a7aabd1c0e8946900e3601a5eacd96439e56db8419660b4508c9f35db4b1d4716ec58011101c9744f6f812d7b742124a3ff1c",
        dataPackages: [
          {
            signature:
              "osKzrnqb87XX51p1TDLZAM2KLoIlgf1JK8SC1OnOjCBGOxFpJG4Yjg6eQuvoLMpA1owO0aMQGO7pge+bjY6gxhw=",
            timestampMilliseconds: 111111111,
            dataPoints: [
              {
                dataFeedId: "BTC",
                value: 444.5,
              },
            ],
          },
          {
            signature:
              "WF1VFvLYv+Nd0PGAi3y1zPBp6fADtyUKREYEwuhl4k1hHZ+2MWnvztrxLK2NPeSryZXU9sgNLG5SJwhwqHV5ohs=",
            timestampMilliseconds: 111111111,
            dataPoints: [
              {
                dataFeedId: "ETH",
                value: 42,
              },
            ],
          },
          {
            signature:
              "VjPF6m+SYKTv4gEBWEqRSR1Ppje0xrRg0gluaQB5vf96YLyHLVdaloSRcypaoHNCu0nSmlxlJWtye7EReGB7vhw=",
            timestampMilliseconds: 111111111,
            dataPoints: [
              {
                dataFeedId: "BTC",
                value: 444.5,
              },
              {
                dataFeedId: "ETH",
                value: 42,
              },
            ],
          },
        ],
      }
    );
  });

  it("should not broadcast fetched and signed prices if values deviates too much", async () => {
    manifest = {
      ...manifest,
      maxPriceDeviationPercent: 0,
    };

    const sut = await NodeRunner.create({
      ...nodeConfig,
      overrideManifestUsingFile: manifest,
    });

    await sut.run();
    expect(axios.post).not.toHaveBeenCalledWith("http://localhost:9000", any());
  });

  describe("when overrideManifestUsingFile flag is null", () => {
    let nodeConfigManifestFromAr: any;
    beforeEach(() => {
      nodeConfigManifestFromAr = {
        ...nodeConfig,
        overrideManifestUsingFile: null,
      };
    });

    it("should download prices when manifest is available", async () => {
      // given
      const arServiceSpy = jest
        .spyOn(ArweaveService.prototype, "getCurrentManifest")
        .mockImplementation(() => Promise.resolve(manifest));

      const sut = await NodeRunner.create(nodeConfigManifestFromAr);

      await sut.run();

      expect(fetchers.uniswap.fetchAll).toHaveBeenCalled();

      arServiceSpy.mockClear();
    });

    it("should not create NodeRunner instance until manifest is available", async () => {
      // given
      jest.useRealTimers();
      let arServiceSpy = jest
        .spyOn(ArweaveService.prototype, "getCurrentManifest")
        .mockImplementation(async () => {
          await timeout(200);
          return Promise.reject("no way!");
        });

      // this effectively makes manifest available after 100ms - so
      // we expect that second manifest fetching trial will succeed.
      setTimeout(() => {
        arServiceSpy = jest
          .spyOn(ArweaveService.prototype, "getCurrentManifest")
          .mockImplementation(() => Promise.resolve(manifest));
      }, 100);
      const sut = await NodeRunner.create(nodeConfigManifestFromAr);
      expect(sut).not.toBeNull();
      expect(ArweaveService.prototype.getCurrentManifest).toHaveBeenCalledTimes(
        2
      );
      arServiceSpy.mockClear();
      jest.useFakeTimers();
    });

    it("should continue working when update manifest fails", async () => {
      // given
      nodeConfigManifestFromAr.manifestRefreshInterval = 0;
      let arServiceSpy = jest
        .spyOn(ArweaveService.prototype, "getCurrentManifest")
        .mockResolvedValueOnce(manifest)
        .mockRejectedValue("timeout");

      const sut = await NodeRunner.create(nodeConfigManifestFromAr);

      await sut.run();

      expect(sut).not.toBeNull();
      expect(ArweaveService.prototype.getCurrentManifest).toHaveBeenCalledTimes(
        2
      );
      expect(fetchers.uniswap.fetchAll).toHaveBeenCalled();
      expect(axios.post).not.toHaveBeenCalledWith(
        "http://localhost:9000",
        any()
      );
      arServiceSpy.mockClear();
    });
  });
});
