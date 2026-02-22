import gzip
import shutil

with open("assets/quotes.json", "rb") as f_in:
    with gzip.open("assets/quotes.gz", "wb", compresslevel=9) as f_out:
        shutil.copyfileobj(f_in, f_out)