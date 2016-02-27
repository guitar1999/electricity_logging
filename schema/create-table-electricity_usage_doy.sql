CREATE TABLE electricity_usage_doy (
    doy_noleap integer CHECK (doy_noleap >=1 AND doy_noleap <= 365),
    doy_leap integer CHECK (doy >= 1 AND doy <= 366),
    month integer CHECK (month >= 1 AND month <= 12),
    day integer CHECK (day >=1 AND day <= 31),
    kwh numeric,
    kwh_avg numeric,
    complete text CHECK (complete = 'yes' OR complete = 'no'),
    timestamp timestamp with time zone
);
