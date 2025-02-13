import 'dart:io'; // Import dart:io for File
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class AddTripForm extends StatefulWidget {
  @override
  _AddTripFormState createState() => _AddTripFormState();
}

class _AddTripFormState extends State<AddTripForm> {
  File? _selectedImage; // Store the selected image file
  bool _isImageLoading = false; //Track the image loading

  Future<void> _pickImage() async {
    setState(() {
      _isImageLoading = true; // Set loading true to show loading indicator
    });

    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      //Get the temp directory
      Directory appDocDir = await getTemporaryDirectory();
      String appDocPath = appDocDir.path;

      //Create a new file in the temp directory
      String imageName = path.basename(pickedFile.path);
      File newFile = File('$appDocPath/$imageName');

      //Copy the picked file to the new file
      File imageFile = File(pickedFile.path);
      await imageFile.copy(newFile.path);

      setState(() {
        _selectedImage =
            newFile; // Update the state with the selected image file
        _isImageLoading = false; // set loading to false
      });
    } else {
      setState(() {
        _isImageLoading = false; // set loading to false
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Trip')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Pick Image from Gallery'),
            ),
            _isImageLoading
                ? CircularProgressIndicator() //Loading progress
                : _selectedImage == null
                    ? Text('No image selected')
                    : Image.file(
                        _selectedImage!,
                        height: 150,
                      ),
            // Other form fields (trip details) go here ...
            ElevatedButton(
              onPressed: () {
                // Here, you would save the trip details
                // Along with the _selectedImage (path or file)
                // You can either:
                // 1. Upload _selectedImage to cloud storage NOW
                // 2. Store the _selectedImage.path locally (NOT recommended long-term)
                //    and upload it later.

                //Example: print the image path
                if (_selectedImage != null) {
                  print('Image path: ${_selectedImage!.path}');
                  // TODO: Process/upload image here
                } else {
                  print('No image selected.');
                }
              },
              child: Text('Save Trip'),
            ),
          ],
        ),
      ),
    );
  }
}
