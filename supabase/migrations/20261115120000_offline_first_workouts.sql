-- Offline-first workouts (dev/decisions.md 21 and 22).
--
-- The active workout now lives on the device and reaches the server only once
-- it is finished, in one call to save_workout. Workouts and manual workouts
-- are identified by a UUID the app creates, so an upload can be retried
-- safely: a workout whose id is already saved is skipped.
--
-- Existing rows keep their data; they get new random UUIDs.

-- 1. Unfinished workouts were only ever read by the server-side recovery,
-- which the app no longer has, and are hidden from history. Their exercises
-- and sets go with them (cascade).
delete from public.workouts where end_time is null;

-- 2. The exercise and set policies compare workouts.id, so they are dropped
-- while the column changes type and recreated unchanged below.
drop policy "Users can read exercises in their workouts" on public.exercises;
drop policy "Users can create exercises in their workouts" on public.exercises;
drop policy "Users can update exercises in their workouts" on public.exercises;
drop policy "Users can delete exercises in their workouts" on public.exercises;
drop policy "Users can read sets in their workouts" on public.exercise_sets;
drop policy "Users can create sets in their workouts" on public.exercise_sets;
drop policy "Users can update sets in their workouts" on public.exercise_sets;
drop policy "Users can delete sets in their workouts" on public.exercise_sets;

-- 3. workouts.id: bigint identity -> uuid. Dropping the old columns also
-- drops the foreign key, the (workout_id, start_time) index and the identity
-- sequence with its grants.
alter table public.workouts
  add column new_id uuid not null default gen_random_uuid();
alter table public.exercises
  add column new_workout_id uuid;

update public.exercises
set new_workout_id = workouts.new_id
from public.workouts
where workouts.id = exercises.workout_id;

alter table public.exercises drop column workout_id;
alter table public.exercises rename column new_workout_id to workout_id;
alter table public.exercises alter column workout_id set not null;

alter table public.workouts drop column id;
alter table public.workouts rename column new_id to id;
alter table public.workouts add primary key (id);

alter table public.exercises
  add constraint exercises_workout_id_fkey
    foreign key (workout_id) references public.workouts (id) on delete cascade;
create index exercises_workout_id_start_time_idx
  on public.exercises (workout_id, start_time);

-- 4. manual_workouts.id: bigint identity -> uuid. Nothing references it.
alter table public.manual_workouts
  add column new_id uuid not null default gen_random_uuid();
alter table public.manual_workouts drop column id;
alter table public.manual_workouts rename column new_id to id;
alter table public.manual_workouts add primary key (id);

-- 5. The policies from step 2, as they were.
create policy "Users can read exercises in their workouts"
  on public.exercises
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.workouts
      where workouts.id = exercises.workout_id
        and workouts.user_id = (select auth.uid())
    )
  );

create policy "Users can create exercises in their workouts"
  on public.exercises
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.workouts
      where workouts.id = exercises.workout_id
        and workouts.user_id = (select auth.uid())
    )
  );

create policy "Users can update exercises in their workouts"
  on public.exercises
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.workouts
      where workouts.id = exercises.workout_id
        and workouts.user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1
      from public.workouts
      where workouts.id = exercises.workout_id
        and workouts.user_id = (select auth.uid())
    )
  );

create policy "Users can delete exercises in their workouts"
  on public.exercises
  for delete
  to authenticated
  using (
    exists (
      select 1
      from public.workouts
      where workouts.id = exercises.workout_id
        and workouts.user_id = (select auth.uid())
    )
  );

create policy "Users can read sets in their workouts"
  on public.exercise_sets
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.exercises
      join public.workouts on workouts.id = exercises.workout_id
      where exercises.id = exercise_sets.exercise_id
        and workouts.user_id = (select auth.uid())
    )
  );

create policy "Users can create sets in their workouts"
  on public.exercise_sets
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.exercises
      join public.workouts on workouts.id = exercises.workout_id
      where exercises.id = exercise_sets.exercise_id
        and workouts.user_id = (select auth.uid())
    )
  );

