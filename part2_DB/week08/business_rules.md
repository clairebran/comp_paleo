# *Paranthropus* and *Homo* Paleoecology Database - Business Rules Document
**Author:** Claire Brandes /
**Date:** October 14, 2026

### Rule Inventory

| # | Rule                                                                                        | Enforceable in SQL? | Constraint type         | SQL expression or note                                                                                                                                                                                             |
|---|---------------------------------------------------------------------------------------------|---------------------|-------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1 | Every proxy record must have a type from the aproved list.                                  | Yes                 | NOT NULL + CHECK (enum) | `type TEXT NOT NULL CHECK (type IN ('faunal_list','enamel_isotopes','paleosol_isootpes'))`                                                                                                                         |
| 2 | A proxy's unit of analysis is determined by its type and is never entered by hand.          | Yes                 | Generated column        | `unit_of_analysis TEXT GENERATED ALWAYS AS (CASE type WHEN 'faunal_list' THEN 'assemblage_level' WHEN 'enamel_isotopes' THEN 'specimen_level' WHEN 'paleosol_isotopes' THEN 'sediment_level' END) STORED NOT NULL` |
| 3 | Every hominin occurrence and every proxy record must name a locality and a publciation      | Yes                 | NOT NULL + FK           | `locality_id INTEGER NOT NULL REFERENCES localities (locality_id) and publication_id INTEGER NOT NULL REFERENCES publications (publication_id)` in both tables                                                     |
| 4 | A locality or publication cannot be deleted while occurrences or proxy records depend on it | Yes                 | FK (ON DELETE)          | `ON DELETE RESTRICT` on all four foreign keys (requires `PRAGMA foreign_keys = ON;`)                                                                                                                               |
| 5 | The same proxy type cannot be recorded twice for the same locality and publication          | Yes                 | UNIQUE (composite)      | `UNIQUE (locality_id, type, publication_id)`                                                                                                                                                                       |
| 6 | A DOI can belong to only one publication                                                    | Yes                 | UNIQUE                  | `doi TEXT UNIQUE` (publications with no DOI are allowed, because NULLs do not conflict)                                                                                                                            |
| 7 | A cited publication must actually report that occurrence or proxy at that locality          | No                  | Manual verification     | The database can confirm a publication exists, but only a person reading the paper can confirm it supports the record                                                                                              |
| 8 | Citations must be formatted in an APA style                                                 | No                  | Data-entry convention   | `citation` is free text, and SQL cannot validate citation formatting convention                                                                                                                                    |

### Cross-field Constraints
#1
`--the publication year must appear in the citation`

`CHECK (year IS NULL OR instr(citation, CAST(year AS TEXT)) > 0)`

#2
`--a proxy's unit of analysis must match its type`

`CHECK (
    (type = 'faunal_list'       AND unit_of_analysis = 'assemblage_level') OR
    (type = 'enamel_isotopes'   AND unit_of_analysis = 'specimen_level')   OR
    (type = 'paleosol_isotopes' AND unit_of_analysis = 'sediment_level')
)`

