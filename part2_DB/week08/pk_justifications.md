# *Paranthropus* and *Homo* Paleoecology Database - Primary Key Justifications Document
**Author:** Claire Brandes /
**Date:** October 13, 2026

### Table: localities 

**Key field:** `locality_id` 

**Key type:** Surrogate  (INTEGER, auto-increment)

**Justification:**
I used a surrogate key, `locality_id`, which is an auto-incrementing integer. The natural identifier for a locality is the combination of site, formation, and member, and that combination is unique because a stratigraphic member belongs to one formation at one site. I don’t use it as the key because it has three parts, and each part could be renamed or redefined in later stratigraphic work. If a member is renamed, I’d change that one row in localities, and every hominin occurrence and proxy record linked by `locality_id` would follow automatically. I’d enforce the combination with a UNIQUE (site, formation, member) constraint, so the same locality can’t be entered twice.

---
### Table: hominin_occurrences

**Key field:** `occurrence_id` 

**Key type:** Surrogate  (INTEGER, auto-increment)

**Justification:**
I used a surrogate key, `occurrence_id`, because a hominin occurrence doesn’t have a natural identifier in my design. Several specimens of the same species at the same locality (site, formation, and member) in the same publication would count as only *one* occurrence, so catalog numbers can't be used here as a natural key. The one natural value that could change is `scientific_name`, which can change with taxonomic revision. Because it’s an ordinary attribute and not part of any key, I’d correct it with an update to the affected rows, and the links to localities and publications would stay intact.

---
### Table: proxies
**Key field:** `proxy_id` 

**Key type:** Surrogate  (INTEGER, auto-increment)

**Justification:**
I used a surrogate key, `proxy_id`. The natural identifier is the composite (`locality_id`, `type`, `publication_id`), which is unique because I define a row as one proxy type, at one locality, reported in one publication, which is the level of detail an inventory needs. However, a three-part key would be awkward to reference and every part of it could be corrected later. If a record’s locality or publication is corrected, I’d update that one foreign key column, and `proxy_id` would stay the same. `type` is limited to a fixed list of values, so adding a new proxy type means changing the list in the table definition, and `unit_of_analysis` follows from it automatically.

---
### Table: publications
**Key field:** `publication_id` 

**Key type:** Surrogate  (INTEGER, auto-increment)

**Justification:**
I used a surrogate key, `publication_id`, even though doi looks like a natural key. A DOI is globally recognized and citable, but it isn’t required (many older papers don't have one), so it can’t be a primary key, because primary keys can’t be `NULL`. Instead, doi is a `UNIQUE` column, which prevents the same paper from being entered twice when a DOI exists. If a DOI is added or corrected later, I’d update that one column, and nothing else in the database would be affected, because the other tables reference `publication_id`.