import requests
import argparse
import json
import csv

# Fetch data from the Megaport API
response = requests.get("https://api.megaport.com/v2/locations")
data = response.json()

# Extract unique statuses and markets
statuses = set(location['status'] for location in data['data'])
markets = set(location['market'] for location in data['data'])

# Set up argument parser
parser = argparse.ArgumentParser(description='Fetch and filter Megaport locations based on various criteria.')
parser.add_argument('--mcr', action='store_true', help='Filter locations where MCR is available.')
parser.add_argument('-m', '--market', type=str, help='Filter locations by market code. Markets: ' + ', '.join(markets))
parser.add_argument('-s', '--status', type=str, choices=statuses, help='Filter locations by their status.')
parser.add_argument('-o', '--output', type=str, choices=['json', 'csv'], help='Output format: json or csv.')

args = parser.parse_args()

# Filter and sort data by criteria
filtered_data = data['data']
if args.mcr:
    filtered_data = [loc for loc in filtered_data if 'mcr' in loc['products'] and loc['products']['mcr']]
if args.market:
    filtered_data = [loc for loc in filtered_data if loc['market'] == args.market]
if args.status:
    filtered_data = [loc for loc in filtered_data if loc['status'] == args.status]
sorted_data = sorted(filtered_data, key=lambda x: x['country'])

# Construct a unique filename based on selected options
filename_parts = ['megaport_locations']
if args.mcr:
    filename_parts.append('mcr')
if args.market:
    filename_parts.append(args.market)
if args.status:
    filename_parts.append(args.status)
filename = '_'.join(filename_parts)

# Output data based on the format specified
if args.output == 'json':
    with open(f'{filename}.json', 'w') as json_file:
        json.dump(sorted_data, json_file, indent=4)
elif args.output == 'csv':
    with open(f'{filename}.csv', 'w', newline='') as csv_file:
        fieldnames = ['ID', 'Market', 'Country', 'Metro', 'MCR', 'Name', 'Status']
        writer = csv.DictWriter(csv_file, fieldnames=fieldnames)
        writer.writeheader()
        for location in sorted_data:
            mcr_available = '1' if location['products'].get('mcr', False) else ''
            writer.writerow({
                'ID': location['id'],
                'Market': location['market'],
                'Country': location['country'],
                'Metro': location['metro'],
                'MCR': mcr_available,
                'Name': location['name'],
                'Status': location['status']
            })
else:
    # Print the data in table format on the terminal
    print("{:<5} {:<10} {:<15} {:<15} {:<5} {:<40} {:<15}".format('ID', 'Market', 'Country', 'Metro', 'MCR', 'Name', 'Status'))
    for location in sorted_data:
        mcr_available = '1' if location['products'].get('mcr', False) else ''
        print("{:<5} {:<10} {:<15} {:<15} {:<5} {:<40} {:<15}".format(location['id'], location['market'], location['country'], location['metro'], mcr_available, location['name'], location['status']))
