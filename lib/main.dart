import 'package:cash_now/admin_screen.dart';
import 'package:cash_now/my_home_page.dart';
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
