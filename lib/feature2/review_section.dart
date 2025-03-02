import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_xploverse/feature2/reviewedit.dart'; // Import the EditReviewDialog
//Make sure you added the imports to tripexpense to help avoid errors

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
  bool _hasReviewed = false; // Track if the user has already reviewed
  String? _existingReviewId; // Track the ID of the existing review

  @override
  void initState() {
    super.initState();
    _checkIfUserHasReviewed();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _checkIfUserHasReviewed() async {
    final user = _auth.currentUser;
    if (user != null) {
      final reviewDocRef = FirebaseFirestore.instance
          .collection('reviews')
          .doc(widget.tripId)
          .collection('userReviews')
          .doc(user.uid);

      final reviewDoc = await reviewDocRef.get();
      setState(() {
        _hasReviewed = reviewDoc.exists;
        if (reviewDoc.exists) {
          _existingReviewId = reviewDoc.id;
        } else {
          _existingReviewId = null;
        }
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
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You must be logged in to submit a review')),
      );
      return;
    }

    final String? profileImageUrl = user.photoURL;

    // Check if the user already has a review for this trip (check if _hasReviewed is true)
    if (_hasReviewed) {
      // User has already reviewed this trip
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have already reviewed this trip.')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final reviewData = <String, dynamic>{
      'review': _reviewController.text,
      'rating': _selectedRating,
      'userName': _nameController.text,
      'tripId': widget.tripId,
      'createdAt': FieldValue.serverTimestamp(),
      'profileImageUrl': profileImageUrl,
    };

    try {
      final reviewDocRef = FirebaseFirestore.instance
          .collection('reviews')
          .doc(widget.tripId)
          .collection('userReviews')
          .doc(user.uid);

      await reviewDocRef.set(reviewData);

      _reviewController.clear();
      _nameController.clear();
      setState(() {
        _selectedRating = 0;
        _hasReviewed =
            true; // Set _hasReviewed to true after successful submission
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print("Error submitting review: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting review: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
      _updateAverageRating();
    }
  }

  Future<void> _deleteReview() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You must be logged in to delete a review')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final reviewDocRef = FirebaseFirestore.instance
          .collection('reviews')
          .doc(widget.tripId)
          .collection('userReviews')
          .doc(user.uid);

      await reviewDocRef.delete();

      _reviewController.clear();
      _nameController.clear();
      setState(() {
        _selectedRating = 0;
        _hasReviewed = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Review deleted successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      print("Error deleting review: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting review: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
      _updateAverageRating();
    }
  }

  Future<void> _updateAverageRating() async {
    try {
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .doc(widget.tripId)
          .collection('userReviews')
          .get();

      if (reviewsSnapshot.docs.isEmpty) {
        await FirebaseFirestore.instance
            .collection('trips')
            .doc(widget.tripId)
            .update({'rating': 0.0});
        return;
      }

      double totalRating = 0;
      for (QueryDocumentSnapshot reviewDoc in reviewsSnapshot.docs) {
        final reviewData = reviewDoc.data() as Map<String, dynamic>;
        totalRating += (reviewData['rating'] as num).toDouble();
      }

      final double averageRating = totalRating / reviewsSnapshot.docs.length;

      await FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.tripId)
          .update({'rating': averageRating});
    } catch (e) {
      print("Error updating average rating: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.blue,
        hintColor: Colors.grey[600],
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[200],
          hintStyle: TextStyle(color: Colors.grey[600]),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      child: Column(
        children: [
          // Review Input Section
          if (!_hasReviewed)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Write a Review',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'Your Name',
                      ),
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
                            index < _selectedRating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _reviewController,
                      decoration: const InputDecoration(
                        hintText: 'Share your experience...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: _isLoading ? null : _submitReview,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white))
                              : const Text('Submit Review'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Thank you for your review!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ),

          // Existing Reviews Section
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('reviews')
                .doc(widget.tripId)
                .collection('userReviews')
                .snapshots(),
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
                        style: TextStyle(color: Colors.grey)));
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final reviewDoc = snapshot.data!.docs[index];
                  final reviewData = reviewDoc.data() as Map<String, dynamic>;
                  final String? profileImageUrl =
                      reviewData['profileImageUrl'] as String?;
                  final int rating =
                      (reviewData['rating'] as num?)?.toInt() ?? 0;

                  // Only show edit/delete buttons for the current user's review
                  final bool isCurrentUserReview =
                      _auth.currentUser?.uid == reviewDoc.id; // Compare IDs

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundImage: profileImageUrl != null
                                        ? NetworkImage(profileImageUrl)
                                        : null,
                                    child: profileImageUrl == null
                                        ? const Icon(Icons.person)
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    reviewData['userName'] as String? ??
                                        'Anonymous',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              if (isCurrentUserReview) // Conditionally show buttons
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => EditReviewDialog(
                                              tripId: widget.tripId,
                                              reviewData:
                                                  reviewData), // Pass the tripId and reviewData
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () {
                                        _deleteReview();
                                      },
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Display the rating stars
                          Row(
                            children: List.generate(
                              5,
                              (starIndex) => Icon(
                                starIndex < rating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Display review text
                          Text(
                            reviewData['review'] as String? ?? 'No review text',
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
    );
  }
}
