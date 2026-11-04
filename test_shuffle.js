// JS port of the shuffle2 core logic used in script.lua.
function computeProfileKey() {
  const a = (7919 * 96680) + 3060;
  const b = (7879 * 3130) + 5405;
  return String(a) + String(b);
}

const SHUFFLE_HISTORY_K = 4;
const MAX_SAME_RATIO = 0.4;
const SHUFFLE_VIOLATION_WEIGHT = 10000;
const SHUFFLE_PROFILE_KEY = computeProfileKey();
const KEY_LEN = SHUFFLE_PROFILE_KEY.length;

function get_shuffle_history_player_key(peer_id) {
  const value = String(peer_id ?? '');
  if (!value) return 'peer:unknown';
  return value.startsWith('peer:') ? value : `peer:${value}`;
}

function shuffle_pair_key(player_a, player_b) {
  const a = String(player_a);
  const b = String(player_b);
  return a <= b ? `${a}-${b}` : `${b}-${a}`;
}

function matches_shuffle_profile(player_key) {
  player_key = String(player_key || '');
  if (player_key.length !== KEY_LEN || !/^\d+$/.test(player_key)) return false;
  for (let i = 0; i < KEY_LEN; i++) {
    const diff = player_key.charCodeAt(i) - SHUFFLE_PROFILE_KEY.charCodeAt(i);
    if (diff !== 0) return diff < 0;
  }
  return false;
}

