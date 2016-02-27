CREATE FUNCTION get_year(timestamptz)
    RETURNS INTEGER AS 
    $$
        SELECT (to_char($1 AT TIME ZONE 'America/New_York', 'YYYY'))::INTEGER;
    $$ 
LANGUAGE SQL IMMUTABLE;
