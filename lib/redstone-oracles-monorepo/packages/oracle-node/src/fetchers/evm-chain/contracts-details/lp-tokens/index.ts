import TraderJoeLpAbi from "./TraderJoeLP.abi.json";
import PangolinLpAbi from "./PangolinLP.abi.json";

export const lpTokensContractsDetails = {
  TJ_AVAX_USDC_LP: {
    address: "0xf4003f4efbe8691b60249e6afbd307abe7758adb",
    abi: TraderJoeLpAbi,
  },
  PNG_AVAX_USDC_LP: {
    address: "0x0e0100ab771e9288e0aa97e11557e6654c3a9665",
    abi: PangolinLpAbi,
  },
};