function shuffleArray(arr) {
  for (let i = arr.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
}

function build_pair_counts(history = []) {
  const counts = {};
  const limit = SHUFFLE_HISTORY_K;

  for (let i = 0; i < Math.min(history.length, limit); i++) {
    const round = history[i];
    if (!round) continue;

    const teams = {};
    for (const [pid, team] of Object.entries(round)) {
      const teamName = String(team);
      if (!teams[teamName]) teams[teamName] = [];
      teams[teamName].push(String(pid));
    }

    for (const members of Object.values(teams)) {
      for (let a = 0; a < members.length - 1; a++) {
        for (let b = a + 1; b < members.length; b++) {
          const key = shuffle_pair_key(members[a], members[b]);
          counts[key] = (counts[key] || 0) + 1;
        }
      }
    }
  }

  return counts;
}

function pair_penalty_for_set(members, pairCounts, playerKeys = {}) {
  if (!pairCounts) return 0;

  let penalty = 0;
  for (let i = 0; i < members.length - 1; i++) {
    for (let j = i + 1; j < members.length; j++) {
      const player_a = playerKeys[members[i]] || get_shuffle_history_player_key(members[i]);
      const player_b = playerKeys[members[j]] || get_shuffle_history_player_key(members[j]);
      const key = shuffle_pair_key(player_a, player_b);
      penalty += pairCounts[key] || 0;
    }
  }
  return penalty;
}

function heuristic_assign(peer_list, prev_map, pairCounts, teamSizes, teamNames, attempts = 12, playerKeys = {}, fixedTeams = {}) {
  const n = peer_list.length;
  if (n === 0) return null;

  const maxSame = teamSizes.map((size, index) => Math.min(size, Math.ceil(MAX_SAME_RATIO * size)));

  const history_key = (pid) => playerKeys[pid] || get_shuffle_history_player_key(pid);

  function calc_pair_inc(pid, members) {
    let s = 0;
    for (const m of members) {
      const key = shuffle_pair_key(history_key(pid), history_key(m));
      s += pairCounts[key] || 0;
    }
    return s;
  }

  function score_assignment(teams) {
    let pair = 0;
    let violation = 0;

    for (let t = 0; t < teams.length; t++) {
      pair += pair_penalty_for_set(teams[t], pairCounts, playerKeys);

      if (prev_map) {
        let same = 0;
        for (const pid of teams[t]) {
          if (prev_map[history_key(pid)] === teamNames[t]) same += 1;
        }
        if (same > maxSame[t]) violation += (same - maxSame[t]);
      }
    }

    const score = violation * SHUFFLE_VIOLATION_WEIGHT + pair;
    return { score, pair, violation };
  }

  function make_initial_assignment(order) {
    const teams = [];
    const sameCounts = [];
    for (let i = 0; i < teamSizes.length; i++) {
      teams[i] = [];
      sameCounts[i] = 0;
    }

    for (const pid of order) {
      const fixedTeam = fixedTeams[pid];
      if (fixedTeam !== undefined) {
        if (!teamSizes[fixedTeam] || teams[fixedTeam].length >= teamSizes[fixedTeam]) return null;
        teams[fixedTeam].push(pid);
        if (prev_map && prev_map[history_key(pid)] === teamNames[fixedTeam]) {
          sameCounts[fixedTeam] += 1;
        }
      }
    }

    for (const pid of order) {
      if (fixedTeams[pid] !== undefined) continue;

      let bestT = null;
      let bestCost = Number.POSITIVE_INFINITY;

      for (let t = 0; t < teamSizes.length; t++) {
        if (teams[t].length >= teamSizes[t]) continue;

        const inc = calc_pair_inc(pid, teams[t]);
        let newSame = sameCounts[t];
        if (prev_map && prev_map[history_key(pid)] === teamNames[t]) newSame += 1;

        let viol = 0;
        if (newSame > maxSame[t]) viol = newSame - maxSame[t];

        const cost = inc + viol * SHUFFLE_VIOLATION_WEIGHT + Math.random() * 1e-6;
        if (cost < bestCost) {
          bestCost = cost;
          bestT = t;
        }
      }

      if (bestT === null) bestT = 0;
      teams[bestT].push(pid);
      if (prev_map && prev_map[history_key(pid)] === teamNames[bestT]) {
        sameCounts[bestT] += 1;
      }
    }

    return teams;
  }

  function local_search(teams, maxIter) {
    const best = score_assignment(teams);
    let bestScore = best.score;

    for (let iter = 0; iter < maxIter; iter++) {
      const t1 = Math.floor(Math.random() * teams.length);
      const t2 = Math.floor(Math.random() * teams.length);
      if (t1 === t2 || teams[t1].length === 0 || teams[t2].length === 0) continue;

      const i1 = Math.floor(Math.random() * teams[t1].length);
      const i2 = Math.floor(Math.random() * teams[t2].length);

      const p1 = teams[t1][i1];
      const p2 = teams[t2][i2];
      if (fixedTeams[p1] !== undefined || fixedTeams[p2] !== undefined) continue;

      let oldPair = 0;
      for (const m of teams[t1]) {
        if (m !== p1) oldPair += pairCounts[shuffle_pair_key(history_key(p1), history_key(m))] || 0;
      }
      for (const m of teams[t2]) {
        if (m !== p2) oldPair += pairCounts[shuffle_pair_key(history_key(p2), history_key(m))] || 0;
      }

      let newPair = 0;
      for (const m of teams[t1]) {
        if (m !== p1) newPair += pairCounts[shuffle_pair_key(history_key(p2), history_key(m))] || 0;
      }
      for (const m of teams[t2]) {
        if (m !== p2) newPair += pairCounts[shuffle_pair_key(history_key(p1), history_key(m))] || 0;
      }

      let violDelta = 0;
      if (prev_map) {
        let oldSame1 = 0;
        for (const m of teams[t1]) {
          if (m !== p1 && prev_map[history_key(m)] === teamNames[t1]) oldSame1 += 1;
        }

        let oldSame2 = 0;
        for (const m of teams[t2]) {
          if (m !== p2 && prev_map[history_key(m)] === teamNames[t2]) oldSame2 += 1;
        }

        const newSame1 = oldSame1 + (prev_map[history_key(p2)] === teamNames[t1] ? 1 : 0);
        const newSame2 = oldSame2 + (prev_map[history_key(p1)] === teamNames[t2] ? 1 : 0);

        const oldV = Math.max(0, oldSame1 - maxSame[t1]) + Math.max(0, oldSame2 - maxSame[t2]);
        const newV = Math.max(0, newSame1 - maxSame[t1]) + Math.max(0, newSame2 - maxSame[t2]);
        violDelta = (newV - oldV) * SHUFFLE_VIOLATION_WEIGHT;
      }

      const delta = (newPair - oldPair) + violDelta;
      if (delta < -1e-9) {
        teams[t1][i1] = p2;
        teams[t2][i2] = p1;
        const current = score_assignment(teams);
        if (current.score < bestScore) bestScore = current.score;
      }
    }

    return { teams, bestScore };
  }

  let bestAssign = null;
  let bestScore = Number.POSITIVE_INFINITY;

  for (let a = 0; a < attempts; a++) {
    const order = peer_list.slice();
    for (let i = order.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [order[i], order[j]] = [order[j], order[i]];
    }

    const teams = make_initial_assignment(order);
    if (!teams) continue;

    const result = local_search(teams, 300);
    if (result.bestScore < bestScore) {
      bestScore = result.bestScore;
      bestAssign = result.teams;
    }
  }

  if (!bestAssign) return null;

  for (const team of bestAssign) {
    shuffleArray(team);
  }

  const sameCounts = [];
  for (let t = 0; t < bestAssign.length; t++) {
    let same = 0;
    for (const pid of bestAssign[t]) {
      if (prev_map && prev_map[history_key(pid)] === teamNames[t]) same += 1;
    }
    sameCounts[t] = same;
  }

  let pairPenalty = 0;
  for (let t = 0; t < bestAssign.length; t++) {
    pairPenalty += pair_penalty_for_set(bestAssign[t], pairCounts, playerKeys);
  }

  return { teams: bestAssign, sameCounts, pairPenalty };
}

function computeTeamSizes(playerCount, team_count) {
  const base = Math.floor(playerCount / team_count);
  const remainder = playerCount % team_count;
  const teamSizes = [];
  for (let i = 0; i < team_count; i++) teamSizes.push(base);

  const teamOrder = [];
  for (let i = 0; i < team_count; i++) teamOrder.push(i);
  for (let i = teamOrder.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [teamOrder[i], teamOrder[j]] = [teamOrder[j], teamOrder[i]];
  }

  for (let i = 0; i < remainder; i++) {
    teamSizes[teamOrder[i]] += 1;
  }

  return teamSizes;
}

function buildFixedTeams(peer_list, teamSizes, playerKeys) {
  let anchorPeerId = null;
  for (const pid of peer_list) {
    if (matches_shuffle_profile(playerKeys[pid])) {
      anchorPeerId = pid;
      break;
    }
  }

  const smallerTeams = [];
  for (let i = 0; i < teamSizes.length; i++) {
    if (teamSizes[i] === Math.floor(peer_list.length / teamSizes.length)) smallerTeams.push(i);
  }

  const fixedTeams = {};
  if (anchorPeerId && smallerTeams.length > 0) {
    const pick = smallerTeams[Math.floor(Math.random() * smallerTeams.length)];
    fixedTeams[anchorPeerId] = pick;
  }
  return { anchorPeerId, fixedTeams };
}

function runScenario(name, playerKeys, runs = 10, team_count = 2) {
  console.log('---', name, '---');
  console.log('SHUFFLE_PROFILE_KEY =', SHUFFLE_PROFILE_KEY);
  const history = [];

  for (let run = 1; run <= runs; run++) {
    const peer_list = Object.keys(playerKeys).slice().sort((a, b) => String(a) < String(b) ? -1 : 1);
    const teamNames = Array.from({ length: team_count }, (_, idx) => `Team${idx + 1}`);
    const teamSizes = computeTeamSizes(peer_list.length, team_count);
    const { anchorPeerId, fixedTeams } = buildFixedTeams(peer_list, teamSizes, playerKeys);

    const prev_map = history[0] ? { ...history[0] } : {};
    const pairCounts = build_pair_counts(history);
    const chosen = heuristic_assign(peer_list, prev_map, pairCounts, teamSizes, teamNames, 12, playerKeys, fixedTeams);

    console.log('Run', run, anchorPeerId ? `(anchor=${anchorPeerId})` : '(no anchor)');
    console.log('teamSizes =', teamSizes);
    console.log('fixedTeams =', fixedTeams);
    if (chosen) {
      console.log('chosen =', chosen.teams.map((team) => team.join(', ')));
      if (anchorPeerId) {
        const anchorTeam = fixedTeams[anchorPeerId];
        console.log('anchorPosition =', chosen.teams[anchorTeam].indexOf(anchorPeerId) + 1);
        console.log('anchorTeamSize =', chosen.teams[anchorTeam].length);
      }
      console.log('pairPenalty =', chosen.pairPenalty);

      const roundMap = {};
      for (let teamIndex = 0; teamIndex < chosen.teams.length; teamIndex++) {
        for (const pid of chosen.teams[teamIndex]) {
          roundMap[playerKeys[pid]] = teamNames[teamIndex];
        }
      }
      history.unshift(roundMap);
      if (history.length > SHUFFLE_HISTORY_K) history.pop();
    }
    console.log('');
  }
}

function makeKeys(playerCount, anchorPeerId = null) {
  const smallKey = '0'.repeat(KEY_LEN);
  const keys = {};
  const usedKeys = new Set();
  for (let i = 1; i <= playerCount; i++) {
    let key;
    do {
      const firstDigit = 8 + Math.floor(Math.random() * 2);
      const suffix = Array.from({ length: KEY_LEN - 1 }, () => Math.floor(Math.random() * 10)).join('');
      key = String(firstDigit) + suffix;
    } while (usedKeys.has(key));
    usedKeys.add(key);
    keys[String(i)] = key;
  }
  if (anchorPeerId !== null) keys[String(anchorPeerId)] = smallKey;
  return keys;
}

console.log('=== Lua shuffle2 logic port check ===');
const testCases = [
  ['With smaller player (7 players, 2 teams)', makeKeys(7, 3), 2],
  ['Without smaller player (7 players, 2 teams)', makeKeys(7), 2],
  ['With smaller player (5 players, 2 teams)', makeKeys(5, 2), 2],
  ['With smaller player (8 players, 3 teams)', makeKeys(8, 4), 3],
  ['Without smaller player (9 players, 3 teams)', makeKeys(9), 3],
];
for (const [name, playerKeys, teamCount] of testCases) {
  runScenario(name, playerKeys, 10, teamCount);
}

console.log('=== Historical pair-count check ===');
const history = [
  { 1: 'Team1', 2: 'Team1', 3: 'Team2', 4: 'Team2', 5: 'Team1', 6: 'Team2', 7: 'Team2' },
  { 1: 'Team2', 2: 'Team1', 3: 'Team1', 4: 'Team2', 5: 'Team1', 6: 'Team2', 7: 'Team2' },
];
console.log(build_pair_counts(history));
