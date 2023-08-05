import fs from "fs";

export const readJSON = (path: string): any => {
  const data = fs.readFileSync(path, { encoding: "utf8" });
  return JSON.parse(data);
};

export const saveJSON = (obj: any, path: string) => {
  console.log(`Saving prettified json to: ${path}`);
  const content = JSON.stringify(obj, null, 2) + "\n";
  fs.writeFileSync(path, content);
};
