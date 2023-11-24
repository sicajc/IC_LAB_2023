import random
from datetime import datetime, timedelta

def generate_date_lookup_table(start_date, end_date):
    date_lookup = {}

    current_date = start_date
    while current_date <= end_date:
        month = current_date.month
        day = current_date.strftime("%d")

        if month not in date_lookup:
            date_lookup[month] = []

        date_lookup[month].append(day)
        current_date += timedelta(days=1)

    return date_lookup

def random_date_from_lookup(lookup_table):
    random_month = random.choice(list(lookup_table.keys()))
    random_day = random.choice(lookup_table[random_month])
    return f"{random_month:02d} {random_day}"

# Define your desired date range
start_date = datetime(2000, 1, 1)
end_date = datetime(2023, 12, 31)

# Generate the lookup table
date_lookup_table = generate_date_lookup_table(start_date, end_date)

# Randomly pick a date and month from the lookup table
random_date = random_date_from_lookup(date_lookup_table)

# Print the randomly picked date
print("Randomly Picked Date:", random_date)
