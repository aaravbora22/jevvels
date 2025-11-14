import 'package:flutter/material.dart';
import 'package:jevvels/src/components/dashboard/button.dart';
import 'package:jevvels/src/components/dashboard/gold_card.dart';
import 'package:jevvels/src/components/dashboard/list_tile_dashboard.dart';
import 'package:jevvels/src/components/dashboard/trading_view_card.dart';
import 'package:jevvels/src/components/dashboard/portfolio_card.dart';
import 'package:jevvels/new_entry/new_entry.dart';
import 'package:jevvels/src/pages/bills.dart';
import 'package:jevvels/src/pages/items.dart';
import 'package:jevvels/src/pages/metals_page.dart';
import 'package:jevvels/src/pages/settings.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:jevvels/src/components/dashboard/nav_item.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final PageController _controller = PageController(viewportFraction: 0.98);
  Key _cardsKey = UniqueKey();

  Future<void> _refreshDashboard() async {
    setState(() {
      _cardsKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomAppBar(
        color: const Color.fromARGB(255, 39, 36, 36),
        elevation: 0,
        child: SizedBox(
          height: 55,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              NavItem(
                icon: Icons.home_outlined,
                label: 'Home',
                onTap: () {},
              ),
              NavItem(
                icon: Icons.add_outlined,
                label: 'Add Entry',
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (context) => const JewelryFormPage()),
                  );
                },
              ),
              NavItem(
                icon: Icons.settings_outlined,
                label: 'Settings',
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const Settings()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 39, 36, 36),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                    key: _cardsKey,
                    scrollDirection: Axis.horizontal,
                    children: const [
                      PortfolioCard(),
                      GoldPriceCard(),
                      TradingViewCard(),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                // Indicator + Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      icon:
                          const Icon(Icons.arrow_back_ios, color: Colors.white),
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

                const SizedBox(height: 15),

                // Quick actions (Bills / Items / Metals)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final allowWrap = c.maxWidth < 360;
                      final spacing = 12.0;

                      if (allowWrap) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            alignment: WrapAlignment.spaceAround,
                            children: [
                              MyButton(
                                iconImagePath: 'assets/icons/bill.png',
                                buttonText: 'Bills',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const BillsPage()),
                                  );
                                },
                              ),
                              MyButton(
                                iconImagePath: 'assets/icons/items.png',
                                buttonText: 'Items',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const ItemsPage()),
                                  );
                                },
                              ),
                              MyButton(
                                iconImagePath: 'assets/icons/gold.png',
                                buttonText: 'Metals',
                                onPressed: () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const MetalsPage()),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          MyButton(
                            iconImagePath: 'assets/icons/bill.png',
                            buttonText: 'Bills',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const BillsPage()),
                              );
                            },
                          ),
                          MyButton(
                            iconImagePath: 'assets/icons/items.png',
                            buttonText: 'Items',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const ItemsPage()),
                              );
                            },
                          ),
                          MyButton(
                            iconImagePath: 'assets/icons/gold.png',
                            buttonText: 'Metals',
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                    builder: (context) => const MetalsPage()),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
                SizedBox(height: 10,),
                // Statistics + Liquidate (responsive, aligned)
                // const Padding(
                //   padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 0),
                //   child: Column(
                //     children: const [
                //       MyListTile(
                //         icon: Icon(Icons.bar_chart_rounded),
                //         tileTitle: "Statistics",
                //         tileSubtitle: "View your portfolio statistics",
                //       ),
                //       MyListTile(
                //         icon: Icon(Icons.pie_chart_rounded),
                //         tileTitle: "Liquidate",
                //         tileSubtitle: "View the liquidation breakdown",
                //       ),
                //     ],
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
