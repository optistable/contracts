import { toBuffer, bufferToHex, keccak256 } from "ethereumjs-util";
import { ethers } from "ethers";
import sortDeepObjectArrays from "sort-deep-object-arrays";
import {
  personalSign,
  recoverPersonalSignature,
  TypedMessage,
} from "@metamask/eth-sig-util";
import {
  PricePackage,
  ShortSinglePrice,
  SignedPricePackage,
  SerializedPriceData,
} from "../types";
import _ from "lodash";

interface MessageTypeProperty {
  name: string;
  type: string;
}
interface PriceDataMessageType {
  EIP712Domain: MessageTypeProperty[];
  PriceData: MessageTypeProperty[];
  [additionalProperties: string]: MessageTypeProperty[];
}

const PriceData = [
  { name: "symbols", type: "bytes32[]" },
  { name: "values", type: "uint256[]" },
  { name: "timestamp", type: "uint256" },
];

const EIP712Domain = [
  { name: "name", type: "string" },
  { name: "version", type: "string" },
  { name: "chainId", type: "uint256" },
];

const serializePriceValue = (value: number) => Math.round(value * 10 ** 8);

export default class EvmPriceSignerOld {
  private _domainData: object;

  constructor(version: string = "0.4", chainId: number = 1) {
    this._domainData = {
      name: "Redstone",
      version: version,
      chainId: chainId,
    };
  }

  getDataToSign(
    priceData: SerializedPriceData
  ): TypedMessage<PriceDataMessageType> {
    return {
      types: {
        EIP712Domain,
        PriceData,
      },
      domain: this._domainData,
      primaryType: "PriceData",
      message: priceData as Record<string, any>,
    };
  }

  getLiteDataBytesString(priceData: SerializedPriceData): string {
    // Calculating lite price data bytes array
    let data = "";
    for (let i = 0; i < priceData.symbols.length; i++) {
      const symbol = priceData.symbols[i];
      const value = priceData.values[i];
      data += symbol.substr(2) + value.toString(16).padStart(64, "0");
    }
    data += Math.ceil(priceData.timestamp / 1000)
      .toString(16)
      .padStart(64, "0");

    return data;
  }

  private getLiteDataToSign(priceData: SerializedPriceData): string {
    const data = this.getLiteDataBytesString(priceData);
    const hash = bufferToHex(keccak256(toBuffer("0x" + data)));
    return hash;
  }

  calculateLiteEvmSignature(
    priceData: SerializedPriceData,
    privateKey: string
  ): string {
    const data = this.getLiteDataToSign(priceData);
    return personalSign({ privateKey: toBuffer(privateKey), data });
  }

  public static convertStringToBytes32String(str: string) {
    if (str.length > 31) {
      // TODO: improve checking if str is a valid bytes32 string later
      const bytes32StringLength = 32 * 2 + 2; // 32 bytes (each byte uses 2 symbols) + 0x
      if (str.length === bytes32StringLength && str.startsWith("0x")) {
        return str;
      } else {
        // Calculate keccak hash if string is bigger than 32 bytes
        return ethers.utils.id(str);
      }
    } else {
      return ethers.utils.formatBytes32String(str);
    }
  }

  serializeToMessage(pricePackage: PricePackage): SerializedPriceData {
    // We clean and sort prices to be sure that prices
    // always have the same format
    const cleanPricesData = pricePackage.prices.map((p) =>
      _.pick(p, ["symbol", "value"])
    );
    const sortedPrices = sortDeepObjectArrays(cleanPricesData);

    return {
      symbols: sortedPrices.map((p: ShortSinglePrice) =>
        EvmPriceSignerOld.convertStringToBytes32String(p.symbol)
      ),
      values: sortedPrices.map((p: ShortSinglePrice) =>
        serializePriceValue(p.value)
      ),
      timestamp: pricePackage.timestamp,
    };
  }

  signPricePackage(
    pricePackage: PricePackage,
    privateKey: string
  ): SignedPricePackage {
    const serializedPriceData = this.serializeToMessage(pricePackage);
    return {
      pricePackage,
      signerAddress: new ethers.Wallet(privateKey).address,
      liteSignature: this.calculateLiteEvmSignature(
        serializedPriceData,
        privateKey
      ),
    };
  }

  verifyLiteSignature(signedPricePackage: SignedPricePackage): boolean {
    const serializedPriceData = this.serializeToMessage(
      signedPricePackage.pricePackage
    );
    const data = this.getLiteDataToSign(serializedPriceData);

    const signer = recoverPersonalSignature({
      data,
      signature: signedPricePackage.liteSignature,
    });

    const signerAddressUC = signer.toUpperCase();
    const expectedSignerAddress = signedPricePackage.signerAddress;
    const expectedSignerAddressUC = expectedSignerAddress.toUpperCase();

    return signerAddressUC === expectedSignerAddressUC;
  }
}
