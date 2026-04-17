/* 1. DATA IMPORT */
proc import datafile="/home/u63632200/ecommerce_user_behavior_8000.csv"
    out=work.raw_data
    dbms=csv
    replace;
    getnames=yes;
run;

/* 2. FINAL CLEANING & POLISHING */
data work.ecommerce_cleaned;
    /* FIX 1: Define lengths to prevent "Unkno" truncation */
    length gender device_type $15 age_group $10;
    set work.raw_data;

    if missing(user_id) then delete;

    /* FIX 2: Advanced Imputation for continuous numbers */
    /* If age is missing, we use the median (38) */
    if age = . then age = 38;
    if time_on_site = . then time_on_site = 15;
    if bounce_rate = . then bounce_rate = 50;

    /* Handle Character Blanks */
    if strip(gender) = '' then gender = 'Unknown';
    if strip(device_type) = '' then device_type = 'Unknown';

    /* Handle Binary Flags with Array */
    array num_flags[*] pages_viewed previous_purchases cart_items 
                       discount_seen ad_clicked returning_user purchase;
    do i = 1 to dim(num_flags);
        if missing(num_flags[i]) then num_flags[i] = 0;
    end;
    drop i;

    /* Funnel Logic */
    stage_1_session = 1;                             
    stage_2_viewed  = (pages_viewed > 0);            
    stage_3_cart    = (cart_items > 0 or purchase=1); 
    stage_4_purchase = (purchase = 1);               

    /* Age Grouping */
    if age < 25 then age_group = '18-24';
    else if age < 35 then age_group = '25-34';
    else if age < 45 then age_group = '35-44';
    else if age < 55 then age_group = '45-54';
    else age_group = '55+';
run;

/* 3. FINAL KPI CALCULATION */
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

/* 4. VERIFICATION REPORT */


/* 4.1. Show the first 10 rows of the cleaned data to verify cleaning */
title "Preview of Cleaned E-commerce Data (First 10 Rows)";
proc print data=work.ecommerce_cleaned(obs=10);
run;

/* 4.2. Show the KPI Summary Table */
title "Key Performance Indicators by Segment";
proc print data=work.ecommerce_kpis;
run;

/* 4.3. PROFESSIONAL TOUCH: Show a high-level statistical summary */
title "Data Validation: Summary of Numerical Metrics";
proc means data=work.ecommerce_cleaned n nmiss mean median min max;
    var age time_on_site pages_viewed bounce_rate;
run;
title "FINAL DATA AUDIT: ZERO MISSING VALUES TARGET";
proc means data=work.ecommerce_cleaned n nmiss mean;
    var age time_on_site bounce_rate purchase;
run;
/* 5. EXPORT FOR POWER BI CONSUMPTION */
proc export data=work.ecommerce_cleaned
    outfile="/home/u63632200/final_ecommerce_for_powerbi.csv"
    dbms=csv
    replace;
run;

proc export data=work.ecommerce_kpis
    outfile="/home/u63632200/ecommerce_kpi_summary.csv"
    dbms=csv
    replace;
run; 