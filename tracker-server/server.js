const express = require('express');
const app = express();

app.use(express.json());

const API_KEY = process.env.API_KEY || 'change-this-secret-key';
const PORT    = process.env.PORT    || 3000;
const ACTIVE_MS = 2 * 60 * 1000; // 2 minutes = "active"

// userId -> { username, lastSeen }
const users = new Map();

// ── Lua script calls this every 30s ──────────────────────────────────────────
app.post('/api/ping', (req, res) => {
    if (req.headers['x-api-key'] !== API_KEY)
        return res.status(403).json({ error: 'Forbidden' });

    const { userId, username } = req.body || {};
    if (!userId || !username)
        return res.status(400).json({ error: 'Missing userId or username' });

    users.set(String(userId), {
        username: String(username).slice(0, 64),
        lastSeen: Date.now(),
    });
    res.json({ ok: true });
});

// ── Dashboard fetches this ────────────────────────────────────────────────────
app.get('/api/users', (req, res) => {
    if (req.headers['x-api-key'] !== API_KEY)
        return res.status(403).json({ error: 'Forbidden' });

    const now = Date.now();
    const result = [];
    for (const [userId, data] of users.entries()) {
        result.push({
            userId,
            username: data.username,
            lastSeen: data.lastSeen,
            active: now - data.lastSeen < ACTIVE_MS,
        });
    }
    result.sort((a, b) => {
        if (a.active !== b.active) return a.active ? -1 : 1;
        return b.lastSeen - a.lastSeen;
    });
    res.json(result);
});

// ── Dashboard HTML (API key injected server-side) ─────────────────────────────
app.get('/', (req, res) => res.send(buildHTML(API_KEY)));

function buildHTML(apiKey) {
return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Script Users</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{background:#0d0d12;color:#e2e8f0;font-family:'Segoe UI',system-ui,sans-serif;min-height:100vh}
header{background:#13131a;border-bottom:1px solid #22222e;padding:18px 32px;display:flex;align-items:center;justify-content:space-between}
h1{font-size:18px;font-weight:600;color:#c9d1d9;letter-spacing:.01em}
.pill{background:#1a1a24;border:1px solid #22222e;border-radius:20px;padding:4px 14px;font-size:12px;color:#555}
main{padding:28px 32px;max-width:960px;margin:0 auto}
.stats{display:grid;grid-template-columns:repeat(3,1fr);gap:14px;margin-bottom:28px}
.stat{background:#13131a;border:1px solid #22222e;border-radius:10px;padding:18px 22px}
.sv{font-size:30px;font-weight:700}
.sl{font-size:11px;color:#555;margin-top:3px;text-transform:uppercase;letter-spacing:.06em}
.card{background:#13131a;border:1px solid #22222e;border-radius:10px;overflow:hidden}
table{width:100%;border-collapse:collapse}
thead th{background:#191921;padding:10px 20px;text-align:left;font-size:11px;font-weight:600;color:#555;text-transform:uppercase;letter-spacing:.07em}
tbody tr{border-top:1px solid #191921;transition:background .15s}
tbody tr:hover{background:#191921}
td{padding:13px 20px;font-size:14px;vertical-align:middle}
.dot{width:7px;height:7px;border-radius:50%;display:inline-block;margin-right:8px;flex-shrink:0}
.on{background:#3fb950;box-shadow:0 0 7px #3fb95088}
.off{background:#333}
.uname{font-weight:500;color:#c9d1d9}
.uid{font-size:11px;color:#444;margin-top:2px}
.ago{font-size:13px;color:#555}
.empty{text-align:center;padding:56px;color:#333;font-size:14px}
</style>
</head>
<body>
<header>
  <h1>📋 Script Users</h1>
  <span class="pill" id="ts">Loading…</span>
</header>
<main>
  <div class="stats">
    <div class="stat"><div class="sv" id="sTotal" style="color:#7c93fa">—</div><div class="sl">Total Seen</div></div>
    <div class="stat"><div class="sv" id="sActive" style="color:#3fb950">—</div><div class="sl">Active Now</div></div>
    <div class="stat"><div class="sv" id="sInactive" style="color:#e05c5c">—</div><div class="sl">Inactive</div></div>
  </div>
  <div class="card">
    <table>
      <thead><tr><th>Status</th><th>Player</th><th>Last Seen</th></tr></thead>
      <tbody id="tb"><tr><td colspan="3" class="empty">Loading…</td></tr></tbody>
    </table>
  </div>
</main>
<script>
const KEY='${apiKey}';
function ago(ms){
  const s=Math.floor((Date.now()-ms)/1000);
  if(s<60)return s+'s ago';
  if(s<3600)return Math.floor(s/60)+'m ago';
  return Math.floor(s/3600)+'h ago';
}
async function load(){
  try{
    const r=await fetch('/api/users',{headers:{'x-api-key':KEY}});
    const u=await r.json();
    const act=u.filter(x=>x.active).length;
    document.getElementById('sTotal').textContent=u.length;
    document.getElementById('sActive').textContent=act;
    document.getElementById('sInactive').textContent=u.length-act;
    const tb=document.getElementById('tb');
    if(!u.length){tb.innerHTML='<tr><td colspan="3" class="empty">No users yet — waiting for script to be executed</td></tr>';return;}
    tb.innerHTML=u.map(x=>\`<tr>
      <td><span class="dot \${x.active?'on':'off'}"></span>\${x.active?'Online':'Offline'}</td>
      <td><div class="uname">\${x.username}</div><div class="uid">ID: \${x.userId}</div></td>
      <td class="ago">\${ago(x.lastSeen)}</td>
    </tr>\`).join('');
    document.getElementById('ts').textContent='Updated '+new Date().toLocaleTimeString();
  }catch(e){
    document.getElementById('ts').textContent='Error: '+e.message;
  }
}
load();
setInterval(load,10000);
</script>
</body>
</html>`;
}

app.listen(PORT, () => console.log(`Tracker on :${PORT}`));
