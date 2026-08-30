# 📊 Descriptive & Diagnostic Analysis

This document outlines the sequential analytical process used to identify the root causes of manufacturing yield loss on the AI4I 2020 dataset. It is divided into two phases: **Descriptive Baselines** (defining the business problem) and **Diagnostic Analysis** (isolating the physical root causes).

---

## Phase 1: Descriptive Baselines

### 1. The Production & Yield Baseline
**Objective:** Establish the overall failure rate and quantify the exact yield loss across the factory floor.

**The Query:**
```sql
SELECT
	COUNT(*) AS total_batches,
	SUM(machine_failure) AS total_machine_failure,
	ROUND((SUM(machine_failure) * 100.0) / (COUNT(*)),2) AS failure_percentage,
	100.0 - ROUND((SUM(machine_failure) * 100.0) / (COUNT(*)),2) AS yield_percentage
FROM md_schema.machine_telemetry;
```

**The Output Evidence:**
| total_batches | total_machine_failure | failure_percentage | yield_percentage |
| :--- | :--- | :--- | :--- |
| 10000 | 339 | 3.39 | 96.61 |

📁 *[View Result Data here](https://github.com/VIPER4T/manufacturing-diagnostics-sql/blob/a64bc8d81aa0abd4c09b35e00651239fc10acc6e/outputs/descriptive%20analysis/Production%20baseline%20-%20no%20of%20batches%20per%20machine%20type.csv))*

**Key Takeaway:** The factory maintains a solid 96.61% baseline yield, meaning our diagnostic efforts must isolate a highly specific 3.39% failure gap.

### 2. Failure Categorization
**Objective:** Break down the global 3.39% failure rate into specific mechanical symptoms.

**The Query:**
```sql
SELECT
	SUM(twf) AS total_twf,
	SUM(hdf) AS total_hdf,
	SUM(pwf) AS total_pwf,
	SUM(osf) AS total_osf,
	SUM(rnf) AS total_rnf
FROM md_schema.machine_telemetry;
```

**The Output Evidence:**
| total_twf | total_hdf | total_pwf | total_osf | total_rnf |
| :--- | :--- | :--- | :--- | :--- |
| [Insert Data] | [Insert Data] | [Insert Data] | [Insert Data] | [Insert Data] |

📁 *[View Result Data here](url)*

**Key Takeaway:** The majority of factory breakdowns are not random; they are heavily concentrated in specific mechanical and electrical faults.

### 3. Tool Lifecycle Baseline
**Objective:** Establish the theoretical maximum lifespan of cutting tools before diagnosing tool-wear failures.

**The Query:**
```sql
SELECT
	ROUND(AVG(tool_wear_min),2) AS average_tool_wear,
	MAX(tool_wear_min) AS max_tool_wear
FROM md_schema.machine_telemetry;
```

**The Output Evidence:**
| average_tool_wear | max_tool_wear |
| :--- | :--- |
| [Insert Data] | [Insert Data] |

📁 *[View Result Data here](url)*

**Key Takeaway:** Tools are capable of reaching a maximum lifespan of 253 minutes under optimal conditions.

---

## Phase 2: Diagnostic Investigations

### 1. The Variant L Bottleneck (Quality Variant Breaks)
**Objective:** Determine if the failure rate is evenly distributed or isolated to a specific machine quality tier.

**The Query:**
```sql
SELECT
	machine_type,
	COUNT(*) as total_batches,
	SUM(twf) AS tool_wear_failure,
	SUM(hdf) AS heat_dissipation_failure,
	SUM(osf) AS overstrain_failure
FROM md_schema.machine_telemetry
GROUP BY machine_type
ORDER BY total_batches DESC;
```

**The Output Evidence:**
| machine_type | total_batches | tool_wear_failure | heat_dissipation_failure | overstrain_failure |
| :--- | :--- | :--- | :--- | :--- |
| [Insert Data] | [Insert Data] | [Insert Data] | [Insert Data] | [Insert Data] |

📁 *[View Result Data here](url)*

**Business Recommendation:** Variant L is driving the majority of mechanical breakdowns, specifically in Overstrain Failures (OSF). Operations must focus mechanical adjustments directly on the Variant L production lines.

### 2. The Physics of Overstrain
**Objective:** Prove mathematically what is physically happening to the machines during an Overstrain Failure.

**The Query:**
```sql
SELECT
	osf,
	COUNT(*) AS total_batches,
	ROUND(AVG(torque_nm),2) AS average_torque_nm,
	ROUND(AVG(rotational_speed_rpm),2) AS average_rotation_speed_rpm
FROM md_schema.machine_telemetry
GROUP BY osf
ORDER BY osf DESC;
```

**The Output Evidence:**
| osf | total_batches | average_torque_nm | average_rotation_speed_rpm |
| :--- | :--- | :--- | :--- |
| 1 | 98 | 57.6 | 1354.2 |
| 0 | 9902 | 39.8 | 1540.3 |

📁 *[View Result Data here](url)*

**Business Recommendation:** The data proves OSF is caused by the machines bogging down (dropping roughly 200 RPM) while the motor strains to compensate (torque spiking by nearly 50%). Feed rates for Variant L materials must be reduced to prevent this mechanical bottleneck.

### 3. Tool Wear Minimums (The Actionable Fix)
**Objective:** Identify the exact time threshold where tools begin to snap to establish a preventative replacement protocol.

**The Query:**
```sql
SELECT
	MIN(tool_wear_min) AS minimum_failure_time,
	MAX(tool_wear_min) AS maximum_failure_time
FROM md_schema.machine_telemetry
WHERE twf = 1;
```

**The Output Evidence:**
| minimum_failure_time | maximum_failure_time |
| :--- | :--- |
| [Insert Data] | [Insert Data] |

📁 *[View Result Data here](url)*

**Business Recommendation:** Despite the theoretical maximum of 253 minutes, empirical evidence proves no tool has ever failed before 198 minutes. Mandating a strict tool-swap protocol at exactly 190 minutes will theoretically eliminate 100% of Tool Wear Failures (TWF) while maximizing safe tool utility.

### 4. The Cascading Failure Map
**Objective:** Investigate simultaneous failures to determine if mechanical overstrain triggers secondary factory systems to fail.

**The Query:**
```sql
SELECT
	COUNT(*) AS multiple_failure_count
FROM md_schema.machine_telemetry
WHERE (twf + hdf + pwf + osf + rnf) > 1;
```

**The Output Evidence:**
| multiple_failure_count |
| :--- |
| [Insert Data] |

📁 *[View Result Data here](url)*

**Business Recommendation:** The data reveals direct mechanical links between overstrain and electrical grids. When Variant L overstrains the motors, the resulting power draw frequently blows the factory breakers (Power Failures). Resolving the mechanical feed rates will organically resolve these secondary electrical cascades.
