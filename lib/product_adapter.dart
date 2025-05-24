import 'main.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
