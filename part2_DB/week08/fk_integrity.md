# *Paranthropus* and *Homo* Paleoecology Database - Foreign Key Integrity Document
**Author:** Claire Brandes /
**Date:** October 13, 2026

### Relationship Inventory

| FK Field       | In table            | References                  | Cardinality | ON DELETE | ON UPDATE |
|----------------|---------------------|-----------------------------|-------------|-----------|-----------|
| locality_id    | hominin_occurrences | localities.locality_id      | ∞:1         | RESTRICT  | CASCADE   |
| publication_id | hominin_occurrences | publications.publication_id | ∞:1         | RESTRICT  | CASCADE   |
| locality_id    | proxies             | localities.locality_id      | ∞:1         | RESTRICT  | CASCADE   |
| publication_id | proxies             | publications.publication_id | ∞:1         | RESTRICT  | CASCADE   |

*My design has no linking table, because there are no many-to-many relationships that need resolving. Hominin occurrences and proxies connect only through their shared `locality_id`.*


### Justifications

`hominin_occurrences.locality_id` → `localities`: **RESTRICT**. A locality is a prerequisite for every occurrence recorded there, since it’s the only thing connecting the occurrence to proxy data. Deleting a locality that still has occurrences should be blocked. `SET NULL` isn’t an option, because the column is `NOT NULL`, and `CASCADE` would quietly delete hominin records along with the locality.

`hominin_occurrences.publication_id` → `publications`: **RESTRICT**. Every occurrence has to be traceable to the paper that reports it, so a publication can’t be deleted while occurrences still cite it. Cascading would delete valid occurrence records just because their source was removed from the publications table. If a citation was entered wrongly, the right fix is to repoint the records to the correct publication and then delete the wrong one.

`proxies.locality_id` → `localities`: **RESTRICT**. A proxy record means nothing without the locality it came from, so the locality can’t be deleted while proxy records point to it. As above, `SET NULL` would break the `NOT NULL` requirement, and `CASCADE` would remove key proxy inventory records.

`proxies.publication_id` → `publications`: **RESTRICT**. Proxy records exist to point readers to a publication, so a publication with proxy records attached can’t be deleted. 

### Recursive Relationships 
None of my tables have a self-referential relationship. 

