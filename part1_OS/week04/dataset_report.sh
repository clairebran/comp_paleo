#!/usr/bin/env bash
# dataset_report.sh
# Generate a summary report of all TSV files in a directory.
# Usage: ./dataset_report.sh <directory>
#
# Author:
# Date:

# ── Argument handling ────────────────────────────────────────────────────────

if [ $# -ne 1 ]; then
    echo "Usage: $0 <directory>"
    exit 1
fi

DIRPATH="$1"

if [ ! -d "$DIRPATH" ]; then
    echo "Error: not a directory: $DIRPATH"
    exit 1
fi

# ── Initialise counters and log file ─────────────────────────────────────────

SMALL_LOG="small_files.log"
> "$SMALL_LOG"   # clear/create the log file

FILES_PROCESSED=0
TOTAL_ROWS=0
SMALL_COUNT=0
OVERALL_RESULT="PASS"

echo "Dataset Report"
echo "Directory: $DIRPATH"
echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================================"
echo ""

# ── Main loop: process each TSV file ─────────────────────────────────────────

for FILEPATH in "$DIRPATH"/*.tsv; do

    # Guard against the case where the glob matches nothing
    [ -e "$FILEPATH" ] || continue

    FILENAME=$(basename "$FILEPATH")
    FILES_PROCESSED=$((FILES_PROCESSED + 1))

    ROWS=$(tail -n +2 "$FILEPATH" | wc -l | tr -d ' ')
    COLS=$(head -1 "$FILEPATH" | tr '\t' '\n' | wc -l | tr -d ' ')
    FIRST3=$(head -1 "$FILEPATH" | tr '\t' '\n' | head -3 | paste -sd '|' - | sed 's/|/ | /g')

    TOTAL_ROWS=$((TOTAL_ROWS + ROWS))

    # Validation: every row (including header) must have COLS fields
    BAD_ROWS=$(awk -F'\t' -v cols="$COLS" 'NF != cols' "$FILEPATH" | wc -l | tr -d ' ')

    if [ "$BAD_ROWS" -eq 0 ]; then
        VALIDATION="PASS"
    else
        VALIDATION="FAIL"
        OVERALL_RESULT="FAIL"
    fi

    echo "File: $FILENAME"
    echo "  Rows:    $ROWS"
    echo "  Columns: $COLS"
    echo "  Fields:  $FIRST3"
    echo "  Validation: $VALIDATION"
    echo ""

    # Log small files
    if [ "$ROWS" -lt 100 ]; then
        echo "$FILENAME: $ROWS rows" >> "$SMALL_LOG"
        SMALL_COUNT=$((SMALL_COUNT + 1))
    fi

done

# ── Summary ───────────────────────────────────────────────────────────────────

echo "============================================================"
echo "Summary"
echo "  Files processed: $FILES_PROCESSED"
echo "  Total rows:      $TOTAL_ROWS"
echo "  Small files:     $SMALL_COUNT"
echo "  Overall result:  $OVERALL_RESULT"

if [ "$OVERALL_RESULT" = "PASS" ]; then
    exit 0
else
    exit 1
fi

