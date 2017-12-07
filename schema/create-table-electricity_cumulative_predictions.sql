CREATE TABLE electricity_statistics.electricity_cumulative_predictions (
    ecpid SERIAL NOT NULL PRIMARY KEY,
    prediction_rundate TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    predicted_timestamp TIMESTAMP WITH TIME ZONE,
    predicted_cumulative_kwh NUMERIC
);
