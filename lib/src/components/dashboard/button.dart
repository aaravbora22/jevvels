import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final String iconImagePath;
  final String buttonText;

  const MyButton({
    Key? key,
    required this.iconImagePath,
    required this.buttonText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 90,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.transparent, // transparent background
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFB99750), // gold outline
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Image.asset(iconImagePath, color: const Color(0xFFB99750)),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          buttonText,
          style: const TextStyle(
            fontFamily: 'Main Font',
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}
