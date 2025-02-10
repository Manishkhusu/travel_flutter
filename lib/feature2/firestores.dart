import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreServices {
  final CollectionReference reviews =
      FirebaseFirestore.instance.collection("reviews");

  Future<void> addReview({
    required String review,
    required int rating,
    required String userName,
    required String tripId,
    required String reviewText,
  }) {
    return reviews.add({
      'review': review, // Ensure consistency
      'rating': rating,
      'userName': userName,
      'tripId': tripId,
      'timestamp': Timestamp.now(),
    });
  }

  Stream<QuerySnapshot> getReviewsStream(String tripId) {
    return reviews
        .where('tripId', isEqualTo: tripId) // Fetch only reviews for this trip
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
