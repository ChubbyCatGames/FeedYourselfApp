import 'productObject.dart';
import 'objectbox.g.dart';

class ObjectBox{
  late final Store store;

  late final Box<productObject> productBox;

  ObjectBox._create(this.store){
    productBox = Box<productObject>(store);

    if(productBox.isEmpty()){
      _putDemoData();
    }
  }

  void _putDemoData(){
    productObject product1= productObject();
    productObject product2= productObject();
    
    productBox.putMany([product1, product2]);
  }


  static Future<ObjectBox> create() async{
    final store = await openStore();
    return ObjectBox._create(store);
  }

  void addProduct(){
    productObject newProduct = productObject();

    productBox.put(newProduct);
  }

  Stream<List<productObject>> getProducts(){
    final builder = productBox.query()..order(productObject_.id, flags: Order.descending);
    return builder.watch(triggerImmediately: true).map((query) => query.find());
  }

}