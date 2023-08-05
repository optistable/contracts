import { SignedDataPackage } from "redstone-protocol";

export interface Broadcaster {
  broadcast(signedDataPackages: SignedDataPackage[]): Promise<void>;
}
