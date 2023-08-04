const generateSubManifest = require("./generate-submanifest-from-main");

const OUTPUT_FILE_PATH = "./manifests/avalanche.json";
const SYMBOLS = [
  "ETH",
  "USDT",
  "PNG",
  "AVAX",
  "XAVA",
  "LINK",
  "BTC",
  "FRAX",
  "YAK",
  "QI",
  "USDC",
  "YYAV3SA1",
  "sAVAX",
  "SAV2",
  "TJ_AVAX_USDC_LP",
  "PNG_AVAX_USDC_LP",
  "YY_TJ_AVAX_USDC_LP",
];

generateSubManifest(SYMBOLS, OUTPUT_FILE_PATH);
