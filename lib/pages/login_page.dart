import 'package:flutter/material.dart';
import 'package:is_project_1/components/app_logo.dart';
import 'package:is_project_1/components/my_button.dart';
import 'package:is_project_1/components/my_textfield.dart';
import 'package:is_project_1/components/square_tile.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  void signUserIn() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        // Safe area helps avoid the top notch area.
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //logo
              AppLogo(imagePath: 'assets/images/app_logo.png'),

              const SizedBox(height: 50),

              //welcome textfield
              Text(
                'Welcome back we missed you :)',
                style: TextStyle(color: Colors.grey[700], fontSize: 16),
              ),

              const SizedBox(height: 25),
              //phone number
              MyTextfield(
                controller: usernameController,
                hintText: 'username',
                obscureText: false,
              ),
              //password textfield
              MyTextfield(
                controller: passwordController,
                hintText: 'password',
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

              const SizedBox(height: 25),
              //sign-in button.
              MyButton(onTap: signUserIn),

              //or continue with
              const SizedBox(height: 50),

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
                  // A divider is a line.
                ),
              ),

              //google _apple sign in button.
              const SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  //google btn
                  SquareTile(imagePath: 'assets/images/google_logo.png'),
                  const SizedBox(width: 10),
                  //apple btn.
                  SquareTile(imagePath: 'assets/images/apple_logo.png'),
                ],
              ),
              const SizedBox(height: 50),
              //Register
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Not a member ?',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    'Register now',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
