import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:flutter_xploverse/feature2/favourite_page.dart';
import 'package:flutter_xploverse/feature2/review_section.dart';
import 'package:intl/intl.dart';

class TripDetailPage extends StatefulWidget {
  final String tripId;
  final Map<String, dynamic> trip;

  const TripDetailPage({Key? key, required this.tripId, required this.trip})
      : super(key: key);

  @override
  _TripDetailPageState createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> {
  final _auth = FirebaseAuth.instance;
  final _customHashtagsController = TextEditingController();
  bool _isOrganizer = false;
  bool _isLoadingHashtags = false;
  bool _isFavorite = false;
  String? _selectedWeather;
  String? _selectedTravelDays;
  String? _selectedBudget;
  double _rating = 0.0;

  List<String> weatherOptions = ['sunny', 'rainy', 'foggy', 'cloudy'];
  List<String> travelDaysOptions = ['1-3 days', '4-7 days', '7+ days'];
  List<String> budgetOptions = ['NPR < 1000', 'NPR 1000-5000', 'NPR > 5000'];

  bool _isDescriptionExpanded = false;
  final int _descriptionMaxLines = 3; // Show 3 lines initially

  @override
  void initState() {
    super.initState();
    _initializeData();
    _getRating(); // Add this line
  }

  Future<void> _initializeData() async {
    await _checkIfFavorite();
    await _checkIfOrganizer();
    _loadInitialData();
  }

  Future<void> _getRating() async {
    try {
      DocumentSnapshot tripSnapshot = await FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.tripId)
          .get();
      if (tripSnapshot.exists) {
        setState(() {
          _rating = (tripSnapshot['rating'] as num?)?.toDouble() ?? 0.0;
        });
      }
    } catch (e) {
      print("Error fetching rating: $e");
    }
  }

  Future<void> _loadInitialData() async {
    Map<String, dynamic>? hashtagsData =
        widget.trip['hashtagsData'] as Map<String, dynamic>?;
    Map<String, dynamic>? presetHashtags =
        hashtagsData?['presetHashtags'] as Map<String, dynamic>?;

    setState(() {
      _selectedWeather = presetHashtags?['weather'] as String?;
      _selectedTravelDays = presetHashtags?['travelDays'] as String?;
      _selectedBudget = presetHashtags?['budget'] as String?;
      _customHashtagsController.text =
          (hashtagsData?['customHashtags'] as List<dynamic>?)?.join(' ') ?? '';
    });
  }

