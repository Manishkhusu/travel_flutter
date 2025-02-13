import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewSection extends StatefulWidget {
  final String tripId;
  final Color backgroundColor;
  final Color textColor;

  const ReviewSection({
    Key? key,
    required this.tripId,
    this.backgroundColor = Colors.grey,
    this.textColor = Colors.white,
  }) : super(key: key);

  @override
  _ReviewSectionState createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<ReviewSection> {
  final _auth = FirebaseAuth.instance;
  final _reviewController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  int _selectedRating = 0;
  bool _isLoading = false;

  String? _existingReviewId; // To store the existing review ID
  DocumentSnapshot? _existingReviewData;

  @override
  void initState() {
    super.initState();
    _loadExistingReview(); // Load any existing review for this user & trip
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingReview() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final reviewDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('reviews')
        .doc(widget.tripId)
        .get();

    if (reviewDoc.exists) {
      setState(() {
        _existingReviewId = reviewDoc.id;
        _existingReviewData = reviewDoc;
        _nameController.text = reviewDoc['userName'] ?? '';
        _reviewController.text = reviewDoc['review'] ?? '';
        _selectedRating = reviewDoc['rating'] as int? ?? 0;
      });
    }
  }

  Future<void> _submitReview() async {
    if (_reviewController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter your name, review, and rating.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final user = _auth.currentUser;
    if (user == null) return;

    final reviewData = {
      'review': _reviewController.text,
      'rating': _selectedRating,
      'userName': _nameController.text,
      'tripId': widget.tripId,
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      final userReviewsCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('reviews');

      if (_existingReviewId != null) {
        // Update existing review
        await userReviewsCollection.doc(widget.tripId).update(reviewData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review updated successfully!')),
        );
      } else {
        // Add new review
        await userReviewsCollection.doc(widget.tripId).set(reviewData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully!')),
        );
      }

      _reviewController.clear();
      _nameController.clear();
      setState(() {
        _selectedRating = 0;
        _existingReviewId = widget.tripId; // Update ID
        _loadExistingReview();
      });
    } catch (e) {
      print("Error submitting/updating review: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting review: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteReview() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userReviewsCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('reviews');

      await userReviewsCollection.doc(widget.tripId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review deleted successfully!')),
      );

      _reviewController.clear();
      _nameController.clear();
      setState(() {
        _selectedRating = 0;
        _existingReviewId = null;
        _isLoading = false;
        _loadExistingReview();
      });
    } catch (e) {
      print("Error deleting review: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting review: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Review Input Section
        Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Write a Review',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Your Name',
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: const OutlineInputBorder(),
                  fillColor: Colors.grey[800],
                  filled: true,
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 10),
              Row(
                children: List.generate(
                  5,
                  (index) => IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedRating = index + 1;
                      });
                    },
                    icon: Icon(
                      index < _selectedRating ? Icons.star : Icons.star_border,
                      color: Colors.yellow[700],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _reviewController,
                decoration: InputDecoration(
                  hintText: 'Share your experience...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: const OutlineInputBorder(),
                  fillColor: Colors.grey[800],
                  filled: true,
                ),
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : _submitReview, // Disable during loading
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow[700],
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          )) // Show loading indicator
                      : Text(
                          _existingReviewId == null
                              ? 'Submit Review'
                              : 'Update Review',
                          style: const TextStyle(color: Colors.black),
                        ),
                ),
                if (_existingReviewId != null)
                  Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _deleteReview,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                )) // Show loading indicator
                            : const Text(
                                'Delete Review',
                                style: TextStyle(color: Colors.white),
                              ),
                      ))
              ]),
            ],
          ),
        ),
        // Existing Reviews Section
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(_auth.currentUser?.uid) // Fetch the current user
              .collection('reviews')
              .snapshots(), // Now for loading the data, you must first specify and filter
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                  child: Text('Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red)));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                  child: Text('No reviews yet',
                      style: TextStyle(color: Colors.white70)));
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var doc = snapshot.data!.docs[index];
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            data['userName'] ?? 'Anonymous',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Row(
                            children: List.generate(
                              5,
                              (starIndex) => Icon(
                                starIndex < (data['rating'] as int? ?? 0)
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 16,
                                color: Colors.yellow[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data['review'] ?? 'No review text',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
