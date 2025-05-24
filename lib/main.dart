import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';

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

class ProductAdapter extends TypeAdapter<Product> {
  @override
  final typeId = 0;

  @override
  Product read(BinaryReader reader) {
    return Product(
      article: reader.readString(),
      name: reader.readString(),
      price: reader.readInt(),
      stock: reader.readInt(),
      category: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, Product obj) {
    writer.writeString(obj.article);
    writer.writeString(obj.name);
    writer.writeInt(obj.price);
    writer.writeInt(obj.stock);
    writer.writeString(obj.category);
  }
}

class CashNow extends StatelessWidget {
  const CashNow({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: CashierScreen(),
      routes: {'/admin': (_) => AdminScreen()},
    );
  }
}

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

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  AdminScreenState createState() => AdminScreenState();
}

class AdminScreenState extends State<AdminScreen> {
  final TextEditingController _articleController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  void _clearControllers() {
    _articleController.clear();
    _nameController.clear();
    _priceController.clear();
    _stockController.clear();
    _categoryController.clear();
  }

  void saveNewProduct() {
    final article = _articleController.text.trim();
    final name = _nameController.text.trim();
    final price = int.tryParse(_priceController.text.trim()) ?? 0;
    final stock = int.tryParse(_stockController.text.trim()) ?? 0;
    final category = _categoryController.text.trim();

    if (article.isEmpty || name.isEmpty) return;

    final box = Hive.box<Product>('products');

    final exists = box.values.any((product) => product.article == article);
    if (exists) {
      // Покажи предупреждение или SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Товар с таким артикулом уже существует')),
      );
      return;
    }

    box.add(
      Product(
        article: article,
        name: name,
        price: price,
        stock: stock,
        category: category,
      ),
    );

    Navigator.of(context).pop();
    _clearControllers();
  }

  void deleteProduct(int key) {
    Hive.box<Product>('products').delete(key);
  }

  void saveProduct(Product product, int key) {
    final name = _nameController.text.trim();
    final price = int.tryParse(_priceController.text.trim()) ?? 0;
    final stock = int.tryParse(_stockController.text.trim()) ?? 0;
    final category = _categoryController.text.trim();

    if (name.isEmpty) return;

    final updatedProduct = Product(
      article: product.article, // не даем менять артикул
      name: name,
      price: price,
      stock: stock,
      category: category,
    );

    final box = Hive.box<Product>('products');
    box.put(key, updatedProduct);

    Navigator.of(context).pop();
    _clearControllers();
  }

  void close() {
    Navigator.of(context).pop();
  }

  void addProduct() {
    _clearControllers();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Добавление товара'),
          content: SingleChildScrollView(
            // чтобы окно не обрезалось
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _articleController,
                  decoration: InputDecoration(labelText: 'Артикул'),
                ),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Название'),
                ),
                TextField(
                  controller: _priceController,
                  decoration: InputDecoration(labelText: 'Цена'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _stockController,
                  decoration: InputDecoration(labelText: 'Количество'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _categoryController,
                  decoration: InputDecoration(labelText: 'Категория'),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: saveNewProduct,
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

  void editProduct(Product product, int key) {
    _articleController.text = product.article;
    _nameController.text = product.name;
    _priceController.text = product.price.toString();
    _stockController.text = product.stock.toString();
    _categoryController.text = product.category;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Редактирование товара'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _articleController,
                  decoration: InputDecoration(labelText: 'Артикул'),
                  enabled: false, // запрет на изменение артикула
                ),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Название'),
                ),
                TextField(
                  controller: _priceController,
                  decoration: InputDecoration(labelText: 'Цена'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _stockController,
                  decoration: InputDecoration(labelText: 'Количество'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _categoryController,
                  decoration: InputDecoration(labelText: 'Категория'),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        saveProduct(product, key); // ← здесь всё корректно
                      },
                      child: Text(
                        'Сохранить',
                        style: TextStyle(
                          color: Color.fromARGB(255, 0, 187, 25),
                        ),
                      ),
                    ),
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
  Widget build(BuildContext context) {
    final box = Hive.box<Product>('products');

    return Scaffold(
      appBar: AppBar(
        title: Text('Управление товарами'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(top: 6), // отступ сверху
            child: IconButton(
              icon: Icon(
                Icons.add,
                color: Color.fromARGB(255, 4, 0, 255),
                size: 40,
              ),
              onPressed: addProduct,
            ),
          ),
          SizedBox(width: 15), // отступ после иконки
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: box.listenable(),
                builder: (context, Box<Product> box, _) {
                  final items = box.toMap().entries.toList();
                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final key = items[index].key as int;
                      final item = items[index].value;
                      return ListTile(
                        title: Text('${item.article} — ${item.name}'),
                        subtitle: Text(
                          '${item.price} грн / Остаток: ${item.stock} / ${item.category}',
                        ),
                        trailing: Row(
                          mainAxisSize:
                              MainAxisSize
                                  .min, // Чтобы кнопки не занимали всё пространство
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.edit,
                                color: const Color.fromARGB(255, 255, 193, 7),
                              ),
                              onPressed: () => editProduct(item, key),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: Color.fromARGB(199, 255, 0, 0),
                              ),
                              onPressed: () => deleteProduct(key),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
