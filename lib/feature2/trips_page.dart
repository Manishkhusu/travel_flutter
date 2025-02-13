import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_xploverse/feature2/model/tripmodel.dart';
import 'package:flutter_xploverse/feature2/trip_detail_page.dart';
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
  bool isOrganizer = false;
  final ImagePicker _imagePicker = ImagePicker();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String? _localImagePath;

  @override
  void initState() {
    super.initState();
    checkIfOrganizer();
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

  Future<void> checkIfOrganizer() async {
    if (currentUser != null) {
      final userDoc =
          await _firestore.collection('users').doc(currentUser!.uid).get();
      if (userDoc.exists) {
        setState(() {
          isOrganizer = userDoc.data()?['usertype'] == 'Organizer';
        });
      }
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

  void _showAddTripDialog() {
    final titleController = TextEditingController();
    final priceController = TextEditingController();
    final durationController = TextEditingController();
    final descriptionController = TextEditingController();
    final locationController = TextEditingController();
    final hashtagsController = TextEditingController();
    //  Now weather budget and travel days set by the hastags by the organizer in the dialogs
    //final weatherConditionsController = TextEditingController();
    //final budgetController = TextEditingController();
    //final travelDaysController = TextEditingController();

    File? selectedImage;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.grey[900],
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Add New Trip',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      GestureDetector(
                        onTap: isLoading
                            ? null
                            : () async {
                                final XFile? image =
                                    await _imagePicker.pickImage(
                                  source: ImageSource.gallery,
                                );
                                if (image != null) {
                                  setState(() {
                                    selectedImage = File(image.path);
                                  });
                                }
                              },
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: selectedImage != null
                              ? Image.file(selectedImage!, fit: BoxFit.cover)
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate,
                                        color: Colors.white, size: 50),
                                    SizedBox(height: 8),
                                    Text(
                                      'Add Image (Optional)',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: titleController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Trip Title',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: locationController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Location',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: priceController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Price',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: durationController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Duration (e.g., 7 days)',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: descriptionController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Description',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: hashtagsController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Hashtags (space-separated)',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    if (titleController.text.isEmpty ||
                                        locationController.text.isEmpty) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Title and location are required')),
                                      );
                                      return;
                                    }

                                    setState(() {
                                      isLoading = true;
                                    });

                                    try {
                                      String? imagePath =
                                          await uploadImage(selectedImage);

                                      List<String> hashtagsList =
                                          hashtagsController.text.split(' ');
                                      //List<String> weatherConditionsList =  delete since all is hashtags
                                      //    weatherConditionsController.text
                                      //        .split(' ');

                                      await _firestore.collection('trips').add({
                                        'title': titleController.text,
                                        'location': locationController.text,
                                        'image': imagePath ?? '',
                                        'price': priceController.text,
                                        'duration': durationController.text,
                                        'description':
                                            descriptionController.text,
                                        'hashtags': hashtagsList,
                                        //'weatherConditions':weatherConditionsList,//delete since all is hashtags
                                        'rating': 0.0,
                                        'organizerId': currentUser?.uid,
                                        'createdAt':
                                            FieldValue.serverTimestamp(),
                                      });

                                      await _saveImagePath(imagePath ?? '');

                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Trip added successfully')),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Error adding trip: ${e.toString()}')),
                                      );
                                    } finally {
                                      setState(() {
                                        isLoading = false;
                                      });
                                    }
                                  },
                            child: isLoading
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ))
                                : Text('Add Trip'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
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
            color: Colors.grey[800],
            child: const Center(
              child: Text('Image Not Found',
                  style: TextStyle(color: Colors.white70)),
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
            color: Colors.grey[800],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_not_supported,
                    size: 50, color: Colors.white70),
                SizedBox(height: 8),
                Text(
                  'No Image Available',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color textColor = Colors.black87;

    return Scaffold(
      appBar: AppBar(
        title: Text('Available Trips', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF29ABE2),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60.0),
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
      backgroundColor: const Color(0xFFE1F5FE),
      floatingActionButton: isOrganizer
          ? FloatingActionButton(
              onPressed: _showAddTripDialog,
              child: Icon(Icons.add),
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

          return ListView.builder(
            itemCount: filteredTrips.length,
            itemBuilder: (context, index) {
              var tripDocument = filteredTrips[index];
              Trip trip = Trip.fromFirestore(
                  tripDocument.data() as Map<String, dynamic>, tripDocument.id);

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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.star,
                                        color: Colors.yellow[700], size: 20),
                                    SizedBox(width: 4),
                                    Text(
                                      trip.rating.toStringAsFixed(1),
                                      style: TextStyle(color: textColor),
                                    ),
                                  ],
                                ),
                                Text(
                                  '\$${trip.price}',
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
      ),
    );
  }
}
