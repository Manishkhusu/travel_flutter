class Trip {
  final String id;
  final String title;
  final String location;
  final String? image;
  final String price;
  final String duration;
  final String description;
  final List<String> hashtags;
  final double rating;
  final String? organizerId;

  Trip({
    required this.id,
    required this.title,
    required this.location,
    this.image,
    required this.price,
    required this.duration,
    required this.description,
    required this.hashtags,
    required this.rating,
    this.organizerId,
  });

  factory Trip.fromFirestore(Map<String, dynamic> data, String id) {
    return Trip(
      id: id,
      title: data['title'] ?? '',
      location: data['location'] ?? '',
      image: data['image'] ?? '',
      price: data['price'] ?? '',
      duration: data['duration'] ?? '',
      description: data['description'] ?? '',
      hashtags: List<String>.from(data['hashtags'] ?? []),
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      organizerId: data['organizerId'],
    );
  }
}
