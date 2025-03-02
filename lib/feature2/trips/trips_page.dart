import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_xploverse/feature2/model/tripmodel.dart';
import 'package:flutter_xploverse/feature2/trips/trip_detail_page.dart';
import 'package:flutter_xploverse/feature2/trips/trip_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class TripsPage extends StatefulWidget {
  @override
  _TripsPageState createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool? isOrganizer = false; // Provide a default value
  final ImagePicker _imagePicker = ImagePicker();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String? _localImagePath;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkIfOrganizer();
    _loadImagePath();
  }

  Future<void> _loadImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _localImagePath = prefs.getString('local_image_path');
    });
  }

  Future<void> _saveImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('local_image_path', path);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkIfOrganizer() async {
    if (currentUser != null) {
      try {
        final userDoc =
            await _firestore.collection('users').doc(currentUser!.uid).get();
        if (userDoc.exists) {
          setState(() {
            isOrganizer = userDoc.data()?['usertype'] == 'Organizer';
          });
        } else {
          setState(() {
            isOrganizer = false;
          });
        }
      } catch (e) {
        print("Error checking organizer status: $e");
        setState(() {
          isOrganizer = false;
        });
      }
    } else {
      setState(() {
        isOrganizer = false;
      });
    }
  }

  Future<String?> uploadImage(File? imageFile) async {
    if (imageFile == null) return null;

    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString() +
          path.extension(imageFile.path);
      return imageFile.path;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // New implementation for add a trip
  void _showAddTripDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return TripDialog(
            isEdit: false,
            onSubmit: (tripData, selectedImage) async {
              try {
                setState(() {
                  isLoading = true;
                });
                String? imagePath = await uploadImage(selectedImage);
                List<String> hashtagsList = List<String>.from(
                    tripData['hashtags']); // Ensure hashtags is a List<String>

                await _firestore.collection('trips').add({
                  'title': tripData['title'],
                  'location': tripData['location'],
                  'image': imagePath ?? '',
                  'price': tripData['price'],
                  'duration': tripData['duration'],
                  'description': tripData['description'],
                  'hashtags': hashtagsList,
                  'rating': 0.0,
                  'organizerId': currentUser?.uid,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                await _saveImagePath(imagePath ?? '');
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Trip added successfully')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Error adding trip: ${e.toString()}')));
              } finally {
                setState(() {
                  isLoading = false;
                });
              }
            },
          );
        });
  }

  // New implementation for edit a trip
  void _showEditTripDialog(Trip trip) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return TripDialog(
          isEdit: true,
          trip: trip,
          onSubmit: (tripData, selectedImage) async {
            try {
              setState(() {
                isLoading = true;
              });
              String? imagePath = await uploadImage(selectedImage);
              List<String> hashtagsList = List<String>.from(
                  tripData['hashtags']); // Ensure hashtags is a List<String>

              await _firestore.collection('trips').doc(trip.id).update({
                'title': tripData['title'],
                'location': tripData['location'],
                'image': imagePath ??
                    trip.image, // Use new image if selected, else keep the old one
                'price': tripData['price'],
                'duration': tripData['duration'],
                'description': tripData['description'],
                'hashtags': hashtagsList,
                'updatedAt': FieldValue.serverTimestamp(),
              });

              await _saveImagePath(imagePath ?? '');
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Trip updated successfully')));
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Error updating trip: ${e.toString()}')));
            } finally {
              setState(() {
                isLoading = false;
              });
            }
          },
        );
      },
    );
  }

  Future<void> _removeTrip(String tripId) async {
    try {
      await _firestore.collection('trips').doc(tripId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip removed successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing trip: ${e.toString()}')),
      );
    }
  }

  Widget _buildTripImage(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
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
                child: Text('Image Not Found',
                    style: TextStyle(color: Colors.grey)),
              ),
            );
          },
        ),
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
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
                    style: TextStyle(color: Colors.grey)),
              ),
            );
          },
        ),
      );
    }
  }

  // Helper function to fetch rating for a given tripId
  Future<double> _getTripRating(String tripId) async {
    try {
      DocumentSnapshot tripSnapshot = await FirebaseFirestore.instance
          .collection('trips')
          .doc(tripId)
          .get();
      if (tripSnapshot.exists) {
        return (tripSnapshot['rating'] as num?)?.toDouble() ?? 0.0;
      } else {
        return 0.0; // Default rating if the document doesn't exist
      }
    } catch (e) {
      print("Error fetching rating: $e");
      return 0.0; // Return a default value in case of an error
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color textColor = Colors.black87;

    return Scaffold(
      backgroundColor: const Color(0xFFE1F5FE),
      appBar: AppBar(
        title: const Text('Available Trips',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF29ABE2),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search for trips...',
                hintStyle: TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: const Color(0xFF29ABE2).withOpacity(0.7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),
      ),
      floatingActionButton: (isOrganizer == true)
          ? FloatingActionButton(
              onPressed: isOrganizer == true && !isLoading
                  ? _showAddTripDialog
                  : null, // Disable button when loading
              child: isLoading
                  ? CircularProgressIndicator(
                      color: Colors.white,
                    )
                  : Icon(Icons.add),
              backgroundColor: const Color(0xFF29ABE2),
            )
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('trips')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: TextStyle(color: textColor)));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow.shade700),
            ));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
                child: Text('No trips available',
                    style: TextStyle(color: textColor)));
          }

          final filteredTrips = snapshot.data!.docs.where((doc) {
            final tripData = doc.data() as Map<String, dynamic>;
            final title = tripData['title']?.toString().toLowerCase() ?? '';
            return title.contains(_searchQuery.toLowerCase());
          }).toList();

          if (filteredTrips.isEmpty) {
            return Center(
              child: Text(
                'No trips found matching your search.',
                style: TextStyle(color: textColor, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: filteredTrips.length,
            itemBuilder: (context, index) {
              var tripDocument = filteredTrips[index];
              Trip trip = Trip.fromFirestore(
                  tripDocument.data() as Map<String, dynamic>, tripDocument.id);
              bool isThisTripOrganizer =
                  (isOrganizer == true && trip.organizerId == currentUser?.uid);

              return FutureBuilder<double>(
                future: _getTripRating(trip.id),
                builder: (context, snapshot) {
                  double rating = snapshot.data ??
                      0.0; // Default to 0.0 if data is null or not available

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TripDetailPage(
                            trip: tripDocument.data() as Map<String, dynamic>,
                            tripId: tripDocument.id,
                          ),
                        ),
                      );
                    },
                    child: Card(
                      margin: EdgeInsets.all(10),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _buildTripImage(trip.image),
                          ),
                          Padding(
                            padding: EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  trip.title,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.star,
                                            color: Colors.yellow[700],
                                            size: 20),
                                        SizedBox(width: 4),
                                        Text(
                                          rating.toStringAsFixed(1),
                                          style: TextStyle(color: textColor),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'NPR ${trip.price}',
                                      style: TextStyle(
                                        color: Colors.yellow[700],
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  trip.duration,
                                  style: TextStyle(color: Colors.black54),
                                ),
                                SizedBox(height: 8),

                                // Conditional Buttons for Organizers
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (isThisTripOrganizer)
                                      ElevatedButton(
                                        onPressed: () =>
                                            _showEditTripDialog(trip),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: Text('Edit'),
                                      ),
                                    if (isThisTripOrganizer)
                                      ElevatedButton(
                                        onPressed: () => _removeTrip(trip.id),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: Text('Remove'),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
