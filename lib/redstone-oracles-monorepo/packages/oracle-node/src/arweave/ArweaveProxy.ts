import Arweave from "arweave";
import { JWKInterface } from "arweave/node/lib/wallet";

export class ArweaveProxy {
  private arweaveClient: Arweave;

  constructor(private readonly jwk: JWKInterface) {
    this.arweaveClient = Arweave.init({
      host: "arweave.net",
      port: 443,
      protocol: "https",
    });
  }

  async getAddress(): Promise<string> {
    return await this.arweaveClient.wallets.jwkToAddress(this.jwk);
  }
}

export default ArweaveProxy;
