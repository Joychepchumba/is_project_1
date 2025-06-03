import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final String imagePath;
  const AppLogo({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(),
      child: Image.asset(imagePath),
    );
  }
}
