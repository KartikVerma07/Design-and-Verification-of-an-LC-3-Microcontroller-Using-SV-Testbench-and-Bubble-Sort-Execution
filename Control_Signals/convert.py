import csv

# Input and output file names
input_file = 'ControlStore.csv'
output_file = 'output.txt'

# Open the input CSV file
with open(input_file, 'r') as csv_file:
    csv_reader = csv.reader(csv_file)

    # Skip the first row (header)
    next(csv_reader)

    # Process the remaining rows
    processed_lines = []
    for row in csv_reader:
        # Skip the first column and process the rest
        processed_row = []
        for cell in row[1:]:
            if cell == '1':
                processed_row.append('1')
            elif cell == '0':
                processed_row.append('0')
            elif cell.lower() == 'x':  # Case insensitive check for 'x'
                processed_row.append('0')
            else:  # Handle empty cells
                processed_row.append('0')
        
        # Join the row into a single binary string and store it
        processed_lines.append(''.join(processed_row))

# Write the processed data to the output text file
with open(output_file, 'w') as txt_file:
    for line in processed_lines:
        txt_file.write(line + '\n')
