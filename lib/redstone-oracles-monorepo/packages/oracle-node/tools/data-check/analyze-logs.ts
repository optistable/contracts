import fs from "fs";

interface ParsedLogLine {
  type: string;
  args: string[];
}

interface Counters {
  [key: string]: number;
}

type MessageDetails =
  | {
      type: "fetching-failed";
      failedSource: string;
    }
  | { type: "not-included-in-response"; sourceName: string; id: string }
  | { type: "no-valid-values-for-symbol"; symbol: string }
  | { type: "fetch-symbol-success"; symbol: string }
  | {
      type: "fetch-source-success";
      fetchedAssetsCount: number;
      sourceName: string;
    }
  | { type: "other" };

const ERROR_CUT_LENGTH = 100;
const LOGS_FILE = "./tmp.out";
const FETCHNIG_FAILED_REGEX = /Fetching failed for source: (.*):/;
const NOT_IN_RESPONSE_REGEX = /Id (.*) is not included in response for: (.*)/;
const NO_VALID_VALUES_REGEX = /No valid values for symbol: (.*)\n/;
const FETCH_SYMBOL_SUCCESS_REGEX = /Fetched price : (.*) :/;
const FETCH_SOURCE_SUCCESS_REGEX =
  /Fetched prices in USD for (.*) currencies from source: \"(.*)\"/;

main();

async function main() {
  const logs = fs.readFileSync(LOGS_FILE, "utf8");
  const logLines = logs.split("\n");

  const logLevels: Counters = {};
  const failedSources: Counters = {};
  const sourcesErrors: { [sourceName: string]: Counters } = {};
  const notIncludedInResponse: { [sourceName: string]: Counters } = {};
  const noValidValuesForSymbols: Counters = {};
  const fetchSuccessSources: Counters = {};
  const fetchSuccessSymbols: Counters = {};
  for (const logLine of logLines) {
    try {
      const parsedMessage = JSON.parse(logLine) as ParsedLogLine;
      const messageDetails = analyzeLogMessage(parsedMessage);

      // Checking message details
      switch (messageDetails.type) {
        case "fetching-failed": {
          const { failedSource } = messageDetails;
          safelyIncrement(failedSources, failedSource);
          if (!sourcesErrors[failedSource]) {
            sourcesErrors[failedSource] = {};
          }
          safelyIncrement(
            sourcesErrors[failedSource],
            parsedMessage.args[1].slice(0, ERROR_CUT_LENGTH)
          );
          break;
        }
        case "not-included-in-response": {
          const { sourceName, id } = messageDetails;
          if (!notIncludedInResponse[sourceName]) {
            notIncludedInResponse[sourceName] = {};
          }
          safelyIncrement(notIncludedInResponse[sourceName], id);
          break;
        }
        case "no-valid-values-for-symbol": {
          safelyIncrement(noValidValuesForSymbols, messageDetails.symbol);
          break;
        }
        case "fetch-symbol-success": {
          safelyIncrement(fetchSuccessSymbols, messageDetails.symbol);
          break;
        }
        case "fetch-source-success": {
          safelyIncrement(fetchSuccessSources, messageDetails.sourceName);
        }
      }

      // Counting types
      safelyIncrement(logLevels, parsedMessage.type);
    } catch (e) {}
  }

  const finalReport = {
    logLevels,
    failedSources,
    notIncludedInResponse,
    failedSourcesCount: Object.keys(failedSources).length,
    validSourceCount: Object.keys(fetchSuccessSources).length,
    noValidValuesForSymbols: Object.keys(noValidValuesForSymbols).length,
    fetchSuccessSymbols: Object.keys(fetchSuccessSymbols).length,
    sourcesErrors,
  };

  console.log(JSON.stringify(finalReport, null, 2));
}

function safelyIncrement(obj: Counters, key: string) {
  obj[key] = (obj[key] || 0) + 1;
}

function analyzeLogMessage(logLine: ParsedLogLine): MessageDetails {
  const message = logLine.args[0] || "";

  if (FETCHNIG_FAILED_REGEX.test(message)) {
    const failedSource = FETCHNIG_FAILED_REGEX.exec(message)![1];
    return {
      type: "fetching-failed",
      failedSource,
    };
  } else if (NOT_IN_RESPONSE_REGEX.test(message)) {
    const parsedRegex = NOT_IN_RESPONSE_REGEX.exec(message)!;
    return {
      type: "not-included-in-response",
      id: parsedRegex[1],
      sourceName: parsedRegex[2],
    };
  } else if (NO_VALID_VALUES_REGEX.test(message)) {
    const parsedRegex = NO_VALID_VALUES_REGEX.exec(message)!;
    return {
      type: "no-valid-values-for-symbol",
      symbol: parsedRegex[1],
    };
  } else if (FETCH_SYMBOL_SUCCESS_REGEX.test(message)) {
    const parsedRegex = FETCH_SYMBOL_SUCCESS_REGEX.exec(message)!;
    return {
      type: "fetch-symbol-success",
      symbol: parsedRegex[1],
    };
  } else if (FETCH_SOURCE_SUCCESS_REGEX.test(message)) {
    const parsedRegex = FETCH_SOURCE_SUCCESS_REGEX.exec(message)!;
    return {
      type: "fetch-source-success",
      fetchedAssetsCount: Number(parsedRegex[1]),
      sourceName: parsedRegex[2],
    };
  } else {
    return {
      type: "other",
    };
  }
}
