"""load_php.py -- load the paleoecological proxy inventory TSV into PostgreSQL.

Usage:
    psql -d <your_database> -f schema.sql        # drop and recreate the tables
    python load_php.py [path/to/file.tsv]  # default: proxy_inventory_sample.tsv

Each row of the TSV is one record, and its record_type column says which table
the record belongs to:

    record_type          what it adds
    -------------------  ------------------------------------------------------
    hominin_occurrence   a row in hominin_occurrences (uses scientific_name)
    proxy                a row in proxies (uses type)

Every row also carries its locality (country, site, formation, member, and the
optional oldest_age_ma / youngest_age_ma) and its publication (citation, and the
optional year / doi). Parents are resolved first (localities, publications), then
the child row is inserted with the parent IDs.

Each row is its own transaction. If a row fails (for example, a constraint is
violated), that row is rolled back and reported, and the loader continues.
"""
import csv
import sys
from decimal import Decimal, InvalidOperation

import psycopg2
import psycopg2.extras

from config import DSN          # config.py is listed in .gitignore and never committed

TSV_FILE = "proxy_inventory_sample.tsv"

COUNT_QUERIES = {      # fixed queries for the summary: no SQL is built from text
    "localities":          "SELECT COUNT(*) AS n FROM localities",
    "publications":        "SELECT COUNT(*) AS n FROM publications",
    "hominin_occurrences": "SELECT COUNT(*) AS n FROM hominin_occurrences",
    "proxies":             "SELECT COUNT(*) AS n FROM proxies",
}

COLUMNS = [
    "record_type", "country", "site", "formation", "member",
    "oldest_age_ma", "youngest_age_ma",
    "citation", "year", "doi",
    "scientific_name", "type",
]


def clean(value):
    """Strip whitespace. An empty TSV cell becomes None, which inserts as SQL NULL."""
    if value is None:
        return None
    value = value.strip()
    return value or None


def to_decimal(value):
    """Convert text to Decimal (exact, unlike float). Raises ValueError on text that is not a number."""
    value = clean(value)
    if value is None:
        return None
    try:
        return Decimal(value)
    except InvalidOperation:
        raise ValueError(f"not a number: {value!r}")


def to_int(value):
    value = clean(value)
    return int(value) if value is not None else None


def get_locality_id(cur, cache, row):
    """Return the locality_id for this row, inserting the locality if it is new."""
    site = clean(row["site"])
    formation = clean(row["formation"])
    member = clean(row["member"])
    key = (site, formation, member)

    if key not in cache:
        cur.execute(
            """SELECT locality_id FROM localities
                WHERE site = %s AND formation = %s AND member = %s""",
            key,
        )
        found = cur.fetchone()
        if found is None:
            cur.execute(
                """INSERT INTO localities
                       (country, site, formation, member, oldest_age_ma, youngest_age_ma)
                   VALUES (%s, %s, %s, %s, %s, %s)
                   RETURNING locality_id""",
                (clean(row["country"]), site, formation, member,
                 to_decimal(row["oldest_age_ma"]), to_decimal(row["youngest_age_ma"])),
            )
            found = cur.fetchone()
        cache[key] = found["locality_id"]
    return cache[key]


def get_publication_id(cur, cache, row):
    """Return the publication_id for this row, inserting the publication if it is new."""
    citation = clean(row["citation"])
    doi = clean(row["doi"])
    key = doi or citation          # a DOI identifies a publication; otherwise use the citation text

    if key not in cache:
        if doi:
            cur.execute("SELECT publication_id FROM publications WHERE doi = %s", (doi,))
        else:
            cur.execute("SELECT publication_id FROM publications WHERE citation = %s", (citation,))
        found = cur.fetchone()
        if found is None:
            cur.execute(
                """INSERT INTO publications (citation, year, doi)
                   VALUES (%s, %s, %s)
                   RETURNING publication_id""",
                (citation, to_int(row["year"]), doi),
            )
            found = cur.fetchone()
        cache[key] = found["publication_id"]
    return cache[key]


def load(path):
    conn = psycopg2.connect(DSN, cursor_factory=psycopg2.extras.RealDictCursor)
    cur = conn.cursor()

    locality_cache = {}      # (site, formation, member) -> locality_id
    publication_cache = {}   # doi (or citation if no doi) -> publication_id
    loaded = skipped = errors = 0

    with open(path, newline="", encoding="utf-8") as fh:
        reader = csv.DictReader(fh, delimiter="\t")
        missing = [c for c in COLUMNS if c not in (reader.fieldnames or [])]
        if missing:
            sys.exit(f"{path} is missing column(s): {', '.join(missing)}")

        for line_number, row in enumerate(reader, start=2):    # line 1 is the header
            try:
                record_type = clean(row["record_type"])
                if record_type not in ("hominin_occurrence", "proxy"):
                    raise ValueError(f"unknown record_type {record_type!r}")

                # Parents first: locality and publication
                locality_id = get_locality_id(cur, locality_cache, row)
                publication_id = get_publication_id(cur, publication_cache, row)

                # Then the child row
                if record_type == "hominin_occurrence":
                    cur.execute(
                        """INSERT INTO hominin_occurrences
                               (scientific_name, locality_id, publication_id)
                           VALUES (%s, %s, %s)""",
                        (clean(row["scientific_name"]), locality_id, publication_id),
                    )
                else:
                    # unit_of_analysis is generated from type, so it is not inserted
                    cur.execute(
                        """INSERT INTO proxies (type, locality_id, publication_id)
                           VALUES (%s, %s, %s)
                           ON CONFLICT (locality_id, type, publication_id) DO NOTHING""",
                        (clean(row["type"]), locality_id, publication_id),
                    )
                    if cur.rowcount == 0:      # this proxy was already loaded
                        skipped += 1
                        conn.commit()
                        continue

                conn.commit()
                loaded += 1

            except Exception as e:
                conn.rollback()
                # The rollback may have undone a new locality or publication that is
                # still in a cache, so empty the caches. They refill from the database.
                locality_cache.clear()
                publication_cache.clear()
                errors += 1
                message = str(e).strip().splitlines()[0]
                print(f"Line {line_number}: {message}", file=sys.stderr)
                continue

    for table, query in COUNT_QUERIES.items():
        cur.execute(query)
        print(f"{table}: {cur.fetchone()['n']} rows")
    print(f"{loaded} records loaded, {skipped} duplicates skipped, {errors} rows failed")

    cur.close()
    conn.close()
    print("Done.")


if __name__ == "__main__":
    load(sys.argv[1] if len(sys.argv) > 1 else TSV_FILE)