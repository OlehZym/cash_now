import 'package:cash_now/main.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
