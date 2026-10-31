<?php
// ── 設定 ──────────────────────────────────────────────────────────────────────
define('API_KEY',   'change-this-secret-key');   // 改成你自己的密鑰
define('DATA_FILE', __DIR__ . '/tracker_data.json');
define('ACTIVE_SEC', 120);  // 2 分鐘內 ping 過 = Online

// ── 資料讀寫 ──────────────────────────────────────────────────────────────────
function loadData(): array {
    if (!file_exists(DATA_FILE)) return ['users'=>[], 'blacklist'=>[]];
    return json_decode(file_get_contents(DATA_FILE), true) ?: ['users'=>[], 'blacklist'=>[]];
}
function saveData(array $d): void {
    file_put_contents(DATA_FILE, json_encode($d), LOCK_EX);
}

// ── 驗證 API Key ──────────────────────────────────────────────────────────────
function checkKey(): bool {
    return ($_SERVER['HTTP_X_API_KEY'] ?? '') === API_KEY;
}
function jsonOut(mixed $v, int $code = 200): void {
    http_response_code($code);
    header('Content-Type: application/json');
    echo json_encode($v);
    exit;
}

$action = $_GET['action'] ?? '';

// ── API 端點 ──────────────────────────────────────────────────────────────────
if ($action === 'ping' && $_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!checkKey()) jsonOut(['error'=>'Forbidden'], 403);
    $body = json_decode(file_get_contents('php://input'), true) ?: [];
    $uid  = (string)($body['userId']   ?? '');
    $name = substr((string)($body['username'] ?? ''), 0, 64);
    if (!$uid || !$name) jsonOut(['error'=>'Missing fields'], 400);

    $d = loadData();
    if (isset($d['blacklist'][$uid])) jsonOut(['ok'=>false, 'banned'=>true]);

    $d['users'][$uid] = ['username'=>$name, 'lastSeen'=>time()];
    saveData($d);
    jsonOut(['ok'=>true, 'banned'=>false]);
}

if ($action === 'users' && $_SERVER['REQUEST_METHOD'] === 'GET') {
    if (!checkKey()) jsonOut(['error'=>'Forbidden'], 403);
    $d    = loadData();
    $now  = time();
    $rows = [];
    foreach ($d['users'] as $uid => $u) {
        $rows[] = [
            'userId'   => $uid,
            'username' => $u['username'],
            'lastSeen' => $u['lastSeen'] * 1000,
            'active'   => ($now - $u['lastSeen']) < ACTIVE_SEC,
            'banned'   => isset($d['blacklist'][$uid]),
        ];
    }
    foreach ($d['blacklist'] as $uid => $b) {
        if (!isset($d['users'][$uid])) {
            $rows[] = ['userId'=>$uid,'username'=>$b['username'],'lastSeen'=>$b['bannedAt']*1000,'active'=>false,'banned'=>true];
        }
    }
    usort($rows, fn($a,$b) => $b['lastSeen'] <=> $a['lastSeen']);
    jsonOut($rows);
}

if ($action === 'ban' && $_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!checkKey()) jsonOut(['error'=>'Forbidden'], 403);
    $body = json_decode(file_get_contents('php://input'), true) ?: [];
    $uid  = (string)($body['userId'] ?? '');
    $name = substr((string)($body['username'] ?? $uid), 0, 64);
    if (!$uid) jsonOut(['error'=>'Missing userId'], 400);
    $d = loadData();
    $d['blacklist'][$uid] = ['username'=>$name, 'bannedAt'=>time()];
    saveData($d);
    jsonOut(['ok'=>true]);
}

if ($action === 'unban' && $_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!checkKey()) jsonOut(['error'=>'Forbidden'], 403);
    $body = json_decode(file_get_contents('php://input'), true) ?: [];
    $uid  = (string)($body['userId'] ?? '');
    if (!$uid) jsonOut(['error'=>'Missing userId'], 400);
    $d = loadData();
    unset($d['blacklist'][$uid]);
    saveData($d);
    jsonOut(['ok'=>true]);
}

