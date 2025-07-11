CREATE OR REPLACE FUNCTION public.water_summary(start_date TIMESTAMP, end_date TIMESTAMP)
RETURNS TABLE(kwh NUMERIC, gallons NUMERIC, cycles INTEGER, total_runtime NUMERIC, avg_runtime NUMERIC, min_runtime NUMERIC, max_runtime NUMERIC)
AS $$
BEGIN
    RETURN QUERY WITH cycles AS (
        SELECT
            w.event_group,
            w.status,
            SUM(EXTRACT('EPOCH' FROM w.tdiff))::NUMERIC / 60 AS runtime,
            SUM(w.gallons)::NUMERIC AS gallons,
            SUM(w.watts_water_pump * EXTRACT('EPOCH' FROM w.tdiff) / 1000 / 60 / 60)::NUMERIC AS kwh
        FROM
            water_status(start_date, end_date) w
        GROUP BY
            event_group,
            status
        ORDER BY
            event_group,
            status
        ) SELECT
            COALESCE(SUM(ROUND(cycles.kwh,3)), 0),
            COALESCE(SUM(cycles.gallons) FILTER (WHERE cycles.status = 'ON'), 0)::NUMERIC,
            COALESCE(COUNT(cycles.*) FILTER (WHERE cycles.status = 'ON'), 0)::INTEGER,
            COALESCE(SUM(cycles.runtime) FILTER (WHERE cycles.status = 'ON'), 0)::NUMERIC,
            COALESCE(AVG(cycles.runtime) FILTER (WHERE cycles.status = 'ON'), 0)::NUMERIC,
            COALESCE(MIN(cycles.runtime) FILTER (WHERE cycles.status = 'ON'), 0)::NUMERIC,
            COALESCE(MAX(cycles.runtime) FILTER (WHERE cycles.status = 'ON'), 0)::NUMERIC
        FROM
            cycles;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
