// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_xploverse/feature2/firestores.dart';

// class CrudPage extends StatefulWidget {
//   const CrudPage({super.key});

//   @override
//   _CrudPageState createState() => _CrudPageState();
// }

// class _CrudPageState extends State<CrudPage> {
//   final FirestoreServices firestoreServices = FirestoreServices();
//   final TextEditingController textcontroller = TextEditingController();

//   void openNoteBox() {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           content: TextField(
//             controller: textcontroller,
//           ),
//           actions: [
//             ElevatedButton(
//                 onPressed: () {
//                   // Only add if text is not empty
//                   if (textcontroller.text.isNotEmpty) {
//                     firestoreServices.addReview(textcontroller.text);
//                     textcontroller.clear();
//                     Navigator.pop(context);
//                   }
//                 },
//                 child: const Text("Add"))
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('CRUD Operations'),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: openNoteBox,
//         child: const Icon(Icons.add),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: firestoreServices.getNotesStream(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }

//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text("No notes available"));
//           }

//           List<DocumentSnapshot> reviewsList = snapshot.data!.docs;

//           return ListView.builder(
//             itemCount: reviewsList.length,
//             itemBuilder: (context, index) {
//               DocumentSnapshot document = reviewsList[index];
//               String docID = document.id;

//               // Safely cast and access the data
//               Map<String, dynamic>? data =
//                   document.data() as Map<String, dynamic>?;

//               // Handle potential null or missing 'note' field
//               String noteText = data?['note']?.toString() ?? 'No content';

//               return ListTile(
//                 title: Text(noteText),
//                 // Optional: Add delete functionality
//                 trailing: IconButton(
//                   icon: const Icon(Icons.delete),
//                   onPressed: () {
//                     // Implement delete functionality here
//                     // firestoreServices.deleteNote(docID);
//                   },
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     textcontroller.dispose();
//     super.dispose();
//   }
// }
