CREATE TABLE energy_statistics.electricity_statistics_doy (
    doy_noleap integer CHECK (doy_noleap >=1 AND doy_noleap <= 365),
    doy_leap integer CHECK (doy >= 1 AND doy <= 366),
    month integer CHECK (month >= 1 AND month <= 12),
    day integer CHECK (day >=1 AND day <= 31),
    count integer,
    kwh_avg numeric,
    previous_year numeric,
    current_year numeric,
    timestamp timestamp with time zone
);
