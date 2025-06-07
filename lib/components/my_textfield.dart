import 'package:flutter/material.dart';

class MyTextfield extends StatelessWidget {
  final controller;
  final String hintText;
  final bool obscureText;
  const MyTextfield({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: TextField(
        controller: controller, // Used to access what users type
        obscureText: obscureText, // Boolean to mask password when typing
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blueAccent.shade400),
          ),
          fillColor: Colors.grey.shade200,
          filled: true,
          hintText: hintText, // hints whgat to be typed in the text field
          hintStyle: TextStyle(color: Colors.grey[500]),
        ),
      ),
    );
  }
}
