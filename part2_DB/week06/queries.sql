-- queries.sql
-- OTB Fossil Database Queries
-- Week 6 Assignment 

-- Query 1 --
-- Question: How many fossil specimens are in the database?
-- Paleoanthropological Significance: Shows how large our sample is. 
SELECT COUNT(*) AS total_specimens FROM fossils;

-- Query 2 --
-- Question: Which specimens were discovered by Kamoya Kimeu?
-- Paleoanthropological Significance: Tells us how many specimens one given researcher (Kamoya Kim) contributed to our knowledge of the hominins.
SELECT catalog_number, preparations, year FROM fossils WHERE discovered_by ILIKE '%Kimeu%' ORDER BY year ASC;

-- Query 3 --
-- Question: How many specimens come from each formation?
-- Paleoanthropological Significance: Tells us which are the most hominin-rich formations. Can be used to tell us about their ecology through time.
SELECT COALESCE(l.formation, 'Unknown') AS formation,
       COUNT(*) AS n_specimens
FROM fossils f
LEFT JOIN localities l ON l.locality_id = f.locality_id
GROUP BY COALESCE(l.formation, 'Unknown')
ORDER BY n_specimens DESC;

-- Query 4 --
-- Question: Which specimens are older than 3 million years?
-- Paleoanthropological Significance: Shows us some of the earliest hominin representatives in existance (Au. anamensis or older taxa). 
SELECT f.catalog_number,
       t.scientific_name,
       f.earliest_chronometric_age,
       l.formation
FROM fossils f
JOIN taxa t       ON t.taxon_id = f.taxon_id
JOIN localities l ON l.locality_id = f.locality_id
WHERE f.earliest_chronometric_age > 3.0
ORDER BY f.earliest_chronometric_age DESC;

-- Query 5 --
-- Question: Which taxon has the most specimens, and what anatomical elements are most commonly preserved for that taxon?
-- Paleoanthropological Significance: Shows us what the most abundant species in this region might have been (ignoring any bias in the fossil record), and shows us what is most likely to be preserved from that species. This affects the sample size for some of our queries. 
SELECT t.scientific_name,
       COUNT(*) AS n_specimens
FROM fossils f
JOIN taxa t ON t.taxon_id = f.taxon_id
GROUP BY t.scientific_name
ORDER BY n_specimens DESC
LIMIT 1;

SELECT COALESCE(f.preparations, '(none recorded)') AS preparations,
       COUNT(*) AS n_specimens
FROM fossils f
JOIN taxa t ON t.taxon_id = f.taxon_id
WHERE t.scientific_name = (
    SELECT t2.scientific_name
    FROM fossils f2
    JOIN taxa t2 ON t2.taxon_id = f2.taxon_id
    GROUP BY t2.scientific_name
    ORDER BY COUNT(*) DESC
    LIMIT 1
)
GROUP BY COALESCE(f.preparations, '(none recorded)')
ORDER BY n_specimens DESC;

