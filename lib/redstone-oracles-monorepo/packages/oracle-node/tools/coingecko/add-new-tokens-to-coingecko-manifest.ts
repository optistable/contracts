import prompts from "prompts";
import { Manifest } from "../../src/types";
import { readJSON, saveJSON } from "../common/fs-utils";
import tokens from "../../src/config/tokens.json";
import {
  generateManifest,
  symbolArrToTokensConfig,
} from "../common/manifest-utils";
import { MAIN_MANIFEST_PATH } from "../common/paths";
import {
  COINGECKO_MANIFEST_PATH,
  getAllCoingeckoCoins,
  SymbolToDetails,
  SYMBOL_TO_DETAILS_PATH,
} from "./coingecko-common";

const mainManifest: Manifest = readJSON(MAIN_MANIFEST_PATH);
const coingeckoSymbolToDetails: SymbolToDetails = readJSON(
  SYMBOL_TO_DETAILS_PATH
);

main();

async function main() {
  const { numberOfTokensToAdd } = await prompts({
    type: "number",
    name: "numberOfTokensToAdd",
    message: "How many *new* tokens do you want to add with coingecko source?",
  });

  const tokensToAdd = await getNewTokensToAdd(numberOfTokensToAdd);
  console.log(
    `The following tokens will be added`,
    JSON.stringify(tokensToAdd)
  );

  const { tokensAddingConfirmed } = await prompts({
    type: "confirm",
    name: "tokensAddingConfirmed",
    message: `Are you sure you want to add ${tokensToAdd.length} new tokens to the coingecko manifest?`,
  });

  if (tokensAddingConfirmed) {
    const currentCoingeckoManifest: Manifest = readJSON(
      COINGECKO_MANIFEST_PATH
    );
    const newCoingeckoManifest = generateManifest({
      defaultSource: ["coingecko"],
      tokens: {
        ...currentCoingeckoManifest.tokens,
        ...symbolArrToTokensConfig(tokensToAdd),
      },
    });

    saveJSON(newCoingeckoManifest, COINGECKO_MANIFEST_PATH);
  }
}

// Selecting new tokens with the highest market cap
// Each new token symbol should not be included in the current main manifest
async function getNewTokensToAdd(
  numberOfTokensToAdd: number
): Promise<string[]> {
  const coins = await getAllCoingeckoCoins();

  const newTokens: string[] = [];
  for (const coin of coins) {
    const symbol = coin.symbol.toUpperCase();
    if (newTokens.length >= numberOfTokensToAdd) {
      break;
    }
    if (shouldNewTokenBeAdded(symbol)) {
      newTokens.push(symbol);
    }
  }

  return newTokens;
}

function shouldNewTokenBeAdded(symbol: string) {
  const notIncludedInMainManifest = !mainManifest.tokens[symbol];
  const hasMetadata = !!(tokens as any)[symbol];
  const tokenSymbolIsNotANumber = isNaN(Number(symbol));
  const symbolIsUnambiguous = coingeckoSymbolToDetails[symbol].length === 1;
  return (
    notIncludedInMainManifest &&
    hasMetadata &&
    tokenSymbolIsNotANumber &&
    symbolIsUnambiguous
  );
}
