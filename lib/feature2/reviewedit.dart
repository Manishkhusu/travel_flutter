import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditReviewDialog extends StatefulWidget {
  final String tripId;
  final Map<String, dynamic> reviewData;

  const EditReviewDialog(
      {Key? key, required this.tripId, required this.reviewData})
      : super(key: key);

  @override
  _EditReviewDialogState createState() => _EditReviewDialogState();
}

class _EditReviewDialogState extends State<EditReviewDialog> {
  final _auth = FirebaseAuth.instance;
  final _reviewController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  int _selectedRating = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _reviewController.text = widget.reviewData['review'] as String? ?? '';
    _nameController.text = widget.reviewData['userName'] as String? ?? '';
    _selectedRating = (widget.reviewData['rating'] as num?)?.toInt() ?? 0;
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateReview() async {
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
            content: Text('You must be logged in to update a review')),
      );
      return;
    }

    try {
      final reviewDocRef = FirebaseFirestore.instance
          .collection('reviews')
          .doc(widget.tripId)
          .collection('userReviews')
          .doc(user.uid);

      await reviewDocRef.update({
        'review': _reviewController.text,
        'rating': _selectedRating,
        'userName': _nameController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Review updated successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating),
      );

      Navigator.of(context).pop(); // Close the dialog
    } catch (e) {
      print("Error updating review: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating review: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Review'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Your Name',
              ),
            ),
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
                    color: Colors.amber,
                  ),
                ),
              ),
            ),
            TextField(
              controller: _reviewController,
              decoration: const InputDecoration(
                hintText: 'Share your experience...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateReview,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white))
              : const Text('Update'),
        ),
      ],
    );
  }
}
