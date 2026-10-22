const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
process.chdir(path.resolve(__dirname, '..'));
const cli = process.env.TSB_LUA_CLI || require.resolve('fengari-node-cli/src/lua-cli.js');
const walk = dir => fs.readdirSync(dir, { withFileTypes: true }).flatMap(entry => {
  const file = path.join(dir, entry.name);
  return entry.isDirectory() ? walk(file) : [file];
});
function run(args, marker) {
  const result = spawnSync(process.execPath, [cli, ...args], { encoding: 'utf8' });
  const output = (result.stdout || '') + (result.stderr || '');
  process.stdout.write(output);
  if (result.error) throw result.error;
  if (result.status !== 0 || !output.includes(marker) || output.includes('stack traceback:')) process.exit(1);
}
const files = walk('mods/PZ_TSB_AstroluxStructure').filter(file => file.endsWith('.lua'));
run(['-e', files.map(file => `assert(loadfile(${JSON.stringify(file.replaceAll('\\', '/'))}))`).join('\n') + "\nprint('PASS: runtime Lua syntax')"], 'PASS: runtime Lua syntax');
run(['tests/structure.lua'], 'PASS: perimeter, floors, four doors');
run(['tests/menu.lua'], 'PASS: right-click menu');
