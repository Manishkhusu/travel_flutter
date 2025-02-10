import 'dart:io';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_xploverse/feature2/favourite_page.dart';
import 'package:flutter_xploverse/feature2/presentation/view/login.dart';
import 'package:flutter_xploverse/feature2/presentation/viewmodel/authentication.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rxdart/rxdart.dart'; // Import FavoritesPage

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthServices _auth = AuthServices();
  final CollectionReference allUsers =
      FirebaseFirestore.instance.collection('users');
  final User? user = FirebaseAuth.instance.currentUser;
  final ImagePicker _imagePicker = ImagePicker();
  String? imageUrl;
  bool isLoading = false;
  bool get isGoogleSignIn =>
      user?.providerData
          .any((userInfo) => userInfo.providerId == 'google.com') ??
      false;
  int totalBookings = 0;
  int totalEvents = 0;
  int createdEvents = 0;
  int totalFavorites = 0; // Add this

  final _bookingStream = BehaviorSubject<int>();
  final _createdEventStream = BehaviorSubject<int>();
  final _bookedEventStream = BehaviorSubject<int>();
  final _favoriteStream = BehaviorSubject<int>(); // Add this

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  @override
  void dispose() {
    _bookingStream.close();
    _createdEventStream.close();
    _bookedEventStream.close();
    _favoriteStream.close(); // Add this
    super.dispose();
  }

  void _setupListeners() {
    _bookingStream.listen((value) {
      setState(() {
        totalBookings = value;
      });
    });

    _createdEventStream.listen((value) {
      setState(() {
        createdEvents = value;
      });
    });

    _bookedEventStream.listen((value) {
      setState(() {
        totalEvents = value;
      });
    });

    _favoriteStream.listen((value) {
      setState(() {
        totalFavorites = value;
      });
    });

    fetchBookingInfo();
    fetchCreatedEvents();
    fetchTotalFavorites(); // Add this
  }

  Future<void> fetchBookingInfo() async {
    try {
      FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: user?.uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.length != totalBookings) {
          _bookingStream.add(snapshot.docs.length);
          _bookedEventStream
              .add(snapshot.docs.map((doc) => doc['eventId']).toSet().length);
        }
      });
    } catch (e) {
      print("Failed to retrieve booking information: $e");
    }
  }

  Future<void> fetchCreatedEvents() async {
    try {
      FirebaseFirestore.instance
          .collection('events')
          .where('organizerId', isEqualTo: user?.uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.length != createdEvents) {
          _createdEventStream.add(snapshot.docs.length);
        }
      });
    } catch (e) {
      print("Failed to retrieve created events: $e");
    }
  }

  Future<void> fetchTotalFavorites() async {
    // Add this function
    try {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('favorites')
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.length != totalFavorites) {
          _favoriteStream.add(snapshot.docs.length);
        }
      });
    } catch (e) {
      print("Failed to retrieve total favorites: $e");
    }
  }

  Future<void> pickImage() async {
    if (isGoogleSignIn) return;

    try {
      final XFile? pickedFile =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        await uploadImageToFirebase(File(pickedFile.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Failed to pick image: $e"),
        ),
      );
    }
  }

  Future<void> uploadImageToFirebase(File image) async {
    setState(() {
      isLoading = true;
    });
    try {
      Reference reference = FirebaseStorage.instance
          .ref()
          .child("images/${DateTime.now().microsecondsSinceEpoch}.png");

      await reference.putFile(image).whenComplete(() async {
        String downloadUrl = await reference.getDownloadURL();
        await allUsers
            .doc(user?.uid)
            .update({'profilePictureUrl': downloadUrl});
        setState(() {
          imageUrl = downloadUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            content: Text("Upload Successful!"),
          ),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Failed to upload image: $e"),
        ),
      );
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Colors.black;
    final cardColor = Colors.grey[900];
    final textColor = Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: backgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: allUsers
            .doc(user?.uid)
            .snapshots()
            .debounceTime(const Duration(milliseconds: 500)),
        builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No user data found'));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String? profilePictureUrl = isGoogleSignIn
              ? user?.photoURL
              : (imageUrl ??
                  userData['profilePictureUrl'] ??
                  user?.photoURL ??
                  'https://via.placeholder.com/150');
          bool isOrganizer = userData['usertype'] == 'Organizer';

          if (isOrganizer) {
            fetchCreatedEvents();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: NetworkImage(profilePictureUrl!),
                    ),
                    if (isLoading)
                      const Positioned.fill(
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    if (!isGoogleSignIn)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: pickImage,
                          child: const CircleAvatar(
                            backgroundColor: Colors.blue,
                            radius: 20,
                            child: Icon(
                              Icons.edit,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  userData['username'] ?? user?.displayName ?? 'Username',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  (userData['usertype'] ?? 'User Type').toUpperCase(),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 30),
                _buildInfoCard(
                  title: 'User Information',
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoText('Email', userData['email'] ?? ''),
                      _buildInfoText('Bio', userData['bio'] ?? ''),
                      // Remove the original bookings Row
                      const SizedBox(height: 20),
                      GestureDetector(
                        // Wrap with GestureDetector
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    FavoritesPage()), // Navigate to FavoritesPage
                          );
                        },
                        child: Container(
                          // Style like the original containers
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                "Total Favorites",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "$totalFavorites",
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.yellow,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isOrganizer) ...[
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Text(
                                      "Created Events",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "$createdEvents",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Colors.yellow,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Text(
                                      "Phone",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      userData['phone'] ?? "",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Colors.yellow,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    _showUpdateProfileDialog(userData);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text(
                    'Update Profile',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await _auth.signOut();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Logout'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({required String title, required Widget content}) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.yellow[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreference(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70),
          ),
          Icon(
            value ? Icons.check_circle : Icons.cancel,
            color: value ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoText(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  void _showUpdateProfileDialog(Map<String, dynamic> userData) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newBio = userData['bio'] ?? '';
        String newPhone = userData['phone'] ?? '';
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.90,
            decoration: BoxDecoration(
              gradient: isDarkMode
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF212121), Color(0xFF000000)],
                    )
                  : const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFE2E2E2),
                        Colors.white,
                      ],
                    ),
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Update Profile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (value) {
                      newBio = value;
                    },
                    controller: TextEditingController(text: newBio),
                    decoration: InputDecoration(
                      hintText: 'Enter your new bio',
                      hintStyle: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 16),
                  if (userData['usertype'] == 'Organizer')
                    TextField(
                      onChanged: (value) {
                        newPhone = value;
                      },
                      controller: TextEditingController(text: newPhone),
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'Enter your phone number',
                        hintStyle: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.red,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: const Text(
                          'Update',
                          style: TextStyle(
                            color: Colors.blue,
                          ),
                        ),
                        onPressed: () {
                          // Update the user document with the new values
                          allUsers.doc(user?.uid).update({
                            'bio': newBio,
                            if (userData['usertype'] == 'Organizer')
                              'phone': newPhone,
                          }).then((_) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profile updated successfully'),
                              ),
                            );
                          }).catchError((error) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Failed to update profile: $error'),
                              ),
                            );
                          });
                        },
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
  }
}
