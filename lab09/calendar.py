calendar = []

# Months with 31 days
months_31 = [1, 3, 5, 7, 8, 10, 12]
for month in months_31:
    days_in_month = list(range(1, 32))
    calendar.append((month, days_in_month))

# February with 28 days (non-leap year)
february_non_leap = (2, list(range(1, 29)))
calendar.append(february_non_leap)

# Months with 30 days
months_30 = [4, 6, 9, 11]
for month in months_30:
    days_in_month = list(range(1, 31))
    calendar.append((month, days_in_month))

# February with 28 days (leap year excluded)
february_leap_excluded = (2, list(range(1, 29)))
calendar.append(february_leap_excluded)

# Displaying the calendar
for month, days in calendar:
    print(f"Month_{month}{days}")
