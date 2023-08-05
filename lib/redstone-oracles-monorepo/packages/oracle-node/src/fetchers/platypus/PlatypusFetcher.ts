import { BaseFetcher } from "../BaseFetcher";
import { PricesObj } from "../../types";
import platypusTokens from "./platypus-tokens.json";
import graphProxy from "../../utils/graph-proxy";

const PLATYPUS_SUBGRAPH_FETCHER =
  "https://api.thegraph.com/subgraphs/name/messari/platypus-finance-avalanche";

export class PlatypusFetcher extends BaseFetcher {
  constructor() {
    super("platypus-finance");
  }

  async fetchData(ids: string[]) {
    const tokensIds = this.getTokenIdsForAssetIds(ids);
    const query = `{
      tokens(where: { id_in: ${JSON.stringify(tokensIds)} }) {
        id
        name
        symbol
        decimals
        lastPriceUSD
      }
    }`;

    return await graphProxy.executeQuery(PLATYPUS_SUBGRAPH_FETCHER, query);
  }

  validateResponse(response: any): boolean {
    return response !== undefined && response.data !== undefined;
  }

  async extractPrices(response: any): Promise<PricesObj> {
    const pricesObj: { [symbol: string]: number } = {};
    for (const token of response.data.tokens) {
      const { symbol, lastPriceUSD } = token;
      pricesObj[symbol] = Number(lastPriceUSD);
    }
    return pricesObj;
  }

  private getTokenIdsForAssetIds(assetIds: string[]): string[] {
    const tokenIds = [];

    for (const { id, name } of platypusTokens) {
      if (assetIds.includes(name)) {
        tokenIds.push(id);
      }
    }

    return tokenIds;
  }
}
