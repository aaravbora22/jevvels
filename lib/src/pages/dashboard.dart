import 'package:flutter/material.dart';
import 'package:jevvels/src/components/dashboard/button.dart';
import 'package:jevvels/src/components/dashboard/gold_card.dart';
import 'package:jevvels/src/components/dashboard/list_tile.dart';
import 'package:jevvels/src/components/dashboard/trading_view_card.dart';
import 'package:jevvels/src/components/dashboard/portfolio_card.dart';
import 'package:jevvels/new_entry/new_entry.dart';
import 'package:jevvels/src/pages/settings.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:jevvels/src/components/dashboard/nav_item.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({
    super.key,
  });

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final PageController _controller = PageController(viewportFraction: 0.98);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomAppBar(
        color: const Color.fromARGB(255, 39, 36, 36),
        elevation: 0,
        child: SizedBox(
          height: 55, // Set the actual height of the nav bar
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              NavItem(
                icon: Icons.home_outlined,
                label: 'Home',
                onTap: () {
                  // Navigate to home
                },
              ),
              NavItem(
                icon: Icons.add_outlined,
                label: 'Add Entry',
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const JewelryFormPage(),
                    ),
                  );
                },
              ),
              NavItem(
                icon: Icons.settings_outlined,
                label: 'Settings',
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const Settings(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 39, 36, 36),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // App bar
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 30),
                child: Row(
                  children: [
                    Text(
                      "Your",
                      style: TextStyle(
                        fontSize: 30,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Main Font',
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Portfolio",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB99750),
                        fontFamily: 'Main Font',
                      ),
                    ),
                  ],
                ),
              ),

              // Cards
              SizedBox(
                height: 320,
                child: PageView(
                  controller: _controller,
                  scrollDirection: Axis.horizontal,
                  children: const [
                    PortfolioCard(),
                    GoldPriceCard(
                      price24k: 72.45,
                      price22k: 66.10,
                      price18k: 54.85,
                    ),
                    TradingViewCard(),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              // Indicator + Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () {
                      _controller.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                  SmoothPageIndicator(
                    controller: _controller,
                    count: 3,
                    effect: const WormEffect(
                      dotColor: Colors.white38,
                      activeDotColor: Color(0xFFB99750),
                      dotHeight: 10,
                      dotWidth: 10,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios,
                        color: Colors.white),
                    onPressed: () {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(
                height: 15,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // bills button
                    MyButton(
                        iconImagePath: 'assets/icons/bill.png',
                        buttonText: 'Bills'),
                    // items button
                    MyButton(
                        iconImagePath: 'assets/icons/items.png',
                        buttonText: 'Items'),
                    // gold button
                    MyButton(
                        iconImagePath: 'assets/icons/gold.png',
                        buttonText: 'Metals')
                  ],
                ),
              ),
              // column -> stats + transactions
              const Padding(
                padding: EdgeInsets.all(30.0),
                child: Column(
                  children: [
                    // statistics
                    MyListTile(
                      icon: Icon(
                        Icons.bar_chart_outlined,
                      ),
                      tileTitle: "Statistics",
                      tileSubtitle: "View your portfolio statistics",
                    ),
                    MyListTile(
                      icon: Icon(
                        Icons.pie_chart_outline,
                      ),
                      tileTitle: "Liquidate",
                      tileSubtitle: "View the liquidation breakwdown",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
