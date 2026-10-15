-- =============================================================================
-- Constraint tests: Paleoecological Proxy Inventory for Hominin Localities
-- Author:  Claire Brandes
-- Date:    2026-10-15
--
-- How to run (on a fresh database, in this order):
--     sqlite3 test.db < schema.sql
--     sqlite3 test.db < constraint_tests.sql
-- Statements marked SHOULD FAIL are meant to print an error. The sqlite3
-- command-line tool shows them as "Runtime error near line N: <message> (19)"
-- and keeps going. The wording of CHECK messages can differ slightly between
-- SQLite versions.
--
-- Not tested: ON DELETE CASCADE and ON DELETE SET NULL. They do not appear in
-- this schema, because all four foreign keys use ON DELETE RESTRICT (the child
-- columns are NOT NULL and every row is an independent record that must stay
-- traceable to its locality and publication). ON UPDATE CASCADE is tested instead.
-- =============================================================================

-- PRAGMA foreign_keys is per connection, so it has to be turned on again here.
PRAGMA foreign_keys = ON;


-- ── NOT NULL on localities.member ────────────────────────────────────────────

-- SHOULD SUCCEED
INSERT INTO localities (country, site, formation, member)
VALUES ('Kenya', 'Koobi Fora', 'Koobi Fora Formation', 'Okote Member');

-- SHOULD FAIL: member is NOT NULL
-- Expected error: NOT NULL constraint failed: localities.member
INSERT INTO localities (country, site, formation, member)
VALUES ('Kenya', 'Koobi Fora', 'Koobi Fora Formation', NULL);


-- ── NOT NULL on publications.citation ────────────────────────────────────────

-- SHOULD SUCCEED
INSERT INTO publications (citation, year, doi)
VALUES ('Wood, B. (1991). Koobi Fora research project. Oxford University Press.', 1991, '10.1000/example.1');

-- SHOULD FAIL: citation is NOT NULL
-- Expected error: NOT NULL constraint failed: publications.citation
INSERT INTO publications (citation, year, doi)
VALUES (NULL, 1991, '10.1000/example.2');


-- ── NOT NULL on hominin_occurrences.scientific_name ──────────────────────────

-- SHOULD SUCCEED
INSERT INTO hominin_occurrences (scientific_name, locality_id, publication_id)
VALUES ('Homo habilis',
        (SELECT locality_id FROM localities
          WHERE site = 'Koobi Fora' AND formation = 'Koobi Fora Formation' AND member = 'Okote Member'),
        (SELECT publication_id FROM publications WHERE doi = '10.1000/example.1'));

-- SHOULD FAIL: scientific_name is NOT NULL
-- Expected error: NOT NULL constraint failed: hominin_occurrences.scientific_name
INSERT INTO hominin_occurrences (scientific_name, locality_id, publication_id)
VALUES (NULL,
        (SELECT locality_id FROM localities
          WHERE site = 'Koobi Fora' AND formation = 'Koobi Fora Formation' AND member = 'Okote Member'),
        (SELECT publication_id FROM publications WHERE doi = '10.1000/example.1'));


-- ── UNIQUE on publications.doi ───────────────────────────────────────────────

-- SHOULD SUCCEED
INSERT INTO publications (citation, year, doi)
VALUES ('Leakey, M. (1995). Fauna of the Koobi Fora Formation.', 1995, '10.1000/example.3');

-- SHOULD FAIL: 10.1000/example.1 already belongs to the Wood (1991) publication
-- Expected error: UNIQUE constraint failed: publications.doi
INSERT INTO publications (citation, year, doi)
VALUES ('Brown, F. (1991). Stratigraphy of the Koobi Fora Formation.', 1991, '10.1000/example.1');


-- ── UNIQUE on localities (site, formation, member) ───────────────────────────

-- SHOULD SUCCEED
INSERT INTO localities (country, site, formation, member)
VALUES ('Tanzania', 'Olduvai Gorge', 'Olduvai Formation', 'Bed I');

-- SHOULD FAIL: same site, formation, and member as the row above
-- Expected error: UNIQUE constraint failed: localities.site, localities.formation, localities.member
INSERT INTO localities (country, site, formation, member)
VALUES ('Tanzania', 'Olduvai Gorge', 'Olduvai Formation', 'Bed I');


-- ── UNIQUE on proxies (locality_id, type, publication_id) ────────────────────

