import fetchers from "../../src/fetchers/index";
import { mockFetcherResponse } from "./_helpers";

jest.mock("axios");

describe("lens fetcher", () => {
  const fetcher = fetchers["lens"];

  beforeEach(() => {
    mockFetcherResponse("../../src/fetchers/lens/example-response.json");
  });

  it("should properly fetch data", async () => {
    const result = await fetcher.fetchAll([
      "aaveaave.lens",
      "wagmi.lens",
      "yoginth.lens",
    ]);
    expect(result).toEqual([
      {
        symbol: "aaveaave.lens",
        value: 4627,
      },
      {
        symbol: "wagmi.lens",
        value: 1878.5,
      },
      {
        symbol: "yoginth.lens",
        value: 57483.5,
      },
    ]);
  });
});
