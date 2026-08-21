// ============================================================
// BADGE DATA - All 13 Malaysian States
// ============================================================
//
// This file contains all predefined state badges with their
// required heritage sites. Each badge is unlocked progressively
// as users visit heritage sites within that state.
//
// To add a new state badge:
// 1. Add a new StateBadge entry to the list below
// 2. Define the requiredSiteIds (must match actual site IDs)
// 3. Set totalPieces based on number of required sites
// 4. Choose a unique badgeIcon and badgeTheme
//
// ============================================================

import '../models.dart';

/// All predefined state badges for Malaysia
const List<StateBadge> allStateBadges = [
  // ============================================================
  // KLANG VALLEY
  // ============================================================

  StateBadge(
    id: 'badge_kl',
    stateName: 'Kuala Lumpur',
    badgeIcon: '🐅',
    badgeTheme: 'Malayan Tiger',
    requiredSiteIds: [
      'site_klcc',
      'site_pasar_seni',
      'site_perdana_garden',
      'site_merdeka_square',
    ],
    totalPieces: 4,
    description: 'Complete all heritage sites in Kuala Lumpur',
    bonusXp: 150,
  ),

  StateBadge(
    id: 'badge_selangor',
    stateName: 'Selangor',
    badgeIcon: '🏛️',
    badgeTheme: 'Royal Selangor',
    requiredSiteIds: [
      'site_batu_caves',
      'site_mah_meri',
    ],
    totalPieces: 2,
    description: 'Complete all heritage sites in Selangor',
    bonusXp: 150,
  ),

  // ============================================================
  // NORTHERN REGION
  // ============================================================

  StateBadge(
    id: 'badge_penang',
    stateName: 'Penang',
    badgeIcon: '🌴',
    badgeTheme: 'Betel Nut / Penang Bridge',
    requiredSiteIds: [
      'site_fort_cornwallis',
      'site_penang_street_art',
      'site_khoo_kongsi',
      'site_kek_lok_si',
      'site_pinang_peranakan',
    ],
    totalPieces: 5,
    description: 'Complete all heritage sites in Penang',
    bonusXp: 150,
  ),

  StateBadge(
    id: 'badge_perak',
    stateName: 'Perak',
    badgeIcon: '🐃',
    badgeTheme: 'Seladang',
    requiredSiteIds: [
      'site_kellie_castle',
      'site_gua_tempurung',
      'site_perak_museum',
    ],
    totalPieces: 3,
    description: 'Complete all heritage sites in Perak',
    bonusXp: 150,
  ),

  StateBadge(
    id: 'badge_kedah',
    stateName: 'Kedah',
    badgeIcon: '🌾',
    badgeTheme: 'Paddy Field',
    requiredSiteIds: [
      // Add actual site IDs here
    ],
    totalPieces: 1,
    description: 'Complete all heritage sites in Kedah',
    bonusXp: 150,
  ),

  StateBadge(
    id: 'badge_perlis',
    stateName: 'Perlis',
    badgeIcon: '🌿',
    badgeTheme: 'Green Landscape',
    requiredSiteIds: [
      // Add actual site IDs here
    ],
    totalPieces: 1,
    description: 'Complete all heritage sites in Perlis',
    bonusXp: 150,
  ),

  // ============================================================
  // SOUTHERN REGION
  // ============================================================

  StateBadge(
    id: 'badge_melaka',
    stateName: 'Melaka',
    badgeIcon: '🦌',
    badgeTheme: 'Mousedeer (Kancil)',
    requiredSiteIds: [
      'site_afamosa',
      'site_st_paul',
      'site_jonker_street',
      'site_melaka_sultanate',
    ],
    totalPieces: 4,
    description: 'Complete all heritage sites in Melaka',
    bonusXp: 150,
  ),

  StateBadge(
    id: 'badge_johor',
    stateName: 'Johor',
    badgeIcon: '🦁',
    badgeTheme: 'Lion',
    requiredSiteIds: [
      'site_gunung_ledang',
    ],
    totalPieces: 1,
    description: 'Complete all heritage sites in Johor',
    bonusXp: 150,
  ),

  StateBadge(
    id: 'badge_ns',
    stateName: 'Negeri Sembilan',
    badgeIcon: '🐃',
    badgeTheme: 'Buffalo',
    requiredSiteIds: [
      // Add actual site IDs here
    ],
    totalPieces: 1,
    description: 'Complete all heritage sites in Negeri Sembilan',
    bonusXp: 150,
  ),

  // ============================================================
  // EAST COAST REGION
  // ============================================================

  StateBadge(
    id: 'badge_pahang',
    stateName: 'Pahang',
    badgeIcon: '🐘',
    badgeTheme: 'Elephant',
    requiredSiteIds: [
      'site_taman_negara',
    ],
    totalPieces: 1,
    description: 'Complete all heritage sites in Pahang',
    bonusXp: 150,
  ),

  StateBadge(
    id: 'badge_tganu',
    stateName: 'Terengganu',
    badgeIcon: '⛵',
    badgeTheme: 'Fishing Boat',
    requiredSiteIds: [
      // Add actual site IDs here
    ],
    totalPieces: 1,
    description: 'Complete all heritage sites in Terengganu',
    bonusXp: 150,
  ),

  StateBadge(
    id: 'badge_kelantan',
    stateName: 'Kelantan',
    badgeIcon: '🎨',
    badgeTheme: 'Cultural Arts',
    requiredSiteIds: [
      // Add actual site IDs here
    ],
    totalPieces: 1,
    description: 'Complete all heritage sites in Kelantan',
    bonusXp: 150,
  ),

  // ============================================================
  // EAST MALAYSIA (BORNEO)
  // ============================================================

  StateBadge(
    id: 'badge_sarawak',
    stateName: 'Sarawak',
    badgeIcon: '🦅',
    badgeTheme: 'Hornbill',
    requiredSiteIds: [
      'site_sarawak_museum',
      'site_kuching_waterfront',
      'site_semenggoh',
    ],
    totalPieces: 3,
    description: 'Complete all heritage sites in Sarawak',
    bonusXp: 150,
  ),

  StateBadge(
    id: 'badge_sabah',
    stateName: 'Sabah',
    badgeIcon: '🐒',
    badgeTheme: 'Proboscis Monkey',
    requiredSiteIds: [
      'site_mt_kinabalu',
      'site_miso_walai',
      'site_sepilok',
    ],
    totalPieces: 3,
    description: 'Complete all heritage sites in Sabah',
    bonusXp: 150,
  ),
];

