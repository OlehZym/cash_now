import 'dart:async';
import 'package:cash_now/main.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  CashierScreenState createState() => CashierScreenState();
}

class CashierScreenState extends State<CashierScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Product> cart = [];
  int total = 0;

  double _progress = 0;
  Timer? _timer;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
  }

  void addItemByArticle(String article) {
    final box = Hive.box<Product>('products');
    final product = box.values.firstWhere(
      (p) => p.article == article,
      orElse:
          () =>
              Product(article: '', name: '', price: 0, stock: 0, category: ''),
    );
    if (product.article == '') {
      showMessage('Товар не найден');
      return;
    }
    if (product.stock <= 0) {
      showMessage('Нет в наличии!');
      return;
    }
    setState(() {
      cart.add(product);
      calculateTotal();
    });
  }

  void calculateTotal() {
    total = cart.fold(0, (sum, item) => sum + item.price);
  }

  void processPayment() {
    if (isProcessing) return;

    setState(() {
      _progress = 0;
      isProcessing = true;
    });

    late StateSetter dialogSetState; // Для обновления состояния внутри диалога

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            dialogSetState = setState;
            return AlertDialog(
              title: Text('Оплата'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${(_progress * 10).toStringAsFixed(0)} / 10'),
                  SizedBox(height: 8),
                  LinearProgressIndicator(value: _progress),
                ],
              ),
            );
          },
        );
      },
    );

    _timer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      _progress += 0.01;
      dialogSetState(() {}); // Обновляем диалог

      if (_progress >= 1.0) {
        timer.cancel();

        final box = Hive.box<Product>('products');
        for (var item in cart) {
          final key = box.keys.firstWhere(
            (k) => box.get(k)!.article == item.article,
          );
          final current = box.get(key)!;
          box.put(
            key,
            Product(
              article: current.article,
              name: current.name,
              price: current.price,
              stock: current.stock - 1,
              category: current.category,
            ),
          );
        }

        setState(() {
          isProcessing = false;
          cart.clear();
          total = 0;
        });

        Navigator.of(context).pop(); // Закрываем диалог

        showMessage('Оплата прошла успешно');
      }
    });
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void close() {
    Navigator.of(context).pop();
  }

  void newProduct() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Добавление товара'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(labelText: 'Артикул'),
                    onSubmitted: (value) {
                      addItemByArticle(value);
                      _controller.clear();
                      close();
                    },
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: () {
                        addItemByArticle(_controller.text);
                        _controller.clear();
                        close();
                      },
                      child: Text(
                        'Добавить',
                        style: TextStyle(
                          color: Color.fromARGB(255, 0, 187, 25),
                        ),
                      ),
                    ),
                    SizedBox(width: 30),
                    ElevatedButton(
                      onPressed: close,
                      child: Text(
                        'Закрыть',
                        style: TextStyle(color: Color.fromARGB(255, 255, 0, 0)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Касса'),
        actions: [
          Padding(
            padding: EdgeInsets.only(top: 6),
            child: IconButton(
              icon: Icon(
                Icons.admin_panel_settings,
                color: Color.fromARGB(255, 4, 0, 255),
                size: 30,
              ),
              onPressed: () => Navigator.pushNamed(context, '/admin'),
            ),
          ),
          SizedBox(width: 15),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            IconButton(
              onPressed: newProduct,
              icon: Icon(
                Icons.add_shopping_cart,
                color: Color.fromARGB(255, 13, 161, 0),
                size: 30,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: cart.length,
                itemBuilder: (context, index) {
                  final item = cart[index];
                  return ListTile(
                    title: Text(item.name),
                    subtitle: Text('${item.price} грн — ${item.category}'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          cart.removeAt(index);
                          calculateTotal();
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            Text('Итого: $total грн', style: TextStyle(fontSize: 20)),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: cart.isEmpty || isProcessing ? null : processPayment,
              child: Text(
                'Оплатить',
                style: TextStyle(color: Color.fromARGB(197, 0, 0, 0)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
