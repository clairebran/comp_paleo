-- =============================================================================
-- Database:  Paranthropus and Homo Paleoecology Database
-- Author:    Claire Brandes
-- Date:      2026-10-15
-- Target:    SQLite 3.31 or newer (uses a generated column)
--
-- Purpose:   Inventory of which paleoecological proxy types exist at localities
--            (site / formation / member) where Paranthropus and Homo occur, and
--            which publications report them. Actual proxy values are not stored.
--            Hominin occurrences and proxy records are linked only through the
--            locality they share.
-- =============================================================================

PRAGMA foreign_keys = ON;

-- Drop in reverse dependency order (child tables first) so the file can be re-run.
DROP TABLE IF EXISTS proxies;
DROP TABLE IF EXISTS hominin_occurrences;
DROP TABLE IF EXISTS publications;
DROP TABLE IF EXISTS localities;


-- ── localities ───────────────────────────────────────────────────────────────
-- One row per distinct stratigraphic location (site, formation, member).
CREATE TABLE localities (
    -- Primary key
    locality_id  INTEGER PRIMARY KEY AUTOINCREMENT,   -- surrogate key: stays stable if names are revised

    -- Required fields (controlled vocabulary by data-entry convention)
    country      TEXT NOT NULL,
    site         TEXT NOT NULL,
    formation    TEXT NOT NULL,
    member       TEXT NOT NULL,                       -- enter 'undifferentiated' if the source names none

    -- Composite uniqueness
    UNIQUE (site, formation, member)                  -- rationale: no duplicate localities; safe because all three are NOT NULL
);


-- ── publications ─────────────────────────────────────────────────────────────
-- One row per published source, cited by both hominin occurrences and proxy records.
CREATE TABLE publications (
    -- Primary key
    publication_id  INTEGER PRIMARY KEY AUTOINCREMENT,

    -- Required fields
    citation        TEXT NOT NULL,                    -- APA format

    -- Optional fields
    year            INTEGER
                    CHECK (year IS NULL OR year BETWEEN 1800 AND 2100),
                                                      -- NULL permitted: undated source; fixed upper bound because SQLite
                                                      -- does not allow strftime('now') inside a CHECK
    doi             TEXT UNIQUE,                      -- NULL permitted: many older publications have no DOI

    -- Cross-field business rule
    CHECK (year IS NULL OR instr(citation, CAST(year AS TEXT)) > 0)
                                                      -- rationale: the stored year must appear in the APA citation
);


-- ── hominin_occurrences ──────────────────────────────────────────────────────
-- One row per hominin occurrence recorded at a locality, as reported in a publication.
CREATE TABLE hominin_occurrences (
    -- Primary key
    occurrence_id    INTEGER PRIMARY KEY AUTOINCREMENT,

    -- Controlled vocabulary
    genus            TEXT NOT NULL
                     CHECK (genus IN ('Paranthropus', 'Homo')),

    -- Optional fields
    scientific_name  TEXT,                            -- NULL permitted: occurrence identified only to genus (e.g., Paranthropus sp.)

    -- Foreign keys
    locality_id      INTEGER NOT NULL
                     REFERENCES localities (locality_id)
                     ON DELETE RESTRICT               -- rationale: never silently delete hominin records with their locality
                     ON UPDATE CASCADE,
    publication_id   INTEGER NOT NULL
                     REFERENCES publications (publication_id)
                     ON DELETE RESTRICT               -- rationale: every occurrence must stay traceable to its source
                     ON UPDATE CASCADE,

    -- Cross-field business rule
    CHECK (scientific_name IS NULL OR scientific_name LIKE printf('%s %%', genus))
                                                      -- rationale: the species name must start with the genus in the same row
);


-- ── proxies ──────────────────────────────────────────────────────────────────
-- One row per paleoecological proxy type reported at a locality in a publication (inventory only, no values).
CREATE TABLE proxies (
    -- Primary key
    proxy_id          INTEGER PRIMARY KEY AUTOINCREMENT,

    -- Controlled vocabulary
    type              TEXT NOT NULL
                      CHECK (type IN ('faunal_list', 'enamel_isotopes', 'paleosol_isotopes')),

    -- Derived field (no DEFAULT needed: the value is generated from type, never entered by hand)
    unit_of_analysis  TEXT GENERATED ALWAYS AS (
                          CASE type
                              WHEN 'faunal_list'       THEN 'assemblage_level'
                              WHEN 'enamel_isotopes'   THEN 'specimen_level'
                              WHEN 'paleosol_isotopes' THEN 'sediment_level'
                          END
                      ) STORED NOT NULL,

    -- Foreign keys
    locality_id       INTEGER NOT NULL
                      REFERENCES localities (locality_id)
                      ON DELETE RESTRICT              -- rationale: never silently delete proxy records with their locality
                      ON UPDATE CASCADE,
    publication_id    INTEGER NOT NULL
                      REFERENCES publications (publication_id)
                      ON DELETE RESTRICT              -- rationale: every proxy record must stay traceable to its source
                      ON UPDATE CASCADE,

    -- Composite uniqueness
    UNIQUE (locality_id, type, publication_id),       -- rationale: one row per proxy type, locality, and publication

    -- Cross-field business rule
    CHECK (
        (type = 'faunal_list'       AND unit_of_analysis = 'assemblage_level') OR
        (type = 'enamel_isotopes'   AND unit_of_analysis = 'specimen_level')   OR
        (type = 'paleosol_isotopes' AND unit_of_analysis = 'sediment_level')
    )                                                 -- rationale: redundant with the generated column, kept as an explicit guard
);