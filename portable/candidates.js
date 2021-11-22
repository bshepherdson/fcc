// Standalone script that examines an account.json-formatted file and proposes
// the best 4-, 3-, and 2-part superinstructions based on what was seen there.
// These are accounted by frequency, and reckoned against the total number of
// entries in the file.

const byLength = {1: {}, 2: {}, 3: {}, 4: {}};

// Turns an array like ['foo', 'bar', '(dolit)'] into 'foo_bar_(dolit)'.
function slug(array) {
  return array.join('_');
}

function count(array) {
  const key = slug(array);
  const len = byLength[array.length];
  if (len[key]) {
    len[key]++;
  } else {
    len[key] = 1;
  }
}

function mostFrequent(map) {
  const keys = Object.keys(map);
  keys.sort((x, y) => map[y] - map[x]);
  for (let i = 0; i < 60 && i < keys.length; i++) {
    console.log(map[keys[i]] + "\t" + keys[i]);
  }
}

const contents = require('fs').readFileSync(process.argv[2], 'utf-8');
// There's an extra comma at the front, and we want to wrap with [].
const adjusted = '[' + contents.substring(1) + ']';
const parsed = JSON.parse(adjusted);
parsed.forEach(count);

console.log('Fours:');
mostFrequent(byLength[4]);
console.log('Threes:');
mostFrequent(byLength[3]);
console.log('Twos:');
mostFrequent(byLength[2]);

