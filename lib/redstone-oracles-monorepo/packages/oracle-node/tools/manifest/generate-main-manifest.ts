import fs from "fs";
import { readJSON, saveJSON } from "../common/fs-utils";
import {
  MAIN_MANIFEST_PATH,
  SINGLE_SOURCE_MANIFESTS_FOLDER,
} from "../common/paths";
import { generateManifest } from "../common/manifest-utils";
import { Manifest, TokensConfig } from "../../src/types";
import popularTokens from "./popular-tokens.json";

const MAX_DEVIATION_FOR_POPULAR_TOKENS = 25;
const MAX_DEVIATION_FOR_UNPOPULAR_TOKENS = 80;

main();

function main() {
  const manifests = readSingleSourceManifests();

  // Building tokens
  const tokens: TokensConfig = {};
  for (const sourceManifest of manifests) {
    const sourceId = sourceManifest!.defaultSource![0];

    for (const tokenName in sourceManifest.tokens) {
      if (tokens[tokenName] !== undefined) {
        tokens[tokenName].source!.push(sourceId);
      } else {
        tokens[tokenName] = {
          source: [sourceId],
          maxPriceDeviationPercent: getMaxDeviationPercent(tokenName),
        };
      }
    }
  }

  // Sort tokens by number of sources
  const tokensWithSortedKeys: TokensConfig = {};
  const sortedKeys = Object.keys(tokens).sort((token1, token2) => {
    return tokens[token2].source!.length - tokens[token1].source!.length;
  });
  for (const symbol of sortedKeys) {
    tokensWithSortedKeys[symbol] = tokens[symbol];
  }

  const manifest = generateManifest({ tokens: tokensWithSortedKeys });

  saveJSON(manifest, MAIN_MANIFEST_PATH);
}

function readSingleSourceManifests() {
  const manifests: Manifest[] = [];
  const files = fs.readdirSync(SINGLE_SOURCE_MANIFESTS_FOLDER);

  for (const fileName of files) {
    const manifest = readJSON(`${SINGLE_SOURCE_MANIFESTS_FOLDER}/${fileName}`);
    manifests.push(manifest);
  }

  return manifests;
}

function getMaxDeviationPercent(symbol: string): number {
  return popularTokens.includes(symbol)
    ? MAX_DEVIATION_FOR_POPULAR_TOKENS
    : MAX_DEVIATION_FOR_UNPOPULAR_TOKENS;
}
