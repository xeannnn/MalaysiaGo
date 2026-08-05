class HeritageSite {
  final String id;
  final String name;
  final String state;
  final String category; // e.g., 'Historical', 'Natural', 'Cultural'
  final String description;
  final String imageUrl;
  final double rating;

  HeritageSite({
    required this.id,
    required this.name,
    required this.state,
    required this.category,
    required this.description,
    required this.imageUrl,
    this.rating = 4.5,
  });
}

// Sample Data for Malaysia Heritage Sites
final List<HeritageSite> sampleHeritageSites = [
  HeritageSite(
    id: '1',
    name: 'A Famosa',
    state: 'Melaka',
    category: 'Historical',
    description: 'Portuguese fortress built in Malacca in 1511.',
    imageUrl: 'https://via.placeholder.com/150',
    rating: 4.6,
  ),
  HeritageSite(
    id: '2',
    name: 'Batu Caves',
    state: 'Selangor',
    category: 'Cultural',
    description: 'Limestone hill with a series of caves and cave temples.',
    imageUrl: 'https://via.placeholder.com/150',
    rating: 4.7,
  ),
  HeritageSite(
    id: '3',
    name: 'Kinabalu Park',
    state: 'Sabah',
    category: 'Natural',
    description: 'Malaysia\'s first World Heritage Site featuring Mount Kinabalu.',
    imageUrl: 'https://via.placeholder.com/150',
    rating: 4.9,
  ),
  HeritageSite(
    id: '4',
    name: 'George Town Historic City',
    state: 'Penang',
    category: 'Historical',
    description: 'UNESCO World Heritage Site with unique architecture and street art.',
    imageUrl: 'https://via.placeholder.com/150',
    rating: 4.8,
  ),
  HeritageSite(
    id: '5',
    name: 'Gunung Mulu National Park',
    state: 'Sarawak',
    category: 'Natural',
    description: 'Famous for its karst formations and vast cave systems.',
    imageUrl: 'https://via.placeholder.com/150',
    rating: 4.9,
  ),
];
