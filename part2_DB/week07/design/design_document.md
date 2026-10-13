# Homo/Paranthropus Paleoecology Database - Preliminary Design Document
**Author:** Claire Brandes
**Date:** October 12, 2026
**Domain:** Paleoanthropology and paleoecology
**Research context:** The research goal of this project is to elucidate the paleoecological data evailable for Paranthropus and Homo paleoanthropological sites. 

## Mission Statement
To organize and describe paleoecological data (e.g., fauna, isotopes, phytoliths, pollen, etc.) available for  _Paranthropus_ and early _Homo_ (_Homo habilis_) paleoanthropological sites. 

## Objectives 
1. Find which hominin species (_Paranthropus_ or _Homo_) are present at a given locality.
```bash
SELECT DISTINCT scientific_name
FROM hominin_occurences
WHERE locality_id = ?;
```

2. Find which types of paleoecological proxies exist for each site. 
```bash
SELECT DISTINCT l.site, p.type
FROM proxies p
JOIN localities l ON l.locality_id = p.locality_id
ORDER BY l.site, p.type;
```

3. Identify the specific member proxy data pertains to. 
```bash 
SELECT p.proxy_id, p.type, l.site, l.formation, l.member
FROM proxies p
JOIN localities l ON l.locality_id = p.locality_id
WHERE p.proxy_id = ?;
```

4. Link paleoecological data to its primary publication. 
```bash
SELECT pub.citation, pub.year, pub.doi
FROM proxies p
JOIN publications pub ON pub.publication_id = p.publication_id
WHERE p.proxy_id = ?;
```

5. Identify which sites a given type of proxy data is available for. 
```bash
SELECT DISTINCT l.site
FROM proxies p
JOIN localities l ON l.locality_id = p.locality_id
WHERE p.type = ?
ORDER BY l.site;
```

## Entity Identification
| Entity | Justification | Example attributes |
|---|---|---|
| `localities` | Each locality represents a distinct location with its own list of geographic attributes and may be used to track multiple hominin occurences at the same place. | site, member, formation |
| `hominin_occurences` | Each hominin occurrence tracks a distinct species present in the same member (if there are multiple specimens present in the same member). It can then be used to identify where an occurrence of a species can be linked to a distinct member and thus paleoecological information. | genus, scientific_name |
| `publications` | Publications have unique data associated with them and can be associated with both hominin occurrence data and paleoecological data. | citation, year, doi |
| `proxies` | Proxies are a distinct entity with unique attribute data that can then be linked to both hominin occurrences and localities. | type, unit_of_analysis |

## Field Specifications
### Table: localities
| Field Name | Data Type | Required | Default | Notes |
|---|---|---|---|---|
| locality_id | Integer | Yes (PK) | | Surrogate key; auto-increment |
| country | Text | No | | Controlled vocabulary |
| site | Text | No | | Controlled vocabulary |
| formation | Text | No | | Controlled vocabulary |
| member | Text | No | | Controlled vocabulary |

### Table: hominin_occurrences
| Field Name | Data Type | Required | Default | Notes |
|---|---|---|---|---|
| occurrence_id | Integer | Yes (PK) | | Surrogate key; auto-increment |
| genus | Text | No | | Controlled vocabulary |
| scientific_name | Text | No | | Controlled vocabulary |
| locality_id | Integer | Yes (FK) | | Foreign key |
| publication_id | Integer | Yes (FK) | | Foreign key |

### Table: proxies
| Field Name | Data Type | Required | Default | Notes |
|---|---|---|---|---|
| proxy_id | Integer | Yes (PK) | | Surrogate key; auto-increment |
| type | Text | No | | Controlled vocabulary |
| unit_of_analysis | Text | No | | Controlled vocabulary (e.g., specimen_level, assemblage_level) |
| locality_id | Integer | Yes (FK) | | Foreign key |
| publication_id | Integer | Yes (FK) | | Foreign key |

### Table: publication
| Field Name | Data Type | Required | Default | Notes |
|---|---|---|---|---|
| publication_id | Integer | Yes (PK) | | Surrogate key; auto-incrementing |
| citation | Text | Yes | | APA format |
| year | Integer | No | | Year of publication |
| doi | Text | No | | DOI, if available; unique |

# Relationships and Keys
| Relationship | Cardinality | Implementation |
|---|---|---|
| One locality → many hominin occurrences | 1:∞ | `hominin_occurrences.locality_id` → `localities.locality_id` |
| One locality → many proxy records | 1:∞ | `proxies.locality_id` → `localities.locality_id` |
| One publication → many hominin occurrences | 1:∞ | `hominin_occurrences.publication_id` → `publications.publication_id` |
| One publication → many proxy records | 1:∞ | `proxies.publication_id` → `publications.publication_id` |
| Many hominin occurrences ↔ many proxy records (indirect, via shared locality) | ∞:∞ | No junction table; no direct foreign key. Linked by joining both tables on `locality_id`. |


