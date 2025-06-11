import 'package:flutter/material.dart';
import 'dart:io';
import 'edit_profile.dart';
import 'profile_details.dart';

class UserProfilePage extends StatefulWidget {
  final VoidCallback onLogout;

  const UserProfilePage({super.key, required this.onLogout});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  String _name = 'Jane Doe';
  String _email = 'jane.doe@example.com';
  File? _profileImage;
  bool _showEditForm = false;

  void _updateProfile(String newName, String newEmail, File? newImage) {
    setState(() {
      _name = newName;
      _email = newEmail;
      if (newImage != null) _profileImage = newImage;
      _showEditForm = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile updated')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ProfileDetails(
              name: _name,
              email: _email,
              imageUrl: _profileImage?.path,
            ),
            const SizedBox(height: 20),
            _showEditForm
                ? EditProfileForm(
                    initialName: _name,
                    initialEmail: _email,
                    onSave: _updateProfile,
                  )
                : ElevatedButton.icon(
                    onPressed: () => setState(() => _showEditForm = true),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profile'),
                  ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: widget.onLogout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
