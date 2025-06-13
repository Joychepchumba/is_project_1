import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:is_project_1/components/my_textfield.dart';
import 'package:is_project_1/components/square_tile.dart';
import 'package:is_project_1/components/image_picker_widget.dart';
import 'package:is_project_1/pages/login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final emergencyContactController = TextEditingController();
  final expertiseAreaController = TextEditingController();
  final emegencyContactNameController = TextEditingController();
  final emergencyContactEmailController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _obscureConfirmPassword = true;
  bool _obscurePassword = true;

  int selectedRole = 5;

  String defaultStatus = "Pending";

  File? _profileImage;
  bool _isLoading = false;

  static const String API_BASE_URL =
      'https://b72e-197-136-185-70.ngrok-free.app';

  String get roleString {
    return selectedRole == 5
        ? 'Safety Concerned Individual'
        : 'Legal Aid Provider';
  }

  Future<void> registerUser() async {
    // Basic validation
    if (nameController.text.isEmpty ||
        phoneController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      _showErrorDialog('Please fill in all required fields');
      return;
    }

    if (roleString == 'Safety Concerned Individual' &&
        (emergencyContactController.text.isEmpty ||
            emegencyContactNameController.text.isEmpty ||
            emergencyContactEmailController.text.isEmpty)) {
      _showErrorDialog('Please provide emergency contact');
      return;
    }

    if (roleString == 'Legal Aid Provider' &&
        expertiseAreaController.text.isEmpty) {
      _showErrorDialog('Please provide expertise area');
      return;
    }

    if (_profileImage != null) {
      final fileSize = await _profileImage!.length();
      if (fileSize > 2 * 1024 * 1024) {
        _showErrorDialog('Image size must be less than 2MB');
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (roleString == 'Safety Concerned Individual') {
        await _registerSafetyUser();
      } else {
        await _registerLegalAidProvider();
      }
    } catch (e) {
      _showErrorDialog('Registration failed: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _registerSafetyUser() async {
    final url = Uri.parse('$API_BASE_URL/register/user');

    String? profileImageBase64;
    if (_profileImage != null) {
      final bytes = await _profileImage!.readAsBytes();
      profileImageBase64 = base64Encode(bytes);
    }

    final requestBody = {
      'full_name': nameController.text.trim(),
      'phone_number': phoneController.text.trim(),
      'email': emailController.text.trim(),
      'password_hash': passwordController.text,
      'emergency_contact': emergencyContactController.text.trim(),
      'contact_name': emegencyContactNameController.text.trim(),
      'email_contact': emergencyContactEmailController.text.trim(),
      'role_id': selectedRole,
      'status': 'Pending',
      'profile_image': profileImageBase64,
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(requestBody),
    );

    if (response.statusCode == 200) {
      _showSuccessDialog('Registration successful!');
    } else {
      final errorData = json.decode(response.body);
      throw Exception('Registration failed');
    }
  }

  Future<void> _registerLegalAidProvider() async {
    final url = Uri.parse('$API_BASE_URL/register/legal_aid_provider');

    String? profileImageBase64;
    if (_profileImage != null) {
      final bytes = await _profileImage!.readAsBytes();
      profileImageBase64 = base64Encode(bytes);
    }

    final requestBody = {
      'full_name': nameController.text.trim(),
      'phone_number': phoneController.text.trim(),
      'email': emailController.text.trim(),
      'password_hash': passwordController.text,
      'expertise_area': expertiseAreaController.text.trim(),
      'role_id': selectedRole,
      'status': defaultStatus,
      'profile_image': profileImageBase64,
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(requestBody),
    );

    if (response.statusCode == 200) {
      _showSuccessDialog('Registration successful!');
    } else {
      final errorData = json.decode(response.body);
      throw Exception('Registration failed');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              Text(
                'Create an Account',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),

              const SizedBox(height: 20),

              // Profile Image Picker
              ImagePickerWidget(
                onImagePicked: (image) {
                  setState(() {
                    _profileImage = image;
                  });
                },
              ),

              const SizedBox(height: 30),

              // Full Name
              MyTextfield(
                controller: nameController,
                hintText: 'Full Name',
                obscureText: false,
              ),
              const SizedBox(height: 15),

              // Phone Number
              MyTextfield(
                controller: phoneController,
                hintText: 'Phone Number',
                obscureText: false,
              ),
              const SizedBox(height: 15),

              // Email
              MyTextfield(
                controller: emailController,
                hintText: 'Email',
                obscureText: false,
              ),
              const SizedBox(height: 15),

              // Password
              MyTextfield(
                controller: passwordController,
                hintText: 'Password',
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),

              const SizedBox(height: 15),
              MyTextfield(
                controller: confirmPasswordController,
                hintText: 'Confirm Password',
                obscureText: _obscureConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: 15),

              // Role Selection
              DropdownButtonFormField<int>(
                value: selectedRole,
                decoration: InputDecoration(
                  labelText: 'Select Role',
                  filled: true,
                  fillColor: Colors.grey[200],
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent.shade400),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                dropdownColor: Colors.white,
                items: const [
                  DropdownMenuItem(
                    value: 5,
                    child: Text('Safety Concerned Individual'),
                  ),
                  DropdownMenuItem(value: 6, child: Text('Legal Aid Provider')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedRole = value!;
                  });
                },
              ),

              const SizedBox(height: 15),

              // Conditional Fields based on roleString
              if (roleString == 'Safety Concerned Individual') ...[
                MyTextfield(
                  controller: emegencyContactNameController,
                  hintText: 'Emergency Contact Name',
                  obscureText: false,
                ),
                const SizedBox(height: 15),
                MyTextfield(
                  controller: emergencyContactController,
                  hintText: 'Emergency Contact',
                  obscureText: false,
                ),
                const SizedBox(height: 15),
                MyTextfield(
                  controller: emergencyContactEmailController,
                  hintText: 'Emergency Contact Email',
                  obscureText: false,
                ),
              ],

              if (roleString == 'Legal Aid Provider')
                MyTextfield(
                  controller: expertiseAreaController,
                  hintText: 'Expertise Area',
                  obscureText: false,
                ),

              const SizedBox(height: 30),

              // Register Button
              ElevatedButton(
                onPressed: _isLoading ? null : registerUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 104, 164, 203),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text('Register', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 25),

              // Divider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        thickness: 0.5,
                        color: Colors.blueAccent[400],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text(
                        'or continue with',
                        style: TextStyle(color: Colors.blueAccent[700]),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        thickness: 0.5,
                        color: Colors.blueAccent[400],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account?'),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    emergencyContactController.dispose();
    expertiseAreaController.dispose();
    emegencyContactNameController.dispose();
    emergencyContactEmailController.dispose();
    super.dispose();
  }
}
