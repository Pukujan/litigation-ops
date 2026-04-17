-- ============================================================
-- LITIGATION OPERATIONS INTELLIGENCE SYSTEM
-- PostgreSQL Schema v1.0
-- Generated: April 17, 2026
-- ============================================================
-- Layer 1: Court Reference
-- Layer 2: Cases & Incidents
-- Layer 3: Knowledge & Intelligence
-- ============================================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";


-- ============================================================
-- LAYER 1 — COURT REFERENCE
-- Stable institutional data. Courts, judges, parts,
-- contacts, rules. Populated from incidents, enriched over time.
-- ============================================================


-- courts
-- One row per court system. Everything else hangs off this.
-- Each court is an isolated universe — no data bleeds across courts.
CREATE TABLE courts (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name                TEXT NOT NULL,                        -- e.g. "Kings County Supreme Court"
    county              TEXT NOT NULL,                        -- e.g. "Kings"
    state               TEXT NOT NULL DEFAULT 'NY',
    court_type          TEXT NOT NULL,                        -- e.g. "Supreme", "Federal District", "Appellate"
    address             TEXT,
    general_phone       TEXT,
    general_email       TEXT,
    ecourts_reliable    BOOLEAN DEFAULT TRUE,                 -- flag if eCourts is known to mislabel
    notes               TEXT,
    extra_data          JSONB DEFAULT '{}',                   -- court-specific fields that don't fit schema
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_courts_name    ON courts(name);
CREATE INDEX idx_courts_county  ON courts(county);


-- judges
-- Judge profiles including behavioral observations.
-- Linked to a court but may sit in multiple parts.
CREATE TABLE judges (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    court_id            UUID NOT NULL REFERENCES courts(id) ON DELETE CASCADE,
    full_name           TEXT NOT NULL,
    honorific           TEXT DEFAULT 'Hon.',
    part_name           TEXT,                                 -- e.g. "IAS Part 63"
    default_courtroom   TEXT,                                 -- e.g. "Room 725"
    enforcement_style   TEXT,                                 -- e.g. "strict", "flexible", "informal"
    behavior_summary    TEXT,                                 -- free text profile
    known_quirks        JSONB DEFAULT '[]',                   -- array of observed behavior tags
    is_active           BOOLEAN DEFAULT TRUE,
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_judges_court_id  ON judges(court_id);
CREATE INDEX idx_judges_full_name ON judges(full_name);


-- parts
-- Court parts / divisions. Each part has its own rules and behavior.
CREATE TABLE parts (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    court_id            UUID NOT NULL REFERENCES courts(id) ON DELETE CASCADE,
    part_name           TEXT NOT NULL,                        -- e.g. "NI-FCP", "CCP", "IAS Part 63"
    part_type           TEXT,                                 -- e.g. "Discovery", "Motion", "Settlement", "Trial"
    default_courtroom   TEXT,
    description         TEXT,
    appearance_rules    JSONB DEFAULT '{}',                   -- structured rules for this part
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_parts_court_id  ON parts(court_id);
CREATE INDEX idx_parts_part_name ON parts(part_name);


-- court_contacts
-- Named clerks, court attorneys, and staff.
-- Every contact is traceable to the incident that verified it.
CREATE TABLE court_contacts (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    court_id                UUID NOT NULL REFERENCES courts(id) ON DELETE CASCADE,
    judge_id                UUID REFERENCES judges(id) ON DELETE SET NULL,
    part_id                 UUID REFERENCES parts(id) ON DELETE SET NULL,
    contact_name            TEXT NOT NULL,
    role                    TEXT NOT NULL,                    -- e.g. "Part Clerk", "Court Attorney", "Calendar Clerk"
    phone                   TEXT,
    email                   TEXT,
    contact_type            TEXT,                             -- e.g. "primary", "fallback", "chambers"
    what_they_confirmed     TEXT,                             -- what this contact has historically confirmed
    verified                BOOLEAN DEFAULT FALSE,
    verified_on             DATE,
    verified_by_incident_id UUID,                             -- FK added after incidents table created (below)
    is_active               BOOLEAN DEFAULT TRUE,
    notes                   TEXT,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_court_contacts_court_id  ON court_contacts(court_id);
CREATE INDEX idx_court_contacts_judge_id  ON court_contacts(judge_id);
CREATE INDEX idx_court_contacts_part_id   ON court_contacts(part_id);


-- court_rules
-- Published and observed rules per court, judge, or part.
-- Tracks conflicts between general rules and judge-specific rules.
CREATE TABLE court_rules (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    court_id                UUID NOT NULL REFERENCES courts(id) ON DELETE CASCADE,
    judge_id                UUID REFERENCES judges(id) ON DELETE SET NULL,
    part_id                 UUID REFERENCES parts(id) ON DELETE SET NULL,
    rule_type               TEXT NOT NULL,                    -- e.g. "appearance", "filing", "communication", "deadline"
    rule_title              TEXT NOT NULL,
    rule_text               TEXT NOT NULL,
    source                  TEXT,                             -- e.g. "Part rules", "Standing order", "Observed behavior"
    conflicts_with_general  BOOLEAN DEFAULT FALSE,
    conflict_note           TEXT,
    conflict_source_id      UUID REFERENCES court_rules(id) ON DELETE SET NULL,
    effective_date          DATE,
    is_active               BOOLEAN DEFAULT TRUE,
    notes                   TEXT,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_court_rules_court_id ON court_rules(court_id);
CREATE INDEX idx_court_rules_judge_id ON court_rules(judge_id);
CREATE INDEX idx_court_rules_part_id  ON court_rules(part_id);
CREATE INDEX idx_court_rules_type     ON court_rules(rule_type);


-- ============================================================
-- LAYER 2 — CASES AND INCIDENTS
-- The living record. Cases link courts to incidents.
-- Incidents are immutable. Updates append only.
-- Index number is the universal key.
-- ============================================================


-- cases
-- One row per case. Index number is the universal connector
-- to NYSCEF, case management systems, and all incidents.
CREATE TABLE cases (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    index_number        TEXT NOT NULL,                        -- universal key connecting all data sources
    court_id            UUID NOT NULL REFERENCES courts(id) ON DELETE RESTRICT,
    judge_id            UUID REFERENCES judges(id) ON DELETE SET NULL,
    case_name           TEXT,
    plaintiff           TEXT,
    defendant           TEXT,
    case_type           TEXT,                                 -- e.g. "Medical Malpractice", "Personal Injury"
    track               TEXT,                                 -- e.g. "Complex", "Standard"
    stage               TEXT,                                 -- e.g. "Discovery", "Pre-trial", "Trial"
    status              TEXT DEFAULT 'active',               -- active / closed / stayed / dismissed
    filed_date          DATE,
    notes               TEXT,
    extra_data          JSONB DEFAULT '{}',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_cases_index_number ON cases(index_number, court_id);
CREATE INDEX idx_cases_court_id            ON cases(court_id);
CREATE INDEX idx_cases_judge_id            ON cases(judge_id);
CREATE INDEX idx_cases_status              ON cases(status);


-- case_appearances
-- Court appearance history per case.
-- Populated from NYSCEF snapshots and incident documents.
CREATE TABLE case_appearances (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id             UUID NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
    court_id            UUID NOT NULL REFERENCES courts(id) ON DELETE RESTRICT,
    judge_id            UUID REFERENCES judges(id) ON DELETE SET NULL,
    part_id             UUID REFERENCES parts(id) ON DELETE SET NULL,
    appearance_date     DATE NOT NULL,
    appearance_type     TEXT,                                 -- e.g. "Conference", "Motion", "NI-FCP", "ADR"
    outcome             TEXT,                                 -- e.g. "Held", "Adjourned", "Granted", "Closed"
    source              TEXT DEFAULT 'eCourts',
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_appearances_case_id  ON case_appearances(case_id);
CREATE INDEX idx_appearances_date     ON case_appearances(appearance_date);
CREATE INDEX idx_appearances_judge_id ON case_appearances(judge_id);


-- incidents
-- Core table. Every incident ever logged.
-- raw_narrative is immutable — never overwrite.
-- All structured fields are extracted from it by the AI agent.
CREATE TABLE incidents (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_id             TEXT UNIQUE NOT NULL,             -- e.g. "INC-2026-041" — human-readable ID
    case_id                 UUID REFERENCES cases(id) ON DELETE SET NULL,
    court_id                UUID REFERENCES courts(id) ON DELETE SET NULL,
    judge_id                UUID REFERENCES judges(id) ON DELETE SET NULL,
    part_id                 UUID REFERENCES parts(id) ON DELETE SET NULL,

    -- Identity
    title                   TEXT NOT NULL,
    incident_date           DATE NOT NULL,
    reported_by             TEXT,

    -- Classification (anchor block)
    domain                  TEXT NOT NULL,                    -- court_ops / case_strategy / client_mgmt / firm_ops / opa_negotiation
    risk_level              TEXT NOT NULL,                    -- low / medium / high / critical
    risk_layer              TEXT NOT NULL,                    -- operational / procedural / decision / multiple
    status                  TEXT NOT NULL DEFAULT 'open',    -- open / monitoring / resolved

    -- Source document
    source_filename         TEXT,
    raw_narrative           TEXT NOT NULL,                    -- IMMUTABLE — full original report text, never edited

    -- Structured extraction (AI populated)
    trigger_description     TEXT,
    trigger_source          TEXT,                             -- eCourts / NYSCEF / phone / email / notice
    deadline                TEXT,

    risk_analysis           TEXT,
    root_cause              TEXT,
    resolution_method       TEXT,
    resolution_detail       TEXT,

    resolved                BOOLEAN DEFAULT FALSE,
    resolved_at             TIMESTAMPTZ,

    -- AI extraction metadata
    extracted_contacts      JSONB DEFAULT '[]',               -- contacts found before linking to court_contacts
    ai_confidence           NUMERIC(3,2),                     -- 0.00–1.00
    ai_metadata             JSONB DEFAULT '{}',

    notes                   TEXT,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_incidents_incident_id  ON incidents(incident_id);
CREATE INDEX idx_incidents_case_id      ON incidents(case_id);
CREATE INDEX idx_incidents_court_id     ON incidents(court_id);
CREATE INDEX idx_incidents_judge_id     ON incidents(judge_id);
CREATE INDEX idx_incidents_domain       ON incidents(domain);
CREATE INDEX idx_incidents_risk_level   ON incidents(risk_level);
CREATE INDEX idx_incidents_status       ON incidents(status);
CREATE INDEX idx_incidents_date         ON incidents(incident_date);

-- Full text search on narrative and title
CREATE INDEX idx_incidents_fts ON incidents
    USING GIN(to_tsvector('english', coalesce(title,'') || ' ' || coalesce(raw_narrative,'')));


-- incident_updates
-- Append-only resolution log.
-- Never delete or edit rows — only insert new ones.
CREATE TABLE incident_updates (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_id         UUID NOT NULL REFERENCES incidents(id) ON DELETE CASCADE,
    updated_by          TEXT NOT NULL,
    update_type         TEXT,                                 -- call_made / confirmed / escalated / resolved / note
    update_note         TEXT NOT NULL,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
    -- No updated_at — append-only by design
);

CREATE INDEX idx_incident_updates_incident_id ON incident_updates(incident_id);
CREATE INDEX idx_incident_updates_created_at  ON incident_updates(created_at);


-- incident_participants
-- Named people involved in each incident.
-- Feeds back into court_contacts when a contact is verified.
CREATE TABLE incident_participants (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_id             UUID NOT NULL REFERENCES incidents(id) ON DELETE CASCADE,
    name                    TEXT NOT NULL,
    role                    TEXT,                             -- Part Clerk / Court Attorney / OPA / Internal attorney
    affiliation             TEXT,
    phone                   TEXT,
    email                   TEXT,
    what_they_confirmed     TEXT,
    contact_created         BOOLEAN DEFAULT FALSE,            -- true if promoted to court_contacts
    contact_id              UUID REFERENCES court_contacts(id) ON DELETE SET NULL,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_incident_participants_incident_id ON incident_participants(incident_id);


-- ============================================================
-- LAYER 3 — KNOWLEDGE AND INTELLIGENCE
-- What the system learns from incidents.
-- All knowledge is traceable to the incident that generated it.
-- ============================================================


-- lessons_learned
-- Reusable IF/THEN operational rules derived from incidents.
CREATE TABLE lessons_learned (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_id         UUID NOT NULL REFERENCES incidents(id) ON DELETE CASCADE,
    court_id            UUID REFERENCES courts(id) ON DELETE SET NULL,
    judge_id            UUID REFERENCES judges(id) ON DELETE SET NULL,
    part_id             UUID REFERENCES parts(id) ON DELETE SET NULL,

    pattern_title       TEXT NOT NULL,
    pattern_description TEXT,
    scope               TEXT NOT NULL DEFAULT 'court',       -- court / judge / part / firm_wide
    domain              TEXT,

    if_condition        TEXT,                                 -- e.g. "judge_assignment_unclear AND NI-FCP_upcoming"
    then_action         TEXT,                                 -- e.g. "call NI-FCP clerk first, fallback to calendar clerk"
    operational_rule    TEXT,                                 -- full free-text rule

    firm_wide           BOOLEAN DEFAULT FALSE,
    confidence_score    INTEGER DEFAULT 1,                    -- increments as more incidents confirm pattern
    is_active           BOOLEAN DEFAULT TRUE,
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_lessons_incident_id ON lessons_learned(incident_id);
CREATE INDEX idx_lessons_court_id    ON lessons_learned(court_id);
CREATE INDEX idx_lessons_judge_id    ON lessons_learned(judge_id);
CREATE INDEX idx_lessons_scope       ON lessons_learned(scope);
CREATE INDEX idx_lessons_firm_wide   ON lessons_learned(firm_wide);


-- conflict_flags
-- Stores contradictions between data sources without resolving prematurely.
-- Both sides stored. Resolution happens when confirmed by a real source.
CREATE TABLE conflict_flags (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_id         UUID NOT NULL REFERENCES incidents(id) ON DELETE CASCADE,
    court_id            UUID REFERENCES courts(id) ON DELETE SET NULL,
    judge_id            UUID REFERENCES judges(id) ON DELETE SET NULL,
    part_id             UUID REFERENCES parts(id) ON DELETE SET NULL,

    conflict_type       TEXT NOT NULL,                        -- courtroom / judge_assignment / appearance_rule / ecourts_label
    source_a_label      TEXT NOT NULL,                        -- e.g. "General Discovery Part rule"
    source_a_value      TEXT NOT NULL,                        -- e.g. "Room 282"
    source_b_label      TEXT NOT NULL,                        -- e.g. "Judge-specific standing order"
    source_b_value      TEXT NOT NULL,                        -- e.g. "Room 561"

    resolution_status   TEXT DEFAULT 'unresolved',           -- unresolved / resolved / superseded
    resolution_note     TEXT,
    resolved_by_incident_id UUID REFERENCES incidents(id) ON DELETE SET NULL,

    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved_at         TIMESTAMPTZ
);

CREATE INDEX idx_conflict_flags_incident_id ON conflict_flags(incident_id);
CREATE INDEX idx_conflict_flags_court_id    ON conflict_flags(court_id);
CREATE INDEX idx_conflict_flags_type        ON conflict_flags(conflict_type);
CREATE INDEX idx_conflict_flags_status      ON conflict_flags(resolution_status);


-- judge_profiles
-- Behavioral observations accumulate over time.
-- One observation is a note. Many observations is institutional knowledge.
CREATE TABLE judge_profiles (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    judge_id                UUID NOT NULL REFERENCES judges(id) ON DELETE CASCADE,
    incident_id             UUID NOT NULL REFERENCES incidents(id) ON DELETE CASCADE,

    behavior_tag            TEXT NOT NULL,                    -- e.g. "strict_scheduling", "informal_resolution"
    enforcement_level       TEXT,                             -- strict / moderate / flexible
    observed_behavior       TEXT NOT NULL,
    operational_implication TEXT,

    observations_count      INTEGER DEFAULT 1,
    last_observed           DATE,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_judge_profiles_judge_id    ON judge_profiles(judge_id);
CREATE INDEX idx_judge_profiles_incident_id ON judge_profiles(incident_id);
CREATE INDEX idx_judge_profiles_tag         ON judge_profiles(behavior_tag);


-- ecourts_flags
-- Documents known eCourts reliability problems and correct interpretations.
CREATE TABLE ecourts_flags (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    court_id                UUID NOT NULL REFERENCES courts(id) ON DELETE CASCADE,
    incident_id             UUID NOT NULL REFERENCES incidents(id) ON DELETE CASCADE,

    flag_type               TEXT NOT NULL,                    -- mislabel / stale_data / missing_assignment / wrong_status
    ecourts_display         TEXT NOT NULL,                    -- what eCourts shows
    correct_interpretation  TEXT NOT NULL,                    -- what it actually means
    description             TEXT,

    occurrences             INTEGER DEFAULT 1,
    first_seen              DATE,
    last_seen               DATE,
    is_active               BOOLEAN DEFAULT TRUE,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ecourts_flags_court_id ON ecourts_flags(court_id);
CREATE INDEX idx_ecourts_flags_type     ON ecourts_flags(flag_type);


-- ingestion_log
-- Full audit trail of every document the AI processed.
CREATE TABLE ingestion_log (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_id             UUID REFERENCES incidents(id) ON DELETE SET NULL,

    source_filename         TEXT,
    doc_type_detected       TEXT,                             -- incident_report / part_rule / case_history / best_practice
    domain_detected         TEXT,
    risk_level_detected     TEXT,

    fields_extracted        JSONB DEFAULT '{}',
    fields_flagged          JSONB DEFAULT '{}',
    conflicts_detected      INTEGER DEFAULT 0,

    human_reviewed          BOOLEAN DEFAULT FALSE,
    reviewed_by             TEXT,
    review_notes            TEXT,

    ingested_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    reviewed_at             TIMESTAMPTZ
);

CREATE INDEX idx_ingestion_log_incident_id    ON ingestion_log(incident_id);
CREATE INDEX idx_ingestion_log_ingested_at    ON ingestion_log(ingested_at);
CREATE INDEX idx_ingestion_log_human_reviewed ON ingestion_log(human_reviewed);


-- ============================================================
-- DEFERRED FOREIGN KEYS
-- ============================================================

ALTER TABLE court_contacts
    ADD CONSTRAINT fk_verified_by_incident
    FOREIGN KEY (verified_by_incident_id)
    REFERENCES incidents(id) ON DELETE SET NULL;

ALTER TABLE conflict_flags
    ADD CONSTRAINT fk_resolved_by_incident
    FOREIGN KEY (resolved_by_incident_id)
    REFERENCES incidents(id) ON DELETE SET NULL;


-- ============================================================
-- SEED DATA — Courts identified in session (April 17, 2026)
-- Behavioral notes included. No case-specific data.
-- ============================================================

INSERT INTO courts (name, county, state, court_type, ecourts_reliable, notes) VALUES
    ('Kings County Supreme Court',
     'Kings', 'NY', 'Supreme', FALSE,
     'Discovery parts operate as shared infrastructure. Judge assignment is not deterministic in advance. eCourts does not confirm future judge assignments. General part rules and judge-specific standing orders frequently conflict on courtroom assignments.'),

    ('Nassau County Supreme Court',
     'Nassau', 'NY', 'Supreme', TRUE,
     'Accelerated post-conference workflow. EBT scheduling often initiated shortly after conference completion. Strict judicial oversight observed in certain parts — court order errors treated as compliance failures regardless of good faith.'),

    ('Bronx County Supreme Court',
     'Bronx', 'NY', 'Supreme', FALSE,
     'Late submissions frequently accepted. Courts may administratively cancel conferences upon receipt of consent order. eCourts motion labels known to misrepresent actual procedural posture — always verify with part clerk directly.'),

    ('Westchester County Supreme Court',
     'Westchester', 'NY', 'Supreme', TRUE,
     'Strict adherence to procedural rules expected. Timely submission alone is insufficient — must confirm receipt and review directly with court via phone or email. Failure to confirm may result in mandatory appearance despite compliant submission.'),

    ('Monroe County Supreme Court',
     'Monroe', 'NY', 'Supreme', TRUE,
     'Standard behavior. No special operational flags identified yet.');


-- ============================================================
-- END OF SCHEMA v1.0
-- ============================================================
-- Tables:  18
-- Layers:  3 (Court Reference / Cases & Incidents / Knowledge)
-- Indexes: 45
-- FTS:     incidents (title + raw_narrative)
-- Seed:    5 NY courts with operational notes
-- ============================================================
