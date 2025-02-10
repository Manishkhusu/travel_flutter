import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_xploverse/feature2/firestores.dart';

class ReviewSection extends StatefulWidget {
  final String tripId;

  const ReviewSection({Key? key, required this.tripId}) : super(key: key);

  @override
  _ReviewSectionState createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<ReviewSection> {
  final FirestoreServices _firestoreServices = FirestoreServices();
  final TextEditingController _reviewController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  int _selectedRating = 0;
  bool _isLoading = false; // Add loading indicator

  @override
  void initState() {
    super.initState();
    print("ReviewSection: tripId = ${widget.tripId}");
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _nameController.dispose();
    super.dispose();
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

    try {
      await _firestoreServices.addReview(
        review: _reviewController.text,
        rating: _selectedRating,
        userName: _nameController.text,
        tripId: widget.tripId,
        reviewText: _reviewController
            .text, // Or whatever you want to pass as reviewText
      );
      _reviewController.clear();
      _nameController.clear();
      setState(() {
        _selectedRating = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted successfully!')),
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
            color: Colors.grey[900],
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
              ElevatedButton(
                onPressed:
                    _isLoading ? null : _submitReview, // Disable during loading
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow[700],
                ),
                child: _isLoading
                    ? const CircularProgressIndicator() // Show loading indicator
                    : const Text(
                        'Submit Review',
                        style: TextStyle(color: Colors.black),
                      ),
              ),
            ],
          ),
        ),
        // Existing Reviews Section
        StreamBuilder<QuerySnapshot>(
          stream: _firestoreServices.getReviewsStream(widget.tripId),
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
