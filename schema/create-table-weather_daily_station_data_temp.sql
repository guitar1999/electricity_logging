CREATE TABLE weather_data.weather_daily_station_data_temp (
    station_id TEXT
    ,observation_date DATE 
    ,temp_max TEXT
    ,temp_min TEXT
    ,temp_avg TEXT
    ,temp_departure TEXT
    ,hdd TEXT
    ,cdd TEXT
    ,precip TEXT
    ,snow_new TEXT
    ,snow_depth TEXT
);

UPDATE weather_data.weather_daily_station_data_temp SET temp_max = NULL WHERE temp_max = 'M';
UPDATE weather_data.weather_daily_station_data_temp SET temp_min = NULL WHERE temp_min = 'M';
UPDATE weather_data.weather_daily_station_data_temp SET temp_avg = NULL WHERE temp_avg = 'M';
UPDATE weather_data.weather_daily_station_data_temp SET temp_departure = NULL WHERE temp_departure = 'M';
UPDATE weather_data.weather_daily_station_data_temp SET hdd = NULL WHERE hdd = 'M';
UPDATE weather_data.weather_daily_station_data_temp SET cdd = NULL WHERE cdd = 'M';
UPDATE weather_data.weather_daily_station_data_temp SET precip = NULL WHERE precip = 'M';
UPDATE weather_data.weather_daily_station_data_temp SET snow_new = NULL WHERE snow_new = 'M';
UPDATE weather_data.weather_daily_station_data_temp SET snow_depth = NULL WHERE snow_depth = 'M';