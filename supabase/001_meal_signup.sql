-- Meal sign-up for Michel & Françoise (16–22 Nov 2026).
-- One person per meal: the slot id is the primary key.
-- The table is never exposed directly: anon users go through the functions below.

create table public.meal_signup (
  slot text primary key
    check (slot ~ '^2026-11-(1[6-9]|2[0-2])-(midi|soir)$' and slot <> '2026-11-16-midi'),
  name text not null check (char_length(btrim(name)) between 1 and 80),
  dish text not null check (char_length(btrim(dish)) between 1 and 300),
  edit_token uuid not null default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.meal_signup enable row level security;
revoke all on table public.meal_signup from anon, authenticated;

-- Deadline of a slot: 12:00 for "midi", 18:00 for "soir", Paris time.
create function public.slot_deadline(p_slot text)
returns timestamptz
language sql stable
set search_path = ''
as $$
  select ((left(p_slot, 10) || case when right(p_slot, 4) = 'midi' then ' 12:00' else ' 18:00' end)::timestamp
          at time zone 'Europe/Paris');
$$;

-- Public list (no edit_token).
create function public.get_meals()
returns table (slot text, name text, dish text)
language sql stable security definer
set search_path = ''
as $$
  select m.slot, m.name, m.dish from public.meal_signup m order by m.slot;
$$;

-- Book a free slot. Returns the secret token that allows editing/cancelling.
create function public.book_meal(p_slot text, p_name text, p_dish text)
returns uuid
language plpgsql security definer
set search_path = ''
as $$
declare
  v_token uuid;
begin
  if now() > public.slot_deadline(p_slot) then
    raise exception 'past';
  end if;
  insert into public.meal_signup (slot, name, dish)
  values (p_slot, btrim(p_name), btrim(coalesce(p_dish, '')))
  returning edit_token into v_token;
  return v_token;
exception
  when unique_violation then raise exception 'taken';
end;
$$;

-- Edit own booking (token required).
create function public.update_meal(p_slot text, p_token uuid, p_name text, p_dish text)
returns void
language plpgsql security definer
set search_path = ''
as $$
begin
  update public.meal_signup
     set name = btrim(p_name), dish = btrim(coalesce(p_dish, '')), updated_at = now()
   where slot = p_slot and edit_token = p_token;
  if not found then
    raise exception 'forbidden';
  end if;
end;
$$;

-- Cancel own booking (token required).
create function public.cancel_meal(p_slot text, p_token uuid)
returns void
language plpgsql security definer
set search_path = ''
as $$
begin
  delete from public.meal_signup where slot = p_slot and edit_token = p_token;
  if not found then
    raise exception 'forbidden';
  end if;
end;
$$;

revoke execute on function public.slot_deadline(text) from public, anon, authenticated;
revoke execute on function public.get_meals() from public;
revoke execute on function public.book_meal(text, text, text) from public;
revoke execute on function public.update_meal(text, uuid, text, text) from public;
revoke execute on function public.cancel_meal(text, uuid) from public;
grant execute on function public.get_meals() to anon, authenticated;
grant execute on function public.book_meal(text, text, text) to anon, authenticated;
grant execute on function public.update_meal(text, uuid, text, text) to anon, authenticated;
grant execute on function public.cancel_meal(text, uuid) to anon, authenticated;

-- Rollback:
-- drop function public.cancel_meal(text, uuid);
-- drop function public.update_meal(text, uuid, text, text);
-- drop function public.book_meal(text, text, text);
-- drop function public.get_meals();
-- drop function public.slot_deadline(text);
-- drop table public.meal_signup;
