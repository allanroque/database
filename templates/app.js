async function loadJSON(url){
  const res = await fetch(url, {cache: "no-store"});
  if(!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.json();
}

function addRow(tbody, k, v){
  const tr = document.createElement("tr");
  const td1 = document.createElement("td"); td1.textContent = k;
  const td2 = document.createElement("td"); td2.textContent = v ?? "—";
  tr.append(td1, td2);
  tbody.appendChild(tr);
}

function parseKVBlock(text){
  // psql_basic saiu como string com linhas, vamos extrair pares-chave simples quando possível
  if(!text) return {};
  // não vamos tentar parsear tudo; só destacamos linhas úteis
  const lines = String(text).split(/\r?\n/).map(l=>l.trim()).filter(Boolean);
  const guess = {};
  lines.forEach(l=>{
    if(l.startsWith("PostgreSQL")) guess.version = l;
    else if(l === "localhost") guess.listen = l;
    else if(/^\d{4,5}$/.test(l)) guess.port = l;
    else if(l.includes("postgresql.conf")) guess.config_file = l;
    else if(l.includes("pg_hba.conf")) guess.hba_file = l;
    else if(/^\d+$/.test(l)) guess.connections = l;
  });
  return guess;
}

function setText(id, txt){ const el=document.getElementById(id); if(el) el.textContent = txt; }

function setPre(id, txt){ const el=document.getElementById(id); if(el) el.textContent = txt || "—"; }

(async ()=>{
  try{
    const data = await loadJSON("health.json");

    // Header
    setText("host", data.host || "—");
    setText("collected", data.collected_at || "—");

    // CORE (SO)
    const oskv = document.getElementById("os-kv");
    addRow(oskv, "OS", data.os?.distro);
    addRow(oskv, "Kernel", data.os?.kernel);
    addRow(oskv, "Arch", data.os?.arch);
    addRow(oskv, "Uptime", data.os?.uptime);
    addRow(oskv, "vCPUs", data.os?.cpu_vcpus);
    addRow(oskv, "Memória (MB)", data.os?.mem_mb);

    const osextra = document.getElementById("os-extra");
    addRow(osextra, "Mounts", (data.os?.mounts||[]).join(", "));
    addRow(osextra, "THP", data.os?.thp?.toString().replace(/\n/g,"  "));
    (data.os?.sysctl_sample||[]).forEach((v,i)=> addRow(osextra, `sysctl#${i+1}`, v));

    // DATABASE (básico + atividade)
    const basics = parseKVBlock(data.postgres?.basics);
    const dbBasics = document.getElementById("db-basics");
    addRow(dbBasics, "Versão", basics.version);
    addRow(dbBasics, "Listen", basics.listen);
    addRow(dbBasics, "Porta", basics.port);
    addRow(dbBasics, "postgresql.conf", basics.config_file);
    addRow(dbBasics, "pg_hba.conf", basics.hba_file);

    const dbAct = document.getElementById("db-activity");
    addRow(dbAct, "Conexões", basics.connections);
    // você pode somar estados a partir de outro bloco se quiser: data.postgres.accounts

    // SIZES / WAL / LOGS / RAW
    setPre("db-sizes", data.postgres?.db_sizes);
    // Se você incluir bgwriter/params no JSON, injete aqui. Se não, deixamos vazio.
    setPre("wal-info", "Use o playbook para adicionar bgwriter/params se quiser.");
    setPre("db-logs", data.postgres?.recent_errors);
    setPre("raw-json", JSON.stringify(data, null, 2));
  }catch(err){
    setPre("raw-json", "Falha ao carregar health.json: " + err.message);
  }
})();
