// ============================================================
// TIPS SERVICE (LOCAL SITE & CATEGORY ADVICE PROVIDER)
// ============================================================

class TipsService {
  // 1. Specific curated tips for major Malaysian landmarks
  static final Map<String, List<String>> _siteSpecificTips = {
    'batu caves': [
      "Arrive before 8 AM to beat the crowds and the heat",
      "Dress modestly — shoulders and knees must be covered",
      "Watch for cheeky macaques near the steps",
      "The Thaipusam festival here draws over 1.5 million visitors",
    ],
    'george town': [
      "Rent a bicycle or grab a trishaw to explore street art murals",
      "Visit Clan Jetties during late afternoon for sunset views",
      "Try local street food like Char Kway Teow along Chulia Street",
      "Stay hydrated as humidity levels are very high",
    ],
    'kinabalu': [
      "Book climbing permits at least 6 months in advance",
      "Bring warm layered clothing for the cold summit winds",
      "Pack rain protection as mountain weather changes quickly",
    ],
    'sultan abdul samad': [
      "Best photographed during evening hours when fully illuminated",
      "Combine with a visit to nearby Dataran Merdeka and River of Life",
      "Watch out for traffic when taking pictures across the street",
    ],
  };

  // 2. Category-based default tips
  static final Map<String, List<String>> _categoryTips = {
    'Religious': [
      "Dress modestly — shoulders and knees should be covered",
      "Remove your shoes before entering main prayer halls",
      "Keep your voice low and respect ongoing religious services",
      "Ask for permission before taking photos of worshippers",
    ],
    'UNESCO': [
      "Check visitor centre operational hours before heading over",
      "Hire an accredited local guide to learn the detailed history",
      "Wear comfortable walking shoes for long heritage walking trails",
    ],
    'Nature': [
      "Apply eco-friendly insect repellent and sunblock",
      "Carry reusable water bottles to minimize plastic waste",
      "Stay on designated trails to avoid disturbing local wildlife",
      "Check weather forecasts before hiking or outdoor exploration",
    ],
    'National': [
      "Look out for historical markers and information plaques",
      "Best visited during early morning hours for clear photos",
      "Check for local admission fees or security checkpoints",
    ],
  };

  // 3. Main Resolver Function
  static List<String> getTips({required String name, required String category}) {
    final lowerName = name.toLowerCase();

    // Check 1: Match site name keywords
    for (final entry in _siteSpecificTips.entries) {
      if (lowerName.contains(entry.key)) {
        return entry.value;
      }
    }

    // Check 2: Match Category
    if (_categoryTips.containsKey(category)) {
      return _categoryTips[category]!;
    }

    // Check 3: Generic fallback tips
    return const [
      "Wear comfortable walking shoes for exploring",
      "Stay hydrated and bring sun protection",
      "Keep your belongings secure in high-traffic areas",
    ];
  }
}