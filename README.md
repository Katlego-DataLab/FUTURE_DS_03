# 📊 E-Commerce User Behavior Analysis  SAS + Power BI

> **Automated data pipeline to clean, transform, and analyze 8,000+ e-commerce user behavior records  uncovering conversion patterns, drop-off points, and segment-level KPIs for executive reporting.**


![DASHBORAD](https://github.com/Katlego-DataLab/FUTURE_DS_03/blob/main/Ecommerce%20Intelligence%20FUTURE_DS_03.png)

---

## 🗂️ Table of Contents

1. [Project Overview](#-project-overview)
2. [Business Problem](#-business-problem)
3. [Tools & Technologies](#️-tools--technologies)
4. [Dataset Summary](#-dataset-summary)
5. [Pipeline Architecture](#-pipeline-architecture)
6. [Stage 1 — Data Import](#stage-1--data-import)
7. [Stage 2 — Data Cleaning & Imputation](#stage-2--data-cleaning--imputation)
8. [Stage 3 — KPI Calculation](#stage-3--kpi-calculation)
9. [Stage 4 — Validation & Quality Checks](#stage-4--validation--quality-checks)
10. [Stage 5 — Export for Power BI](#stage-5--export-for-power-bi)
11. [Key Insights](#-key-insights)
12. [Output Files](#-output-files)
13. [Business Impact](#-business-impact)
14. [Future Improvements](#-future-improvements)
15. [Author](#-author)

---

##  Project Overview

This project builds a **fully automated, end-to-end SAS data pipeline** that processes raw e-commerce behavioral data through 5 structured stages — from raw CSV import all the way to clean, Power BI-ready exports.

| Metric | Value |
|---|---|
| Total records processed | **8,000+** |
| Pipeline stages | **5** |
| KPI dimensions | **3** (device, gender, age group) |
| Output files generated | **2** (cleaned data + KPI summary) |
| Missing value target post-cleaning | **0** |
| Funnel stages engineered | **4** |

---

## 🎯 Business Problem

E-commerce businesses lose revenue at every stage of the customer journey without knowing exactly where or why. This project was built to answer three critical business questions:

1. **Where do users drop off** in the buying journey browsing, cart, or checkout?
2. **Which customer segments convert the most** by device, age, or gender?
3. **How do engagement metrics** (time on site, bounce rate) actually impact purchase behavior?

Without clean, structured data and a defined funnel, these questions cannot be answered reliably. This pipeline solves that.

---

##  Tools & Technologies

| Tool | Purpose |
|---|---|
| **SAS Base** | Data step programming cleaning, imputation, feature engineering |
| **PROC SQL** | KPI aggregation across 3 segmentation dimensions |
| **PROC MEANS** | Statistical validation and missing value audit |
| **PROC PRINT** | Output preview for QA |
| **PROC IMPORT** | Raw CSV ingestion |
| **PROC EXPORT** | Power BI-ready CSV outputs |
| **Power BI** | Final dashboard and executive reporting |

---

##  Dataset Summary

- **Source format:** CSV (`ecommerce_user_behavior_8000.csv`)
- **Total records:** 8,000+ user sessions
- **Total variables:** 11 core fields

| Variable | Type | Description |
|---|---|---|
| `user_id` | ID | Unique user identifier |
| `age` | Numeric | User age (years) |
| `gender` | Character | Male / Female / Unknown |
| `device_type` | Character | Mobile / Desktop / Tablet / Unknown |
| `time_on_site` | Numeric | Session duration (minutes) |
| `pages_viewed` | Binary/Int | Number of pages viewed |
| `bounce_rate` | Numeric | % chance of immediate exit (0–100) |
| `cart_items` | Binary/Int | Items added to cart |
| `discount_seen` | Binary | Whether user saw a discount (0/1) |
| `ad_clicked` | Binary | Whether user clicked an ad (0/1) |
| `purchase` | Binary | Whether user completed a purchase (0/1) |

---

##  Pipeline Architecture

```
Raw CSV (8,000+ rows)
        │
        ▼
┌─────────────────────┐
│  STAGE 1: IMPORT    │  ← PROC IMPORT reads CSV with headers
└─────────────────────┘
        │
        ▼
┌─────────────────────┐
│  STAGE 2: CLEAN     │  ← Remove nulls, impute missing values,
│  & ENGINEER         │    fix character truncation, build funnel
└─────────────────────┘
        │
        ▼
┌─────────────────────┐
│  STAGE 3: KPI CALC  │  ← PROC SQL: conversion rate, avg time,
│  (PROC SQL)         │    avg bounce rate — by 3 dimensions
└─────────────────────┘
        │
        ▼
┌─────────────────────┐
│  STAGE 4: VALIDATE  │  ← PROC MEANS: verify 0 missing values,
│  (PROC MEANS/PRINT) │    check distributions, preview 10 rows
└─────────────────────┘
        │
        ▼
┌─────────────────────┐
│  STAGE 5: EXPORT    │  ← 2 CSVs for Power BI consumption
└─────────────────────┘
```

---

## Stage 1 — Data Import

```sas
proc import datafile="/home/u63632200/ecommerce_user_behavior_8000.csv"
    out=work.raw_data
    dbms=csv
    replace;
    getnames=yes;
run;
```

**What this does:**
- Reads the raw CSV into a SAS work library dataset called `raw_data`
- `getnames=yes` tells SAS the first row contains column headers
- `replace` allows re-running the script without conflict errors

---

## Stage 2 — Data Cleaning & Imputation

This is the most critical and technically advanced stage of the pipeline. It handles **5 distinct types of data quality issues** in a single DATA step.

```sas
data work.ecommerce_cleaned;
    length gender device_type $15 age_group $10;
    set work.raw_data;

    /* Remove records without a user ID — no anchor key = unusable row */
    if missing(user_id) then delete;

    /* Continuous variable imputation using domain-appropriate defaults */
    if age = . then age = 38;             /* median age across dataset */
    if time_on_site = . then time_on_site = 15;  /* default session baseline */
    if bounce_rate = . then bounce_rate = 50;    /* neutral midpoint */

    /* Fix blank character fields — prevent them becoming empty strings */
    if strip(gender) = '' then gender = 'Unknown';
    if strip(device_type) = '' then device_type = 'Unknown';

    /* Array-based imputation for 7 binary behavioral flags at once */
    array num_flags[*] pages_viewed previous_purchases cart_items
                       discount_seen ad_clicked returning_user purchase;
    do i = 1 to dim(num_flags);
        if missing(num_flags[i]) then num_flags[i] = 0;
    end;
    drop i;

    /* Conversion funnel: 4 engineered stages */
    stage_1_session  = 1;
    stage_2_viewed   = (pages_viewed > 0);
    stage_3_cart     = (cart_items > 0 or purchase = 1);
    stage_4_purchase = (purchase = 1);

    /* Age segmentation for demographic analysis */
    if age < 25 then age_group = '18-24';
    else if age < 35 then age_group = '25-34';
    else if age < 45 then age_group = '35-44';
    else if age < 55 then age_group = '45-54';
    else age_group = '55+';
run;
```

### Cleaning Decisions Explained

| Issue | Variable(s) Affected | Fix Applied | Reasoning |
|---|---|---|---|
| Missing record anchor | `user_id` | Delete row | No ID = can't link to any segment |
| Missing age | `age` | Impute with **38** (median) | Median avoids skew from outliers |
| Missing session duration | `time_on_site` | Impute with **15 mins** | Conservative default engagement estimate |
| Missing bounce rate | `bounce_rate` | Impute with **50%** | Neutral midpoint — no assumption of exit/stay |
| Blank character fields | `gender`, `device_type` | Fill with `"Unknown"` | Preserves record while flagging unknown |
| Missing binary flags | 7 variables (see array) | Fill with **0** | Absence of action = action not taken |
| Character truncation | `gender`, `device_type` | `length $15` declared | Prevents SAS defaulting to short $8 length |

### Advanced Technique: Array-Based Imputation

Instead of writing 7 separate `IF` statements, a **SAS array** is used to loop through all binary flag variables in a single `DO` loop:

```sas
array num_flags[*] pages_viewed previous_purchases cart_items
                   discount_seen ad_clicked returning_user purchase;
do i = 1 to dim(num_flags);
    if missing(num_flags[i]) then num_flags[i] = 0;
end;
```

- `array num_flags[*]` — dynamically sizes the array, no need to hardcode the count
- `dim(num_flags)` — returns the array size automatically (7 here)
- This is more scalable, readable, and maintainable than repeated `IF` blocks

###  Conversion Funnel Engineering

A **4-stage funnel** is created as binary flag columns to track exactly where users exit:

| Stage | Variable | Logic | Meaning |
|---|---|---|---|
| 1 | `stage_1_session` | Always = 1 | User started a session (100% baseline) |
| 2 | `stage_2_viewed` | `pages_viewed > 0` | User actually browsed products |
| 3 | `stage_3_cart` | `cart_items > 0 OR purchase = 1` | User showed purchase intent |
| 4 | `stage_4_purchase` | `purchase = 1` | User completed the transaction |

Each stage can be summed across the dataset to calculate **exact drop-off rates** between stages.

---

## Stage 3 — KPI Calculation

```sas
proc sql;
    create table work.ecommerce_kpis as
    select 
        device_type, 
        gender,
        age_group,
        count(user_id) as total_users,
        sum(purchase) as total_purchases,
        (calculated total_purchases / calculated total_users) as conversion_rate format=percent10.2,
        avg(time_on_site) as avg_time_on_site format=8.2,
        avg(bounce_rate) as avg_bounce_rate format=8.2
    from work.ecommerce_cleaned
    group by device_type, gender, age_group;
quit;
```

**KPIs calculated:**

| KPI | Formula | Format |
|---|---|---|
| `total_users` | `COUNT(user_id)` | Integer count |
| `total_purchases` | `SUM(purchase)` | Integer count |
| `conversion_rate` | `total_purchases / total_users` | `percent10.2` (e.g. 23.45%) |
| `avg_time_on_site` | `AVG(time_on_site)` | Minutes, 2 decimal places |
| `avg_bounce_rate` | `AVG(bounce_rate)` | Percentage, 2 decimal places |

**Segmentation dimensions:**

KPIs are broken down across **3 dimensions simultaneously** using `GROUP BY`:

- 📱 **Device type** — Mobile vs Desktop vs Tablet
- 👤 **Gender** — Male, Female, Unknown
- 📅 **Age group** — 5 bands (18–24, 25–34, 35–44, 45–54, 55+)

This produces a **multi-dimensional KPI matrix** that Power BI can slice and filter interactively.

---

## Stage 4 — Validation & Quality Checks

Three separate validation reports are generated to confirm data integrity before export.

```sas
/* 4.1 Preview first 10 cleaned records */
title "Preview of Cleaned E-commerce Data (First 10 Rows)";
proc print data=work.ecommerce_cleaned(obs=10);
run;

/* 4.2 Print KPI summary table */
title "Key Performance Indicators by Segment";
proc print data=work.ecommerce_kpis;
run;

/* 4.3 Statistical distribution check */
title "Data Validation: Summary of Numerical Metrics";
proc means data=work.ecommerce_cleaned n nmiss mean median min max;
    var age time_on_site pages_viewed bounce_rate;
run;

/* 4.4 Final zero-missing audit */
title "FINAL DATA AUDIT: ZERO MISSING VALUES TARGET";
proc means data=work.ecommerce_cleaned n nmiss mean;
    var age time_on_site bounce_rate purchase;
run;
```

**Validation checks performed:**

| Check | Method | What it confirms |
|---|---|---|
| Visual row preview | `PROC PRINT (obs=10)` | Cleaning applied correctly on real records |
| KPI table review | `PROC PRINT` on KPI table | Aggregations look reasonable |
| Distribution stats | `PROC MEANS` (n, nmiss, mean, median, min, max) | No unexpected outliers; distributions are sane |
| Zero-missing audit | `PROC MEANS` (nmiss only) | All 4 key variables have `nmiss = 0` post-cleaning |

The **`nmiss` statistic** in the final audit is the critical pass/fail gate — it must equal **0** on `age`, `time_on_site`, `bounce_rate`, and `purchase` for the pipeline to be considered complete.

---

## Stage 5 — Export for Power BI

```sas
/* Full cleaned dataset */
proc export data=work.ecommerce_cleaned
    outfile="/home/u63632200/final_ecommerce_for_powerbi.csv"
    dbms=csv
    replace;
run;

/* Aggregated KPI summary */
proc export data=work.ecommerce_kpis
    outfile="/home/u63632200/ecommerce_kpi_summary.csv"
    dbms=csv
    replace;
run;
```

Two files are exported — one for row-level exploration, one for executive summary views.

---

##  Key Insights

The pipeline is designed to surface these specific business insights in Power BI:

- **Funnel drop-off by stage** — What % of users reach each of the 4 funnel stages
- **Conversion rate by device** — Do mobile users convert at lower rates than desktop?
- **Engagement vs. purchase correlation** — Does higher time on site predict purchase?
- **Bounce rate by age group** — Which demographic segments exit the fastest?
- **Segment-level conversion** — Which (device × gender × age) combination converts best?

---

## 📤 Output Files

| File | Contents | Use Case |
|---|---|---|
| `final_ecommerce_for_powerbi.csv` | 8,000+ cleaned records with all original + engineered features | Row-level filtering, funnel charts, scatter plots |
| `ecommerce_kpi_summary.csv` | Aggregated KPIs grouped by device × gender × age | Executive KPI cards, bar charts, comparison tables |

---

## 💼 Business Impact

| Capability Enabled | How |
|---|---|
| Targeted marketing | Conversion rates segmented by demographics and device |
| UX optimization | Funnel drop-off stage reveals which step needs improvement |
| Budget allocation | Device-level performance guides ad spend distribution |
| Executive reporting | Pre-aggregated KPI file ready for dashboard without further processing |

---

##  Future Improvements

- [ ] Add **revenue metrics** — Average Order Value (AOV), Revenue per User
- [ ] Build a **predictive model** using logistic regression (purchase likelihood score)
- [ ] Incorporate **time-series analysis** — session trends by week/month
- [ ] Enhance Power BI dashboard with **real-time data refresh**
- [ ] Add **cohort analysis** — comparing new vs. returning users

---

## 👤 Author

**Katlego Mathebula**
Diploma in Mathematical Sciences 

---

*Built with SAS Base | PROC SQL | Power BI*
