-- Clean and standardize NYC Open Restaurant Applications data
-- One row per restaurant application
WITH source AS (
    SELECT * FROM {{ source('raw', 'source_nyc_open_restaurant_apps') }}
),
 
cleaned AS (
    SELECT
        -- Identifiers
        CAST(objectid AS STRING) AS application_id,
        CAST(globalid AS STRING) AS global_id,
 
        -- Date/Time
        CAST(time_of_submission AS TIMESTAMP) AS time_of_submission,
 
        -- Restaurant details
        CAST(restaurant_name AS STRING) AS restaurant_name,
        CAST(legal_business_name AS STRING) AS legal_business_name,
        CAST(doing_business_as_dba AS STRING) AS doing_business_as_dba,
        CAST(food_service_establishment AS STRING) AS food_service_establishment,
 
        -- Seating interest and approval
        CAST(seating_interest_sidewalk AS STRING) AS seating_interest_sidewalk,
        CAST(approved_for_sidewalk_seating AS STRING) AS approved_for_sidewalk_seating,
        CAST(approved_for_roadway_seating AS STRING) AS approved_for_roadway_seating,
 
        -- Location - address fields
        CAST(business_address AS STRING) AS business_address,
        CAST(building_number AS STRING) AS building_number,
        CAST(street AS STRING) AS street,
 
        -- Location - borough standardized
        CASE
            WHEN UPPER(TRIM(borough)) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
            WHEN UPPER(TRIM(borough)) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
            WHEN UPPER(TRIM(borough)) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
            WHEN UPPER(TRIM(borough)) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
            WHEN UPPER(TRIM(borough)) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
            ELSE 'UNKNOWN or CITYWIDE'
        END AS borough,
 
        -- Location - zip code cleaned
        CASE
            WHEN UPPER(TRIM(CAST(zip AS STRING))) IN ('N/A', 'NA', '') THEN NULL
            WHEN LENGTH(CAST(zip AS STRING)) = 5 THEN CAST(zip AS STRING)
            WHEN LENGTH(CAST(zip AS STRING)) = 9 THEN CAST(zip AS STRING)
            WHEN LENGTH(CAST(zip AS STRING)) = 10
                AND REGEXP_CONTAINS(CAST(zip AS STRING), r'^\d{5}-\d{4}')
                THEN CAST(zip AS STRING)
            ELSE NULL
        END AS zip_code,
 
        -- Location - coordinates
        CAST(latitude AS DECIMAL) AS latitude,
        CAST(longitude AS DECIMAL) AS longitude,
 
        -- Location - geographic identifiers
        CAST(community_board AS STRING) AS community_board,
        CAST(council_district AS STRING) AS council_district,
        CAST(census_tract AS STRING) AS census_tract,
        CAST(bin AS STRING) AS bin,
        CAST(bbl AS STRING) AS bbl,
        CAST(nta AS STRING) AS nta,
 
        -- Sidewalk dimensions
        CAST(sidewalk_dimensions_length AS FLOAT64) AS sidewalk_length_ft,
        CAST(sidewalk_dimensions_width AS FLOAT64) AS sidewalk_width_ft,
        CAST(sidewalk_dimensions_area AS FLOAT64) AS sidewalk_area_sqft,
 
        -- Roadway dimensions
        CAST(roadway_dimensions_length AS FLOAT64) AS roadway_length_ft,
        CAST(roadway_dimensions_width AS FLOAT64) AS roadway_width_ft,
        CAST(roadway_dimensions_area AS FLOAT64) AS roadway_area_sqft,
 
        -- Alcohol and licensing
        CAST(qualify_alcohol AS STRING) AS qualify_alcohol,
        CAST(sla_serial_number AS STRING) AS sla_serial_number,
        CAST(sla_license_type AS STRING) AS sla_license_type,
 
        -- Landmark and compliance
        CAST(landmark_district_or_building AS STRING) AS is_landmark_location,
        CAST(landmarkdistrict_terms AS STRING) AS landmark_terms_accepted,
        CAST(healthcompliance_terms AS STRING) AS health_compliance_terms_accepted,
 
        -- Metadata
        CURRENT_TIMESTAMP() AS _stg_loaded_at
 
    FROM source
 
    -- Filters
    WHERE objectid IS NOT NULL
        AND time_of_submission IS NOT NULL
 
    -- Deduplicate on objectid, keep most recent submission
    QUALIFY ROW_NUMBER() OVER (PARTITION BY objectid ORDER BY time_of_submission DESC) = 1
)
 
SELECT * FROM cleaned