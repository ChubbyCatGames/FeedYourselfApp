import 'ProductObject.dart';
import 'objectbox.g.dart';

class ObjectBox{
  late final Store store;

  late final Box<ProductObject> productBox;

  ObjectBox._create(this.store){
    productBox = Box<ProductObject>(store);
  }


  static Future<ObjectBox> create() async{
    final store = await openStore();
    return ObjectBox._create(store);
  }

  /*void addProduct(){
    ProductObject newProduct = ProductObject();

    productBox.put(newProduct);
  }*/

  Stream<List<ProductObject>> getProducts(){
    final builder = productBox.query()..order(ProductObject_.id, flags: Order.descending);
    return builder.watch(triggerImmediately: true).map((query) => query.find());
  }

}