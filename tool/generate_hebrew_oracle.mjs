// Generate independent reference tables using an externally installed Hebcal.
// npm install --prefix .dart_tool/hebrew_oracle --ignore-scripts @hebcal/hdate@0.23.1
// node tool/generate_hebrew_oracle.mjs .dart_tool/hebrew_oracle output.json
// No Hebcal implementation or source is copied into the published Dart package.
import { readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const [referenceDirectory, output] = process.argv.slice(2);
if (!referenceDirectory || !output) {
  throw new Error('Provide the reference installation directory and output JSON path.');
}
const packageRoot = resolve(referenceDirectory, 'node_modules/@hebcal/hdate');
const metadata = JSON.parse(readFileSync(resolve(packageRoot, 'package.json'), 'utf8'));
const { HDate } = await import(pathToFileURL(resolve(packageRoot, 'dist/esm/index.js')).href);
const years = [];
for (let year = 1; year <= 9999; year++) {
  const lengths = Array(13).fill(0);
  const leap = HDate.isLeapYear(year);
  for (let month = 1; month <= HDate.monthsInYear(year); month++) {
    const slot = month <= 6 ? month + 7 : !leap && month === 12 ? 7 : month - 6;
    lengths[slot - 1] = HDate.daysInMonth(month, year);
  }
  years.push({
    year, startDay: new HDate(1, 7, year).abs() - 719163,
    lengths, yearLength: HDate.daysInYear(year),
  });
}
writeFileSync(output, JSON.stringify({
  source: `${metadata.name} ${metadata.version}`, calendar: 'Hebcal Rata Die', years,
}));
console.log(`Independent Hebcal oracle: ${years.length} years, ${years.reduce((sum, year) => sum + year.yearLength, 0)} days.`);
