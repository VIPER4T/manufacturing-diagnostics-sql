# 🏭 Predictive Maintenance Diagnostics: AI4I 2020

## 📌 Executive Summary
This repository contains an end-to-end SQL data analytics pipeline designed to diagnose manufacturing yield loss using the AI4I 2020 Predictive Maintenance Dataset. The objective was to isolate the mechanical root causes of machine failure on a factory floor experiencing a 3.39% yield loss, and to architect a PostgreSQL database optimized for production-level query performance.

## 📂 Repository Structure
```text
sql-predictive-maintenance-ai4i/
├── data/
│   └── ai4i2020.csv                            # The raw telemetry dataset
├── scripts/
│   └── Predictive_Maintenance_Diagnostic.sql   # The finalized 149-line execution script
├── docs/
│   ├── 01_Diagnostic_Questions.md              # Query logic, output evidence, and business findings
│   └── 02_Technical_Architecture.md            # B-Tree indexing strategy and performance metrics
└── README.md                                   # Executive summary and execution guide
```
*(Note: To view the exact SQL queries, output tables, and diagnostic evidence, please refer to the `docs/` directory).*

## 🛠️ Technical Stack
* **Database:** PostgreSQL
* **Core Techniques:** DDL/DML, Bulk Data Ingestion (`COPY`), Aggregate Functions, Subqueries, Logic-Based Filtering.
* **Performance Engineering:** B-Tree Indexing, Query Execution X-Rays (`EXPLAIN ANALYZE`).

## 📊 Key Business Recommendations
Through sequential diagnostic analysis, we uncovered the specific mechanical bottlenecks limiting factory yield and formulated the following operational directives:

1. **Mandate a 190-Minute Tool Swap:** Despite tools possessing a maximum lifespan of 253 minutes, empirical evidence proves no tool across any product variant has ever failed before 198 minutes. Mandating a tool-swap protocol at exactly 190 minutes will theoretically eliminate 100% of Tool Wear Failures (TWF).
2. **Adjust Variant L Feed Rates:** The "Low" (L) quality variant drives the majority of mechanical breakdowns, causing Overstrain Failures (OSF) at a rate of 1.45% (nearly 5x higher than Variant M). Diagnostic evidence proves this is a mechanical limitation, not a thermal one. The machines are bogging down (dropping 200 RPM) and pushing too hard (torque spiking by nearly 50%). Feed rates for Variant L must be reduced.
3. **Resolve Electrical Cascades:** Diagnosing simultaneous failures revealed a direct mechanical link between overstrain and electrical grids. When Variant L overstrains the motors, the resulting power draw frequently blows the factory breakers. Fixing the Variant L mechanical overstrain will organically resolve the simultaneous Power Failures (PWF).

## 🚀 Database Performance Optimization
To ensure this pipeline can scale to millions of rows without crashing business intelligence dashboards, the physical table architecture was optimized. 

By applying B-Tree Indexing to the `machine_type`, `osf`, and `twf` columns *after* the bulk data ingestion phase, we eliminated resource-heavy Sequential Scans.
* **Pre-Index Execution (Seq Scan):** ~1,820 ms
* **Post-Index Execution (Index Scan):** 0.601 ms
* **Net Result:** Over a 99% reduction in raw engine calculation time.

## ⚙️ How to Run This Project Locally

1. Clone this repository to your local machine.
2. Ensure you have a PostgreSQL environment running (e.g., pgAdmin, DBeaver).
3. Open `scripts/Predictive_Maintenance_Diagnostic.sql`.
4. **Configuration Step:** On line 34, update the `COPY` file path to point to the exact local directory where you saved the `data/ai4i2020.csv` file. 
   ```sql
   COPY md_schema.machine_telemetry
   FROM '/your/local/directory/ai4i2020.csv'
   DELIMITER ','
   CSV HEADER;
   ```
5. Execute the script top-to-bottom to generate the schema, ingest the data, build the indexes, and run the analytical baselines.
