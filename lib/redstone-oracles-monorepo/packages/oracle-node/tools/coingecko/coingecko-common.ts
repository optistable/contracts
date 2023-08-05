import axios from "axios";
import { sleep } from "../common/sleep";

const SLEEP_MILLISECONDS_FOR_COINGECKO_FETCHING = 2000;

export interface SymbolToDetails {
  [symbol: string]: [{ id: string; name: string }];
}

export const COINGECKO_MANIFEST_PATH = `./manifests/single-source/coingecko.json`;
export const COINGECKO_FETCHER_PATH = `./src/fetchers/coingecko`;
export const SYMBOL_TO_DETAILS_PATH = `${COINGECKO_FETCHER_PATH}/coingecko-symbol-to-details.json`;
export const SYMBOL_TO_ID_PATH = `${COINGECKO_FETCHER_PATH}/coingecko-symbol-to-id.json`;
export const coingeckoClient = new (require("coingecko-api") as any)();

export async function getAllCoingeckoCoins() {
  let lastPageReached = false,
    pageNr = 1;
  const allCoins: any[] = [];

  while (!lastPageReached) {
    console.log(`Fetching coins from coingecko on page: ${pageNr}`);
    const response = await axios.get(
      "https://api.coingecko.com/api/v3/coins/markets?&=&=&page=200&sparkline=true&price_change_percentage=24h",
      {
        params: {
          vs_currency: "usd",
          order: "market_cap_desc",
          per_page: 250,
          page: pageNr,
          sparkline: true,
          price_change_percentage: "24h",
        },
      }
    );
    if (response.data.length === 0) {
      lastPageReached = true;
    } else {
      pageNr++;
      allCoins.push(...response.data);
      await sleep(SLEEP_MILLISECONDS_FOR_COINGECKO_FETCHING);
    }
  }

  return allCoins;
}
