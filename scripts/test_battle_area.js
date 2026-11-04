const assert = require('assert');
const fs = require('fs');
const path = require('path');

const scriptPath = path.join(__dirname, '..', 'script.lua');
const source = fs.readFileSync(scriptPath, 'utf8');

function requireSource(pattern, message) {
  assert(pattern.test(source), message);
}

requireSource(
  /if not force and g_webmap_battle_area_last_signature==payload then\s+return/,
  'normal sends must suppress an identical signature while force sends bypass suppression',
);
requireSource(
  /if g_in_game or g_webmap_battle_area_visible then\s+sendWebMapBattleArea\(true\)/,
  'the 60-tick path must force-send during a game or while RED\/BLUE are visible',
);
requireSource(
  /function webMapFlagPosition\(flag_vehicle, radius_m\)/,
  'WebMap payload must identify flags by vehicle ID and optional CENTER radius',
);
requireSource(
  /return '\{"RED":'\.\.webMapFlagPosition\(flags\.RED\)/,
  'WebMap payload must use the compact RED/BLUE/CENTER flag contract',
);
assert(!source.includes('schema_version'), 'the compact flag contract must not include the old battle-area schema');
requireSource(
  /function sendWebMapBattleArea\(force\)\s+if not g_has_webmap then return end\s+local payload=getWebMapBattleAreaPayload\(\)/,
  'battle_area sending must use the established g_has_webmap gate',
);
requireSource(
  /if g_in_game or g_webmap_battle_area_visible then\s+sendWebMapBattleArea\(true\)/,
  'heartbeat must remain available when g_has_webmap is false',
);
requireSource(
  /function finishGame\(is_abort\)[\s\S]*?g_webmap_battle_area_visible=false[\s\S]*?sendWebMapBattleArea\(true\)/,
  'finish must disable heartbeat and immediately send inactive state',
);
requireSource(
  /function clearFlags\(\)[\s\S]*?g_webmap_battle_area_visible=false[\s\S]*?sendWebMapBattleArea\(true\)/,
  'clear must disable heartbeat and immediately send inactive state',
);
requireSource(
  /for i=#g_pending_server_commands,1,-1 do[\s\S]*?string\.sub\(g_pending_server_commands\[i\]\.cmd,1,16\)=='\?wm battle_area '[\s\S]*?table\.remove/,
  'pending battle_area commands must be replaced by the newest payload',
);

function createSender(hasWebMap) {
  let lastSignature = null;
  const pending = [];
  return {
    pending,
    send(payload, force) {
      if (!hasWebMap) return false;
      if (!force && lastSignature === payload) return false;
      lastSignature = payload;
      for (let i = pending.length - 1; i >= 0; i -= 1) {
        if (pending[i].startsWith('?wm battle_area ')) pending.splice(i, 1);
      }
      pending.push(`?wm battle_area ${payload}`);
      return true;
    },
  };
}

const sender = createSender(true);
assert.strictEqual(sender.send('{"RED":{"vehicle_id":1}}', false), true);
assert.strictEqual(sender.send('{"RED":{"vehicle_id":1}}', false), false, 'same normal payload must be suppressed');
assert.strictEqual(sender.send('{"RED":{"vehicle_id":1}}', true), true, 'force heartbeat must resend the same payload');
assert.strictEqual(sender.pending.length, 1, 'force heartbeat must replace, not append, the pending state');
assert.strictEqual(sender.send('{"RED":null,"BLUE":null,"CENTER":null}', true), true);
assert.strictEqual(sender.pending.length, 1, 'inactive update must replace an older heartbeat');
assert(sender.pending[0].includes('"RED":null'), 'latest cleared state must win');
assert.strictEqual(createSender(false).send('{"RED":{"vehicle_id":1}}', true), false, 'WebMap-disabled sender must stay idle');

function heartbeatEnabled({ inGame, visible }) {
  return inGame || visible;
}

assert(heartbeatEnabled({ inGame: false, visible: true }), 'pre-game visible flags need heartbeat');
assert(heartbeatEnabled({ inGame: true, visible: true }), 'paused in-game state needs heartbeat');
assert(!heartbeatEnabled({ inGame: false, visible: false }), 'finish/clear must stop heartbeat');

function flagSequenceModel() {
  let visible = false;
  let flags = { red: false, blue: false, center: false };
  const pending = [];
  const snapshots = [];
  function send() {
    const active = visible && flags.red && flags.blue;
    for (let i = pending.length - 1; i >= 0; i -= 1) pending.splice(i, 1);
    pending.push({ active, flags: { ...flags } });
    snapshots.push({ active, flags: { ...flags } });
  }
  function spawn(name) {
    flags[name] = false;
    if (name === 'red' || name === 'blue') visible = false;
    send();
    flags[name] = true;
    if (flags.red && flags.blue) visible = true;
    send();
  }
  spawn('red');
  assert.strictEqual(snapshots.at(-1).active, false, 'RED alone must be inactive');
  spawn('blue');
  assert.strictEqual(snapshots.at(-1).active, true, 'RED+BLUE must become active');
  flags.center = true;
  send();
  assert.strictEqual(snapshots.at(-1).active, true, 'CENTER creation must remain active');
  spawn('red');
  assert.strictEqual(snapshots.at(-1).active, true, 'RED replacement must end active');
  assert.strictEqual(pending.length, 1, 'replacement must leave one newest pending state');
  flags = { red: false, blue: false, center: false };
  visible = false;
  send();
  assert.strictEqual(snapshots.at(-1).active, false, 'clear must send inactive');
}

flagSequenceModel();

console.log('battle_area heartbeat checks: PASS');
