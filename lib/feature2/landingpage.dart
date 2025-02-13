import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_xploverse/feature2/trip_detail_page.dart';
import 'package:flutter_xploverse/feature2/trips_page.dart';
import 'dart:io';

class LandingPage extends StatefulWidget {
  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _getRecommendedTrips() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return [];
    }

    DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
        .instance
        .collection('users')
        .doc(user.uid)
        .get();

    List<dynamic> userHashtags = userDoc.data()?['hashtags'] ?? [];
    if (userHashtags.isEmpty) {
      return [];
    }

    QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
        .instance
        .collection('trips')
        .where('hashtags', arrayContainsAny: userHashtags)
        .get();

    return snapshot.docs.map((doc) {
      var tripData = doc.data();
      tripData!['id'] = doc.id;
      return tripData;
    }).toList();
  }

  Widget _buildTripImage(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty && imageUrl.startsWith('/')) {
      try {
        return Image.file(
          File(imageUrl),
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildNoImageAvailable();
          },
        );
      } catch (e) {
        print('Error loading local image: $e');
        return _buildNoImageAvailable();
      }
    } else {
      return Image.network(
        imageUrl ?? 'https://via.placeholder.com/400',
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildNoImageAvailable();
        },
      );
    }
  }

  Widget _buildNoImageAvailable() {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey[300],
      child: const Center(
          child:
              Text('No Image Available', style: TextStyle(color: Colors.grey))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1F5FE),
      body: Container(
        decoration: const BoxDecoration(
          color: const Color(0xFFE1F5FE),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Text(
                  'Discover Your Next Adventure',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF29ABE2),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  Text(
                    'Explore amazing destinations around the nepal',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  SlideTransition(
                    position: _slideAnimation,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => TripsPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow[700],
                          padding: EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: Text(
                        'Start Exploring',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _getRecommendedTrips(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                            child: Text('Error: ${snapshot.error}',
                                style: TextStyle(color: Colors.black87)));
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                            child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.yellow.shade700),
                        ));
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                            child: Text('No recommended trips available',
                                style: TextStyle(color: Colors.black87)));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final tripData = snapshot.data![index];
                          final tripId = tripData['id'];

                          return AnimatedContainer(
                            duration:
                                Duration(milliseconds: 400 + (index * 100)),
                            curve: Curves.easeInOut,
                            margin: EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  spreadRadius: 2,
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TripDetailPage(
                                        trip: tripData,
                                        tripId: tripId,
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child:
                                            _buildTripImage(tripData['image']),
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        tripData['title'],
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
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
                                                '${(tripData['rating'] as num?)?.toDouble() ?? 0.0}',
                                                style: TextStyle(
                                                    color: Colors.black54),
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
                                        style: TextStyle(color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    })),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

Widget _buildNoImageAvailable() {
  return Container(
    height: 200,
    width: double.infinity,
    color: Colors.grey[300],
    child: const Center(
        child:
            Text('No Image Available', style: TextStyle(color: Colors.grey))),
  );
}
