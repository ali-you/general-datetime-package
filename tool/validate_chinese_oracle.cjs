// Independent comparison with the ICU bundled in Node. The pinned .NET table is authoritative
// for this package; intentional astronomical/table differences are reported.
const fs = require('node:fs');
const path = require('node:path');
const rows = JSON.parse(fs.readFileSync(path.join(__dirname,
  '../packages/general_datetime_core/test/fixtures/chinese_dotnet_months.json')));
const fmt = new Intl.DateTimeFormat('en-u-ca-chinese', {
  timeZone: 'UTC', year: 'numeric', month: 'numeric', day: 'numeric'});
const mismatches = [];
let checked = 0;
for (const [start, year, ordinal, month, leap, length] of rows) {
  for (let day = 1; day <= length; day++) {
    const date = new Date(Date.parse(start + 'T00:00:00Z') + (day - 1) * 86400000);
    const fields = Object.fromEntries(fmt.formatToParts(date).map(p => [p.type, p.value]));
    const expected = [year, month, leap, day];
    const actual = [+fields.relatedYear, parseInt(fields.month), fields.month.includes('bis'), +fields.day];
    if (JSON.stringify(expected) !== JSON.stringify(actual)) {
      mismatches.push({date: date.toISOString().slice(0, 10), dotnet: expected, icu: actual});
    }
    checked++;
  }
}
const result = {icuVersion: process.versions.icu, nodeVersion: process.versions.node,
  checkedDays: checked, mismatchDays: mismatches.length, mismatches};
const check = process.argv[2] === '--check';
const output = check ? (process.argv[3] || path.join(__dirname, '../docs/chinese-icu-comparison.json'))
  : process.argv[2];
if (check) {
  const baseline = JSON.parse(fs.readFileSync(output));
  for (const key of ['icuVersion', 'checkedDays', 'mismatchDays', 'mismatches']) {
    if (JSON.stringify(baseline[key]) !== JSON.stringify(result[key])) {
      throw new Error(`Chinese ICU comparison changed: ${key}`);
    }
  }
} else if (output) {
  fs.writeFileSync(output, JSON.stringify(result, null, 2) + '\n');
}
console.log(JSON.stringify({...result, mismatches: mismatches.slice(0, 5)}));
