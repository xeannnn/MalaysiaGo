// ============================================================
// BADGE DATA - 13 Malaysian States + 3 Federal Territories
// ============================================================
//
// Each badge contains the 4 heritage sites used by the nationwide
// Heritage Explorer dataset (64 sites total).
//
// IMPORTANT:
// - requiredSiteIds must match heritage_sites.site_id in Supabase.
// - totalPieces should match requiredSiteIds.length.
// ============================================================

import '../models.dart';

/// All predefined state / federal territory badges for Malaysia.
const List<StateBadge> allStateBadges = [
  // ============================================================
  // SOUTHERN REGION
  // ============================================================
  StateBadge(
    id: 'badge_johor',
    stateName: 'Johor',
    badgeIcon: '🦁',
    badgeTheme: 'Southern Heritage',
    requiredSiteIds: [
      'sultan_abu_bakar_mosque',
      'johor_bahru_old_chinese_temple',
      'kota_johor_lama',
      'tanjung_piai',
    ],
    totalPieces: 4,
    description: 'Complete all featured heritage sites in Johor',
    bonusXp: 150,
  ),

  StateBadge(
    id: 'badge_melaka',
    stateName: 'Melaka',
    badgeIcon: '🦌',
    badgeTheme: 'Historic Melaka',
    requiredSiteIds: [
      'malacca_city',
      'a_famosa',
      'stadthuys',
      'cheng_hoon_teng',
    ],
    totalPieces: 4,
    description: 'Complete all featured heritage sites in Melaka',
    bonusXp: 150,
  ),

  StateBadge(
    id: 'badge_ns',
    stateName: 'Negeri Sembilan',
    badgeIcon: '🐃',
    badgeTheme: 'Minangkabau Heritage',
    requiredSiteIds: [
      'seri_menanti_royal_museum',
      'pengkalan_kempas',
      'negeri_sembilan_state_museum',
      'centipede_temple',
    ],
    totalPieces: 4,
    description: 'Complete all featured heritage sites in Negeri Sembilan',
    bonusXp: 150,
  ),

  // ============================================================
  // NORTHERN REGION
  // ============================================================
  StateBadge(
    id: 'badge_kedah',
    stateName: 'Kedah',
    badgeIcon: '🌾',
    badgeTheme: 'Paddy Heritage',
    requiredSiteIds: [
      'masjid_zahir',
      'bujang_valley',
      'bukit_choras',
      'balai_besar_alor_setar',
    ],
    totalPieces: 4,
    description: 'Complete all featured heritage sites in Kedah',
    bonusXp: 150,
  ),

  StateBadge(
    id: 'badge_penang',
    stateName: 'Penang',
    badgeIcon: '🌴',
    badgeTheme: 'Pearl of the Orient',
    requiredSiteIds: [
      'george_town',
      'kek_lok_si',
      'fort_cornwallis',
      'khoo_kongsi',
    ],
    totalPieces: 4,
    description: 'Complete all featured heritage sites in Penang',
    bonusXp: 150,
  ),

  StateBadge(
    id: 'badge_perak',
    stateName: 'Perak',
    badgeIcon: '🐃',
    badgeTheme: 'Silver State Heritage',
    requiredSiteIds: [
      'lenggong_valley',
      'kellies_castle',
      'perak_museum',
      'taiping_lake_gardens',
    ],
    totalPieces: 4,
    description: 'Complete all featured heritage sites in Perak',
    bonusXp: 150,
  ),

  StateBadge(
    id: 'badge_perlis',
    stateName: 'Perlis',
    badgeIcon: '🌿',
    badgeTheme: 'Northern Heritage',
    requiredSiteIds: [
      'state_secretariat_perlis',
      'kota_kayang_museum',
      'alwi_mosque',
      'gua_kelam',
    ],
    totalPieces: 4,
    description: 'Complete all featured heritage sites in Perlis',
    bonusXp: 150,
  ),

  // ============================================================
  // EAST COAST REGION
  // ============================================================
  StateBadge(
    id: 'badge_kelantan',
    stateName: 'Kelantan',
    badgeIcon: '🎨',
    badgeTheme: 'Cultural Arts',
    requiredSiteIds: [
      'istana_jahar',
      'masjid_muhammadi',
      'gua_cha',
      'muzium_negeri_kelantan',
    ],
    totalPieces: 4,
    description: 'Complete all featured heritage sites in Kelantan',
    bonusXp: 150,
  ),

  StateBadge(
    id: 'badge_pahang',
    stateName: 'Pahang',
    badgeIcon: '🐘',
    badgeTheme: 'Nature & Heritage',
    requiredSiteIds: [
      'cameron_highlands',
      'taman_negara',
      'sungai_lembing',
      'sultan_ahmad_1_mosque',
    ],
    totalPieces: 4,
    description: 'Complete all featured heritage sites in Pahang',
    bonusXp: 150,
  ),

  StateBadge(
    id: 'badge_tganu',
    stateName: 'Terengganu',
    badgeIcon: '⛵',
    badgeTheme: 'East Coast Heritage',
    requiredSiteIds: [
      'crystal_mosque',
      'terengganu_state_museum',
      'masjid_tengku_tengah_zaharah',
      'terengganu_inscription_stone_site',
    ],
    totalPieces: 4,
    description: 'Complete all featured heritage sites in Terengganu',
    bonusXp: 150,
  ),

  // ============================================================
  // CENTRAL REGION
  // ============================================================
  StateBadge(
    id: 'badge_selangor',
    stateName: 'Selangor',
    badgeIcon: '🏛️',
    badgeTheme: 'Selangor Heritage',
    requiredSiteIds: [
      'batu_caves',
      'frim_forest_park',
      'sultan_salahuddin_mosque',
      'sungai_buloh_leprosarium',
    ],
    totalPieces: 4,
    description: 'Complete all featured heritage sites in Selangor',
    bonusXp: 150,
  ),

  StateBadge(
    id: 'badge_kl',
    stateName: 'Kuala Lumpur',
    badgeIcon: '🐅',
    badgeTheme: 'Capital Heritage',
    requiredSiteIds: [
      'merdeka_square',
      'sultan_abdul_samad',
      'national_mosque',
      'national_museum',
      'tarumt_kl',
      'petronas_towers',
    ],
    totalPieces: 6,
    description: 'Complete all featured heritage sites in Kuala Lumpur',
    bonusXp: 150,
  ),

  StateBadge(
    id: 'badge_putrajaya',
    stateName: 'Putrajaya',
    badgeIcon: '🏙️',
    badgeTheme: 'Administrative Capital',
    requiredSiteIds: [
      'putra_mosque',
      'perdana_putra',
      'putra_square',
      'seri_wawasan_bridge',
    ],
    totalPieces: 4,
    description: 'Complete all featured heritage sites in Putrajaya',
    bonusXp: 150,
  ),

  // ============================================================
  // EAST MALAYSIA
  // ============================================================
  StateBadge(
    id: 'badge_sabah',
    stateName: 'Sabah',
    badgeIcon: '🐒',
    badgeTheme: 'Land Below the Wind',
    requiredSiteIds: [
      'kinabalu_park',
      'sabah_state_museum',
      'agnes_keith_house',
      'bukit_tengkorak',
    ],
    totalPieces: 4,
    description: 'Complete all featured heritage sites in Sabah',
    bonusXp: 150,
  ),

  StateBadge(
    id: 'badge_sarawak',
    stateName: 'Sarawak',
    badgeIcon: '🦅',
    badgeTheme: 'Land of the Hornbills',
    requiredSiteIds: [
      'gunung_mulu',
      'niah_national_park',
      'fort_margherita',
      'sarawak_cultural_village',
    ],
    totalPieces: 4,
    description: 'Complete all featured heritage sites in Sarawak',
    bonusXp: 150,
  ),

  StateBadge(
    id: 'badge_labuan',
    stateName: 'Labuan',
    badgeIcon: '⚓',
    badgeTheme: 'Island Heritage',
    requiredSiteIds: [
      'labuan_war_cemetery',
      'chimney_museum_labuan',
      'peace_park_labuan',
      'surrender_point_labuan',
    ],
    totalPieces: 4,
    description: 'Complete all featured heritage sites in Labuan',
    bonusXp: 150,
  ),
];

