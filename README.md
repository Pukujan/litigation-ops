# Litigation Operations Intelligence System ( Schema research )

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




*This project started from a real operational incident. Every design decision traces back to something that actually happened.*


