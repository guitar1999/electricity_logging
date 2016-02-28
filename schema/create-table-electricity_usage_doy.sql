CREATE TABLE electricity.electricity_usage_doy (
    doy_noleap integer CHECK (doy_noleap >=1 AND doy_noleap <= 365),
    doy_leap integer CHECK (doy_leap >= 1 AND doy_leap <= 366),
    month integer CHECK (month >= 1 AND month <= 12),
    day integer CHECK (day >=1 AND day <= 31),
    kwh numeric,
    complete text CHECK (complete = 'yes' OR complete = 'no'),
    updated timestamp with time zone
);
\copy electricity.electricity_usage_doy (doy_noleap, doy_leap, month, day) FROM doy_statistics.data
UPDATE electricity.electricity_usage_doy SET (kwh, complete, updated) = (0, 'no', CURRENT_TIMESTAMP);
