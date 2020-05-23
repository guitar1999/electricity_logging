CREATE TABLE electricity_iotawatt.electricity_measurements (
    emid SERIAL NOT NULL PRIMARY KEY,
    measurement_time TIMESTAMP WITH TIME ZONE UNIQUE,
    tdiff NUMERIC,
    watts_main_1 NUMERIC,
    watts_main_2 NUMERIC,
    watts_boiler NUMERIC,
    watts_subpanel_1 NUMERIC,
    watts_subpanel_2 NUMERIC,
    watts_water_pump NUMERIC,
    watts_generator_1 NUMERIC,
    watts_generator_2 NUMERIC
);
