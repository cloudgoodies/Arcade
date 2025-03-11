# Query the top 10 most popular names from the public dataset
bq query --nouse_legacy_sql \
"
SELECT name, gender, SUM(number) AS total
FROM \`bigquery-public-data.usa_names.usa_1910_2013\`
GROUP BY name, gender
ORDER BY total DESC
LIMIT 10
"

# Create the dataset only if it doesn’t already exist
bq --quiet mk --dataset IF NOT EXISTS babynames

# Create the table with the specified schema
bq mk --table --schema "name:STRING,count:INTEGER,gender:STRING" babynames.names_2014

# Query the top 5 most popular male names from the names_2014 table
bq query --nouse_legacy_sql \
"
SELECT name, count
FROM \`babynames.names_2014\`
WHERE gender = 'M'
ORDER BY count DESC
LIMIT 5
"
