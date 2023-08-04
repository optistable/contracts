import fs from "fs";

(() => {
  const manifestsDir = "../../manifests/single-source/lens.json";
  const fileData = fs.readFileSync(manifestsDir, "utf8");
  const data = JSON.parse(fileData);

  const lensHandlesObject = data.tokens;
  const result: { [x in string]: any } = {};
  for (const handle of Object.keys(lensHandlesObject)) {
    result[handle] = {
      logoURI:
        "https://raw.githubusercontent.com/redstone-finance/redstone-images/main/sources/lens.png",
      name: handle,
      url: `https://www.lensfrens.xyz/${handle}`,
      tags: ["lens"],
      providers: ["redstone"],
    };
  }
  console.log(JSON.stringify(result));
})();