-- SHOULD SUCCEED
INSERT INTO proxies (type, locality_id, publication_id)
VALUES ('enamel_isotopes',
        (SELECT locality_id FROM localities
          WHERE site = 'Koobi Fora' AND formation = 'Koobi Fora Formation' AND member = 'Okote Member'),
        (SELECT publication_id FROM publications WHERE doi = '10.1000/example.1'));

-- SHOULD FAIL: same proxy type, locality, and publication as the row above
-- Expected error: UNIQUE constraint failed: proxies.locality_id, proxies.type, proxies.publication_id
INSERT INTO proxies (type, locality_id, publication_id)
VALUES ('enamel_isotopes',
        (SELECT locality_id FROM localities
          WHERE site = 'Koobi Fora' AND formation = 'Koobi Fora Formation' AND member = 'Okote Member'),
        (SELECT publication_id FROM publications WHERE doi = '10.1000/example.1'));


-- ── CHECK (enum) on proxies.type ─────────────────────────────────────────────

-- SHOULD SUCCEED
INSERT INTO proxies (type, locality_id, publication_id)
VALUES ('faunal_list',
        (SELECT locality_id FROM localities
          WHERE site = 'Koobi Fora' AND formation = 'Koobi Fora Formation' AND member = 'Okote Member'),
        (SELECT publication_id FROM publications WHERE doi = '10.1000/example.1'));

-- SHOULD FAIL: 'pollen' is not in the controlled vocabulary
-- Expected error: NOT NULL constraint failed: proxies.unit_of_analysis
-- (SQLite reports the generated column first: unit_of_analysis has no value for 'pollen',
--  so it is NULL. The CHECK on type would also reject this row.)
INSERT INTO proxies (type, locality_id, publication_id)
VALUES ('pollen',
        (SELECT locality_id FROM localities
          WHERE site = 'Koobi Fora' AND formation = 'Koobi Fora Formation' AND member = 'Okote Member'),
        (SELECT publication_id FROM publications WHERE doi = '10.1000/example.1'));


-- ── CHECK (controlled vocabulary) on hominin_occurrences.scientific_name ─────
-- Only names that start with Paranthropus or Homo are allowed.

-- SHOULD SUCCEED
INSERT INTO hominin_occurrences (scientific_name, locality_id, publication_id)
VALUES ('Paranthropus boisei',
        (SELECT locality_id FROM localities
          WHERE site = 'Koobi Fora' AND formation = 'Koobi Fora Formation' AND member = 'Okote Member'),
        (SELECT publication_id FROM publications WHERE doi = '10.1000/example.1'));

-- SHOULD FAIL: Pan troglodytes is not a genus in the study
-- Expected error: CHECK constraint failed: scientific_name GLOB 'Paranthropus *' OR scientific_name GLOB 'Homo *'
INSERT INTO hominin_occurrences (scientific_name, locality_id, publication_id)
VALUES ('Pan troglodytes',
        (SELECT locality_id FROM localities
          WHERE site = 'Koobi Fora' AND formation = 'Koobi Fora Formation' AND member = 'Okote Member'),
        (SELECT publication_id FROM publications WHERE doi = '10.1000/example.1'));


-- ── CHECK (range) on publications.year ───────────────────────────────────────

-- SHOULD SUCCEED
INSERT INTO publications (citation, year, doi)
VALUES ('Brown, F. (1995). Stratigraphy of the Koobi Fora Formation.', 1995, NULL);

-- SHOULD FAIL: 3000 is outside 1800-2100 (the year also appears in the citation,
-- so only the range rule is violated)
-- Expected error: CHECK constraint failed: year IS NULL OR year BETWEEN 1800 AND 2100
INSERT INTO publications (citation, year, doi)
VALUES ('Future, A. (3000). An impossible paper.', 3000, NULL);


-- ── CHECK (cross-field) on publications: year appears in the citation ────────

-- SHOULD SUCCEED
INSERT INTO publications (citation, year, doi)
VALUES ('Walker, A. (1986). Hominin fossils from Nariokotome.', 1986, NULL);

-- SHOULD FAIL: year is 1987 but the citation says 1986
-- Expected error: CHECK constraint failed: year IS NULL OR instr(citation, CAST(year AS TEXT)) > 0
INSERT INTO publications (citation, year, doi)
VALUES ('Walker, A. (1986). Hominin fossils from Nariokotome.', 1987, NULL);


