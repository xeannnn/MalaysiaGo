-- Give every valid heritage_sites row a quiz and exactly five seeded
-- questions. Safe to run repeatedly: rows are updated by site/order.

insert into public.quiz_sites
  (site_id, name, icon, location, category, description, difficulty,
   latitude, longitude)
select
  h.site_id,
  h.name,
  case lower(coalesce(h.category, ''))
    when 'unesco' then '🏛️'
    when 'religious' then '🛕'
    when 'nature' then '🌳'
    when 'national' then '🇲🇾'
    when 'cultural' then '🎭'
    when 'archaeological' then '🏺'
    else '📍'
  end,
  coalesce(nullif(h.location, ''), 'Malaysia'),
  coalesce(nullif(h.category, ''), 'Heritage'),
  coalesce(
    nullif(h.description, ''),
    'Discover the history and cultural significance of ' || h.name || '.'
  ),
  'Medium',
  h.latitude,
  h.longitude
from public.heritage_sites h
where h.site_id is not null
  and h.site_id <> ''
  and h.site_id <> 'masjid_negara'
  and h.latitude between -90 and 90
  and h.longitude between -180 and 180
  and not (h.latitude = 0 and h.longitude = 0)
on conflict (site_id) do update set
  name = excluded.name,
  icon = excluded.icon,
  location = excluded.location,
  category = excluded.category,
  description = excluded.description,
  difficulty = excluded.difficulty,
  latitude = excluded.latitude,
  longitude = excluded.longitude,
  updated_at = now();

with catalogue as (
  select
    h.site_id,
    h.name,
    coalesce(nullif(h.location, ''), 'Malaysia') as location,
    coalesce(nullif(h.category, ''), 'Heritage') as category,
    coalesce(
      nullif(h.description, ''),
      'A Malaysian heritage destination.'
    ) as description,
    h.latitude,
    h.longitude,
    greatest(coalesce(h.xp, 50), 1)::integer as visit_xp
  from public.heritage_sites h
  where h.site_id is not null
    and h.site_id <> ''
    and h.site_id <> 'masjid_negara'
    and h.latitude between -90 and 90
    and h.longitude between -180 and 180
    and not (h.latitude = 0 and h.longitude = 0)
), question_rows as (
  select
    c.site_id,
    q.display_order,
    q.question,
    q.options,
    q.correct_index,
    q.explanation,
    20::smallint as xp_reward,
    true as is_active
  from catalogue c
  cross join lateral (
    select array_agg(other_name order by md5(c.site_id || other_name)) as names
    from (
      select distinct c2.name as other_name
      from catalogue c2
      where c2.site_id <> c.site_id
      limit 12
    ) candidates
  ) other_names
  cross join lateral (
    select array_agg(other_location order by md5(c.site_id || other_location)) as locations
    from (
      select distinct c3.location as other_location
      from catalogue c3
      where c3.location <> c.location
      limit 12
    ) candidates
  ) other_locations
  cross join lateral (
    select array_agg(other_category order by md5(c.site_id || other_category)) as categories
    from unnest(array[
      'UNESCO', 'Religious', 'Nature', 'National',
      'Cultural', 'Archaeological', 'Historical'
    ]) as other_category
    where lower(other_category) <> lower(c.category)
  ) other_categories
  cross join lateral (
    values
      (
        1::smallint,
        'Where in Malaysia is ' || c.name || ' located?',
        jsonb_build_array(
          c.location,
          other_locations.locations[1],
          other_locations.locations[2],
          other_locations.locations[3]
        ),
        0::smallint,
        c.name || ' is located in ' || c.location || '.'
      ),
      (
        2::smallint,
        'Which category best describes ' || c.name || '?',
        jsonb_build_array(
          c.category,
          other_categories.categories[1],
          other_categories.categories[2],
          other_categories.categories[3]
        ),
        0::smallint,
        c.name || ' is listed in the ' || c.category || ' category.'
      ),
      (
        3::smallint,
        'Which heritage site matches this description: "' ||
          left(c.description, 180) || '"?',
        jsonb_build_array(
          c.name,
          other_names.names[1],
          other_names.names[2],
          other_names.names[3]
        ),
        0::smallint,
        'The description refers to ' || c.name || '.'
      ),
      (
        4::smallint,
        'Which site is positioned near ' ||
          round(c.latitude::numeric, 3)::text || '° latitude and ' ||
          round(c.longitude::numeric, 3)::text || '° longitude?',
        jsonb_build_array(
          c.name,
          other_names.names[2],
          other_names.names[3],
          other_names.names[4]
        ),
        0::smallint,
        'Those coordinates identify ' || c.name || '.'
      ),
      (
        5::smallint,
        'How much check-in XP is awarded at ' || c.name || '?',
        jsonb_build_array(
          c.visit_xp::text || ' XP',
          (c.visit_xp + 10)::text || ' XP',
          (c.visit_xp + 20)::text || ' XP',
          (c.visit_xp + 30)::text || ' XP'
        ),
        0::smallint,
        'A verified check-in at ' || c.name || ' awards ' ||
          c.visit_xp::text || ' XP.'
      )
  ) q(display_order, question, options, correct_index, explanation)
)
insert into public.quiz_questions
  (site_id, display_order, question, options, correct_index, explanation,
   xp_reward, is_active)
select
  site_id,
  display_order,
  question,
  options,
  correct_index,
  explanation,
  xp_reward,
  is_active
from question_rows
on conflict (site_id, display_order) do update set
  question = excluded.question,
  options = excluded.options,
  correct_index = excluded.correct_index,
  explanation = excluded.explanation,
  xp_reward = excluded.xp_reward,
  is_active = excluded.is_active;

-- Keep public clients read-only while allowing the app to load every quiz.
alter table public.quiz_sites enable row level security;
alter table public.quiz_questions enable row level security;

drop policy if exists "Public can read quiz sites" on public.quiz_sites;
create policy "Public can read quiz sites"
  on public.quiz_sites for select using (true);

drop policy if exists "Public can read active quiz questions"
  on public.quiz_questions for select using (is_active);
