/* This report is based on research on Cyclistic, a fictional bike-share company. I utilize public data 
   which has been downloaded and stored in a local file named 'cyclistic_study'. I use data collected by
   Cyclistic over a one year period, stored into 12 different spreadsheets, one for each month. Each spreadsheet 
   is named by YYYY_MM convention. */


-- Unionize all tables into one
SELECT *
INTO all_data
FROM
(
    SELECT * FROM [2021_01] 
    UNION ALL 
    SELECT * FROM [2021_02]
    UNION ALL 
    SELECT * FROM [2021_03]
    UNION ALL 
    SELECT * FROM [2021_04]
    UNION ALL 
    SELECT * FROM [2021_05]
    UNION ALL 
    SELECT * FROM [2021_06]
    UNION ALL 
    SELECT * FROM [2021_07]
    UNION ALL 
    SELECT * FROM [2021_08]
    UNION ALL 
    SELECT * FROM [2021_09]
    UNION ALL 
    SELECT * FROM [2021_10]
    UNION ALL 
    SELECT * FROM [2021_11]
    UNION ALL 
    SELECT * FROM [2021_12]
)t;

--View columns and datatypes
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.columns 
WHERE table_name = 'all_data';

-- create new column ride_length, day_of_week, and month to help with data analysis
ALTER TABLE all_data
ADD ride_length as datediff(s, started_at, ended_at),
    day_of_week as DATENAME(weekday, started_at),
    month as DATENAME(month, started_at)

--             DATA CLEANING            --

SELECT MAX(ride_length) as max, MIN(ride_length) as min
FROM all_data;
/* The longest ride length was over 3 millions seconds - a computing error or some other anomaly. I will 
remove all rows with ride length over 6 hours, and delete any rows with a value less than 1 minute. */
DELETE FROM [all_data] WHERE ride_length < 60 OR ride_length > 21600;

/* Removing all rows with NULL values in any column */
SELECT * 
INTO all_data_cleaned 
FROM
(
    SELECT *
    FROM all_data
    WHERE start_station_name NOT LIKE '%NULL%'
      AND end_station_name NOT LIKE '%NULL%'
      AND start_lat NOT LIKE '%NULL%'
      AND start_lng NOT LIKE '%NULL%'
      AND end_lat NOT LIKE '%NULL%'
      AND end_lng NOT LIKE '%NULL%'
)t;
/* Trimming station name to ensure no spaces */
UPDATE all_data_cleaned
SET start_station_name = TRIM(start_station_name),
    end_station_name = TRIM(end_station_name)


--               DATA EXPLORATION               --

-- Find ride count for each group
SELECT member_casual as [Member Type], count(ride_id) as [Ride Count]
FROM all_data_cleaned
GROUP BY member_casual

-- Find average ride length for each group 
SELECT member_casual as [Member Type], avg(cast(ride_length as bigint)) as [Ride Length]
FROM all_data_cleaned
GROUP BY member_casual


-- Difference in ride lengths between casual riders and members by day of week
SELECT DATEPART(w, started_at) as weekday_id, 
       member_casual as [Member Type],
       day_of_week, 
       avg(ride_length) as [Average Ride Length]
FROM all_data_cleaned
GROUP BY member_casual, DATEPART(w, started_at), day_of_week
ORDER BY DATEPART(w, started_at), member_casual;


-- Calculate how often people use service based on day of week
SELECT DATEPART(w, started_at) as weekday_id, 
       day_of_week, 
       member_casual as [Member Type], 
       count(ride_id) as [Number]
FROM all_data_cleaned
GROUP BY member_casual, DATEPART(w, started_at), day_of_week
ORDER BY DATEPART(w, started_at), member_casual;

-- Tracking ride count throughout the year
SELECT CAST(started_at as date) as date, member_casual, count(ride_id) as num
FROM all_data_cleaned
GROUP BY CAST(started_at as date), member_casual
ORDER BY CAST(started_at as date), member_casual


-- Giving each start station a single, unique coordinate
SELECT * INTO start_station FROM
(
    SELECT start_station_name, ROUND(AVG(start_lat), 4) as dep_lat, ROUND(AVG(end_lng), 4) as dep_lng
    FROM all_data_cleaned
    GROUP BY start_station_name
)t;

-- Do the same for end station
SELECT * INTO end_station FROM
(
    SELECT end_station_name, ROUND(AVG(start_lat), 4) as dep_lat, ROUND(AVG(end_lng), 4) as dep_lng
    FROM all_data_cleaned
    GROUP BY end_station_name
)t;

-- Selecting top 100 start and end stations from members 
SELECT TOP (100) s.start_station_name, s.dep_lat, s.dep_lng,  COUNT(a.ride_id) as [Ride Count]
FROM start_station as s JOIN all_data_cleaned as a 
ON s.start_station_name = a.start_station_name
WHERE member_casual = 'member'
GROUP BY s.start_station_name, s.dep_lat, s.dep_lng
ORDER BY COUNT(a.ride_id) DESC;

SELECT TOP (100) s.end_station_name, s.dep_lat, s.dep_lng,  COUNT(a.ride_id) as [Ride Count]
FROM end_station as s JOIN all_data_cleaned as a 
ON s.end_station_name = a.end_station_name
WHERE member_casual = 'member'
GROUP BY s.end_station_name, s.dep_lat, s.dep_lng
ORDER BY COUNT(a.ride_id) DESC;

-- Selecting top 100 stations from each casual users 
SELECT TOP (100) s.start_station_name, s.dep_lat, s.dep_lng,  COUNT(a.ride_id) as [Ride Count]
FROM start_station as s JOIN all_data_cleaned as a 
ON s.start_station_name = a.start_station_name
WHERE member_casual = 'casual'
GROUP BY s.start_station_name, s.dep_lat, s.dep_lng
ORDER BY COUNT(a.ride_id) DESC;

SELECT TOP (100) s.end_station_name, s.dep_lat, s.dep_lng,  COUNT(a.ride_id) as [Ride Count]
FROM end_station as s JOIN all_data_cleaned as a 
ON s.end_station_name = a.end_station_name
WHERE member_casual = 'casual'
GROUP BY s.end_station_name, s.dep_lat, s.dep_lng
ORDER BY COUNT(a.ride_id) DESC









