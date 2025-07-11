import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:is_project_1/components/app_logo.dart';
import 'package:is_project_1/components/my_button.dart';
import 'package:is_project_1/components/my_textfield.dart';
import 'package:is_project_1/pages/admin_pages/admin_homepage.dart';
import 'package:is_project_1/pages/legal_aid_pages/legalaid_homepage.dart';
import 'package:is_project_1/pages/register_page.dart';
import 'package:is_project_1/pages/user_pages/user_homepage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  bool _obscurePassword = true;
  String baseUrl = 'https://b0b2bb2b9a75.ngrok-free.app'; // Default fallback

  @override
  void initState() {
    super.initState();
    loadEnv();
  }

  Future<void> loadEnv() async {
    try {
      await dotenv.load(fileName: ".env");
      setState(() {
        baseUrl = dotenv.env['API_BASE_URL'] ?? baseUrl;
      });
    } catch (e) {
      print('Error loading .env file: $e');
    }
  }

  // Your deployed Vercel API URL for now we'll use the local Ip cause vercel did that thing:(

  Map<String, dynamic> decodeJWT(String token) {
    final parts = token.split('.');
    if (parts.length != 3) throw Exception('Invalid token');

    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    return json.decode(decoded);
  }

  void signUserIn() async {
    if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
      showErrorMessage('Please fill in all fields');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': usernameController.text.trim(),
          'password': passwordController.text,
        },
      );

      if (response.statusCode == 200) {
        final Map responseData = json.decode(response.body);

        await storeTokens(
          responseData['access_token'],
          responseData['refresh_token'],
        );

        // Decode the JWT to get role information
        try {
          final tokenPayload = decodeJWT(responseData['access_token']);
          int roleId = tokenPayload['role_id'];
          final prefs = await SharedPreferences.getInstance();

          final userId = tokenPayload['sub']; // this is the user ID

          // Save user_id to SharedPreferences
          await prefs.setString('user_id', userId);

          if (mounted) {
            Widget destinationPage;
            if (roleId == 4) {
              destinationPage = const AdminHomepage();
            } else if (roleId == 6) {
              destinationPage = const LegalAidHomepage();
            } else {
              destinationPage = const UserHomepage();
            }
            final userId = tokenPayload['sub']; // Save UUID from token
            await prefs.setString('user_id', userId);

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => destinationPage),
            );

            showSuccessMessage('Login successful!');
          }
        } catch (e) {
          showErrorMessage('Authentication error. Please try again.');
          print('JWT decode error: $e');
        }
      } else if (response.statusCode == 400) {
        final Map<String, dynamic> errorData = json.decode(response.body);
        showErrorMessage(errorData['detail'] ?? 'Invalid credentials');
      } else {
        showErrorMessage('Login failed. Please try again.');
      }
    } catch (e) {
      showErrorMessage('Network error. Please check your connection.');
      print('Login error: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Store tokens securely using shared_preferences
  Future<void> storeTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }

  // Show error message
  void showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Show success message
  void showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //logo
                AppLogo(imagePath: 'assets/images/app_logo.png'),

                const SizedBox(height: 30),

                //welcome textfield
                Text(
                  'LOG IN :)',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 25),
                //phone number or email
                MyTextfield(
                  controller: usernameController,
                  hintText: 'Email or Phone Number',
                  obscureText: false,
                ),
                //password textfield
                const SizedBox(height: 7),
                MyTextfield(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 10),
                //forgot password?
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Forgot Password',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
                //sign-in button with loading state
                isLoading
                    ? const CircularProgressIndicator()
                    : MyButton(onTap: signUserIn),

                //or continue with
                const SizedBox(height: 25),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(thickness: 0.5, color: Colors.grey[400]),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                          'or continue with',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                      Expanded(
                        child: Divider(thickness: 0.5, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),

                //Register
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Not a member ?',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(width: 4.0),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterPage(),
                          ),
                        );
                      },
                      child: const Text(
                        'Register now',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}

class SuccessPage extends StatelessWidget {
  const SuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const Center(
        child: Text(
          'Welcome, you are logged in!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
