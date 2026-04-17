# Litigation Operations Intelligence System

A knowledge infrastructure layer for litigation firms — capturing operational intelligence from real incidents and making it queryable before the next emergency.

---

## The problem

Court rules exist in published form. How courts actually behave does not.

A litigation firm operating across New York state courts deals with a reality that no legal research tool captures:

- eCourts shows filing history but not whether its labels are accurate
- Part rules say one thing but judge-specific standing orders say another
- The right clerk to call depends on which judge is sitting, which nobody confirms in advance
- A new judicial assignment can mean a same-day conference with three hours notice
- A court order typo becomes a critical compliance risk when the producing party has no scheduling flexibility
- Opposing counsel non-appearance at a compliance conference may be deliberate delay strategy — or an oversight

None of this is written down anywhere. It lives in the heads of experienced attorneys and senior paralegals. It transfers through word of mouth. And when those people are unavailable, the firm flies blind on a real matter with a real deadline.

In a firm with tens of thousands of active cases, this happens constantly.

---

## What this system builds

A structured database that captures operational intelligence from real incidents and makes it queryable in real time.

**Three layers:**

**1 — Court reference layer**
Courts, judges, parts, clerks, contact information, rules — all stored per court system, all traceable to the real incident that verified them. Each court is an isolated universe. Nothing bleeds across jurisdictions.

**2 — Incident log**
Every operational incident ever documented: what happened, what the risk was, what actions were taken, how it was resolved. The raw narrative is immutable — it happened, it is recorded, it never changes. Updates append. Nothing overwrites.

**3 — Knowledge layer**
What the system learns from incidents over time. Reusable IF/THEN operational rules. Judge behavior profiles that accumulate with every observation. eCourts reliability flags. Conflict detections when a general rule contradicts a judge-specific rule.

**The AI layer**
An ingestion agent reads incident reports in any format — Word documents, PDFs, plain text — extracts structured data automatically, populates all three layers, and flags conflicts or uncertainty before anything touches the database.

---

## What existing tools don't do

| Tool | What it does | What it misses |
|---|---|---|
| Westlaw / Lexis | Published rules and case law | How courts actually behave |
| Clio / Litify | Deadlines, billing, docketing | Operational intelligence |
| Harvey / CoCounsel | AI research and drafting | Firm-specific institutional knowledge |
| Docket Alarm | Static court rule tracking | Incident layer, judge profiles, clerk routing |
| eCourts / NYSCEF | Filing records | Confirmed future assignments, reliable status |

None of them capture that certain counties accept late submissions informally while others require confirmed receipt. None of them know that a specific judge's enforcement style means you call the clerk the day before, not the morning of. None of them know which clerk to call first and which number is the fallback.

That knowledge exists only in people. This system makes it institutional.

---

## The problem this started from

A recurring operational incident type in NY Supreme Court litigation: a scheduled court appearance where the assigned judge, correct courtroom, and right clerk contact are all simultaneously unclear — and each has a different answer depending on whether you follow the general part rule or the judge-specific standing order.

Resolving it requires knowing the correct clerk contact sequence for that specific part — knowledge that exists in one person's head and nowhere else.

This system captures that sequence so the next person doesn't have to figure it out from scratch.

---

## Tech stack

- **Database:** PostgreSQL (hosted on Supabase)
- **AI ingestion:** Anthropic Claude API (claude-sonnet-4-6)
- **Backend:** Node.js
- **Schema:** 18 tables across 3 layers, 45 indexes, full-text search on incident narratives

---

## Repository structure

```
litigation-ops-system/
├── README.md
├── devlog/
│   └── 2026-04-17.md        ← Architecture session — first day
├── schema/
│   └── schema_v1.sql        ← Full PostgreSQL schema, ready to run
└── templates/
    └── Litigation_Incident_Report_Template.docx
```

---

## Dev log

All architecture decisions, design changes, and build progress are documented in [`devlog/`](./devlog/).

| Date | Entry | Summary |
|---|---|---|
| 2026-04-17 | [April 17](./devlog/2026-04-17.md) | Full architecture session. Incident types reviewed. Flowchart designed. Schema drafted. Template built. |

