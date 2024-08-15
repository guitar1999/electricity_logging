-- oil stats
delete from oil_statistics.oil_sums_hourly where sum_date = '2023-12-18' and hour = 11;
INSERT INTO oil_statistics.oil_sums_hourly (sum_date, hour, btu, runtime)
            SELECT ('2023-12-18')::DATE AS sum_date,
            11 AS hour,
            COALESCE(bs.btu, 0),
            COALESCE(bs.total_boiler_runtime, 0)
            FROM boiler_summary( 
                ('2023-12-18 11:00:00')::TIMESTAMP, ('2023-12-18 11:00:00')::TIMESTAMP + '00:59:59'::INTERVAL ) AS bs;

-- electricity stats
delete from electricity_iotawatt_statistics.electricity_sums_hourly where sum_date = '2023-12-18' and hour = 11;
INSERT INTO 
                electricity_iotawatt_statistics.electricity_sums_hourly (sum_date, hour, kwh)
            SELECT 
                ('2023-12-18')::DATE AS sum_date,
                11 AS hour,
                COALESCE(SUM((watts_main_1 + watts_main_2) * tdiff / 1000 / 60 / 60), 0) AS kwh
            FROM 
                electricity_iotawatt.electricity_measurements
            WHERE 
                measurement_time > '2023-12-18 11:00:00'::TIMESTAMP - INTERVAL '1 DAY'
                AND measurement_time::DATE = ('2023-12-18')::DATE
                AND DATE_PART('HOUR', measurement_time) = 11
            GROUP BY 1,
                    2;

-- water stats
delete from water_statistics.water_sums_hourly where sum_date = '2023-12-18' and hour = 11;
INSERT INTO water_statistics.water_sums_hourly (sum_date, hour, kwh, gallons, cycles, total_runtime, avg_runtime, min_runtime, max_runtime)
            SELECT ('2023-12-18')::DATE AS sum_date,
                11 AS hour,
                COALESCE(ws.kwh, 0),
                COALESCE(ws.gallons, 0),
                COALESCE(ws.cycles, 0),
                COALESCE(ws.total_runtime, 0),
                COALESCE(ws.avg_runtime, 0),
                COALESCE(ws.min_runtime, 0),
                COALESCE(ws.max_runtime, 0)
            FROM water_summary( ('2023-12-18 11:00:00')::TIMESTAMP, ('2023-12-18 11:00:00')::TIMESTAMP + '00:59:59'::INTERVAL ) AS ws;