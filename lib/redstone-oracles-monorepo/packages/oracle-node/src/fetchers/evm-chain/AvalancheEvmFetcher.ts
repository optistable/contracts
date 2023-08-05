import redstone from "redstone-api";
import { BigNumber, ethers, providers } from "ethers";
import { Interface } from "ethers/lib/utils";
import { BaseFetcher } from "../BaseFetcher";
import { EvmMulticallService } from "./EvmMulticallService";
import { yieldYakContractsDetails } from "./contracts-details/yield-yak";
import { lpTokensContractsDetails } from "./contracts-details/lp-tokens";
import { MulticallParsedResponses, PricesObj } from "../../types";

type YieldYakDetailsKeys = keyof typeof yieldYakContractsDetails;
type LpTokensDetailsKeys = keyof typeof lpTokensContractsDetails;

const MUTLICALL_CONTRACT_ADDRESS = "0x8755b94F88D120AB2Cc13b1f6582329b067C760d";

const yyTokenIds = ["YYAV3SA1", "SAV2", "YY_TJ_AVAX_USDC_LP"];

const lpTokensIds = ["TJ_AVAX_USDC_LP", "PNG_AVAX_USDC_LP"];

export class AvalancheEvmFetcher extends BaseFetcher {
  private evmMulticallService: EvmMulticallService;

  constructor(
    provider: providers.Provider,
    multicallContractAddress: string = MUTLICALL_CONTRACT_ADDRESS
  ) {
    super("avalanche-evm-fetcher");
    this.evmMulticallService = new EvmMulticallService(
      provider,
      multicallContractAddress
    );
  }

  async fetchData(ids: string[]) {
    const requests = [];
    for (const id of ids) {
      if (yyTokenIds.includes(id)) {
        const requestsPerId = this.prepareYYMulticallRequests(id);
        requests.push(...requestsPerId);
      } else if (lpTokensIds.includes(id)) {
        const requestsPerId = this.prepareLpTokenMulticallRequests(id);
        requests.push(...requestsPerId);
      }
    }
    return await this.evmMulticallService.performMulticall(requests);
  }

  prepareYYMulticallRequests(id: string) {
    const { abi, address } =
      yieldYakContractsDetails[id as YieldYakDetailsKeys];
    const totalDepositsData = new Interface(abi).encodeFunctionData(
      "totalDeposits"
    );
    const totalSupplyData = new Interface(abi).encodeFunctionData(
      "totalSupply"
    );
    const requests = [
      {
        address,
        data: totalDepositsData,
        name: "totalDeposits",
      },
      {
        address,
        data: totalSupplyData,
        name: "totalSupply",
      },
    ];
    return requests;
  }

  prepareLpTokenMulticallRequests(id: string) {
    const { abi, address } =
      lpTokensContractsDetails[id as LpTokensDetailsKeys];
    const getReservesData = new Interface(abi).encodeFunctionData(
      "getReserves"
    );
    const totalSupplyData = new Interface(abi).encodeFunctionData(
      "totalSupply"
    );
    const requests = [
      {
        address,
        data: getReservesData,
        name: "getReserves",
      },
      {
        address,
        data: totalSupplyData,
        name: "totalSupply",
      },
    ];
    return requests;
  }

  async extractPrices(
    response: MulticallParsedResponses,
    ids: string[]
  ): Promise<PricesObj> {
    const pricesObject: PricesObj = {};
    for (const id of ids) {
      if (yyTokenIds.includes(id)) {
        const price = await this.extractPriceForYieldYak(response, id);
        pricesObject[id] = Number(price);
      } else if (lpTokensIds.includes(id)) {
        const price = await this.extractPriceForLpTokens(response, id);
        pricesObject[id] = Number(price);
      }
    }
    return pricesObject;
  }

  async extractPriceForYieldYak(
    multicallResult: MulticallParsedResponses,
    id: string
  ) {
    const { address } = yieldYakContractsDetails[id as YieldYakDetailsKeys];

    const totalDeposits = BigNumber.from(
      multicallResult[address].totalDeposits.value
    );
    const totalSupply = BigNumber.from(
      multicallResult[address].totalSupply.value
    );

    const tokenValue = totalDeposits
      .mul(ethers.utils.parseUnits("1.0", 8))
      .div(totalSupply);

    const tokenPrice = await this.fetchTokenPrice(id);
    const yieldYakPrice = tokenValue
      .mul(tokenPrice)
      .div(ethers.utils.parseUnits("1.0", 8));

    return ethers.utils.formatEther(yieldYakPrice);
  }

  async extractPriceForLpTokens(
    multicallResult: MulticallParsedResponses,
    id: string
  ) {
    const { address } = lpTokensContractsDetails[id as LpTokensDetailsKeys];

    const reserves = multicallResult[address].getReserves.value;
    const wavaxReserve = BigNumber.from(reserves.slice(0, 66));
    const wavaxPrice = await this.fetchPriceFromRedStone("WAVAX");
    const wavaxReservePrice = wavaxReserve.mul(wavaxPrice);

    const usdcReserveInHex = `0x${reserves.slice(66, 130)}`;
    const usdcReserveWith18Decimals = BigNumber.from(usdcReserveInHex).mul(
      ethers.utils.parseUnits("1.0", 12)
    );
    const usdcPrice = await this.fetchPriceFromRedStone("USDC");
    const usdcReservePrice = usdcReserveWith18Decimals.mul(usdcPrice);

    const reservesPricesSum = wavaxReservePrice.add(usdcReservePrice);
    const totalSupply = BigNumber.from(
      multicallResult[address].totalSupply.value
    );
    const lpTokenPrice = reservesPricesSum.div(totalSupply);
    return ethers.utils.formatEther(lpTokenPrice);
  }

  async fetchTokenPrice(id: string) {
    switch (id) {
      case "YYAV3SA1": {
        return this.fetchPriceFromRedStone("AVAX");
      }
      case "SAV2": {
        return this.fetchPriceFromRedStone("sAVAX");
      }
      case "YY_TJ_AVAX_USDC_LP": {
        return this.fetchPriceFromRedStone("TJ_AVAX_USDC_LP");
      }
      default:
        throw new Error("Invalid id for Avalanche EVM fetcher");
    }
  }

  async fetchPriceFromRedStone(token: string) {
    const priceObjectFromApi = await redstone.getPrice(token);
    const priceAsString = priceObjectFromApi.value.toString();
    return ethers.utils.parseUnits(priceAsString, 18);
  }
}
