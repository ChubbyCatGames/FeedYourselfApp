import 'package:objectbox/objectbox.dart';
import 'package:openfoodfacts/openfoodfacts.dart';


@Entity()
class ProductObject {
  @Id()
  int id = 0;

  int? idProduct;

  String? barCode;

  ProductObject(
    {this.id = 0,
    required this.idProduct,
    required this.barCode,
    }
  );
}
