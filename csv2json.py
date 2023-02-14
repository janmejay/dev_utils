import csv
import json


if __name__ == "__main__":
    with open('/tmp/foo.csv', newline='') as csvfile:
        rdr = csv.reader(csvfile, delimiter=',', quotechar='"')
        for row in rdr:
            j = json.dumps(row)
            print(j)
