import 'package:flutter/material.dart';

class MyListTile extends StatelessWidget {
  final Icon icon;
  final String tileTitle;
  final String tileSubtitle;
  const MyListTile({
    Key? key,
    required this.icon,
    required this.tileTitle,
    required this.tileSubtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 15,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // icon
              Container(
                padding: const EdgeInsets.all(12),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFB99750),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon.icon,
                    color: Color.fromARGB(255, 39, 36, 36), size: 25),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tileTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Main Font',
                    ),
                  ),
                  Text(
                    tileSubtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Main Font',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white),
        ],
      ),
    );
  }
}
