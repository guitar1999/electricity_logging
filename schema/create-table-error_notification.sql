CREATE TABLE error_notification (
    enid SERIAL NOT NULL PRIMARY KEY,
    error TEXT NOT NULL,
    notified BOOLEAN NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE
);
