#!/usr/bin/env python3
"""
fix_newlines.py
Reads a CSV file, removes embedded newlines from all fields,
and writes the result as a tab-separated (TSV) file.

Usage: python3 fix_newlines.py input.csv output.tsv
"""

import csv
# Imports the csv module that is used to read and write CSV and TSV data.

import sys
# Imports the sys module, which allows the script to access code from the command-line and standard error outputs.

def fix_newlines(input_path, output_path):
# Creates a function called fix_newlines and that uses the arguments input_path and output_path (input and output file paths, respectively). 

    rows_fixed = 0
     # Creates a variable that will count the number of rows that have new line characters embedded in them. 

    with open(input_path, newline='', encoding='utf-8') as infile, \
         open(output_path, 'w', newline='', encoding='utf-8') as outfile:
	  # At the same time, opens the input file to be read and opens the output file to write to. 

        reader = csv.reader(infile)
	 # Creates a CSV file reader to read from the input file. 	

        writer = csv.writer(outfile, delimiter='\t')
	 # Creates a CSV file writer that will write the newly cleaned rows to the output file. It will use tab-seperated values in doing so. 

        for i, row in enumerate(reader):
	 # Loops through each row in the input file.

            cleaned = []
	    # An empty list that will store the clean rows. 

            row_had_newline = False
	    # Records whether or not each row contained an embedded new line character. 

            for field in row:
	    # Loops through each field in the current row.

                if '\n' in field or '\r' in field:
		 # Checks if the current field contains a new line character (\n) or a carriage return character (\r). If it does it will trigger the next two lines of code. 

                    cleaned.append(field.replace('\n', ' ').replace('\r', '').strip())
		    # Removes new line characters and replaces them with spaces, removes carriage return characters and replaces them with nothing (essentially removing them), removes excess spaces around the text, and finally adds the newly cleaned field to the cleaned list. 

                    row_had_newline = True
		    # Records that the row did in fact contain a new line character. 

                else:
                    cleaned.append(field)
		    # Adds the field to the cleaned list. This triggers only if a new line character or carriage return character is not detected in any fields. 

            if row_had_newline:
	    # Checks if the current row contains a new line character. If it does, the next three lines of code will trigger. 

                rows_fixed += 1
		# Adds one to the counter established at the beginning of the script to track the number of rows that had new line characters embedded in them. 

                print(f"  Row {i}: embedded newline removed", file=sys.stderr)
		# Prints a message to standard error indicating the number of the row that was fixed. 

            writer.writerow(cleaned)
	    # Writes the newly cleaned row to the output TSV file. 

    print(f"Done. {rows_fixed} row(s) fixed.")
    # Prints the number of rows that were fixed (i.e. the number of rows that contained new line characters according to the counter. 

    print(f"Output written to: {output_path}")
    # Prints the file path to the newly created output TSV file. 

if __name__ == '__main__':
# Checks if the script is being run directly (as opposed to being run via an imported module. If that condition is true, then it will trigger the next line of code. 

    if len(sys.argv) != 3:
    # Checks if two arguments were provided after the function fix_newlines.py. If that condition is not true, it will trigger the next two lines of code. 

        print("Usage: python3 fix_newlines.py input.csv output.tsv")
	# Prints a line indicating the correct usage of the fix_newlines.py function. 

        sys.exit(1)
	# Stops the script and prints the exit code 1, indicating a general error. 

    fix_newlines(sys.argv[1], sys.argv[2])
    # If two arguments were correctly provided to the function, this will call the function using the arguments and run it. 