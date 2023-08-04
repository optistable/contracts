import axios from "axios";
import { Consola } from "consola";
import { SignedDataPackage, UniversalSigner } from "redstone-protocol";
import { stringifyError } from "../../utils/error-stringifier";
import { Broadcaster } from "../Broadcaster";

const logger = require("../../utils/logger")("HttpBroadcaster") as Consola;

export class HttpBroadcaster implements Broadcaster {
  constructor(
    private readonly broadcasterURLs: string[],
    private readonly ethereumPrivateKey: string
  ) {}

  async broadcast(dataPackages: SignedDataPackage[]): Promise<void> {
    const dataPackagesObjects = dataPackages.map((dp) => dp.toObj());
    const requestSignature = UniversalSigner.signStringifiableData(
      dataPackagesObjects,
      this.ethereumPrivateKey
    );

    const signedDataPackagesPostReqBody = {
      requestSignature,
      dataPackages: dataPackagesObjects,
    };

    const promises = this.broadcasterURLs.map((url) => {
      logger.info(`Posting prices to ${url}`);
      return axios
        .post(url + "/data-packages/bulk", signedDataPackagesPostReqBody)
        .then(() => logger.info(`Broadcasting to ${url} completed`))
        .catch((e) =>
          logger.error(`Broadcasting to ${url} failed: ${stringifyError(e)}`)
        );
    });

    await Promise.allSettled(promises);
  }
}
