const twemoji = require('./twemoji.npm.js');

let content = '';
process.stdin.setEncoding('utf-8');
process.stdin.resume();
process.stdin.on('data', buf => content += buf.toString());
process.stdin.on('end', () => {
  try {
    const result = twemoji.parse(content, {
        base: '/images/',
        folder: 'emojis',
      }).trim();
    console.log(result);
  } catch (e) {
    console.error(e.toString());
  }
});