  Future<void> _checkIfFavorite() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final favoriteDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .doc(widget.tripId)
            .get();
        setState(() {
          _isFavorite = favoriteDoc.exists;
        });
      } catch (e) {
        print("Error checking favorite status: $e");
      }
    }
  }

  Future<void> _checkIfOrganizer() async {
    final user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot tripSnapshot = await FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.tripId)
          .get();
      setState(() {
        _isOrganizer = tripSnapshot['organizerId'] == user.uid;
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
        DocumentSnapshot tripSnapshot = await FirebaseFirestore.instance
            .collection('trips')
            .doc(widget.tripId)
            .get();
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .doc(widget.tripId)
            .set(tripSnapshot.data() as Map<String, dynamic>);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to favorites!')),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => FavoritesPage()),
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

  Future<void> _updateHashtags() async {
    List<String> customHashtags = _customHashtagsController.text.split(' ');
    Map<String, dynamic> presetHashtags = {
      'weather': _selectedWeather,
      'travelDays': _selectedTravelDays,
      'budget': _selectedBudget,
    };

    Map<String, dynamic> hashtagsData = {
      'customHashtags': customHashtags,
      'presetHashtags': presetHashtags,
    };

    await _updateTripField('hashtagsData', hashtagsData);
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
      Map<String, dynamic> dataToUpdate = {fieldName: value};

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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Trip Details',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF29ABE2),
        elevation: 0,
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(widget.trip),
              const SizedBox(height: 20),
              _buildDescriptionSection(widget.trip),
              const SizedBox(height: 20),
              _buildHashtagsSection(widget.trip),
              const SizedBox(height: 20),
              ReviewSection(tripId: widget.tripId),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(Map<String, dynamic> trip) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
          ),
          child: _buildTripImage(trip['image']),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                trip['title'] ?? 'No Title',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 4),
                  Text(
                    trip['location'] ?? 'Unknown Location',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber[700], size: 20),
                      const SizedBox(width: 4),
                      Text(
                        _rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  // Price display (Conditional)
                  if (trip.containsKey('price') &&
                      trip['price'] != null &&
                      double.tryParse(trip['price'].toString()) != null)
                    Text(
                      NumberFormat.currency(locale: 'en_NP', symbol: 'NPR ')
                          .format(double.parse(trip['price'].toString())),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF29ABE2),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                trip['duration'] ?? 'Unknown Duration',
                style: TextStyle(color: Colors.grey[700], fontSize: 16),
              ),
              // Budget display (most robust check)
              if (trip.containsKey('budget') &&
                  trip['budget'] != null &&
                  trip['budget'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Budget: NPR ${trip['budget']}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildDescriptionSection(Map<String, dynamic> trip) {
    String description = trip['description'] ?? 'No description available.';
    bool isLongDescription = description.split(' ').length > 50;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w100,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: ConstrainedBox(
              constraints: _isDescriptionExpanded || !isLongDescription
                  ? const BoxConstraints()
                  : BoxConstraints(
                      maxHeight: 70.0 * _descriptionMaxLines / 3.0),
              child: Text(
                description,
                style: TextStyle(color: Colors.grey[800], fontSize: 16),
                softWrap: true,
                overflow: TextOverflow.fade,
              ),
            ),
          ),
          if (isLongDescription)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _isDescriptionExpanded = !_isDescriptionExpanded;
                  });
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  _isDescriptionExpanded ? 'Read Less' : 'Read More',
                  style: const TextStyle(color: Color(0xFF29ABE2)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHashtagsSection(Map<String, dynamic> trip) {
    Map<String, dynamic>? hashtagsData =
        trip['hashtagsData'] as Map<String, dynamic>?;
    List<dynamic>? customHashtags =
        hashtagsData?['customHashtags'] as List<dynamic>?;
    Map<String, dynamic>? presetHashtags =
        hashtagsData?['presetHashtags'] as Map<String, dynamic>?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hashtags',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Custom Hashtags',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          if (_isOrganizer)
            TextFormField(
              controller: _customHashtagsController,
              decoration: InputDecoration(
                hintText: 'Enter custom hashtags (space-separated)',
                border: const OutlineInputBorder(borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            )
          else
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: (customHashtags != null)
                  ? customHashtags.map<Widget>((hashtag) {
                      return Chip(
                        label: Text(
                          hashtag,
                          style: const TextStyle(color: Colors.black),
                        ),
                        backgroundColor: Colors.grey[200],
                        surfaceTintColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList()
                  : [],
            ),
          const SizedBox(height: 20),
          const Text(
            'Preset Hashtags',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          if (!_isOrganizer)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPresetHashtagText('Weather', presetHashtags?['weather']),
                _buildPresetHashtagText(
                    'Travel Days', presetHashtags?['travelDays']),
                _buildPresetHashtagText('Budget', presetHashtags?['budget']),
              ],
            )
          else
            Column(
              children: [
                _buildPresetDropdown(
                    'Weather', _selectedWeather, weatherOptions, (value) {
                  setState(() {
                    _selectedWeather = value;
                  });
                }),
                const SizedBox(height: 8),
                _buildPresetDropdown(
                    'Travel Days', _selectedTravelDays, travelDaysOptions,
                    (value) {
                  setState(() {
                    _selectedTravelDays = value;
                  });
                }),
                const SizedBox(height: 8),
                _buildPresetDropdown('Budget', _selectedBudget, budgetOptions,
                    (value) {
                  setState(() {
                    _selectedBudget = value;
                  });
                }),
              ],
            ),
          const SizedBox(height: 16),
          if (_isOrganizer)
            ElevatedButton(
              onPressed: _isLoadingHashtags ? null : _updateHashtags,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF29ABE2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isLoadingHashtags
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    )
                  : const Text('Update Hashtags'),
            ),
        ],
      ),
    );
  }

  Widget _buildPresetHashtagText(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        '$label: ${value ?? 'Not specified'}',
        style: const TextStyle(fontSize: 16, color: Colors.black87),
      ),
    );
  }

  Widget _buildPresetDropdown(String label, String? value, List<String> options,
      ValueChanged<String?> onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black87),
          border: InputBorder.none,
        ),
        style: const TextStyle(color: Colors.black87),
        value: value,
        items: options.map((option) {
          return DropdownMenuItem(
            value: option,
            child: Text(option, style: const TextStyle(color: Colors.black87)),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTripImage(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.file(
        File(imageUrl),
        height: 250,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Image loading error: $error');
          return Container(
            height: 250,
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
      return Container(
        height: 250,
        width: double.infinity,
        color: Colors.grey[300],
        child: const Center(
            child: Text('No Image Available',
                style: TextStyle(color: Colors.grey))),
      );
    }
  }
}
