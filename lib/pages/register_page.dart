import 'package:flutter/material.dart';
import 'package:is_project_1/components/my_textfield.dart';
import 'package:is_project_1/components/square_tile.dart';

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

  String selectedRole = 'Safety Concerned Individual';

  void registerUser() {
    print("Name: ${nameController.text}");
    print("Phone: ${phoneController.text}");
    print("Email: ${emailController.text}");
    print("Password: ${passwordController.text}");
    print("Role: $selectedRole");

    if (selectedRole == 'Safety Concerned Individual') {
      print("Emergency Contact: ${emergencyContactController.text}");
    } else if (selectedRole == 'Legal Aid Provider') {
      print("Expertise Area: ${expertiseAreaController.text}");
    }
  }

  Widget buildTextField(
    String label,
    TextEditingController controller, {
    bool obscure = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(labelText: label, border: InputBorder.none),
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
              const SizedBox(height: 30),
              Text(
                'Create an Account',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 30),
              MyTextfield(
                controller: nameController,
                hintText: 'Full Name',
                obscureText: false,
              ),

              const SizedBox(height: 15),

              MyTextfield(
                controller: phoneController,
                hintText: 'Phone Number',
                obscureText: false,
              ),
              const SizedBox(height: 15),

              MyTextfield(
                controller: emailController,
                hintText: 'Email',
                obscureText: false,
              ),

              const SizedBox(height: 15),

              MyTextfield(
                controller: passwordController,
                hintText: 'Password',
                obscureText: true,
              ),

              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: InputDecoration(
                  labelText: 'Select Role',
                  filled: true,
                  fillColor: Colors.grey[200],
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white,
                    ), // Default white border
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.blueAccent.shade400,
                    ), // Focused blue border
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                dropdownColor: Colors.white,
                items: const [
                  DropdownMenuItem(
                    value: 'Safety Concerned Individual',
                    child: Text(
                      'Safety Concerned Individual',
                      style: TextStyle(color: Colors.grey), // Text always grey
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Legal Aid Provider',
                    child: Text(
                      'Legal Aid Provider',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedRole = value!;
                  });
                },
              ),

              const SizedBox(height: 15),

              if (selectedRole == 'Safety Concerned Individual')
                MyTextfield(
                  controller: emergencyContactController,
                  hintText: 'Emergency Contact',
                  obscureText: false,
                ),

              if (selectedRole == 'Legal Aid Provider')
                MyTextfield(
                  controller: expertiseAreaController,
                  hintText: 'Expertise Area',
                  obscureText: false,
                ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: registerUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 104, 164, 203),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Register', style: TextStyle(fontSize: 16)),
              ),
              //or continue with
              const SizedBox(height: 25),

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

              //google _apple sign in button.
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  //google btn
                  SquareTile(imagePath: 'assets/images/google_logo.png'),
                  SizedBox(
                    width: 10,
                  ), // you had 'const SizedBox' here, just corrected
                ],
              ),

              const SizedBox(height: 20),

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
}
