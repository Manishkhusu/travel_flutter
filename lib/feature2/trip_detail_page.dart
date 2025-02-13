import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

import 'package:flutter_xploverse/feature2/review_section.dart';

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
  final _reviewController = TextEditingController();
  final _hashtagsController = TextEditingController();

  bool _isOrganizer = false;
  bool _isLoadingHashtags = false;

  double _averageRating = 0.0;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
    _checkIfOrganizer();
    _hashtagsController.text =
        (widget.trip['hashtags'] as List<dynamic>?)?.join(' ') ?? '';
    _calculateAverageRating();
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

  @override
  void dispose() {
    _reviewController.dispose();
    _hashtagsController.dispose();
    super.dispose();
  }

  Future<void> _checkIfOrganizer() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _isOrganizer = widget.trip['organizerId'] == user.uid;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final user = _auth.currentUser;
    if (user == null) {
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
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .doc(widget.tripId)
            .set(widget.trip);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to favorites!')),
        );
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .doc(widget.tripId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from favorites!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update favorite: ${e.toString()}')),
      );
      setState(() {
        _isFavorite = !_isFavorite;
      });
    }
  }

  Future<void> _calculateAverageRating() async {
    QuerySnapshot reviewSnapshot = await FirebaseFirestore.instance
        .collectionGroup('reviews')
        .where('tripId', isEqualTo: widget.tripId)
        .get();

    if (reviewSnapshot.docs.isNotEmpty) {
      double totalRating = 0;
      for (var doc in reviewSnapshot.docs) {
        totalRating += (doc['rating'] as num).toDouble();
      }
      setState(() {
        _averageRating = totalRating / reviewSnapshot.docs.length;
      });

      await FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.tripId)
          .update({'rating': _averageRating});
    } else {
      setState(() {
        _averageRating = 0.0;
      });
    }
  }

  Future<void> _updateHashtags() async {
    _updateTripField('hashtags', _hashtagsController.text.split(' '));
  }

  Future<void> _updateTripField(String fieldName, dynamic value) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in.')),
      );
      return;
    }

    if (!_isOrganizer) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only the organizer can edit $fieldName.')),
      );
      return;
    }

    setState(() {
      _isLoadingHashtags = true;
    });

    try {
      dynamic dataToUpdate = {fieldName: value};
      await FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.tripId)
          .update(dataToUpdate);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$fieldName updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update $fieldName: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoadingHashtags = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color textColor = Colors.black87;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trip['title'] ?? 'Trip Details',
            style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF29ABE2),
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
      backgroundColor: const Color(0xFFE1F5FE),
      body: SingleChildScrollView(
        child: Card(
          margin: const EdgeInsets.all(10),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildTripImage(widget.trip['image']),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.trip['title'] ?? 'No Title',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.yellow[700], size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '${(widget.trip['rating'] as num?)?.toStringAsFixed(1) ?? '0.0'}',
                          style: TextStyle(color: textColor),
                        ),
                      ],
                    ),
                    Text(
                      '\$${widget.trip['price'] ?? 'Unknown Price'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.yellow,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.trip['duration'] ?? 'Unknown Duration',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.trip['description'] ?? 'No description available.',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Hashtags',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                if (_isOrganizer)
                  TextFormField(
                    controller: _hashtagsController,
                    decoration: InputDecoration(
                      hintText: 'Enter hashtags (space-separated)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                else
                  Wrap(
                    children: (widget.trip['hashtags'] as List<dynamic>?)
                            ?.map((hashtag) {
                          return Chip(
                            label: Text(hashtag),
                            backgroundColor: Colors.blue,
                          );
                        }).toList() ??
                        [],
                  ),
                const SizedBox(height: 8),
                if (_isOrganizer)
                  ElevatedButton(
                    onPressed: _isLoadingHashtags ? null : _updateHashtags,
                    child: _isLoadingHashtags
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : const Text('Update Hashtags'),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                const SizedBox(height: 24),
                ReviewSection(tripId: widget.tripId),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTripImage(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.file(
        File(imageUrl),
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey[300],
            child: const Center(
              child:
                  Text('Image Not Found', style: TextStyle(color: Colors.grey)),
            ),
          );
        },
      );
    } else {
      return Image.network(
        'https://www.andbeyond.com/wp-content/uploads/sites/5/Kathmandu-Bhaktapur.jpg',
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey[300],
            child: const Center(
                child: Text('No Image Available',
                    style: TextStyle(color: Colors.grey))),
          );
        },
      );
    }
  }
}
