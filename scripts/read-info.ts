//
//  read-info.ts
//  factorio-k2-reinforced-plates
//
//  Created by Rakesh Ayyaswami on 01 Jan 2023.
//

import fs from 'fs';

function main(): void {
  // Check if key path is provided
  const keyPath = process.argv[2];
  if (!keyPath) {
    printUsageAndExit();
  }

  // read info.json
  const info = JSON.parse(fs.readFileSync('info.json', 'utf8'));

  // break key path into parts & extract the value
  const keyParts = keyPath.split('.');
  let value = info;
  for (const keyPart of keyParts) {
    value = value[keyPart];
    if (value === undefined) {
      console.error(`Key path '${keyPath}' not found`);
      process.exit(-1);
    }
  }

  // print the value
  console.log(value);
}
main();

function printUsageAndExit(code = -1): never {
  console.log('Usage: npm run read-info <key-path>');
  process.exit(code);
}
