CREATE TABLE IF NOT EXISTS water_statistics.water_cycles (
    cycle_start TIMESTAMP WITH TIME ZONE NOT NULL PRIMARY KEY,
    cycle_end TIMESTAMP WITH TIME ZONE NOT NULL,
    sum_date DATE NOT NULL,
    hour INTEGER NOT NULL CHECK (hour >= 0 AND hour <= 23),
    runtime NUMERIC NOT NULL CHECK (runtime >= 0)
);

CREATE INDEX IF NOT EXISTS water_cycles_sum_date_idx
    ON water_statistics.water_cycles (sum_date);
