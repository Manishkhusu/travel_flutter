import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_xploverse/feature2/model/tripmodel.dart';
import 'package:flutter_xploverse/feature2/trip_detail_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class TripsPage extends StatefulWidget {
  @override
  _TripsPageState createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isOrganizer = false;
  final ImagePicker _imagePicker = ImagePicker();

  // Default placeholder image URL
  static const String defaultImageUrl =
      'https://firebasestorage.googleapis.com/v0/b/your-project-id.appspot.com/o/placeholders%2Fdefault_trip.jpg?alt=media';

  @override
  void initState() {
    super.initState();
    checkIfOrganizer();
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
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference reference =
          FirebaseStorage.instance.ref().child('trips/$fileName');
      await reference.putFile(imageFile);
      return await reference.getDownloadURL();
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
    File? selectedImage;

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
                        onTap: () async {
                          final XFile? image = await _imagePicker.pickImage(
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
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              if (titleController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Title is required')),
                                );
                                return;
                              }

                              try {
                                String? imageUrl =
                                    await uploadImage(selectedImage);

                                await _firestore.collection('trips').add({
                                  'title': titleController.text,
                                  'image': imageUrl ?? defaultImageUrl,
                                  'price': priceController.text,
                                  'duration': durationController.text,
                                  'description': descriptionController.text,
                                  'rating': 0.0,
                                  'organizerId': currentUser?.uid,
                                  'createdAt': FieldValue.serverTimestamp(),
                                });

                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Trip added successfully')),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Error adding trip: ${e.toString()}')),
                                );
                              }
                            },
                            child: Text('Add Trip'),
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
    return Image.network(
      imageUrl ?? defaultImageUrl,
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
              Icon(Icons.image_not_supported, size: 50, color: Colors.white70),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Available Trips'),
        backgroundColor: Colors.black,
      ),
      floatingActionButton: isOrganizer
          ? FloatingActionButton(
              onPressed: _showAddTripDialog,
              child: Icon(Icons.add),
              backgroundColor: Colors.blue,
            )
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('trips')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No trips available'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var tripDocument = snapshot.data!.docs[index];
              var tripData = tripDocument.data() as Map<String, dynamic>;
              String tripId = tripDocument.id; // Get the document ID

              // Create a Trip object
              Trip trip = Trip(
                id: tripId, // Use the document ID as the trip ID
                title: tripData['title'] ?? '',
                image: tripData['image'] ?? '',
                rating: (tripData['rating'] ?? 0).toDouble(),
                price: tripData['price'] ?? '',
                duration: tripData['duration'] ?? '',
              );

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TripDetailPage(
                        trip: tripData,
                        tripId: tripId, // Pass the trip ID
                      ),
                    ),
                  );
                },
                child: Card(
                  margin: EdgeInsets.all(10),
                  color: Colors.grey[900],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTripImage(tripData['image']),
                      Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tripData['title'],
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
                                      '${tripData['rating']}',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                                Text(
                                  '\$${tripData['price']}',
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
                              tripData['duration'],
                              style: TextStyle(color: Colors.white70),
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
