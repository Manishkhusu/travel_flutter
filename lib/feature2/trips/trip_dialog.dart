// trip_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_xploverse/feature2/model/tripmodel.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class TripDialog extends StatefulWidget {
  final bool isEdit;
  final Function(Map<String, dynamic> tripData, File? imageFile) onSubmit;
  final Trip? trip; // Make Trip nullable

  TripDialog(
      {Key? key, required this.isEdit, required this.onSubmit, this.trip})
      : super(key: key);

  @override
  _TripDialogState createState() => _TripDialogState();
}

class _TripDialogState extends State<TripDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController titleController;
  late TextEditingController priceController;
  late TextEditingController durationController;
  late TextEditingController descriptionController;
  late TextEditingController locationController;
  late TextEditingController hashtagsController;
  File? selectedImage;
  bool isLoading = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();

    // Initialize controllers with trip data if it's an edit, otherwise use empty strings
    titleController = TextEditingController(text: widget.trip?.title ?? '');
    priceController = TextEditingController(text: widget.trip?.price ?? '');
    durationController =
        TextEditingController(text: widget.trip?.duration ?? '');
    descriptionController =
        TextEditingController(text: widget.trip?.description ?? '');
    locationController =
        TextEditingController(text: widget.trip?.location ?? '');
    hashtagsController = TextEditingController(
        text: widget.trip?.hashtags.join(' ') ?? ''); // Handle null hashtags
  }

  @override
  void dispose() {
    titleController.dispose();
    priceController.dispose();
    durationController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    hashtagsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(widget.isEdit ? 'Edit Trip' : 'Add New Trip',
          style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black)), //Updated
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: isLoading ? null : _pickImage,
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(selectedImage!, fit: BoxFit.cover))
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate,
                                color: Colors.grey[600], size: 36),
                            const SizedBox(height: 8),
                            Text('Add Image (Optional)',
                                style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                style:
                    const TextStyle(color: Colors.black), //Updated text color
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Trip Title',
                  labelStyle: const TextStyle(
                      color: Colors.black), //Added to all fields
                  hintText: 'Enter trip title',
                  hintStyle:
                      const TextStyle(color: Colors.grey), //Added to all input

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                style:
                    const TextStyle(color: Colors.black), //Updated text color

                controller: locationController,
                decoration: InputDecoration(
                  labelText: 'Location',
                  labelStyle: const TextStyle(
                      color: Colors.black), //Added to all fields
                  hintText: 'Enter location',
                  hintStyle:
                      const TextStyle(color: Colors.grey), //Added to all input
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                style:
                    const TextStyle(color: Colors.black), //Updated text color
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Price',
                  labelStyle: const TextStyle(
                      color: Colors.black), //Added to all fields
                  hintText: 'Enter price',
                  hintStyle:
                      const TextStyle(color: Colors.grey), //Added to all input
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                style:
                    const TextStyle(color: Colors.black), //Updated text color
                controller: durationController,
                decoration: InputDecoration(
                  labelText: 'Duration',
                  labelStyle: const TextStyle(
                      color: Colors.black), //Added to all fields
                  hintText: 'Enter duration (e.g., 7 days)',
                  hintStyle:
                      const TextStyle(color: Colors.grey), //Added to all input
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                style:
                    const TextStyle(color: Colors.black), //Updated text color
                controller: descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: const TextStyle(
                      color: Colors.black), //Added to all fields
                  hintText: 'Enter description',
                  hintStyle:
                      const TextStyle(color: Colors.grey), //Added to all input
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                style:
                    const TextStyle(color: Colors.black), //Updated text color
                controller: hashtagsController,
                decoration: InputDecoration(
                  labelText: 'Hashtags',
                  labelStyle: const TextStyle(
                      color: Colors.black), //Added to all fields
                  hintText: 'Enter hashtags (space-separated)',
                  hintStyle:
                      const TextStyle(color: Colors.grey), //Added to all input
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel',
              style: TextStyle(
                  fontSize: 16, color: Colors.black)), //Add black color
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF29ABE2),
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : Text(widget.isEdit ? 'Update Trip' : 'Add Trip'),
          onPressed: isLoading
              ? null
              : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      isLoading = true;
                    });

                    final tripData = {
                      'title': titleController.text,
                      'location': locationController.text,
                      'price': priceController.text,
                      'duration': durationController.text,
                      'description': descriptionController.text,
                      'hashtags': hashtagsController.text.split(' '),
                    };

                    widget.onSubmit(tripData,
                        selectedImage); // Let the TripsPage handle submission
                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Trip delete successfully!'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );

                    setState(() {
                      isLoading = false;
                    });
                  }
                },
        ),
      ],
    );
  }
}
