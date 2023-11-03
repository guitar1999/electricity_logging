-- This table contains events that may impact one or more of the data streams

CREATE TABLE events (
    id SERIAL NOT NULL PRIMARY KEY
    , event_time TIMESTAMP WITH TIME ZONE
    , affects_electricity BOOLEAN
    , affects_oil BOOLEAN
    , affects_water BOOLEAN
    , event_description TEXT
);
CREATE INDEX events_event_time_idx ON events USING BTREE (event_time);