const prompts = require("prompts");
const jwk = require("../../.secrets/redstone-dev-jwk.json");
const { default: Bundlr } = require("@bundlr-network/client");

const TEST_TAG_NAME = "redstone-test-tag-hehe";

main();

async function main() {
  // Prompt test tag value
  const { testTagValue } = await prompts({
    type: "text",
    name: "testTagValue",
    message: "Enter test tag value",
  });

  // Create bundlr instance
  const bundlr = new Bundlr("https://node2.bundlr.network/", "arweave", jwk);

  const tx = bundlr.createTransaction("Some mock data", {
    tags: [{ name: TEST_TAG_NAME, value: testTagValue }],
  });

  console.log(`Signing tx: ${tx.id}`);
  await tx.sign();
  console.log(`Uploading tx: ${tx.id}`);
  await tx.upload();
  console.log(`Uploaded :)`);
}
