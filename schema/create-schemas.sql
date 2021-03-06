CREATE SCHEMA electricity;
CREATE SCHEMA electricity_iotawatt;
CREATE SCHEMA electricity_iotawatt_statistics;
CREATE SCHEMA electricity_statistics;
CREATE SCHEMA electricity_cmp;
CREATE SCHEMA electricity_plotting;
CREATE SCHEMA oil;
CREATE SCHEMA oil_statistics;
CREATE SCHEMA oil_plotting;
CREATE SCHEMA propane;
CREATE SCHEMA propane_statistics;
CREATE SCHEMA water;
CREATE SCHEMA water_statistics;
CREATE SCHEMA water_plotting;
CREATE SCHEMA weather_data;
ALTER DATABASE lunt_energy SET search_path = public, electricity, electricity_iotawatt, electricity_iotawatt_statistics, electricity_statistics, electricity_cmp, electricity_plotting, oil, oil_statistics, oil_plotting, propane, propane_statistics, water, water_statistics, water_plotting, weather_data;

