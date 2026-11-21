-- Exercise types. Everything saved before this is strength. A cardio
-- exercise has no sets; its time is in lap_seconds, one entry per lap in
-- order, and its active time is their sum.
alter table public.exercises
  add column type text not null default 'strength'
    constraint exercises_type_check check (type in ('strength', 'cardio')),
  add column lap_seconds integer[] not null default '{}';

-- As before, but each exercise's type and laps are saved too. A payload from
-- an older app has neither, which means strength with no laps.
create or replace function public.save_workout(payload jsonb)
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
  v_lap_seconds integer[];
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
    v_lap_seconds := '{}';
    if jsonb_typeof(v_exercise -> 'lap_seconds') = 'array' then
      select coalesce(array_agg(lap.value::integer order by lap.ordinality), '{}')
      into v_lap_seconds
      from jsonb_array_elements_text(v_exercise -> 'lap_seconds')
        with ordinality as lap(value, ordinality);
    end if;

    insert into public.exercises (
      workout_id, name, start_time, end_time, exercise_number, type,
      lap_seconds
    )
    values (
      v_workout_id,
      v_exercise ->> 'name',
      (v_exercise ->> 'start_time')::timestamptz,
      (v_exercise ->> 'end_time')::timestamptz,
      v_exercise_position,
      coalesce(v_exercise ->> 'type', 'strength'),
      v_lap_seconds
    )
    returning id into v_exercise_id;

    for v_set, v_set_position in
      select value, ordinality
      from jsonb_array_elements(coalesce(v_exercise -> 'sets', '[]'::jsonb))
        with ordinality
    loop
      insert into public.exercise_sets (
        exercise_id, set_number, reps, weight, unit, created_at
      )
      values (
        v_exercise_id,
        v_set_position - 1,
        (v_set ->> 'reps')::integer,
        (v_set ->> 'weight')::double precision,
        coalesce(v_set ->> 'unit', 'kg'),
        coalesce((v_set ->> 'created_at')::timestamptz, now())
      );
    end loop;
  end loop;

  return v_workout_id;
end;
$$;
