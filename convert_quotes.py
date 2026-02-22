import csv, json

authors = {}
categories = {}
quotes = []

def get_index(map_obj, value):
    if value not in map_obj:
        map_obj[value] = len(map_obj)
    return map_obj[value]

with open("assets/quotes.csv", encoding="utf-8") as f:
    reader = csv.DictReader(f)
    for row in reader:
        a = get_index(authors, row["author"])
        cats = [get_index(categories, c.strip()) for c in row["category"].split(",")]
        quotes.append([a, row["quote"], cats])

data = {
    "authors": list(authors.keys()),
    "categories": list(categories.keys()),
    "quotes": quotes
}

with open("assets/quotes.json", "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False)