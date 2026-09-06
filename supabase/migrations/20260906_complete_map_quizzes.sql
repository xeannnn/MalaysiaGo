-- Complete the quiz catalogue used by the Flutter map.
-- Safe to run more than once: site and question conflicts are updated.

insert into public.quiz_sites
  (site_id, name, icon, location, category, description, difficulty, latitude, longitude)
values
  ('kek_lok_si', 'Kek Lok Si Temple', '🛕', 'Penang · Religious', 'Religious', 'Malaysia''s largest Buddhist temple complex in Air Itam', 'Medium', 5.399018, 100.273544),
  ('cameron_highlands', 'Cameron Highlands', '⛰️', 'Pahang · Nature', 'Nature', 'A cool hill region known for tea estates and mossy forest', 'Easy', 4.469516, 101.379261)
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

insert into public.quiz_questions
  (site_id, display_order, question, options, correct_index, explanation, xp_reward, is_active)
values
  ('batu_caves', 4, 'Batu Caves is located in which Malaysian state?', '["Selangor","Perak","Johor","Pahang"]'::jsonb, 0, 'Batu Caves is in Gombak, Selangor.', 20, true),
  ('batu_caves', 5, 'The main Batu Caves shrine is dedicated to which Hindu deity?', '["Lord Murugan","Lord Ganesha","Lord Krishna","Lord Brahma"]'::jsonb, 0, 'The temple complex is one of the most important shrines dedicated to Lord Murugan.', 20, true),
  ('merdeka_square', 4, 'Which landmark building faces Dataran Merdeka?', '["Sultan Abdul Samad Building","Petronas Towers","Kuala Lumpur Tower","National Mosque"]'::jsonb, 0, 'The Sultan Abdul Samad Building is one of the square''s defining landmarks.', 20, true),
  ('merdeka_square', 5, 'What does the Malay word "merdeka" mean?', '["Independence","Unity","Heritage","Celebration"]'::jsonb, 0, 'Merdeka means independence or freedom.', 20, true),
  ('george_town', 4, 'George Town is the capital of which state?', '["Penang","Perak","Kedah","Selangor"]'::jsonb, 0, 'George Town is the capital city of Penang.', 20, true),
  ('george_town', 5, 'George Town shares its UNESCO listing with which Malaysian city?', '["Malacca City","Ipoh","Kuching","Johor Bahru"]'::jsonb, 0, 'George Town and Malacca are jointly listed as Historic Cities of the Straits of Malacca.', 20, true),
  ('malacca_city', 4, 'What is the name of Malacca''s famous red Dutch building?', '["The Stadthuys","A Famosa","Victoria Memorial Hall","Istana Negara"]'::jsonb, 0, 'The Stadthuys was the administrative centre built during Dutch rule.', 20, true),
  ('malacca_city', 5, 'Which river runs through the historic centre of Malacca?', '["Malacca River","Klang River","Perak River","Pahang River"]'::jsonb, 0, 'The Malacca River flows through the old trading-port centre.', 20, true),
  ('masjid_zahir', 4, 'What colour are Zahir Mosque''s five prominent domes?', '["Black","Blue","Green","Gold"]'::jsonb, 0, 'Its five black domes are a distinctive part of the mosque''s design.', 20, true),
  ('masjid_zahir', 5, 'Zahir Mosque is a major landmark of which Malaysian state?', '["Kedah","Kelantan","Perlis","Terengganu"]'::jsonb, 0, 'The mosque stands in Alor Setar, the capital of Kedah.', 20, true),
  ('lenggong_valley', 4, 'Lenggong Valley is located in which state?', '["Perak","Pahang","Sabah","Negeri Sembilan"]'::jsonb, 0, 'The archaeological heritage valley is in Perak.', 20, true),
  ('lenggong_valley', 5, 'Why is Lenggong Valley internationally important?', '["It preserves evidence of early human history","It was Malaysia''s first airport","It contains a royal palace","It is a modern art district"]'::jsonb, 0, 'Its archaeological sites preserve a very long record of early human activity.', 20, true),
  ('crystal_mosque', 4, 'The Crystal Mosque is part of which attraction?', '["Islamic Heritage Park","Taman Negara","Kinabalu Park","Perdana Botanical Gardens"]'::jsonb, 0, 'The mosque is a landmark within the Islamic Heritage Park.', 20, true),
  ('crystal_mosque', 5, 'The Crystal Mosque is near which city?', '["Kuala Terengganu","Kota Bharu","Kuantan","Alor Setar"]'::jsonb, 0, 'It stands on Wan Man Island near Kuala Terengganu.', 20, true),
  ('taman_negara', 4, 'What was Taman Negara formerly called?', '["King George V National Park","Royal Pahang Reserve","Malayan Jungle Park","Kuala Tahan Forest"]'::jsonb, 0, 'It was known as King George V National Park before being renamed Taman Negara.', 20, true),
  ('taman_negara', 5, 'Which elevated attraction lets visitors walk above the forest floor?', '["Canopy walkway","Sky bridge","Observation wheel","Cliff railway"]'::jsonb, 0, 'The canopy walkway offers an elevated view of the rainforest.', 20, true),
  ('sultan_abu_bakar_mosque', 4, 'In which city is the Sultan Abu Bakar State Mosque?', '["Johor Bahru","Muar","Kluang","Batu Pahat"]'::jsonb, 0, 'The mosque overlooks the Johor Strait from Johor Bahru.', 20, true),
  ('sultan_abu_bakar_mosque', 5, 'Which country can be seen across the Johor Strait?', '["Singapore","Indonesia","Thailand","Brunei"]'::jsonb, 0, 'Singapore lies across the Johor Strait.', 20, true),
  ('kek_lok_si', 1, 'Kek Lok Si Temple is located in which Penang neighbourhood?', '["Air Itam","Batu Ferringhi","Butterworth","Balik Pulau"]'::jsonb, 0, 'The hillside temple complex is in Air Itam.', 20, true),
  ('kek_lok_si', 2, 'Kek Lok Si is associated with which religion?', '["Buddhism","Hinduism","Islam","Sikhism"]'::jsonb, 0, 'Kek Lok Si is a major Buddhist temple complex.', 20, true),
  ('kek_lok_si', 3, 'Which large bodhisattva statue overlooks Kek Lok Si?', '["Kuan Yin","Maitreya","Manjushri","Samantabhadra"]'::jsonb, 0, 'A large bronze statue of Kuan Yin overlooks the temple grounds.', 20, true),
  ('kek_lok_si', 4, 'How many tiers does Kek Lok Si''s main pagoda have?', '["Seven","Five","Nine","Twelve"]'::jsonb, 0, 'The Pagoda of Ten Thousand Buddhas has seven tiers.', 20, true),
  ('kek_lok_si', 5, 'The temple''s pagoda blends Chinese design with which two other traditions?', '["Thai and Burmese","Indian and Persian","Japanese and Korean","Malay and Javanese"]'::jsonb, 0, 'Its architecture combines Chinese, Thai, and Burmese elements.', 20, true),
  ('cameron_highlands', 1, 'Cameron Highlands is located in which state?', '["Pahang","Perak","Selangor","Kelantan"]'::jsonb, 0, 'Cameron Highlands is a highland district in Pahang.', 20, true),
  ('cameron_highlands', 2, 'Which crop is Cameron Highlands especially famous for?', '["Tea","Rice","Cocoa","Pepper"]'::jsonb, 0, 'Its cool climate supports extensive tea plantations.', 20, true),
  ('cameron_highlands', 3, 'Who is Cameron Highlands named after?', '["William Cameron","James Brooke","Francis Light","Henry Gurney"]'::jsonb, 0, 'The highlands are named after British surveyor William Cameron.', 20, true),
  ('cameron_highlands', 4, 'Which forest attraction is known for cool mist and moss-covered trees?', '["Mossy Forest","Taman Negara","Endau-Rompin","Belum Forest"]'::jsonb, 0, 'The Mossy Forest is one of the highlands'' best-known natural attractions.', 20, true),
  ('cameron_highlands', 5, 'Why is Cameron Highlands cooler than much of Malaysia?', '["Its high elevation","It is farther north","It receives sea breezes","It has less rainfall"]'::jsonb, 0, 'Its elevation produces lower temperatures than the surrounding lowlands.', 20, true)
on conflict (site_id, display_order) do update set
  question = excluded.question,
  options = excluded.options,
  correct_index = excluded.correct_index,
  explanation = excluded.explanation,
  xp_reward = excluded.xp_reward,
  is_active = excluded.is_active;
