import { Broadcaster } from "../Broadcaster";
import { Consola } from "consola";
import { StreamrProxy } from "./StreamrProxy";
import { SignedDataPackage } from "redstone-protocol";

// TODO: implement streams existence checking

const logger = require("../../utils/logger")("StreamrBroadcaster") as Consola;

const STREAM_NAME = "data-packages";

export class StreamrBroadcaster implements Broadcaster {
  private streamrProxy: StreamrProxy;

  constructor(ethereumPrivateKey: string) {
    this.streamrProxy = new StreamrProxy(ethereumPrivateKey);
  }

  async broadcast(dataPackages: SignedDataPackage[]): Promise<void> {
    const dataToBroadcast = dataPackages.map((dp) => dp.toObj());
    logger.info("Broadcasting data packages to streamr");
    await this.streamrProxy.publishToStreamByName(dataToBroadcast, STREAM_NAME);
  }
}
