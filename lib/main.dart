import 'package:cash_now/admin_screen.dart';
import 'package:cash_now/cashier_screen.dart';
import 'package:cash_now/product_adapter.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(ProductAdapter());
  await Hive.openBox<Product>('products');
  runApp(CashNow());
}

class Product {
  final String article;
  final String name;
  final int price;
  final int stock;
  final String category;

  Product({
    required this.article,
    required this.name,
    required this.price,
    required this.stock,
    required this.category,
  });
}

class CashNow extends StatelessWidget {
  const CashNow({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MyHomePage(), // БЫЛО: CashierScreen()
      routes: {'/admin': (_) => AdminScreen()},
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final List<Tab> myTabs = const [
    Tab(icon: Icon(Icons.point_of_sale), text: 'Касса'),
    Tab(icon: Icon(Icons.admin_panel_settings), text: 'Админ'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CashNow'),
        bottom: TabBar(controller: _tabController, tabs: myTabs),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [CashierScreen(), AdminScreen()],
      ),
    );
  }
}