-- ── Generated column: proxies.unit_of_analysis ───────────────────────────────
-- unit_of_analysis is generated from type, so the CHECK that compares the two
-- (type vs unit_of_analysis) can never be triggered by an INSERT.

-- SHOULD SUCCEED
INSERT INTO proxies (type, locality_id, publication_id)
VALUES ('paleosol_isotopes',
        (SELECT locality_id FROM localities
          WHERE site = 'Koobi Fora' AND formation = 'Koobi Fora Formation' AND member = 'Okote Member'),
        (SELECT publication_id FROM publications WHERE doi = '10.1000/example.1'));

-- Verify the generated values
-- Expected result: enamel_isotopes|specimen_level, faunal_list|assemblage_level, paleosol_isotopes|sediment_level
SELECT type, unit_of_analysis FROM proxies ORDER BY proxy_id;

-- SHOULD FAIL: a generated column cannot be written to
-- Expected error: cannot INSERT into generated column "unit_of_analysis"
INSERT INTO proxies (type, unit_of_analysis, locality_id, publication_id)
VALUES ('faunal_list', 'specimen_level',
        (SELECT locality_id FROM localities WHERE site = 'Olduvai Gorge'),
        (SELECT publication_id FROM publications WHERE doi = '10.1000/example.3'));


-- ── FK on hominin_occurrences.locality_id: the parent must exist ─────────────

-- SHOULD SUCCEED (an occurrence identified only to genus)
INSERT INTO hominin_occurrences (scientific_name, locality_id, publication_id)
VALUES ('Homo sp.',
        (SELECT locality_id FROM localities
          WHERE site = 'Koobi Fora' AND formation = 'Koobi Fora Formation' AND member = 'Okote Member'),
        (SELECT publication_id FROM publications WHERE doi = '10.1000/example.1'));

-- SHOULD FAIL: no locality has this ID
-- Expected error: FOREIGN KEY constraint failed
INSERT INTO hominin_occurrences (scientific_name, locality_id, publication_id)
VALUES ('Homo sp.', 999999,
        (SELECT publication_id FROM publications WHERE doi = '10.1000/example.1'));


-- ── FK ON DELETE RESTRICT ────────────────────────────────────────────────────
-- Olduvai Gorge / Bed I and the Leakey (1995) publication have no child rows.
-- The Koobi Fora / Okote Member locality and the Wood (1991) publication each have
-- hominin occurrences and proxy records.

-- SHOULD SUCCEED: parent rows with no children
DELETE FROM localities WHERE site = 'Olduvai Gorge' AND formation = 'Olduvai Formation' AND member = 'Bed I';
DELETE FROM publications WHERE doi = '10.1000/example.3';

-- SHOULD FAIL: this locality still has hominin occurrences and proxy records
-- Expected error: FOREIGN KEY constraint failed
DELETE FROM localities
 WHERE site = 'Koobi Fora' AND formation = 'Koobi Fora Formation' AND member = 'Okote Member';

-- SHOULD FAIL: this publication is still cited by hominin occurrences and proxy records
-- Expected error: FOREIGN KEY constraint failed
DELETE FROM publications WHERE doi = '10.1000/example.1';

-- Verify the children are still there
-- Expected result: 3 proxy records and 3 hominin occurrences
SELECT (SELECT COUNT(*) FROM proxies) AS proxy_rows,
       (SELECT COUNT(*) FROM hominin_occurrences) AS occurrence_rows;


-- ── FK ON UPDATE CASCADE ─────────────────────────────────────────────────────

-- SHOULD SUCCEED: change the parent keys
UPDATE localities SET locality_id = 1000
 WHERE site = 'Koobi Fora' AND formation = 'Koobi Fora Formation' AND member = 'Okote Member';
UPDATE publications SET publication_id = 500 WHERE doi = '10.1000/example.1';

-- Verify the children followed their parents to the new key values
-- Expected result: 3 proxy records and 3 hominin occurrences at locality 1000 / publication 500
SELECT (SELECT COUNT(*) FROM proxies WHERE locality_id = 1000 AND publication_id = 500) AS proxy_rows,
       (SELECT COUNT(*) FROM hominin_occurrences WHERE locality_id = 1000 AND publication_id = 500) AS occurrence_rows;