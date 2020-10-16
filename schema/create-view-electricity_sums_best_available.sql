CREATE OR REPLACE VIEW electricity_statistics.electricity_sums_hourly_best_available AS (
    SELECT 
        DISTINCT ON (sum_date, hour) 
        sum_date,
        hour,
        kwh,
        complete,
        source
    FROM
        (SELECT 
            sum_date,
            hour,
            kwh,
            'yes' AS complete,
            1 AS rank,
            'cmp' AS source
        FROM 
            electricity_cmp.cmp_electricity_sums_hourly_view
        UNION ALL 
        SELECT 
            sum_date,
            hour,
            kwh,
            'no' AS complete,
            2 AS rank,
            'iotawatt' AS source
        FROM 
            electricity_iotawatt_statistics.electricity_sums_hourly_view
        UNION ALL 
            SELECT 
                sum_date,
                hour,
                kwh,
                'no' AS complete,
                3 AS rank,
                'current_cost' AS source
        FROM 
            electricity_statistics.electricity_sums_hourly_view 
        ) AS sums
    ORDER BY 
        sum_date,
        hour,
        rank
);
