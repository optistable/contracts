import axios from "axios";
import { BroadcasterOld } from "../BroadcasterOld";
import { PriceDataSigned, SignedPricePackage } from "../../types";
import { Consola } from "consola";
import { stringifyError } from "../../utils/error-stringifier";

const logger = require("../../utils/logger")("HttpBroadcasterOld") as Consola;

// TODO: add timeout to broadcasting

export class HttpBroadcasterOld implements BroadcasterOld {
  constructor(private readonly broadcasterURLs: string[]) {}

  async broadcast(prices: PriceDataSigned[]): Promise<void> {
    const promises = this.broadcasterURLs.map((url) => {
      logger.info(`Posting prices to ${url}`);
      return axios
        .post(
          url + "/prices",
          prices.map((p) => ({ ...p, permawebTx: "mock-permaweb-tx" }))
        )
        .then(() => logger.info(`Broadcasting to ${url} completed`))
        .catch((e) =>
          logger.error(`Broadcasting to ${url} failed: ${stringifyError(e)}`)
        );
    });

    await Promise.allSettled(promises);
  }

  async broadcastPricePackage(
    signedData: SignedPricePackage,
    providerAddress: string
  ): Promise<void> {
    const body = {
      signerAddress: signedData.signerAddress,
      liteSignature: signedData.liteSignature,
      provider: providerAddress,
      ...signedData.pricePackage, // unpacking prices and timestamp
    };

    const promises = this.broadcasterURLs.map((url) => {
      logger.info(`Posting pacakages to ${url}`);
      return axios
        .post(url + "/packages", body)
        .then(() => logger.info(`Broadcasting package to ${url} completed`))
        .catch((e) =>
          logger.error(
            `Broadcasting package to ${url} failed: ${stringifyError(e)}`
          )
        );
    });

    await Promise.allSettled(promises);
  }
}
