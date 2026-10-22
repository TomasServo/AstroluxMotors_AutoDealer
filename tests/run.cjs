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
const media = 'mods/PZ_TSB_AstroluxStructure/42/media';
const kioskScript = fs.readFileSync(`${media}/scripts/TSBAstroluxKiosk.txt`, 'utf8');
if (!/module TSBAstroluxVend/.test(kioskScript) || !/item SalesKiosk/.test(kioskScript)
  || !/ItemType = base:moveable/.test(kioskScript) || !/WorldObjectSprite = TSBAstroluxKiosk_0/.test(kioskScript)
  || /Obsolete|Hidden/.test(kioskScript)) throw Error('Kiosk must be a visible native furniture item');
if (JSON.parse(fs.readFileSync(`${media}/lua/shared/Translate/EN/ItemName.json`, 'utf8'))['TSBAstroluxVend.SalesKiosk'] !== 'Astrolux Motors Sales Kiosk') throw Error('Kiosk item name missing');
const kioskMenu = fs.readFileSync(`${media}/lua/client/TSBAstroluxVend/KioskClient.lua`, 'utf8');
if (/add kiosk to inventory|place sales kiosk here|kioskItem/.test(kioskMenu)) throw Error('Ground kiosk creation menus must be removed');
run(['-e', files.map(file => `assert(loadfile(${JSON.stringify(file.replaceAll('\\', '/'))}))`).join('\n') + "\nprint('PASS: runtime Lua syntax')"], 'PASS: runtime Lua syntax');
run(['tests/structure.lua'], 'PASS: perimeter, floors, centered openings');
run(['tests/menu.lua'], 'PASS: right-click menu');
run(['tests/clear-walls.lua'], 'PASS: 24 transparent panes');
run(['tests/visibility.lua'], 'PASS: all 404 slices');
run(['tests/flooring.lua'], 'PASS: 28 dark border tiles');
run(['tests/sliding-doors.lua'], 'PASS: eight native sliding leaves');
run(['tests/vending/payments.lua'], 'standalone Astrolux payment checks passed');
run(['tests/vending/areas.lua'], 'PASS: unrestricted remote rectangles');
run(['tests/vending/server-areas.lua'], 'PASS: server remote/huge area configuration');
run(['tests/vending/client-startup.lua'], 'PASS: client modules load before native handlers');
run(['tests/vending/sales-flow.lua'], 'PASS: kiosk quote/cash purchase queues remotely');
run(['tests/vending/furniture.lua'], 'PASS: native furniture hooks retain kiosk identity/setup');

run(['tests/decor-capture.lua'], 'PASS: decoration survey records relative furniture layout');
run(['tests/showroom-sink.lua'], 'PASS: native sink on opposite counter');
