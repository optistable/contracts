import axios, { AxiosResponse } from "axios";
import { Consola } from "consola";
import { Manifest } from "../types";
import { promiseTimeout } from "../utils/promise-timeout";
import {
  getOracleRegistryState,
  getDataServiceIdForSigner,
} from "redstone-sdk";
import { config } from "../config";

const logger = require("../utils/logger")("ArweaveService") as Consola;

const ARWEAVE_URL = "https://arweave.net";
const TIMEOUT_MS = 10 * 1000;

// Business service that supplies operations required by Redstone-Node.
export default class ArweaveService {
  constructor(private readonly timeout: number = TIMEOUT_MS) {}

  private async fetchManifestPromise(manifestTxId: string) {
    const response = await axios.get(`${ARWEAVE_URL}/${manifestTxId}`);
    const parsedManifest = (response as AxiosResponse<Manifest>).data;
    parsedManifest.txId = manifestTxId;
    return parsedManifest;
  }

  async getCurrentManifest(oldManifest?: Manifest): Promise<Manifest> {
    try {
      const oracleRegistryState = await getOracleRegistryState();
      const dataServiceId = getDataServiceIdForSigner(
        oracleRegistryState,
        config.ethereumAddress
      );
      const currentDataService =
        oracleRegistryState.dataServices[dataServiceId];
      const manifestTxId = currentDataService.manifestTxId;
      return await promiseTimeout(
        () => this.fetchManifestPromise(manifestTxId),
        this.timeout
      );
    } catch (error: any) {
      if (oldManifest) {
        return oldManifest;
      } else {
        logger.error(error.stack);
        throw new Error(
          "Cannot fetch new manifest and old manifest doesn't exist"
        );
      }
    }
  }
}