---

## Schema overview

Full schema in [`schema/schema_v1.sql`](./schema/schema_v1.sql) — run directly in Supabase or any PostgreSQL instance.

**Layer 1 — Court reference:** `courts` `judges` `parts` `court_contacts` `court_rules`

**Layer 2 — Cases and incidents:** `cases` `case_appearances` `incidents` `incident_updates` `incident_participants`

**Layer 3 — Knowledge and intelligence:** `lessons_learned` `conflict_flags` `judge_profiles` `ecourts_flags` `ingestion_log`

---

## Courts in scope (initial)

| Court | County | Operational notes |
|---|---|---|
| Kings County Supreme Court | Kings | Discovery parts operate as shared infrastructure. Judge assignment not deterministic. eCourts labels unreliable for future appearances. |
| Nassau County Supreme Court | Nassau | Accelerated post-conference workflow. Strict judicial oversight observed in certain parts. |
| Bronx County Supreme Court | Bronx | Late submissions frequently accepted. eCourts motion labels known to misrepresent procedural status. |
| Westchester County Supreme Court | Westchester | Strict adherence required. Must confirm receipt of filings directly with court. |
| Monroe County Supreme Court | Monroe | Standard behavior. No special flags identified yet. |

---

## Status

**April 17, 2026 — Architecture complete**

- [x] Problem defined
- [x] Incident types catalogued across multiple domains and courts
- [x] System flowchart designed
- [x] Database schema designed (18 tables)
- [x] Incident report template built
- [x] Dev log started
- [ ] Supabase project created and schema deployed
- [ ] AI ingestion layer built and tested
- [ ] First incidents ingested and validated
- [ ] Attorney-facing query interface built
- [ ] Court reference layer populated for all 5 courts

---

<style>
.layer-label{font-size:13px;font-weight:500;color:var(--color-text-secondary);margin:0 0 4px}
.layer-desc{font-size:12px;color:var(--color-text-tertiary);margin:0 0 12px}
#e1 svg{width:100%!important}
#e1 svg.erDiagram .divider path{stroke-opacity:.4}
#e1 svg.erDiagram .row-rect-odd path,#e1 svg.erDiagram .row-rect-odd rect,#e1 svg.erDiagram .row-rect-even path,#e1 svg.erDiagram .row-rect-even rect{stroke:none!important}
</style>
<p class="layer-label">Layer 1 — Court reference (v2)</p>
<p class="layer-desc">No case-identifiable data. Courts, judges, parts, contacts, rules only. All verified_by links use incident UUIDs — never index numbers.</p>
<div id="e1"></div>
<script type="module">
import mermaid from 'https://esm.sh/mermaid@11/dist/mermaid.esm.min.mjs';
const dark=matchMedia('(prefers-color-scheme: dark)').matches;
await document.fonts.ready;
mermaid.initialize({startOnLoad:false,theme:'base',fontFamily:'"Anthropic Sans",sans-serif',
  themeVariables:{darkMode:dark,fontSize:'13px',fontFamily:'"Anthropic Sans",sans-serif',
    lineColor:dark?'#9c9a92':'#73726c',textColor:dark?'#c2c0b6':'#3d3d3a',
    primaryColor:dark?'#1D3A5F':'#E6F1FB',primaryTextColor:dark?'#B5D4F4':'#0C447C',
    primaryBorderColor:dark?'#378ADD':'#185FA5',
    secondaryColor:dark?'#1A3A2A':'#E1F5EE',tertiaryColor:dark?'#3A2A1A':'#FAEEDA'}});
