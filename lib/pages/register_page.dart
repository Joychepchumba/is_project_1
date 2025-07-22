import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:is_project_1/components/my_textfield.dart';
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
  final emegencyContactNameController = TextEditingController();
  final emergencyContactEmailController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final pskController = TextEditingController();
  final aboutController = TextEditingController();

  bool _obscureConfirmPassword = true;
  bool _obscurePassword = true;

  int selectedRole = 5;
  List<int> selectedExpertiseAreas = [];
  List<Map<String, dynamic>> expertiseAreas = [];
  bool _loadingExpertiseAreas = false;

  String defaultStatus = "Pending";

  File? _profileImage;
  bool _isLoading = false;
  String API_BASE_URL =
      dotenv.env['API_BASE_URL'] ??
      'https://8d6b815e648b.ngrok-free.app'; // Default fallback

  // Default fallback

  //static const String API_BASE_URL = 'https://81bb-41-81-48-172.ngrok-free.app';

  String get roleString {
    return selectedRole == 5
        ? 'Safety Concerned Individual'
        : 'Legal Aid Provider';
  }

  @override
  void initState() {
    super.initState();
    _loadExpertiseAreas();
    loadEnv();
  }

  Future<void> loadEnv() async {
    try {
      await dotenv.load(fileName: ".env");
      setState(() {
        API_BASE_URL =
            dotenv.env['API_BASE_URL'] ??
            'http://localhost:8000'; // Default fallback
      });
    } catch (e) {
      print('Error loading .env file: $e');
    }
  }

  Future<void> _loadExpertiseAreas() async {
    setState(() {
      _loadingExpertiseAreas = true;
    });

    try {
      final url = Uri.parse('$API_BASE_URL/expertise-areas');
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          expertiseAreas = data.cast<Map<String, dynamic>>();
        });
      } else {
        print('Failed to load expertise areas: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading expertise areas: $e');
    } finally {
      setState(() {
        _loadingExpertiseAreas = false;
      });
    }
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

    // Password confirmation validation
    if (passwordController.text != confirmPasswordController.text) {
      _showErrorDialog('Passwords do not match');
      return;
    }

    if (roleString == 'Safety Concerned Individual' &&
        (emergencyContactController.text.isEmpty ||
            emegencyContactNameController.text.isEmpty ||
            emergencyContactEmailController.text.isEmpty)) {
      _showErrorDialog('Please provide emergency contact information');
      return;
    }

    if (roleString == 'Legal Aid Provider' && selectedExpertiseAreas.isEmpty) {
      _showErrorDialog('Please select at least one expertise area');
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
      'emergency_contact_number': emergencyContactController.text.trim(),
      'emergency_contact_name': emegencyContactNameController.text.trim(),
      'emergency_contact_email': emergencyContactEmailController.text.trim(),
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
    } else if (response.statusCode == 422) {
      final errorData = json.decode(response.body);

      // Get first validation error (or show all if you prefer)
      final errorMsg = errorData['detail'][0]['msg'];
      _showErrorDialog('Validation Error: $errorMsg');
    } else {
      _showErrorDialog('Registration failed. Please try again.');
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
      'expertise_area_ids': selectedExpertiseAreas, // Changed to array of IDs
      'role_id': selectedRole,
      'status': defaultStatus,
      'profile_image': profileImageBase64,
      'psk_number': pskController.text.trim(),
      'about': aboutController.text.trim(),
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

  Widget _buildExpertiseAreaSelector() {
    // Email

    if (_loadingExpertiseAreas) {
      return Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        MyTextfield(
          controller: pskController,
          hintText: 'Key in your LSK practicing certificate number',
          obscureText: false,
        ),
        const SizedBox(height: 15),
        MyTextfield(
          controller: aboutController,
          hintText:
              'Write a brief description about yourself,eg education, experience, etc.',
          obscureText: false,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Expertise Areas',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: expertiseAreas.map((area) {
                  final isSelected = selectedExpertiseAreas.contains(
                    area['id'],
                  );
                  return FilterChip(
                    label: Text(area['name']),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          selectedExpertiseAreas.add(area['id']);
                        } else {
                          selectedExpertiseAreas.remove(area['id']);
                        }
                      });
                    },
                    selectedColor: Colors.blue.shade100,
                    checkmarkColor: Colors.blue.shade700,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        if (selectedExpertiseAreas.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Selected: ${selectedExpertiseAreas.length} area(s)',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ],
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
                    // Clear expertise areas when role changes
                    selectedExpertiseAreas.clear();
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

              if (roleString == 'Legal Aid Provider') ...[
                _buildExpertiseAreaSelector(),
              ],

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
    emegencyContactNameController.dispose();
    emergencyContactEmailController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
