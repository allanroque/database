async function loadJSON(url){
  const res = await fetch(url, {cache:"no-store"});
  if(!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.json();
}
function setText(id, txt){ const el=document.getElementById(id); if(el) el.textContent = (txt ?? "—"); }
function setPre(id, txt){ const el=document.getElementById(id); if(el) el.textContent = (txt && String(txt).trim().length ? txt : "—"); }
function addRow(tbodyId, k, v){
  const tb=document.getElementById(tbodyId); if(!tb) return;
  const tr=document.createElement("tr");
  const td1=document.createElement("td"); td1.textContent=k;
  const td2=document.createElement("td"); td2.textContent=(v ?? "—");
  tr.append(td1,td2); tb.appendChild(tr);
}

// extrai campos do bloco básico (resultado da task psql_basic)
function parseBasicsBlock(text){
  if(!text) return {};
  const lines=String(text).split(/\r?\n/).map(l=>l.trim()).filter(Boolean);
  const out={};
  for(const l of lines){
    if(l.startsWith("PostgreSQL")) out.version=l;
    else if(l==="localhost") out.listen=l;
    else if(/^\d{4,5}$/.test(l)) out.port=l;
    else if(l.includes("postgresql.conf")) out.config_file=l;
    else if(l.includes("pg_hba.conf")) out.hba_file=l;
    else if(/^\d+$/.test(l)) out.connections=l;
  }
  return out;
}

(async ()=>{
  try{
    const data = await loadJSON("health.json");

    // header
    setText("host", data.host);
    setText("collected", data.collected_at);
    setText("collected-hero", data.collected_at);

    // CORE
    addRow("os-kv","OS",data.os?.distro);
    addRow("os-kv","Kernel",data.os?.kernel);
    addRow("os-kv","Arch",data.os?.arch);
    addRow("os-kv","Uptime",data.os?.uptime);
    addRow("os-kv","vCPUs",data.os?.cpu_vcpus);
    addRow("os-kv","Memória (MB)",data.os?.mem_mb);

    addRow("os-extra","Mounts",(data.os?.mounts||[]).join(", "));
    // THP em linha única
    addRow("os-extra","THP",(data.os?.thp||"").toString().replace(/\n/g,"  "));
    // sysctl em chave=valor
    const sys = data.os?.sysctl_sample || [];
    sys.forEach((line,i)=>{
      const s=(line||"").toString().trim(); if(!s) return;
      const [k,v]= s.includes("=") ? s.split("=",2) : [`sysctl#${i+1}`, s];
      addRow("os-extra",k,v);
    });
    setPre("dns-info", data.os?.dns);

    // SERVICE
    setPre("svc-status", data.service?.status);
    setPre("svc-bin", data.service?.bin_version);
   
