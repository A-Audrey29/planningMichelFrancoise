-- Add the week of 23–29 Nov 2026 (midi + soir every day).
-- Slots now allowed: 16 Nov soir → 29 Nov soir. Past meals stay in the table (archive).

alter table public.meal_signup drop constraint meal_signup_slot_check;
alter table public.meal_signup add constraint meal_signup_slot_check
  check (slot ~ '^2026-11-(1[6-9]|2[0-9])-(midi|soir)$' and slot <> '2026-11-16-midi');

-- Rollback (fails if rows exist for 23–29 Nov: delete them first, after export):
-- alter table public.meal_signup drop constraint meal_signup_slot_check;
-- alter table public.meal_signup add constraint meal_signup_slot_check
--   check (slot ~ '^2026-11-(1[6-9]|2[0-2])-(midi|soir)$' and slot <> '2026-11-16-midi');