// ── Dashboard HTML ────────────────────────────────────────────────────────────
// 只有 action 是空的才顯示 dashboard（直接開網址）
if ($action !== '') { http_response_code(404); exit; }
?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Script Users</title>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap">
<style>
*{margin:0;padding:0;box-sizing:border-box}
:root{--bg:#0b0b10;--sur:#111118;--bdr:#1e1e2a;--hov:#17171f;--fg:#d4d8e8;--mut:#52546a;--acc:#6c7cff;--on:#34d058;--og:#34d05830;--red:#e05c5c;--rbg:#2a1010;--rbdr:#5a2020;color-scheme:dark}
@media(prefers-color-scheme:light){:root:not([data-theme=dark]){--bg:#f2f3f8;--sur:#fff;--bdr:#e0e2ee;--hov:#f7f8fc;--fg:#1a1b2e;--mut:#8b8da8;--acc:#4a5aef;--on:#1a8f38;--og:#1a8f3820;--red:#c0392b;--rbg:#fff0ef;--rbdr:#f5c6c3;color-scheme:light}}
:root[data-theme=light]{--bg:#f2f3f8;--sur:#fff;--bdr:#e0e2ee;--hov:#f7f8fc;--fg:#1a1b2e;--mut:#8b8da8;--acc:#4a5aef;--on:#1a8f38;--og:#1a8f3820;--red:#c0392b;--rbg:#fff0ef;--rbdr:#f5c6c3;color-scheme:light}
body{background:var(--bg);color:var(--fg);font-family:'Inter',system-ui,sans-serif;font-size:14px;min-height:100%;padding:0 max(16px,env(safe-area-inset-left,0px))}
header{position:sticky;top:0;z-index:10;background:var(--bg);border-bottom:1px solid var(--bdr);display:flex;align-items:center;justify-content:space-between;gap:12px;padding:14px 0}
.logo{display:flex;align-items:center;gap:10px;font-weight:600;font-size:15px}
.li{width:28px;height:28px;background:var(--acc);border-radius:7px;display:grid;place-items:center;font-size:13px}
.ts{font-size:12px;color:var(--mut);font-variant-numeric:tabular-nums}
.tbtn{background:var(--sur);border:1px solid var(--bdr);border-radius:6px;color:var(--mut);cursor:pointer;font-size:13px;padding:5px 10px}
.tbtn:hover{color:var(--fg)}
main{max-width:920px;margin:0 auto;padding:28px 0}
.stats{display:grid;grid-template-columns:repeat(4,1fr);gap:12px;margin-bottom:24px}
.stat{background:var(--sur);border:1px solid var(--bdr);border-radius:10px;padding:18px 20px}
.sv{font-size:28px;font-weight:700;font-variant-numeric:tabular-nums;line-height:1;margin-bottom:5px}
.sl{font-size:11px;color:var(--mut);text-transform:uppercase;letter-spacing:.06em;font-weight:500}
.card{background:var(--sur);border:1px solid var(--bdr);border-radius:10px;overflow:hidden}
.ch{display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:8px;padding:14px 20px;border-bottom:1px solid var(--bdr)}
.tabs{display:flex;gap:4px}
.tab{background:none;border:1px solid transparent;border-radius:6px;color:var(--mut);cursor:pointer;font-family:'Inter',sans-serif;font-size:12px;font-weight:500;padding:4px 10px;transition:all .15s}
.tab:hover{color:var(--fg)}
.tab.active{background:var(--bdr);border-color:var(--bdr);color:var(--fg)}
.srch{background:var(--bg);border:1px solid var(--bdr);border-radius:6px;color:var(--fg);font-family:'Inter',sans-serif;font-size:13px;padding:5px 10px;width:180px;outline:none;transition:border-color .15s}
.srch:focus{border-color:var(--acc)}
.srch::placeholder{color:var(--mut)}
.tw{overflow-x:auto}
table{width:100%;border-collapse:collapse;min-width:480px}
thead th{background:var(--bg);padding:10px 20px;text-align:left;font-size:11px;font-weight:600;color:var(--mut);text-transform:uppercase;letter-spacing:.07em;white-space:nowrap}
tbody tr{border-top:1px solid var(--bdr);transition:background .12s}
tbody tr:hover{background:var(--hov)}
tbody tr.ib{opacity:.55}
td{padding:12px 20px;vertical-align:middle}
.sc{display:flex;align-items:center;gap:8px;white-space:nowrap}
.dot{width:7px;height:7px;border-radius:50%;flex-shrink:0}
.dot.on{background:var(--on);box-shadow:0 0 0 3px var(--og)}
.dot.off{background:var(--mut)}
.dot.ban{background:var(--red)}
.st{font-size:13px}
.st.on{color:var(--on)}
.st.off{color:var(--mut)}
.bb{background:var(--rbg);border:1px solid var(--rbdr);border-radius:4px;color:var(--red);font-size:11px;font-weight:600;padding:2px 8px}
.un{font-family:'JetBrains Mono',monospace;font-size:13px;font-weight:500}
.ui{font-family:'JetBrains Mono',monospace;font-size:11px;color:var(--mut);margin-top:2px}
.tc{font-size:13px;color:var(--mut);font-variant-numeric:tabular-nums;white-space:nowrap}
.bbn{background:var(--rbg);border:1px solid var(--rbdr);border-radius:6px;color:var(--red);cursor:pointer;font-family:'Inter',sans-serif;font-size:12px;font-weight:500;padding:5px 12px;transition:opacity .15s}
.ubn{background:color-mix(in srgb,var(--on) 12%,transparent);border:1px solid color-mix(in srgb,var(--on) 30%,transparent);border-radius:6px;color:var(--on);cursor:pointer;font-family:'Inter',sans-serif;font-size:12px;font-weight:500;padding:5px 12px;transition:opacity .15s}
.bbn:hover,.ubn:hover{opacity:.7}
.er td{text-align:center;padding:56px 20px;color:var(--mut)}
@media(max-width:540px){.stats{grid-template-columns:repeat(2,1fr)}.srch{width:120px}}
</style>
</head>
<body>
<header>
  <div class="logo"><div class="li">◈</div>Script Users</div>
  <div style="display:flex;align-items:center;gap:10px">
    <span class="ts" id="ts">—</span>
    <button class="tbtn" onclick="toggleTheme()">◐</button>
  </div>
</header>
<main>
  <div class="stats">
    <div class="stat"><div class="sv" style="color:var(--acc)" id="s0">—</div><div class="sl">Total</div></div>
    <div class="stat"><div class="sv" style="color:var(--on)"  id="s1">—</div><div class="sl">Online</div></div>
    <div class="stat"><div class="sv" style="color:var(--mut)" id="s2">—</div><div class="sl">Offline</div></div>
    <div class="stat"><div class="sv" style="color:var(--red)" id="s3">—</div><div class="sl">Banned</div></div>
  </div>
  <div class="card">
    <div class="ch">
      <div class="tabs">
        <button class="tab active" onclick="sf('all',this)">All</button>
        <button class="tab" onclick="sf('on',this)">Online</button>
        <button class="tab" onclick="sf('off',this)">Offline</button>
        <button class="tab" onclick="sf('ban',this)">Banned</button>
      </div>
      <input class="srch" id="q" placeholder="Search username…" oninput="render()">
    </div>
    <div class="tw">
      <table>
        <thead><tr><th>Status</th><th>Player</th><th>Last Seen</th><th>Action</th></tr></thead>
        <tbody id="tb"></tbody>
      </table>
    </div>
  </div>
</main>
<script>
const KEY='<?= htmlspecialchars(API_KEY, ENT_QUOTES) ?>';
let users=[],filter='all';

function ago(ms){const s=Math.floor((Date.now()-ms)/1000);if(s<60)return s+'s ago';if(s<3600)return Math.floor(s/60)+'m ago';if(s<86400)return Math.floor(s/3600)+'h ago';return Math.floor(s/86400)+'d ago';}

async function api(a,body){
  await fetch('?action='+a,{method:'POST',headers:{'x-api-key':KEY,'Content-Type':'application/json'},body:JSON.stringify(body)});
  await load();
}

function sf(f,el){filter=f;document.querySelectorAll('.tab').forEach(t=>t.classList.remove('active'));el.classList.add('active');render();}

function render(){
  const q=document.getElementById('q').value.trim().toLowerCase();
  const on=users.filter(u=>u.active&&!u.banned).length,ban=users.filter(u=>u.banned).length;
  document.getElementById('s0').textContent=users.length;
  document.getElementById('s1').textContent=on;
  document.getElementById('s2').textContent=users.filter(u=>!u.active&&!u.banned).length;
  document.getElementById('s3').textContent=ban;
  const rows=users.filter(u=>{
    if(filter==='on'&&(!u.active||u.banned))return false;
    if(filter==='off'&&(u.active||u.banned))return false;
    if(filter==='ban'&&!u.banned)return false;
    if(q&&!u.username.toLowerCase().includes(q)&&!u.userId.includes(q))return false;
    return true;
  });
  const tb=document.getElementById('tb');
  if(!rows.length){tb.innerHTML='<tr class="er"><td colspan="4">No users match</td></tr>';return;}
  const esc=s=>s.replace(/'/g,"\\'");
  tb.innerHTML=rows.map(u=>`<tr class="${u.banned?'ib':''}">
    <td><div class="sc">${u.banned
      ?'<span class="dot ban"></span><span class="bb">Banned</span>'
      :`<span class="dot ${u.active?'on':'off'}"></span><span class="st ${u.active?'on':'off'}">${u.active?'Online':'Offline'}</span>`
    }</div></td>
    <td><div class="un">${u.username}</div><div class="ui">${u.userId}</div></td>
    <td class="tc">${ago(u.lastSeen)}</td>
    <td>${u.banned
      ?`<button class="ubn" onclick="api('unban',{userId:'${esc(u.userId)}'})">Unban</button>`
      :`<button class="bbn" onclick="api('ban',{userId:'${esc(u.userId)}',username:'${esc(u.username)}'})">Ban</button>`
    }</td>
  </tr>`).join('');
}

async function load(){
  try{
    const r=await fetch('?action=users',{headers:{'x-api-key':KEY}});
    users=await r.json();
    render();
    document.getElementById('ts').textContent='Updated '+new Date().toLocaleTimeString([],{hour:'2-digit',minute:'2-digit',second:'2-digit'});
  }catch(e){document.getElementById('ts').textContent='Error: '+e.message;}
}

function toggleTheme(){const r=document.documentElement,c=r.getAttribute('data-theme');r.setAttribute('data-theme',c?(c==='dark'?'light':'dark'):(matchMedia('(prefers-color-scheme:dark)').matches?'light':'dark'));try{localStorage.setItem('t',r.getAttribute('data-theme'));}catch(e){}}
try{const t=localStorage.getItem('t');if(t)document.documentElement.setAttribute('data-theme',t);}catch(e){}

load();setInterval(load,10000);
</script>
</body>
</html>
