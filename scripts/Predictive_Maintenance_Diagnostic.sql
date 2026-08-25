-- SQL PROJECT 1: AI4I 2020 Predictive Maintenance Dataset
/*
Welcome to my project 1. This project is on manufacturing diagnostics. This project's objective is to answer the diagnosis on observations of manufacturing.

*/
/*
STAGE 1: CREATION OF A TABLE WITH DATA IMPORTING
I am creating a table to import the dataset and answer the questions which are mandatory. Also, there will be dropping of a table when the script is updated
*/

--Drop the table if exists due to updation
DROP TABLE IF EXISTS md_schema.machine_telemetry;

-- Create the table after updation in the script
CREATE TABLE md_schema.machine_telemetry(
	udi INT PRIMARY KEY,
	product_id TEXT,
	machine_type TEXT,
	air_temperature_k NUMERIC,
	process_temperature_k NUMERIC,
	rotational_speed_rpm NUMERIC,
	torque_nm NUMERIC,
	tool_wear_min NUMERIC,
	machine_failure INT,
	twf INT, -- Tool Wear Failure
	hdf INT, -- Heat Dissipation Failure
	pwf INT, -- Power Failure
	osf INT, -- Overstrain Failure
	rnf INT -- Random Failures
);

/*
Importing the data with skipping header as the table is created with headers
*/

-- Copying the dataset into this raw table
COPY md_schema.machine_telemetry
FROM 'D:\Data Analysis project\Gemini\SQL\Project 1\ai4i+2020+predictive+maintenance+dataset\ai4i2020.csv'
DELIMITER ','
CSV HEADER;

-- I have created the B-Tree Indexes for optimized SQL execution
CREATE INDEX idx_machine_type ON md_schema.machine_telemetry(machine_type);
CREATE INDEX idx_osf ON md_schema.machine_telemetry(osf);
CREATE INDEX idx_twf ON md_schema.machine_telemetry(twf);

/*
Now, I will fetch the data and observe whether it is a complete 10,000 rows dataset or an incomplete data.
*/
SELECT COUNT(*) AS total_rows FROM md_schema.machine_telemetry;
SELECT * FROM md_schema.machine_telemetry LIMIT 100; -- Added LIMIT here to prevent UI freezing

-- STAGE 1 COMMPLETED

/*
STAGE 2: DESCRIPTIVE ANALYSIS
This is the stage on data analysis on this dataset to know what has happened on this timeline.
*/
-- Production baseline: no of batches per machine type
SELECT
	machine_type,
	COUNT(product_id) AS count_of_batches,
	ROUND((COUNT(product_id) * 100.0) / (SELECT COUNT(*) FROM md_schema.machine_telemetry),2) AS floor_volume_percentage
FROM md_schema.machine_telemetry
GROUP BY machine_type
ORDER BY count_of_batches DESC;

-- Failure Baseline: no of failures from the machine from number of batches
SELECT
	COUNT(*) AS total_batches,
	SUM(machine_failure) AS total_machine_failure,
	ROUND((SUM(machine_failure) * 100.0) / (COUNT(*)),2) AS failure_percentage,
	100.0 - ROUND((SUM(machine_failure) * 100.0) / (COUNT(*)),2) AS yield_percentage
FROM md_schema.machine_telemetry;

-- Thermodynamics Baseline: Avg of air temp & rotational speed, and max of process temp & torque
SELECT
	COUNT(*) AS total_batches,
	ROUND(AVG(air_temperature_k),2) AS average_air_temp_k, -- AVG air temp in K
	MAX(process_temperature_k) AS max_process_temp_k, -- MAX process temp in K
	ROUND(AVG(rotational_speed_rpm),2) AS average_rotation_speed_rpm, -- AVG of rotational speed in RPM
	MAX(torque_nm) AS max_torque_nm -- MAX torque in NM
FROM md_schema.machine_telemetry;

-- Tool Lifecycle: Aveerage tool wear as a usage in minutes and maximum tool wear which shows how much time taken to use which degrades over period of time.
SELECT
	SUM(tool_wear_min) AS total_tool_wear_min,	
	ROUND(AVG(tool_wear_min),2) AS average_tool_wear_min,
	MAX(tool_wear_min) AS max_tool_wear_min
FROM md_schema.machine_telemetry;

-- Failure Categorization: Machine failed due to different factors such as TWF: Tool Wear Failure, HDF: Heat Dissipation Failure, PWF: Power Failure, OSF: Overstrain Failure, RNF: Random Failures
SELECT
	SUM(machine_failure) AS total_machine_failure,
	SUM(twf) AS tool_wear_failure,
	SUM(hdf) AS heat_dissipation_failure,
	SUM(pwf) AS power_failure,
	SUM(osf) AS overstrain_failure,
	SUM(rnf) AS random_failure
FROM md_schema.machine_telemetry;

-- STAGE 2 COMMPLETED

/*
STAGE 3: DIAGNOSTIC ANALYSIS
This is the stage on data analysis on this dataset to know why this has happened on this timeline.
*/
-- Quality variant breaks distinguishment: Telling which variant of machine have high failures followed by other variants
SELECT
	machine_type,
	COUNT(*) as total_batches,
	SUM(twf) AS tool_wear_failure,
	SUM(hdf) AS heat_dissipation_failure,
	SUM(osf) AS overstrain_failure
FROM md_schema.machine_telemetry
GROUP BY machine_type
ORDER BY total_batches DESC;

-- The Heat Matrix: Average of air temperature and process temoerature telling which machine variant have got high temperature in air and process which may cause HDF
SELECT
	machine_type,
	COUNT(*) as total_batches,
	ROUND(AVG(air_temperature_k),2) AS average_air_temp_k,
	ROUND(AVG(process_temperature_k),2) AS average_process_temp_k,
	MAX(process_temperature_k) AS max_process_temp_k
FROM md_schema.machine_telemetry
GROUP BY machine_type
ORDER BY max_process_temp_k DESC;

-- Tool Wear Failure: Different machine variants with showing tool wear failure from which variant first
SELECT
	machine_type,
	COUNT(twf) as tool_wear_failure,
	MIN(tool_wear_min) AS min_tool_wear_time,
	ROUND(AVG(tool_wear_min),2) AS average_tool_wear_min,
	MAX(tool_wear_min) AS max_tool_wear_time
FROM md_schema.machine_telemetry
WHERE twf = 1
GROUP BY machine_type;

-- OSF either due to torque or rotatioal speed: Distinguising between torque and rotational speed caused OSF
SELECT
	osf,
	COUNT(*) AS total_batches,
	ROUND(AVG(torque_nm),2) AS average_torque_nm,
	ROUND(AVG(rotational_speed_rpm),2) AS average_rotation_speed_rpm
FROM md_schema.machine_telemetry
GROUP BY osf
ORDER BY osf DESC;

-- The Cascading Failure Map: Critical things comes due to critical reasoning. Looking the batches where the failures are more than one simple failure to call out.
SELECT
	product_id,
	twf,
	hdf,
	pwf,
	osf,
	rnf,
	twf + hdf + pwf + osf + rnf AS simultaneous_failures
FROM md_schema.machine_telemetry
WHERE twf + hdf + pwf + osf + rnf > 1
ORDER BY simultaneous_failures DESC;