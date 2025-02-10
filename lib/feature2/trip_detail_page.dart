import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_xploverse/feature2/firestores.dart'; // Import FirestoreServices

class TripDetailPage extends StatefulWidget {
  final Map<String, dynamic> trip;
  final String tripId;

  const TripDetailPage({Key? key, required this.trip, required this.tripId})
      : super(key: key);

  @override
  _TripDetailPageState createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> {
  final _auth = FirebaseAuth.instance;
  final _firestoreService =
      FirestoreServices(); // Instantiate FirestoreServices
  final _reviewController = TextEditingController();
  int _rating = 0;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _checkIfFavorite() async {
    final user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot favoriteDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(widget.tripId)
          .get();

      setState(() {
        _isFavorite = favoriteDoc.exists;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('User is not authenticated! Cannot update favorites.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in.')),
      );
      return;
    }

    setState(() {
      _isFavorite = !_isFavorite;
    });

    try {
      if (_isFavorite) {
        // Add to favorites
        print('Adding to favorites: tripId = ${widget.tripId}');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .doc(widget.tripId)
            .set(widget.trip);
        print('Successfully added to favorites');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to favorites!')),
        );
      } else {
        // Remove from favorites
        print('Removing from favorites: tripId = ${widget.tripId}');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .doc(widget.tripId)
            .delete();
        print('Successfully removed from favorites');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from favorites!')),
        );
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update favorite: ${e.toString()}')),
      );
      //Revert the UI change if the save to firebase failed
      setState(() {
        _isFavorite = !_isFavorite;
      });
    }
  }

  void _submitReview() async {
    if (_reviewController.text.isEmpty || _rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a review and rating.')),
      );
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to review.')),
      );
      return;
    }

    try {
      await _firestoreService.addReview(
        review: _reviewController.text,
        rating: _rating,
        userName: user.displayName ?? 'Anonymous',
        tripId: widget.tripId,
        reviewText: _reviewController.text,
      );

      _reviewController.clear();
      setState(() {
        _rating = 0; // Reset rating after submission
      });
      FocusScope.of(context).unfocus(); // Hide keyboard
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting review: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trip['title'] ?? 'Trip Details'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: Colors.red,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip Image
            Image.network(
              widget.trip['image'] ?? 'https://via.placeholder.com/400',
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 16),

            // Trip Title
            Text(
              widget.trip['title'] ?? 'No Title',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            // Trip Price and Duration
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${widget.trip['price'] ?? 'Unknown Price'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow,
                  ),
                ),
                Text(
                  widget.trip['duration'] ?? 'Unknown Duration',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Trip Description
            Text(
              widget.trip['description'] ?? 'No description available.',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 24),

            // Review Submission Form
            const Text(
              'Add a Review',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            // Rating Stars
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.yellow[700],
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                );
              }),
            ),

            // Review Text Field
            TextField(
              controller: _reviewController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Write your review here...',
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 8),

            // Submit Button
            ElevatedButton(
              onPressed: _submitReview,
              child: const Text('Submit Review'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),

            const SizedBox(height: 24),

            // Reviews Section
            const Text(
              'Reviews',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            // Review List
            StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getReviewsStream(widget.tripId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('No reviews yet.',
                      style: TextStyle(color: Colors.white70));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var reviewData = snapshot.data!.docs[index].data()
                        as Map<String, dynamic>;

                    return Card(
                      color: Colors.grey[800],
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  reviewData['userName'] ?? 'Anonymous',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Row(
                                  children: List.generate(5, (index) {
                                    return Icon(
                                      index <
                                              (reviewData['rating'] as int? ??
                                                  0)
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.yellow[700],
                                      size: 16,
                                    );
                                  }),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              reviewData['review'] ?? 'No review text',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      backgroundColor: Colors.black,
    );
  }
}
