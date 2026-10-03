// Validate the shipped TOC/XML graph, including libraries hidden by other addons.
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '../..');
const visited = new Set();
const errors = [];
function visit(file) {
  if (visited.has(file)) return;
  visited.add(file);
  if (!fs.existsSync(file)) {
    errors.push(`Missing load dependency: ${path.relative(root, file)}`);
    return;
  }
  const source = fs.readFileSync(file, 'utf8');
  let refs = [];
  if (file.endsWith('.toc')) {
    refs = source.split(/\r?\n/).map(s => s.trim()).filter(s => s && !s.startsWith('#'));
  } else if (file.endsWith('.xml')) {
    refs = [...source.matchAll(/<(?:Script|Include)\b[^>]*\bfile=["']([^"']+)["']/g)].map(m => m[1]);
  }
  for (const ref of refs) visit(path.resolve(path.dirname(file), ref.replace(/\\/g, '/')));
}
visit(path.join(root, 'Bistooltip/Bistooltip.toc'));
if (errors.length) {
  console.error(errors.join('\n'));
  process.exitCode = 1;
} else {
  console.log(`package: OK (${visited.size} load dependencies)`);
}
