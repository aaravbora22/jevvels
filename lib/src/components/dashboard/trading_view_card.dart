import 'package:flutter/material.dart';
import 'package:jevvels/api/tradingview_widget.dart';

class TradingViewCard extends StatelessWidget {
  const TradingViewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        width: 300,
        height: 300,
        padding: const EdgeInsets.all(10.0),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          color: Color(0xFFB99750), // Gold tone
        ),
        child: const ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(15)),
          child: TradingViewWebView(), // Your embedded chart widget
        ),
      ),
    );
  }
}