const d=`erDiagram
  courts{
    uuid id PK
    string name
    string county
    string state
    string court_type
    string address
    string general_phone
    string general_email
    boolean ecourts_reliable
    jsonb extra_data
    timestamp created_at
    timestamp updated_at
  }
  judges{
    uuid id PK
    uuid court_id FK
    string full_name
    string honorific
    string part_name
    string default_courtroom
    string enforcement_style
    string behavior_summary
    jsonb known_quirks
    boolean is_active
    timestamp created_at
    timestamp updated_at
  }
  parts{
    uuid id PK
    uuid court_id FK
    string part_name
    string part_type
    string default_courtroom
    string description
    jsonb appearance_rules
    timestamp created_at
    timestamp updated_at
  }
  court_contacts{
    uuid id PK
    uuid court_id FK
    uuid judge_id FK
    uuid part_id FK
    string contact_name
    string role
    string phone
    string email
    string contact_type
    text what_they_confirmed
    boolean verified
    date verified_on
    uuid verified_by_incident_id FK
    boolean is_active
    timestamp created_at
    timestamp updated_at
  }
  court_rules{
    uuid id PK
    uuid court_id FK
    uuid judge_id FK
    uuid part_id FK
    string rule_type
    string rule_title
    text rule_text
    string source
    boolean conflicts_with_general
    text conflict_note
    uuid conflict_source_id FK
    date effective_date
    boolean is_active
    timestamp created_at
    timestamp updated_at
  }
  courts||--o{judges:"sits in"
  courts||--o{parts:"has"
  courts||--o{court_contacts:"has"
  courts||--o{court_rules:"governs"
  judges||--o{court_contacts:"has clerk"
  judges||--o{court_rules:"imposes"
  parts||--o{court_contacts:"has clerk"
  parts||--o{court_rules:"has rules"`;
const{svg}=await mermaid.render('e1-svg',d);
document.getElementById('e1').innerHTML=svg;
document.querySelectorAll('#e1 svg.erDiagram .node').forEach(n=>{
  const fp=n.querySelector('path[d]');if(!fp)return;
  const nums=fp.getAttribute('d').match(/-?[\d.]+/g)?.map(Number);
  if(!nums||nums.length<8)return;
  const xs=[nums[0],nums[2],nums[4],nums[6]],ys=[nums[1],nums[3],nums[5],nums[7]];
  const x=Math.min(...xs),y=Math.min(...ys),w=Math.max(...xs)-x,h=Math.max(...ys)-y;
  const r=document.createElementNS('http://www.w3.org/2000/svg','rect');
  r.setAttribute('x',x);r.setAttribute('y',y);r.setAttribute('width',w);r.setAttribute('height',h);r.setAttribute('rx','8');
  for(const a of['fill','stroke','stroke-width','class','style'])if(fp.hasAttribute(a))r.setAttribute(a,fp.getAttribute(a));
  fp.replaceWith(r);
});
document.querySelectorAll('#e1 svg.erDiagram .row-rect-odd path,#e1 svg.erDiagram .row-rect-even path').forEach(p=>p.setAttribute('stroke','none'));
</script>

