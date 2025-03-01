import 'dart:io';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_xploverse/feature2/favourite_page.dart';
import 'package:flutter_xploverse/feature2/presentation/view/login.dart';
import 'package:flutter_xploverse/feature2/presentation/viewmodel/authentication.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

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
  File? selectedImage;
  bool isLoading = false;

  int totalFavorites = 0;

  final _favoriteStream = BehaviorSubject<int>();

  // Custom Hashtags Controller
  final TextEditingController _customHashtagsController =
      TextEditingController();

  // Preset Hashtag Options (Same as in TripDetailPage)
  String? _selectedWeather;
  String? _selectedTravelDays;
  String? _selectedBudget;
  String? _localImagePath;
  bool isOrganizer = false; // Initialize with a default value

  List<String> weatherOptions = ['sunny', 'rainy', 'foggy', 'cloudy'];
  List<String> travelDaysOptions = ['1-3 days', '4-7 days', '7+ days'];
  List<String> budgetOptions = ['NPR < 1000', 'NPR 1000-5000', 'NPR > 5000'];

  @override
  void initState() {
    super.initState();
    _setupListeners();
    _loadUserData(); // Load both custom and preset hashtags
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

  Future<void> _pickImage() async {
    final XFile? image =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // Save the image locally
      final File? localImage = await _saveImageLocally(File(image.path));

      if (localImage != null) {
        setState(() {
          selectedImage = localImage;
          _localImagePath = localImage.path; // Store for immediate display
        });
        await _saveImagePath(
            localImage.path); // Persist path for future sessions
      } else {
        // Handle error saving image locally
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save image locally'),
          ),
        );
      }
    }
  }

  // Function to save the image locally
  Future<File?> _saveImageLocally(File image) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = path.join(directory.path,
          'profile_${DateTime.now().millisecondsSinceEpoch}.png'); // Unique name

      final File newImage = await image.copy(imagePath);
      return newImage;
    } catch (e) {
      print("Error saving image locally: $e");
      return null;
    }
  }

  Future<void> _loadUserData() async {
    DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
        .instance
        .collection('users')
        .doc(user?.uid)
        .get();

    if (userDoc.exists) {
      var userData = userDoc.data();
      setState(() {
        //Load Custom Hastags
        _customHashtagsController.text =
            (userData?['hashtags'] as List<dynamic>?)?.join(' ') ?? '';

        //Load Preference Hastags
        _selectedWeather =
            (userData?['presetHashtags'] as Map<String, dynamic>?)?['weather'];
        _selectedTravelDays = (userData?['presetHashtags']
            as Map<String, dynamic>?)?['travelDays'];
        _selectedBudget =
            (userData?['presetHashtags'] as Map<String, dynamic>?)?['budget'];

        // Determine if the user is an organizer
        isOrganizer = (userData?['usertype'] == 'Organizer');
      });
    }
  }

  @override
  void dispose() {
    _favoriteStream.close();
    _customHashtagsController.dispose(); //Dispose memory

    super.dispose();
  }

  void _setupListeners() {
    _favoriteStream.listen((value) {
      setState(() {
        totalFavorites = value;
      });
    });

    fetchTotalFavorites();
  }

  Future<void> fetchTotalFavorites() async {
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

  Future<void> _updateUserData() async {
    //Save User Data
    List<String> customHashtags = _customHashtagsController.text.split(' ');

    //Save Preferences Data
    Map<String, dynamic> presetHashtags = {
      'weather': _selectedWeather,
      'travelDays': _selectedTravelDays,
      'budget': _selectedBudget,
    };

    await allUsers.doc(user?.uid).update({
      'hashtags': customHashtags,
      'presetHashtags': presetHashtags,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully! 🎉'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Object _buildProfileImage() {
    if (selectedImage != null) {
      return FileImage(File(selectedImage!.path));
    } else if (_localImagePath != null) {
      return FileImage(File(_localImagePath!));
    } else {
      return const NetworkImage('https://via.placeholder.com/150');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1F5FE),
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.black87)),
        backgroundColor: const Color.fromARGB(255, 45, 165, 251),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
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
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: TextStyle(color: Colors.black54)));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
                child: Text('No user data found',
                    style: TextStyle(color: Colors.black54)));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;

          // Determine if the user is an organizer here as well, in case _loadUserData didn't complete yet.
          bool currentIsOrganizer = (userData['usertype'] == 'Organizer');

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
                      backgroundImage: _buildProfileImage() as ImageProvider,
                    ),
                    if (isLoading)
                      const Positioned.fill(
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: const CircleAvatar(
                          backgroundColor: Color(0xFF29ABE2),
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
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF29ABE2),
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
                      const SizedBox(height: 8),
                      const Text(
                        'Your Interests(Custom Hastags)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      TextField(
                        controller: _customHashtagsController,
                        decoration: const InputDecoration(
                            hintText: 'Enter your interests (space-separated)',
                            hintStyle: TextStyle(
                                color: Colors.grey), // Set hint text color
                            labelStyle: TextStyle(
                                color: Colors.black), //Set label text color
                            border: OutlineInputBorder()),
                        style: const TextStyle(
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Your Preferences',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      Column(
                        children: [
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(labelText: 'Weather'),
                            value: _selectedWeather,
                            items: weatherOptions
                                .map((option) => DropdownMenuItem(
                                      value: option,
                                      child: Text(option),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedWeather = value;
                              });
                            },
                          ),
                          DropdownButtonFormField<String>(
                            decoration:
                                InputDecoration(labelText: 'Travel Days'),
                            value: _selectedTravelDays,
                            items: travelDaysOptions
                                .map((option) => DropdownMenuItem(
                                      value: option,
                                      child: Text(option),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedTravelDays = value;
                              });
                            },
                          ),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(labelText: 'Budget'),
                            value: _selectedBudget,
                            items: budgetOptions
                                .map((option) => DropdownMenuItem(
                                      value: option,
                                      child: Text(option),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedBudget = value;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => FavoritesPage()),
                          );
                        },
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
                                "Total Favorites",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
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
                      if (currentIsOrganizer) ...[
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
                    _updateUserData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF29ABE2),
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 18),
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 17),
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
      color: Colors.white,
      elevation: 4,
      margin: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            content,
          ],
        ),
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
            color: Colors.black,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}
