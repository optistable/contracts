const fs = require("fs");
const manifestForMainProvider = require("../../manifests/data-services/main.json");

module.exports = function (symbols, outputFilePath, predefinedManifest = {}) {
  const manifest = {
    interval: 10000,
    priceAggregator: "median",
    defaultSource: ["coingecko"],
    sourceTimeout: 7000,
    maxPriceDeviationPercent: 25,
    evmChainId: 1,
    httpBroadcasterURLs: [
      "https://api.redstone.finance",
      "https://vwx3eni8c7.eu-west-1.awsapprunner.com",
      "https://container-service-1.dv9sai71f4rsq.eu-central-1.cs.amazonlightsail.com",
    ],
    enableStreamrBroadcaster: false,
    enableArweaveBackup: false,
    tokens: {},
    ...predefinedManifest,
  };

  // Building tokens
  for (const symbol of symbols) {
    manifest.tokens[symbol] = manifestForMainProvider.tokens[symbol];
  }

  // Saving manifest to the output file
  console.log(`Saving manifest to: ${outputFilePath}`);
  fs.writeFileSync(outputFilePath, JSON.stringify(manifest, null, 2) + "\n");
};
