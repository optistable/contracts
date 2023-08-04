import redstone from "redstone-api";
import { PriceData } from "redstone-api/lib/types";
import { Contract } from "ethers";
import { MockProvider, deployContract } from "ethereum-waffle";
import { AvalancheEvmFetcher } from "../../src/fetchers/evm-chain/AvalancheEvmFetcher";
import Multicall2 from "../../src/fetchers/evm-chain/contracts-details/common/Multicall2.json";
import { yieldYakContractsDetails } from "../../src/fetchers/evm-chain/contracts-details/yield-yak";
import { lpTokensContractsDetails } from "../../src/fetchers/evm-chain/contracts-details/lp-tokens";
import YYMock from "./mocks/YYMock.json";
import LPTokenMock from "./mocks/LPTokenMock.json";
import { mockRedstoneApiPrice } from "./_helpers";

jest.setTimeout(15000);

describe("Avalanche EVM fetcher", () => {
  let provider: MockProvider;
  let multicallContract: Contract;

  describe("YYAV3SA1", () => {
    beforeAll(async () => {
      provider = new MockProvider();
      const [wallet] = provider.getWallets();
      const Yycontract = await deployContract(wallet, {
        bytecode: YYMock.bytecode,
        abi: YYMock.abi,
      });

      multicallContract = await deployContract(wallet, {
        bytecode: Multicall2.bytecode,
        abi: Multicall2.abi,
      });

      yieldYakContractsDetails.YYAV3SA1.abi = YYMock.abi;
      yieldYakContractsDetails.YYAV3SA1.address = Yycontract.address;
    });

    test("Should properly fetch data", async () => {
      const fetcher = new AvalancheEvmFetcher(
        provider,
        multicallContract.address
      );

      mockRedstoneApiPrice(17, "AVAX");

      const result = await fetcher.fetchAll(["YYAV3SA1"]);
      expect(result).toEqual([{ symbol: "YYAV3SA1", value: 17.28590481 }]);
    });
  });

  describe("SAV2", () => {
    beforeAll(async () => {
      provider = new MockProvider();
      const [wallet] = provider.getWallets();
      const Yycontract = await deployContract(wallet, {
        bytecode: YYMock.bytecode,
        abi: YYMock.abi,
      });

      multicallContract = await deployContract(wallet, {
        bytecode: Multicall2.bytecode,
        abi: Multicall2.abi,
      });

      yieldYakContractsDetails.SAV2.abi = YYMock.abi;
      yieldYakContractsDetails.SAV2.address = Yycontract.address;
    });

    test("Should properly fetch data", async () => {
      const fetcher = new AvalancheEvmFetcher(
        provider,
        multicallContract.address
      );

      mockRedstoneApiPrice(23, "SAV2");

      const result = await fetcher.fetchAll(["SAV2"]);
      expect(result).toEqual([{ symbol: "SAV2", value: 23.38681239 }]);
    });
  });

  describe("LP Token", () => {
    beforeAll(async () => {
      provider = new MockProvider();
      const [wallet] = provider.getWallets();
      const lpTokenContract = await deployContract(wallet, {
        bytecode: LPTokenMock.bytecode,
        abi: LPTokenMock.abi,
      });

      multicallContract = await deployContract(wallet, {
        bytecode: Multicall2.bytecode,
        abi: Multicall2.abi,
      });

      lpTokensContractsDetails.TJ_AVAX_USDC_LP.abi = LPTokenMock.abi;
      lpTokensContractsDetails.TJ_AVAX_USDC_LP.address =
        lpTokenContract.address;
    });

    test("Should properly fetch data", async () => {
      const fetcher = new AvalancheEvmFetcher(
        provider,
        multicallContract.address
      );

      mockRedstoneApiPrice(17, "TJ_AVAX_USDC_LP");

      const result = await fetcher.fetchAll(["TJ_AVAX_USDC_LP"]);
      expect(result).toEqual([
        { symbol: "TJ_AVAX_USDC_LP", value: 98663550.92399499 },
      ]);
    });
  });
});
