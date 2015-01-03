CREATE FUNCTION get_month(timestamptz)
    RETURNS INTEGER AS 
    $$
        SELECT (to_char($1 AT TIME ZONE 'America/New_York', 'FMMM'))::INTEGER;
    $$ 
LANGUAGE SQL IMMUTABLE;