[schema_v2_layer1_courts.html](https://github.com/user-attachments/files/26841769/schema_v2_layer1_courts.html)

<style>
.layer-label{font-size:13px;font-weight:500;color:var(--color-text-secondary);margin:0 0 4px}
.layer-desc{font-size:12px;color:var(--color-text-tertiary);margin:0 0 12px}
#e2 svg{width:100%!important}
#e2 svg.erDiagram .divider path{stroke-opacity:.4}
#e2 svg.erDiagram .row-rect-odd path,#e2 svg.erDiagram .row-rect-odd rect,#e2 svg.erDiagram .row-rect-even path,#e2 svg.erDiagram .row-rect-even rect{stroke:none!important}
</style>
<p class="layer-label">Layer 2 — Cases and incidents (v2)</p>
<p class="layer-desc">Key change: cases now has internal_ref as the public-facing identifier. index_number, case_name, plaintiff, defendant are encrypted at rest. raw_narrative stored encrypted. Everything else references cases.id (UUID) — never the index number directly.</p>
<div id="e2"></div>
<script type="module">
import mermaid from 'https://esm.sh/mermaid@11/dist/mermaid.esm.min.mjs';
const dark=matchMedia('(prefers-color-scheme: dark)').matches;
await document.fonts.ready;
mermaid.initialize({startOnLoad:false,theme:'base',fontFamily:'"Anthropic Sans",sans-serif',
  themeVariables:{darkMode:dark,fontSize:'13px',fontFamily:'"Anthropic Sans",sans-serif',
    lineColor:dark?'#9c9a92':'#73726c',textColor:dark?'#c2c0b6':'#3d3d3a',
    primaryColor:dark?'#2A1A3A':'#EEEDFE',primaryTextColor:dark?'#CECBF6':'#3C3489',
    primaryBorderColor:dark?'#7F77DD':'#534AB7',
    secondaryColor:dark?'#1A3A2A':'#E1F5EE',tertiaryColor:dark?'#1A2A3A':'#E6F1FB'}});
const d=`erDiagram
  cases{
    uuid id PK
    string internal_ref UK
    text index_number_enc "ENCRYPTED"
    uuid court_id FK
    uuid judge_id FK
    text case_name_enc "ENCRYPTED"
    text plaintiff_enc "ENCRYPTED"
    text defendant_enc "ENCRYPTED"
    string case_type
    string track
    string stage
    string status
    date filed_date
    jsonb extra_data
    timestamp created_at
    timestamp updated_at
  }
  case_appearances{
    uuid id PK
    uuid case_id FK
    uuid court_id FK
    uuid judge_id FK
    uuid part_id FK
    date appearance_date
    string appearance_type
    string outcome
    string source
    timestamp created_at
  }
  incidents{
    uuid id PK
    string incident_id UK
    uuid case_id FK
    uuid court_id FK
    uuid judge_id FK
    uuid part_id FK
    string title
    date incident_date
    string reported_by
    string domain
    string risk_level
    string risk_layer
    string status
    string source_filename
    text raw_narrative_enc "ENCRYPTED"
    text trigger_description
    string trigger_source
    string deadline
    text risk_analysis
    text root_cause
    text resolution_method
    text resolution_detail
    boolean resolved
    timestamptz resolved_at
    jsonb extracted_contacts
    numeric ai_confidence
    jsonb ai_metadata
    timestamp created_at
    timestamp updated_at
  }
  incident_updates{
    uuid id PK
    uuid incident_id FK
    string updated_by
    string update_type
    text update_note
    timestamp created_at
  }
  incident_participants{
    uuid id PK
    uuid incident_id FK
    string name
    string role
    string affiliation
    string phone
    string email
    text what_they_confirmed
    boolean contact_created
    uuid contact_id FK
    timestamp created_at
  }
  cases||--o{case_appearances:"has"
  cases||--o{incidents:"generates"
  incidents||--o{incident_updates:"receives"
  incidents||--o{incident_participants:"involves"`;
const{svg}=await mermaid.render('e2-svg',d);
document.getElementById('e2').innerHTML=svg;
document.querySelectorAll('#e2 svg.erDiagram .node').forEach(n=>{
  const fp=n.querySelector('path[d]');if(!fp)return;
  const nums=fp.getAttribute('d').match(/-?[\d.]+/g)?.map(Number);
  if(!nums||nums.length<8)return;
  const xs=[nums[0],nums[2],nums[4],nums[6]],ys=[nums[1],nums[3],nums[5],nums[7]];
  const x=Math.min(...xs),y=Math.min(...ys),w=Math.max(...xs)-x,h=Math.max(...ys)-y;
  const r=document.createElementNS('http://www.w3.org/2000/svg','rect');
  r.setAttribute('x',x);r.setAttribute('y',y);r.setAttribute('width',w);r.setAttribute('height',h);r.setAttribute('rx','8');
  for(const a of['fill','stroke','stroke-width','class','style'])if(fp.hasAttribute(a))r.setAttribute(a,fp.getAttribute(a));
  fp.replaceWith(r);
});
document.querySelectorAll('#e2 svg.erDiagram .row-rect-odd path,#e2 svg.erDiagram .row-rect-even path').forEach(p=>p.setAttribute('stroke','none'));
</script>

[schema_v2_layer2_cases_incidents.html](https://github.com/user-attachments/files/26841770/schema_v2_layer2_cases_incidents.html)



*This project started from a real operational incident. Every design decision traces back to something that actually happened.*


