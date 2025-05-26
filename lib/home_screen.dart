import 'package:flutter/material.dart';
import 'admin_screen.dart';
import 'cashier_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  final List<Widget> pages = const [CashierScreen(), AdminScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(
                  Icons.point_of_sale,
                  color: Color.fromARGB(255, 0, 38, 255),
                ),
                label: Text('Касса'),
              ),
              NavigationRailDestination(
                icon: Icon(
                  Icons.admin_panel_settings,
                  color: Color.fromARGB(255, 255, 0, 0),
                ),
                label: Text('Админ'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: pages[selectedIndex]),
        ],
      ),
    );
  }
}
