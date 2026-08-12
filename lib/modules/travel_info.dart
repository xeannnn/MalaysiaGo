import 'package:flutter/material.dart';

class TravelInfoPage extends StatefulWidget {
  final int totalXp;
  const TravelInfoPage({super.key, required this.totalXp});

  @override
  State<TravelInfoPage> createState() => _TravelInfoPageState();
}

class _TravelInfoPageState extends State<TravelInfoPage> {
  int _selectedSubTab = 0; // 0: Transport, 1: Etiquette, 2: Safety

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Hero Banner
          _buildHeroBanner(),
          const SizedBox(height: 16),

          // 2. Sub-Category Tabs (Transport / Etiquette / Safety)
          _buildSubTabSelector(),
          const SizedBox(height: 12),

          // Sub-description text
          Text(
            _selectedSubTab == 0
                ? 'Getting around Malaysia is easy with its modern transport network.'
                : _selectedSubTab == 1
                ? "Malaysia's rich multicultural society has a few customs worth knowing before you visit."
                : "Malaysia is a safe destination for most travellers. Here's what to be aware of.",
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 16),

          // 3. Dynamic content list based on selected sub-tab
          if (_selectedSubTab == 0) ...[
            _buildTransportCards(),
          ] else if (_selectedSubTab == 1) ...[
            _buildEtiquetteCards(),
          ] else ...[
            _buildSafetyCards(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F756B), Color(0xFF1E3C72), Color(0xFF2A5298)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Essential Reading',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 4),
          Text(
            'Travel in Malaysia',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            'Transport · Etiquette · Safety',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTabSelector() {
    final tabs = [
      {'icon': Icons.directions_subway, 'label': 'Transport'},
      {'icon': Icons.handshake_outlined, 'label': 'Etiquette'},
      {'icon': Icons.shield_outlined, 'label': 'Safety'},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F2F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedSubTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedSubTab = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                      : [],
                ),
                child: Column(
                  children: [
                    Icon(
                      tabs[index]['icon'] as IconData,
                      size: 20,
                      color: isSelected ? const Color(0xFF1E3C72) : Colors.black45,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tabs[index]['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.black : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ==================== 1. TRANSPORT SECTION ====================
  Widget _buildTransportCards() {
    return Column(
      children: const [
        _TransportCard(
          title: 'KTM Komuter',
          priceRange: 'RM1.00 – RM9.80',
          headerColor: Color(0xFFDCEBFE),
          badgeColor: Color(0xFF2563EB),
          description:
          'Intercity rail linking KL Sentral to Seremban, Rawang, Port Klang, and Batu Caves. Ideal for visiting suburban heritage sites.',
          tips: [
            'Buy a Touch \'n Go card for seamless travel across all rail lines',
            'Trains run approx every 20–30 min; check MyRapid app for live schedules',
            'KL Sentral is the main interchange hub for all rail services',
          ],
        ),
        SizedBox(height: 16),
        _TransportCard(
          title: 'MRT / LRT',
          priceRange: 'RM1.20 – RM5.00',
          headerColor: Color(0xFFEDE9FE),
          badgeColor: Color(0xFF7C3AED),
          description:
          'Urban metro network covering Kuala Lumpur and the Klang Valley. MRT Putrajaya Line, Kajang Line, and LRT Kelana Jaya & Ampang lines.',
          tips: [
            'Runs from ~6 AM to midnight daily',
            'Women-only coaches are marked — please respect the signage',
            'Off-peak travel (before 7 AM or after 9 AM) is significantly less crowded',
          ],
        ),
        SizedBox(height: 16),
        _TransportCard(
          title: 'Bus (RapidKL)',
          priceRange: 'Free (GoKL) – RM2.50',
          headerColor: Color(0xFFE0F2FE),
          badgeColor: Color(0xFF0284C7),
          description:
          'Extensive bus network across the Klang Valley. GoKL City Bus offers free service within central KL on 4 colour-coded routes.',
          tips: [
            'GoKL routes (Red, Blue, Green, Purple) are free — great for heritage areas',
            'Download MyRapid or Moovit app for real-time bus tracking',
            'Exact change helpful; Touch \'n Go accepted on most routes',
          ],
        ),
        SizedBox(height: 16),
        _TransportCard(
          title: 'Grab',
          priceRange: 'From RM8 (city trips)',
          headerColor: Color(0xFFDCFCE7),
          badgeColor: Color(0xFF16A34A),
          description:
          'Southeast Asia\'s leading ride-hailing app. Available in all major Malaysian cities, including airport transfers and food delivery.',
          tips: [
            'Book via the Grab app; payment by card, e-wallet, or cash',
            'GrabCar Pool is the most affordable option for solo travellers',
            'Surge pricing applies during peak hours and rain — plan accordingly',
          ],
        ),
        SizedBox(height: 16),
        _TransportCard(
          title: 'Intercity Bus',
          priceRange: 'RM10 – RM60',
          headerColor: Color(0xFFFEF3C7),
          badgeColor: Color(0xFFD97706),
          description:
          'Long-distance buses connect KL to Penang, Malacca, Ipoh, JB, and East Malaysia. Operators: Transnational, Aeroline, CatchThatBus.',
          tips: [
            'Book via CatchThatBus or BusOnlineTicket for the best prices',
            'Premium coach seats recline flat — worth it for overnight journeys',
            'Terminal Bersepadu Selatan (TBS) is KL\'s main intercity bus hub',
          ],
        ),
        SizedBox(height: 16),
        _TransportCard(
          title: 'Ferry',
          priceRange: 'RM12 – RM70',
          headerColor: Color(0xFFE0F2FE),
          badgeColor: Color(0xFF0284C7),
          description:
          'Essential for island destinations: Langkawi (from Kuala Kedah/Kuala Perlis), Penang (from Butterworth), and Perhentian Islands.',
          tips: [
            'Langkawi ferries run multiple times daily; book in advance during school holidays',
            'Penang ferry from Butterworth takes just 20 min (pedestrians only)',
            'Perhentian and Redang services operate Mar–Oct only (monsoon off-season)',
          ],
        ),
      ],
    );
  }

  // ==================== 2. ETIQUETTE SECTION ====================
  Widget _buildEtiquetteCards() {
    return Column(
      children: const [
        _EtiquetteCard(
          title: 'Dress Code at Religious Sites',
          iconEmoji: '🕌',
          headerColor: Color(0xFFFEF3C7),
          titleColor: Color(0xFF9A3412),
          checkColor: Color(0xFFD97706),
          checkBgColor: Color(0xFFFEF3C7),
          items: [
            'Cover shoulders and knees at mosques, temples, and shrines',
            'Remove footwear before entering all places of worship',
            'Headscarves (tudung) may be required for women at mosques — loaners are usually available',
            'Avoid tight-fitting or revealing clothing in religious precincts',
          ],
        ),
        SizedBox(height: 16),
        _EtiquetteCard(
          title: 'Greetings & Social Customs',
          iconEmoji: '🤝',
          headerColor: Color(0xFFDCFCE7),
          titleColor: Color(0xFF15803D),
          checkColor: Color(0xFF16A34A),
          checkBgColor: Color(0xFFDCFCE7),
          items: [
            '"Salam" (a light touch to the heart after a handshake) is the traditional Malay greeting',
            'Use your right hand when giving or receiving anything — using the left is impolite',
            'Address elders and strangers respectfully: "Encik" (Mr) and "Cik/Puan" (Ms/Mrs)',
            'Pointing with the index finger is considered rude — use your thumb instead',
          ],
        ),
        SizedBox(height: 16),
        _EtiquetteCard(
          title: 'Dining Etiquette',
          iconEmoji: '🍽️',
          headerColor: Color(0xFFEDE9FE),
          titleColor: Color(0xFF6D28D9),
          checkColor: Color(0xFF7C3AED),
          checkBgColor: Color(0xFFEDE9FE),
          items: [
            'Say "Selamat makan!" (bon appétit) before a shared meal',
            'Many Malaysians are Muslim — avoid pork and confirm halal status at unfamiliar eateries',
            'Tipping is not customary; a service charge (10%) is often included in bills',
            'It is polite to wait for the eldest or host to start eating first',
          ],
        ),
        SizedBox(height: 16),
        _EtiquetteCard(
          title: 'Photography Etiquette',
          iconEmoji: '📸',
          headerColor: Color(0xFFE0F2FE),
          titleColor: Color(0xFF0369A1),
          checkColor: Color(0xFF0284C7),
          checkBgColor: Color(0xFFE0F2FE),
          items: [
            'Always ask permission before photographing individuals, especially in rural or indigenous communities',
            'No photography inside most prayer halls; look for signage at each site',
            'Avoid photographing people eating during Ramadan in Muslim communities',
            'Drone usage requires CAAM permits; flying near heritage sites may be restricted',
          ],
        ),
        SizedBox(height: 16),
        _EtiquetteCard(
          title: 'Cultural Sensitivity',
          iconEmoji: '🌺',
          headerColor: Color(0xFFFCE7F3),
          titleColor: Color(0xFFBE185D),
          checkColor: Color(0xFFDB2777),
          checkBgColor: Color(0xFFFCE7F3),
          items: [
            'Malaysia is a multicultural society — show equal respect for Malay, Chinese, and Indian traditions',
            'During Ramadan, avoid eating and drinking in public in predominantly Muslim areas during daylight',
            'Public displays of affection are frowned upon in conservative areas',
            'Bargaining is expected in markets; maintain a good-natured tone throughout',
          ],
        ),
        SizedBox(height: 16),
        _EtiquetteCard(
          title: 'Home & Homestay Visits',
          iconEmoji: '🏡',
          headerColor: Color(0xFFECFDF5),
          titleColor: Color(0xFF047857),
          checkColor: Color(0xFF059669),
          checkBgColor: Color(0xFFECFDF5),
          items: [
            'Remove shoes at the entrance — always, without needing to be asked',
            'Bring a small gift of fruit, cakes, or sweets when visiting a Malaysian home',
            'Accept offered food and drink graciously — declining can be perceived as rude',
            'Sit cross-legged or with legs tucked to one side; never point feet toward others',
          ],
        ),
      ],
    );
  }

  // ==================== 3. SAFETY SECTION ====================
  Widget _buildSafetyCards() {
    return Column(
      children: const [
        _SafetyCard(
          title: 'General Safety',
          iconEmoji: '🛡️',
          badgeText: 'Low Risk',
          headerColor: Color(0xFFDCFCE7),
          titleColor: Color(0xFF15803D),
          badgeColor: Color(0xFF16A34A),
          badgeBgColor: Color(0xFFBBF7D0),
          bulletColor: Color(0xFF16A34A),
          items: [
            'Malaysia is generally safe for tourists; violent crime against visitors is uncommon',
            'Stick to well-lit, populated areas at night, especially in city centres',
            'Keep a photocopy of your passport and store originals securely',
            'Register with your country\'s embassy for updates during extended stays',
          ],
        ),
        SizedBox(height: 16),
        _SafetyCard(
          title: 'Petty Crime',
          iconEmoji: '👜',
          badgeText: 'Moderate Risk',
          headerColor: Color(0xFFFEF3C7),
          titleColor: Color(0xFFB45309),
          badgeColor: Color(0xFFD97706),
          badgeBgColor: Color(0xFFFDE68A),
          bulletColor: Color(0xFFD97706),
          items: [
            'Bag snatching (including from motorcyclists) occurs — carry bags away from the roadside',
            'Be vigilant with smartphones and cameras in crowded tourist areas',
            'Use ATMs in banks or well-lit malls rather than isolated street machines',
            'Avoid displaying large amounts of cash or expensive jewellery in public',
          ],
        ),
        SizedBox(height: 16),
        _SafetyCard(
          title: 'Health & Medical',
          iconEmoji: '💊',
          badgeText: 'Prepare Ahead',
          headerColor: Color(0xFFE0F2FE),
          titleColor: Color(0xFF0369A1),
          badgeColor: Color(0xFF0284C7),
          badgeBgColor: Color(0xFFBAE6FD),
          bulletColor: Color(0xFF0284C7),
          items: [
            'Tap water is treated but drinking bottled water is recommended for visitors',
            'Dengue fever is present year-round — use mosquito repellent (DEET-based), especially after rain',
            'Malaysia has excellent private hospitals; ensure you have comprehensive travel insurance',
            'Government (Klinik Kesihatan) clinics are affordable; private clinics are faster for minor issues',
          ],
        ),
        SizedBox(height: 16),
        _SafetyCard(
          title: 'Natural Hazards',
          iconEmoji: '🌧️',
          badgeText: 'Seasonal',
          headerColor: Color(0xFFEDE9FE),
          titleColor: Color(0xFF6D28D9),
          badgeColor: Color(0xFF7C3AED),
          badgeBgColor: Color(0xFFDDD6FE),
          bulletColor: Color(0xFF7C3AED),
          items: [
            'Northeast monsoon (Nov–Mar) brings heavy rain to the east coast; flooding is possible',
            'Flash floods can occur rapidly in urban KL during intense afternoon downpours',
            'Heatstroke risk is real — stay hydrated and rest during peak heat (11 AM–3 PM)',
            'Jellyfish season on east coast beaches peaks Jun–Aug; ask locals before swimming',
          ],
        ),
        SizedBox(height: 16),
        _SafetyCard(
          title: 'Wildlife & Jungle Safety',
          iconEmoji: '🐒',
          badgeText: 'Be Cautious',
          headerColor: Color(0xFFFFEDD5),
          titleColor: Color(0xFFC2410C),
          badgeColor: Color(0xFFEA580C),
          badgeBgColor: Color(0xFFFED7AA),
          bulletColor: Color(0xFFEA580C),
          items: [
            'Do not feed macaque monkeys — they can bite aggressively if food is present',
            'Always use a licensed guide for jungle treks; inform someone of your route and ETA',
            'Wear long sleeves, trousers, and closed shoes in rainforests — leeches are common',
            'Carry a basic first-aid kit and ensure your tetanus vaccination is up to date',
          ],
        ),
        SizedBox(height: 16),
        _SafetyCard(
          title: 'Emergency Contacts',
          iconEmoji: '🆘',
          badgeText: 'Save These',
          headerColor: Color(0xFFFEE2E2),
          titleColor: Color(0xFFB91C1C),
          badgeColor: Color(0xFFDC2626),
          badgeBgColor: Color(0xFFFECACA),
          bulletColor: Color(0xFFDC2626),
          items: [
            '🚓 Police: 999 (nationwide emergency hotline)',
            '🚑 Ambulance / Fire: 999 or 112 (mobile networks)',
            '🏥 Hospital Kuala Lumpur (HKL): +603-2615 5555',
            '🌐 Tourism Malaysia Helpline: 1-300-88-5050',
          ],
        ),
      ],
    );
  }
}

// ==================== WIDGET COMPONENTS ====================

// --- Transport Card Widget ---
class _TransportCard extends StatelessWidget {
  final String title;
  final String priceRange;
  final Color headerColor;
  final Color badgeColor;
  final String description;
  final List<String> tips;

  const _TransportCard({
    required this.title,
    required this.priceRange,
    required this.headerColor,
    required this.badgeColor,
    required this.description,
    required this.tips,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: badgeColor,
                  radius: 16,
                  child: const Icon(Icons.directions_subway, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: badgeColor,
                      ),
                    ),
                    Text(
                      priceRange,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: badgeColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.3),
                ),
                const SizedBox(height: 12),
                ...List.generate(tips.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: badgeColor,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tips[index],
                            style: const TextStyle(fontSize: 11.5, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Etiquette Card Widget ---
class _EtiquetteCard extends StatelessWidget {
  final String title;
  final String iconEmoji;
  final Color headerColor;
  final Color titleColor;
  final Color checkColor;
  final Color checkBgColor;
  final List<String> items;

  const _EtiquetteCard({
    required this.title,
    required this.iconEmoji,
    required this.headerColor,
    required this.titleColor,
    required this.checkColor,
    required this.checkBgColor,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Text(iconEmoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: titleColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: List.generate(items.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: checkBgColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Icon(Icons.check, size: 14, color: checkColor),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          items[index],
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Colors.black87,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Safety Card Widget ---
class _SafetyCard extends StatelessWidget {
  final String title;
  final String iconEmoji;
  final String badgeText;
  final Color headerColor;
  final Color titleColor;
  final Color badgeColor;
  final Color badgeBgColor;
  final Color bulletColor;
  final List<String> items;

  const _SafetyCard({
    required this.title,
    required this.iconEmoji,
    required this.badgeText,
    required this.headerColor,
    required this.titleColor,
    required this.badgeColor,
    required this.badgeBgColor,
    required this.bulletColor,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Header with Risk Level Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Text(iconEmoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: titleColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bullet point items
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: List.generate(items.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: bulletColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          items[index],
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Colors.black87,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}