create policy "Users can update sets in their workouts"
  on public.exercise_sets
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.exercises
      join public.workouts on workouts.id = exercises.workout_id
      where exercises.id = exercise_sets.exercise_id
        and workouts.user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1
      from public.exercises
      join public.workouts on workouts.id = exercises.workout_id
      where exercises.id = exercise_sets.exercise_id
        and workouts.user_id = (select auth.uid())
    )
  );

create policy "Users can delete sets in their workouts"
  on public.exercise_sets
  for delete
  to authenticated
  using (
    exists (
      select 1
      from public.exercises
      join public.workouts on workouts.id = exercises.workout_id
      where exercises.id = exercise_sets.exercise_id
        and workouts.user_id = (select auth.uid())
    )
  );

-- 6. Saves one finished workout with its exercises and sets, all or nothing.
--
-- payload:
--   { id, start_time, end_time, title, location_type,
--     place_name, place_address, place_lat, place_lng,
--     exercises: [ { name, start_time, end_time,
--                    sets: [ { weight, reps, created_at } ] } ] }
--
-- Exercises are numbered and sets ordered by their position in the arrays.
-- The owner is always the caller (auth.uid()), never taken from the payload.
-- If the id is already saved the call changes nothing and returns the id, so
-- the app can retry an upload whose response it never received. Runs as the
-- caller, so row level security still applies to every insert.
create function public.save_workout(payload jsonb)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_caller uuid := (select auth.uid());
  v_workout_id uuid := (payload ->> 'id')::uuid;
  v_inserted_id uuid;
  v_exercise jsonb;
  v_exercise_position bigint;
  v_exercise_id bigint;
  v_set jsonb;
  v_set_position bigint;
begin
  if v_caller is null then
    raise exception 'save_workout needs a signed-in user'
      using errcode = '42501';
  end if;
  if v_workout_id is null
    or payload ->> 'start_time' is null
    or payload ->> 'end_time' is null
    or jsonb_typeof(payload -> 'exercises') is distinct from 'array' then
    raise exception 'save_workout needs id, start_time, end_time and exercises'
      using errcode = '22023';
  end if;

  insert into public.workouts (
    id, user_id, start_time, end_time, created_at, title, location_type,
    place_name, place_address, place_lat, place_lng
  )
  values (
    v_workout_id,
    v_caller,
    (payload ->> 'start_time')::timestamptz,
    (payload ->> 'end_time')::timestamptz,
    now(),
    payload ->> 'title',
    payload ->> 'location_type',
    payload ->> 'place_name',
    payload ->> 'place_address',
    (payload ->> 'place_lat')::double precision,
    (payload ->> 'place_lng')::double precision
  )
  on conflict (id) do nothing
  returning id into v_inserted_id;

  if v_inserted_id is null then
    return v_workout_id;
  end if;

  for v_exercise, v_exercise_position in
    select value, ordinality
    from jsonb_array_elements(payload -> 'exercises') with ordinality
  loop
    insert into public.exercises (
      workout_id, name, start_time, end_time, exercise_number
    )
    values (
      v_workout_id,
      v_exercise ->> 'name',
      (v_exercise ->> 'start_time')::timestamptz,
      (v_exercise ->> 'end_time')::timestamptz,
      v_exercise_position
    )
    returning id into v_exercise_id;

    for v_set, v_set_position in
      select value, ordinality
      from jsonb_array_elements(coalesce(v_exercise -> 'sets', '[]'::jsonb))
        with ordinality
    loop
      insert into public.exercise_sets (
        exercise_id, set_number, reps, weight, created_at
      )
      values (
        v_exercise_id,
        v_set_position - 1,
        (v_set ->> 'reps')::integer,
        (v_set ->> 'weight')::double precision,
        coalesce((v_set ->> 'created_at')::timestamptz, now())
      );
    end loop;
  end loop;

  return v_workout_id;
end;
$$;

revoke all on function public.save_workout(jsonb) from public, anon;
grant execute on function public.save_workout(jsonb) to authenticated;
grant execute on function public.save_workout(jsonb) to service_role;
