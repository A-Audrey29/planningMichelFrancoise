-- Anyone can edit or cancel any booking, from any browser, at any time.
-- Decided by the organiser (family trust: "on s'arrange entre nous").
-- Signatures are unchanged so the already-deployed page keeps working;
-- p_token is now ignored (kept only for compatibility).

create or replace function public.update_meal(p_slot text, p_token uuid, p_name text, p_dish text)
returns void
language plpgsql security definer
set search_path = ''
as $$
begin
  update public.meal_signup
     set name = btrim(p_name), dish = btrim(coalesce(p_dish, '')), updated_at = now()
   where slot = p_slot;
  if not found then
    raise exception 'not_found';
  end if;
end;
$$;

create or replace function public.cancel_meal(p_slot text, p_token uuid)
returns void
language plpgsql security definer
set search_path = ''
as $$
begin
  delete from public.meal_signup where slot = p_slot;
  if not found then
    raise exception 'not_found';
  end if;
end;
$$;

-- Rollback: re-run the update_meal and cancel_meal definitions from 001_meal_signup.sql
-- (token check: "where slot = p_slot and edit_token = p_token", exception 'forbidden').
