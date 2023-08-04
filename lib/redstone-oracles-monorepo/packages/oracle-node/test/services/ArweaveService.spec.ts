import { rest } from "msw";
import { setupServer } from "msw/node";
import ArweaveService from "../../src/arweave/ArweaveService";
import devManifest from "../../manifests/dev/dev.json";
import { Manifest } from "../../src/types";

const mockOracleRegistryState = {
  nodes: {
    nodeId: {
      dataServiceId: "testDataServiceId",
      evmAddress: "0x19E7E376E7C213B7E7e7e46cc70A5dD086DAff2A",
    },
  },
  dataServices: {
    testDataServiceId: {
      manifestTxId: "mockManifestTxId",
    },
  },
};

const devManifestWithTxId: Manifest = {
  ...devManifest,
  txId: "mockManifestTxId",
};

jest.mock("redstone-sdk", () => ({
  ...jest.requireActual("redstone-sdk"),
  getOracleRegistryState: jest.fn(() => mockOracleRegistryState),
}));

const validHandler = rest.get(
  "https://arweave.net/mockManifestTxId",
  (_, res, ctx) => res(ctx.json(devManifest))
);

const invalidHandler = rest.get(
  "https://arweave.net/mockManifestTxId",
  (_, res, ctx) => res(ctx.status(400))
);

const bigDelayHandler = rest.get(
  "https://arweave.net/mockManifestTxId",
  (_, res, ctx) => res(ctx.delay(10), ctx.json(devManifest))
);

export const server = setupServer(validHandler);

const TEST_TIMEOUT_MS = 5;

describe("ArweaveService - getCurrentManifest", () => {
  let arweaveService: ArweaveService;

  beforeAll(() => server.listen());
  afterEach(() => server.resetHandlers());
  afterAll(() => server.close());
  beforeEach(() => {
    arweaveService = new ArweaveService(TEST_TIMEOUT_MS);
  });

  test("Should fetch current manifest", async () => {
    const manifest = await arweaveService.getCurrentManifest();
    expect(manifest).toEqual(devManifestWithTxId);
  });

  test("Fetching failed, old manifest doesn't exist", async () => {
    server.use(invalidHandler);
    await expect(arweaveService.getCurrentManifest()).rejects.toThrowError(
      "Cannot fetch new manifest and old manifest doesn't exist"
    );
  });

  test("Fetching failed, old manifest exists", async () => {
    server.use(invalidHandler);
    const manifest = await arweaveService.getCurrentManifest(
      devManifestWithTxId
    );
    expect(manifest).toEqual(devManifestWithTxId);
  });

  test("Fetching failed with timeout, old manifest doesn't exist", async () => {
    server.use(bigDelayHandler);
    await expect(arweaveService.getCurrentManifest()).rejects.toThrowError(
      "Cannot fetch new manifest and old manifest doesn't exist"
    );
  });

  test("Fetching failed with timeout, old manifest exists", async () => {
    server.use(bigDelayHandler);
    const manifest = await arweaveService.getCurrentManifest(
      devManifestWithTxId
    );
    expect(manifest).toEqual(devManifestWithTxId);
  });
});
