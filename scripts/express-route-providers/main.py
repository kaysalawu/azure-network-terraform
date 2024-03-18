import json

# Load data from a JSON file
with open('providers.json', 'r') as file:
    data = json.load(file)

# Initialize a dictionary to store peering locations and associated names
location_dict = {}

# Loop through each item in the data
for item in data:
    for location in item["peeringLocations"]:
        # If the location is not already in the dictionary, add it with an empty list
        if location not in location_dict:
            location_dict[location] = []
        # Append the provider's name to the list of names associated with the location
        location_dict[location].append(item["name"])

# Open a file to write the output
with open('providers-by-location.tsv', 'w') as f:
    # Write the header
    f.write("PeeringLocation\tProvider\n")
    # Loop through the dictionary and write each location and its associated names
    for location, names in location_dict.items():
        f.write(f"{location}\t{' | '.join(names)}\n")
