class Trip {
  final String id;
  final String title;
  final String image;
  final double rating;
  final String price;
  final String duration;

  Trip({
    required this.id,
    required this.title,
    required this.image,
    required this.rating,
    required this.price,
    required this.duration,
  });

  factory Trip.fromFirestore(Map<String, dynamic> data, String id) {
    return Trip(
      id: id,
      title: data['title'] ?? '',
      image: data['image'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      price: data['price'] ?? '',
      duration: data['duration'] ?? '',
    );
  }
}
