import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        backgroundColor: Colors.black,
      ),
      body: user == null
          ? const Center(
              child: Text('Please log in to view your favorites.',
                  style: TextStyle(color: Colors.white70)))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('favorites')
                  .snapshots(),
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.favorite_border,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No favorites yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var tripData = snapshot.data!.docs[index].data()
                        as Map<String, dynamic>;
                    return Dismissible(
                      key: Key(tripData['title']),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      onDismissed: (direction) async {
                        // Remove from favorites in Firestore
                        final user = FirebaseAuth
                            .instance.currentUser; // Get user again to be sure
                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Not logged in!")));
                          return;
                        }
                        try {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .collection('favorites')
                              .doc(snapshot.data!.docs[index].id)
                              .delete();

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Removed from favorites.')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Error removing favorite: $e')),
                          );
                        }
                      },
                      child: Card(
                        margin: const EdgeInsets.all(10),
                        color: Colors.grey[900],
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(tripData['image'] ??
                                    ''), // Handle possible null image
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          title: Text(
                            tripData['title'] ?? 'No Title',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Row(
                            children: [
                              Icon(Icons.star,
                                  color: Colors.yellow[700], size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${tripData['rating'] ?? 0.0}', //Handle possible null rating
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                          trailing: Text(
                            tripData['price'] ?? 'Unknown Price',
                            style: const TextStyle(
                              color: Color.fromARGB(255, 237, 188, 61),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
