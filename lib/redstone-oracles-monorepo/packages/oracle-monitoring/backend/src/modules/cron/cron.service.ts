import { Injectable, Logger } from "@nestjs/common";
import { SchedulerRegistry } from "@nestjs/schedule";
import { ConfigService } from "@nestjs/config";
import { Model } from "mongoose";
import { InjectModel } from "@nestjs/mongoose";
import { HttpService } from "@nestjs/axios";
import { CronJob } from "cron";
import { requestDataPackages } from "redstone-sdk";
import { dataServicesToCheck } from "../../config";
import { stringifyError } from "../../shared/error-stringifier";
import { Issue, IssueDocument } from "../issues/issues.schema";
import { Metric, MetricDocument } from "../metrics/metrics.schema";

interface CheckDataFeedInput {
  dataServiceId: string;
  symbol?: string;
  urls?: string[];
}

interface Input {
  dataServiceId: string;
  minTimestampDiffForWarning: number;
  url: string;
  dataFeeds: string[];
}

interface SaveMetricInput {
  metricName: string;
  timestampDiff: number;
  timestamp: number;
  dataServiceId: string;
  url: string;
}

@Injectable()
export class CronService {
  constructor(
    private schedulerRegistry: SchedulerRegistry,
    @InjectModel(Issue.name) private issueModel: Model<IssueDocument>,
    @InjectModel(Metric.name) private metricModel: Model<MetricDocument>,
    private readonly httpService: HttpService,
    private configService: ConfigService
  ) {}

  addCronJobs() {
    // Starting data feed checker jobs
    for (const dataService of dataServicesToCheck) {
      // Starting job for checking whole data package fetching
      // (without specified symbol)
      if (dataService.checkWithoutSymbol) {
        Logger.log(`Starting data feed checker job for: ${dataService.id}`);
        const job = new CronJob(dataService.schedule, () => {
          this.checkDataFeed({
            dataServiceId: dataService.id,
            urls: dataService.urls,
          });
        });
        this.schedulerRegistry.addCronJob(
          `date-feed-checker-${dataService.id}`,
          job
        );
        job.start();
      }

      // Starting jobs for each symbol checking
      if (dataService.symbolsToCheck && dataService.symbolsToCheck.length > 0) {
        for (const symbol of dataService.symbolsToCheck) {
          Logger.log(
            `Starting data feed checker job for: ${dataService.id} with symbol: ${symbol}`
          );
          const job = new CronJob(dataService.schedule, () => {
            this.checkDataFeed({
              dataServiceId: dataService.id,
              symbol,
              urls: dataService.urls,
            });
          });
          this.schedulerRegistry.addCronJob(
            `date-feed-checker-${dataService.id}-symbol-${symbol}`,
            job
          );
          job.start();
        }
      }

      // Starting jobs for each single url
      if (dataService.checkEachSingleUrl) {
        for (const url of dataService.urls) {
          Logger.log(`Starting single url checker job for: ${dataService.id}`);
          const job = new CronJob(dataService.schedule, () => {
            this.checkSingleUrl({
              dataServiceId: dataService.id,
              minTimestampDiffForWarning:
                dataService.minTimestampDiffForWarning,
              url,
              dataFeeds: dataService.symbolsToCheck,
            });
          });
          this.schedulerRegistry.addCronJob(
            `url-checker-${dataService.id}-${JSON.stringify(url)}`,
            job
          );
          job.start();
        }
      }
    }
  }

  checkDataFeed = async ({
    dataServiceId,
    symbol,
    urls,
  }: CheckDataFeedInput) => {
    Logger.log(
      `Checking data feed: ${dataServiceId}${
        symbol ? " with symbol " + symbol : ""
      }`
    );
    const currentTimestamp = Date.now();

    try {
      if (symbol) {
        await requestDataPackages(
          {
            dataServiceId: dataServiceId,
            uniqueSignersCount: 1,
            dataFeeds: [symbol],
          },
          urls
        );
      }
    } catch (e) {
      const errStr = stringifyError(e);
      Logger.error(
        `Error occured in data feed checker-job ` +
          `(${dataServiceId}-${symbol}). ` +
          `Saving issue in DB: ${errStr}`
      );
      await new this.issueModel({
        timestamp: currentTimestamp,
        type: "data-feed-failed",
        symbol,
        level: "ERROR",
        dataServiceId,
        comment: errStr,
      }).save();
      const uptimeKumaUrl = this.configService.get("UPTIME_KUMA_URL");
      const uptimeKumaUrlWithMessage = `${uptimeKumaUrl}&msg=(${dataServiceId}-${symbol}): ${errStr}`;
      if (uptimeKumaUrl) {
        await this.httpService.axiosRef.get(uptimeKumaUrlWithMessage);
      }
    }
  };

  checkSingleUrl = async ({
    dataServiceId,
    minTimestampDiffForWarning,
    url,
    dataFeeds,
  }: Input) => {
    const currentTimestamp = Date.now();
    Logger.log(
      `Checking a single url in data feed: ${dataServiceId}. ` +
        `Url: ${JSON.stringify(url)}`
    );

    try {
      // Trying to fetch from redstone
      const response = await requestDataPackages(
        {
          dataServiceId,
          uniqueSignersCount: 1,
          dataFeeds,
        },
        [url]
      );

      for (const dataFeedId of Object.keys(response)) {
        const dataPackage = response[dataFeedId as any][0]?.dataPackage;
        if (dataPackage) {
          const { timestampMilliseconds } = dataPackage;
          const timestampDiff = currentTimestamp - timestampMilliseconds;

          // Saving metric to DB
          this.safelySaveMetricInDB({
            metricName: `timestamp-diff-${dataFeedId}`,
            timestampDiff,
            timestamp: timestampMilliseconds,
            dataServiceId,
            url,
          });
          if (timestampDiff > minTimestampDiffForWarning) {
            Logger.warn(
              `Timestamp diff is quite big: ${timestampDiff}. Saving issue in DB`
            );
            await new this.issueModel({
              timestamp: currentTimestamp,
              type: "timestamp-diff",
              level: "WARNING",
              dataServiceId,
              url,
              timestampDiffMilliseconds: timestampDiff,
            }).save();
          }
        } else {
          Logger.error(
            `Error occurred: no data package for ${dataFeedId}. Saving issue in DB`
          );
          await new this.issueModel({
            timestamp: currentTimestamp,
            type: "no-data-package",
            level: "WARNING",
            dataServiceId,
            url,
            comment: `No data package for ${dataFeedId}`,
          }).save();
        }
      }
    } catch (e) {
      const errStr = stringifyError(e);
      Logger.error(`Error occurred: ${errStr}. Saving issue in DB`);
      await new this.issueModel({
        timestamp: currentTimestamp,
        type: "one-url-failed",
        level: "WARNING",
        dataServiceId,
        url,
        comment: errStr,
      }).save();
    }
  };

  safelySaveMetricInDB = async ({
    metricName,
    timestampDiff,
    timestamp,
    dataServiceId,
    url,
  }: SaveMetricInput) => {
    try {
      Logger.log(
        `Saving metric to DB. Name: ${metricName}, Value: ${timestampDiff}`
      );
      await new this.metricModel({
        name: metricName,
        value: timestampDiff,
        timestamp,
        tags: {
          dataServiceId,
          url,
        },
      }).save();
    } catch (e) {
      Logger.error(`Metric saving failed: ${stringifyError(e)}`);
    }
  };
}
