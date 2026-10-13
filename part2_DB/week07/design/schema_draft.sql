-- schema_draft.sql
-- Paleoecological proxy inventory: which proxy types exist at localities
-- (site / formation / member) where hominins occur, and which publications
-- report them.
-- Target: SQLite

PRAGMA foreign_keys = ON;

-- localities
-- One row per distinct geographic/stratigraphic location (site, formation,
-- member). Hominin occurrences and proxy records are linked to each other
-- only through the locality they share.
CREATE TABLE localities (
    locality_id  INTEGER PRIMARY KEY AUTOINCREMENT,
    country      TEXT,
    site         TEXT,
    formation    TEXT,
    member       TEXT
);

-- publications
-- One row per published source. Referenced by both hominin occurrences and
-- proxy records so each can be traced to its own publication.
CREATE TABLE publications (
    publication_id  INTEGER PRIMARY KEY AUTOINCREMENT,
    citation        TEXT NOT NULL,            -- APA format
    year            INTEGER,                  -- year of publication
    doi             TEXT UNIQUE               -- NULL if no DOI exists
);

-- hominin_occurrences
-- One row per hominin specimen (identified by institutional catalog number)
-- recorded at a locality. genus and scientific_name are NULL when the source
-- does not identify the specimen to that level (e.g., Paranthropus sp.).
CREATE TABLE hominin_occurrences (
    occurrence_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    genus            TEXT,                    -- controlled vocabulary
    scientific_name  TEXT,                    -- controlled vocabulary
    locality_id      INTEGER NOT NULL,
    publication_id   INTEGER NOT NULL,
    FOREIGN KEY (locality_id)    REFERENCES localities (locality_id),
    FOREIGN KEY (publication_id) REFERENCES publications (publication_id)
);

-- proxies
-- One row per paleoecological proxy record (inventory only; no measured
-- values are stored yet). unit_of_analysis describes what the proxy was
-- measured on, e.g., specimen_level, assemblage_level.
CREATE TABLE proxies (
    proxy_id          INTEGER PRIMARY KEY AUTOINCREMENT,
    type              TEXT,                   -- controlled vocabulary
    unit_of_analysis  TEXT,                   -- controlled vocabulary
    locality_id       INTEGER NOT NULL,
    publication_id    INTEGER NOT NULL,
    FOREIGN KEY (locality_id)    REFERENCES localities (locality_id),
    FOREIGN KEY (publication_id) REFERENCES publications (publication_id)
);