// ============================================================
// HELPER FUNCTIONS
// ============================================================

/// Get a badge by its ID
StateBadge? getBadgeById(String id) {
  try {
    return allStateBadges.firstWhere((b) => b.id == id);
  } catch (e) {
    return null;
  }
}

/// Get all badges for a specific state
List<StateBadge> getBadgesByState(String stateName) {
  return allStateBadges.where((b) => b.stateName == stateName).toList();
}

/// Get total number of badges
int getTotalBadges() {
  return allStateBadges.length;
}

/// Get number of completed badges based on visited sites
int getCompletedBadgeCount(Map<String, List<String>> visitedSites) {
  int count = 0;
  for (StateBadge badge in allStateBadges) {
    List<String> visited = visitedSites[badge.id] ?? [];
    if (badge.isComplete(visited)) {
      count++;
    }
  }
  return count;
}

/// Get progress for all badges
List<UserBadgeProgress> getAllBadgeProgress(
    Map<String, List<String>> visitedSites,
    ) {
  List<UserBadgeProgress> progress = [];

  for (StateBadge badge in allStateBadges) {
    List<String> visited = visitedSites[badge.id] ?? [];
    int unlocked = badge.getUnlockedPieces(visited);
    bool complete = badge.isComplete(visited);

    progress.add(UserBadgeProgress(
      badgeId: badge.id,
      stateName: badge.stateName,
      badgeIcon: badge.badgeIcon,
      badgeTheme: badge.badgeTheme,
      totalPieces: badge.totalPieces,
      unlockedPieces: unlocked,
      isComplete: complete,
      bonusXpEarned: complete ? badge.bonusXp : 0,
      bonusClaimed: false,
    ));
  }

  return progress;
}

/// Get total XP earned from badges (bonus XP for completed badges)
int getTotalBadgeBonusXp(Map<String, List<String>> visitedSites) {
  int total = 0;
  for (StateBadge badge in allStateBadges) {
    List<String> visited = visitedSites[badge.id] ?? [];
    if (badge.isComplete(visited)) {
      total += badge.bonusXp;
    }
  }
  return total;
}