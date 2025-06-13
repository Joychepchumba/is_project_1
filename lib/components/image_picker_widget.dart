import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ImagePickerWidget extends StatefulWidget {
  final Function(File?) onImagePicked;

  const ImagePickerWidget({super.key, required this.onImagePicked});

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  File? _image;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });

      widget.onImagePicked(_image);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[300],
            backgroundImage: _image != null ? FileImage(_image!) : null,
            child: _image == null
                ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                : null,
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _pickImage,
          child: const Text('Select Profile Image'),
        ),
      ],
    );
  }
}
