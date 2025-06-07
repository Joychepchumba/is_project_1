import 'package:flutter/material.dart';
import 'package:is_project_1/components/app_logo.dart';
import 'package:is_project_1/components/my_button.dart';
import 'package:is_project_1/components/my_textfield.dart';
import 'package:is_project_1/components/square_tile.dart';
import 'package:is_project_1/pages/register_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  // Your Vercel deployed API URL
  static const String baseUrl = 'https://your-project-name.vercel.app';

  void signUserIn() async {
    // Validate input
    if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
      showErrorMessage('Please fill in all fields');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Prepare the request body for OAuth2PasswordRequestForm
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': usernameController.text.trim(),
          'password': passwordController.text,
        },
      );

      if (response.statusCode == 200) {
        // Parse the response
        final Map<String, dynamic> responseData = json.decode(response.body);

        // Store tokens securely
        await storeTokens(
          responseData['access_token'],
          responseData['refresh_token'],
        );

        // Navigate to home page or dashboard
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/home',
          ); // Update with your route
          showSuccessMessage('Login successful!');
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
                  obscureText: true,
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

                //google sign in button.
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    //google btn
                    SquareTile(imagePath: 'assets/images/google_logo.png'),
                    SizedBox(width: 10),
                  ],
                ),
                const SizedBox(height: 30),
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
