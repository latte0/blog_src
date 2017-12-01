const katex = require('./katex.min.js');

let content = '';
process.stdin.setEncoding('utf-8');
process.stdin.resume();
process.stdin.on('data', buf => content += buf.toString());
process.stdin.on('end', () => {
  try {
    console.log(katex.renderToString(content).trim());
  } catch (e) {
    console.error(e.toString());
  }
});
