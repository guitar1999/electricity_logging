CREATE TABLE meteorological_season (
    doy integer PRIMARY KEY CHECK (doy > 0 AND doy <= 366),
    season text CHECK (season = 'spring' OR season = 'summer' OR season = 'fall' OR season = 'winter')
);
