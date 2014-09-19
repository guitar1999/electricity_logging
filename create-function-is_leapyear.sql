create or replace function is_leapyear(in year int) returns bool as
$$begin
  if extract( month from ($1::text || '-02-28')::date +
'1day'::interval) = 2
  then
    return true;
  else
    return false;
  end if;
end;
$$language plpgsql;
