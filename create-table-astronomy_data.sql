BEGIN;
CREATE TABLE astronomy_data (
    adid serial NOT NULL PRIMARY KEY,
    date date NOT NULL UNIQUE,
    sunrise time NOT NULL,
    sunset time NOT NULL
);
COMMIT;
