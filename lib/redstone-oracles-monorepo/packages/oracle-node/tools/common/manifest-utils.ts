import { Manifest, TokensConfig } from "../../src/types";

export const generateManifest = (
  customManifestFields: Partial<Manifest>
): Manifest => {
  return {
    interval: 60000,
    priceAggregator: "median",
    sourceTimeout: 50000,
    maxPriceDeviationPercent: 80,
    evmChainId: 1,
    httpBroadcasterURLs: [
      "https://api.redstone.finance",
      "https://vwx3eni8c7.eu-west-1.awsapprunner.com",
      "https://container-service-1.dv9sai71f4rsq.eu-central-1.cs.amazonlightsail.com",
    ],
    enableStreamrBroadcaster: false,
    tokens: {},
    ...customManifestFields,
  };
};

export const symbolArrToTokensConfig = (symbols: string[]): TokensConfig => {
  const tokensConfig: TokensConfig = {};
  for (const symbol of symbols) {
    tokensConfig[symbol] = {};
  }
  return tokensConfig;
};
