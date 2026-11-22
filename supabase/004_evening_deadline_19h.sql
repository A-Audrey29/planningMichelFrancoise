-- Evening meals can now be dropped off until 19:00 (was 18:00), Paris time.

create or replace function public.slot_deadline(p_slot text)
returns timestamptz
language sql stable
set search_path = ''
as $$
  select ((left(p_slot, 10) || case when right(p_slot, 4) = 'midi' then ' 12:00' else ' 19:00' end)::timestamp
          at time zone 'Europe/Paris');
$$;

-- Rollback: re-run the same function with ' 18:00' instead of ' 19:00'.
