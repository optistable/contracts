import YieldYakAaveAVAXAbi from "./YYAaveAVAX.abi.json";
import YieldYakSAVAXAbi from "./YYSAVAX.abi.json";
import YYTraderJoeLPTokenAbi from "./YYTraderJoeLPToken.abi.json";

export const yieldYakContractsDetails = {
  YYAV3SA1: {
    address: "0xaAc0F2d0630d1D09ab2B5A400412a4840B866d95",
    abi: YieldYakAaveAVAXAbi,
  },
  SAV2: {
    address: "0xd0F41b1C9338eB9d374c83cC76b684ba3BB71557",
    abi: YieldYakSAVAXAbi,
  },
  YY_TJ_AVAX_USDC_LP: {
    address: "0xDEf94a13fF31FB6363f1e03bF18fe0F59Db83BBC",
    abi: YYTraderJoeLPTokenAbi,
  },
};