/// Every badge above is backed by heritage sites currently available in the app.
List<StateBadge> get activeStateBadges => allStateBadges
    .where((badge) => badge.requiredSiteIds.isNotEmpty)
    .toList(growable: false);

// ============================================================
// HELPER FUNCTIONS
// ============================================================

StateBadge? getBadgeById(String id) {
  try {
    return allStateBadges.firstWhere((b) => b.id == id);
  } catch (e) {
    return null;
  }
}

List<StateBadge> getBadgesByState(String stateName) {
  return allStateBadges.where((b) => b.stateName == stateName).toList();
}

int getTotalBadges() {
  return activeStateBadges.length;
}

int getCompletedBadgeCount(Map<String, List<String>> visitedSites) {
  int count = 0;

  for (StateBadge badge in activeStateBadges) {
    final List<String> visited = visitedSites[badge.id] ?? [];
    if (badge.isComplete(visited)) {
      count++;
    }
  }

  return count;
}

List<UserBadgeProgress> getAllBadgeProgress(
  Map<String, List<String>> visitedSites,
) {
  final List<UserBadgeProgress> progress = [];

  for (StateBadge badge in activeStateBadges) {
    final List<String> visited = visitedSites[badge.id] ?? [];
    final int unlocked = badge.getUnlockedPieces(visited);
    final bool complete = badge.isComplete(visited);

    progress.add(
      UserBadgeProgress(
        badgeId: badge.id,
        stateName: badge.stateName,
        badgeIcon: badge.badgeIcon,
        badgeTheme: badge.badgeTheme,
        totalPieces: badge.totalPieces,
        unlockedPieces: unlocked,
        isComplete: complete,
        bonusXpEarned: complete ? badge.bonusXp : 0,
        bonusClaimed: false,
      ),
    );
  }

  return progress;
}

int getTotalBadgeBonusXp(Map<String, List<String>> visitedSites) {
  int total = 0;

  for (StateBadge badge in activeStateBadges) {
    final List<String> visited = visitedSites[badge.id] ?? [];
    if (badge.isComplete(visited)) {
      total += badge.bonusXp;
    }
  }

  return total;
}
