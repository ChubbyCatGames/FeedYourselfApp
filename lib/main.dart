import 'dart:isolate';

import 'package:comida/allergensData.dart';
import 'package:comida/color_schemes.g.dart';
import 'package:comida/objectbox.g.dart';
import 'package:flutter/material.dart';
import 'package:sembast/sembast.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/theme.dart';
import 'package:openfoodfacts/openfoodfacts.dart';

import 'dart:math' as math;

import 'package:go_router/go_router.dart';
import 'package:english_words/english_words.dart';

import 'package:barcode_scan2/barcode_scan2.dart';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

import 'package:objectbox/objectbox.dart';
import 'ProductObject.dart';
import 'allergensData.dart';

import 'dart:convert';

import 'objectbox.dart';

late ObjectBox objectBox;
Box allergensBox = objectBox.store.box<AllergensData>();
Box productBox = objectBox.store.box<ProductObject>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  objectBox = await ObjectBox.create();

  InitProducts();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  State<MyApp> createState() => _MyAppState();
}

/////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////TEMA//////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////
////GLOBALES
///
var scanName = "";
List<Ingredient> scanIngredients = [];
Allergens? scanAllergens;
var db;

// Allergies list.
List<Allergy> allergiesList = CreateAllergies();

// Product list.
List<Product> productList = [];

class _MyAppState extends State<MyApp> {
  final GoRouter _router = GoRouter(
    initialLocation: '/recents',
    routes: <RouteBase>[
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return MyAppShell(
            child: child,
          );
        },
        routes: <RouteBase>[
          GoRoute(
            path: '/recents',
            pageBuilder: (context, state) {
              return FadeTransitionPage(
                child: RecentsScreen(),
                key: state.pageKey,
              );
            },
            routes: <RouteBase>[
              GoRoute(
                path: 'product/:productId',
                builder: (BuildContext context, GoRouterState state) {
                  return ProductScreen(
                    productId: state.params['productId'],
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/alergies',
            pageBuilder: (context, state) {
              return FadeTransitionPage(
                child: const AlergiesScreen(),
                key: state.pageKey,
              );
            },
          ),
        ],
      ),
    ],
  );

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Feed Yourself',
      routerConfig: _router,
      theme: ThemeData(
          useMaterial3: true,
          colorScheme: lightColorScheme,
          textTheme: GoogleFonts.poppinsTextTheme(),
          pageTransitionsTheme: pageTransitionsTheme),
      darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: darkColorScheme,
          textTheme: GoogleFonts.poppinsTextTheme(),
          pageTransitionsTheme: pageTransitionsTheme),
      themeMode: ThemeMode.system,
    );
  }
}

//////////////////////////////////////////////////////////////SHELL////////////////////////////////////////////////////////////////

class MyAppShell extends StatelessWidget {
  final Widget child;

  const MyAppShell({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.background,
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: colors.primaryContainer,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time_outlined),
            label: 'Recent',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_box_outlined),
            label: 'Allergies',
          ),
        ],
        currentIndex: _calculateSelectedIndex(context),
        onTap: (int idx) => _onItemTapped(idx, context),
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final GoRouter route = GoRouter.of(context);
    final String location = route.location;
    if (location.startsWith('/alergies')) {
      return 1;
    } else {
      return 0;
    }
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 1:
        GoRouter.of(context).go('/alergies');
        break;
      case 0:
      default:
        GoRouter.of(context).go('/recents');
        break;
    }
  }
}

///////////////////////////////////////////////////
///--------------------SCREENS--------------------
//////////////////////////////////////////////////
///
///
///-----------------RECENT------------------------------
class RecentsScreen extends StatefulWidget {
  RecentsScreen({Key? key}) : super(key: key);
  RecentScreenState createState() => RecentScreenState();
}

class RecentScreenState extends State<RecentsScreen>{
  int counter = 0;
  void updateCounter(){
    setState(() {
      counter++;
    });
  }

@override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    productBox.removeAll();
    InitProducts();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recents'),
        backgroundColor: colors.primaryContainer,
      ),
      body: ListView.builder(
        itemCount: productList.length,
        itemBuilder: (context, productId) {
          //final product = Producto(name, ingredients, allergies,
          //    'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl-2.jpg');
          return ProductTile(
            product: productList[productId],
            onTap: () {
              GoRouter.of(context).go('/recents/product/$productId');
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
          backgroundColor: colors.tertiaryContainer,
          onPressed: () {
            startCamera(context);
          },
          tooltip: 'Camera',
          child: const Icon(Icons.add_a_photo_outlined)),
    );
  }
}

void InitProducts(){
  List<ProductObject> prodList = productBox.getAll() as List<ProductObject>;
    if(prodList.isNotEmpty){
      prodList.forEach((element) async {
        print(prodList.length);
        print(element.barCode);
        Future<Product?> product = getProduct(element.barCode!);
        var product33 = await product;

        //  Check if already exists.
        bool contains = false;
        int index = 0;
        productList.forEach((element) {
        if(element.barcode == product33?.barcode){
          contains = true;
          index = productList.indexOf(element);
        }
        });
        if(!contains){
          productList.add(product33!);
        }
      });
    }
}

void startCamera(BuildContext context) async {
  var result;
  try{
    result = await BarcodeScanner.scan();
  }
  catch(e)
  {
    print(e);
    return null;
  }

  String code = result.rawContent;

  if (result.format == 'qr') {
    print("esto es un qr");
  } else {
    
    var product  = getProduct(code);
    var product33 = await product;

    if(product33 != null){
      bool contains = false;
      int index = 0;
      productList.forEach((element) {
        if(element.barcode == product33?.barcode){
          contains = true;
          index = productList.indexOf(element);
        }
      });

      if(!contains){
        productList.add(product33);
      }else{
        product33 = productList[index];
      }

      // Check if already exists
      final query = productBox.query(ProductObject_.barCode.equals(code));
      final search = query.build().findFirst();
      if(search != null){
        // Add the product to the database
        ProductObject productObject = ProductObject(idProduct: productList.indexOf(product33), barCode: product33.barcode);
        productBox.put(productObject);
      }
      GoRouter.of(context).go('/recents/product/${productList.indexOf(product33).toString()}');
      /*final myWidgetKey = GlobalKey<RecentScreenState>();
      final RecentScreenState widgetState = myWidgetKey.currentState!;
      widgetState.updateCounter();*/
    }
    
  }
}


//----------------------------ALLERGIES----------------------------------------
List<bool> isSelected = List<bool>.generate(10, (index) => false);

class AlergiesScreen extends StatefulWidget {
  const AlergiesScreen({Key? key}) : super(key: key);
  AlergiesScreenState createState() => AlergiesScreenState();
}

class AlergiesScreenState extends State<AlergiesScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.primaryContainer,
        title: const Text('Selected allergies'),
      ),
      body: ListView.builder(
        itemCount: allergiesList.length,
        itemBuilder: (context, index) {
          // Checkbox.
          Color getColor(Set<MaterialState> states) {
            const Set<MaterialState> interactiveStates = <MaterialState>{
              MaterialState.pressed,
              MaterialState.hovered,
              MaterialState.focused,
            };
            if (states.any(interactiveStates.contains)) {
              return Colors.blue;
            }
            return Colors.red;
          }

          return AllergyTile(
              allergy: allergiesList[index],
              imagePath: allergiesList[index].imagePath,
              onTap: () {
                allergiesList[index].ChangeBool();
              });
        },
      ),
    );
  }
}

List<Allergy> CreateAllergies() {
  List<Allergy> allergies = [];
  Allergy lupine = Allergy(0, 'Lupine', 'lib/assets/altramuces.png');
  allergies.add(lupine);
  Allergy celery = Allergy(1, 'Celery', 'lib/assets/Apio.png');
  allergies.add(celery);
  Allergy peanuts = Allergy(2, 'Peanuts', 'lib/assets/cacahuetes.png');
  allergies.add(peanuts);
  Allergy crustaceans = Allergy(3, 'Crustaceans', 'lib/assets/Crustáceos.png');
  allergies.add(crustaceans);
  Allergy gluten = Allergy(4, 'Gluten', 'lib/assets/Gluten.png');
  allergies.add(gluten);
  Allergy eggs = Allergy(5, 'Eggs', 'lib/assets/huevos.png');
  allergies.add(eggs);
  Allergy dairy = Allergy(6, 'Dairy', 'lib/assets/leche.png');
  allergies.add(dairy);
  Allergy mollusks = Allergy(7, 'Mollusks', 'lib/assets/moluscos.png');
  allergies.add(mollusks);
  Allergy mustard = Allergy(8, 'Mustard', 'lib/assets/Mostaza.png');
  allergies.add(mustard);
  Allergy nuts = Allergy(9, 'Nuts', 'lib/assets/nueces.png');
  allergies.add(nuts);
  Allergy fish = Allergy(10, 'Fish', 'lib/assets/pescado.png');
  allergies.add(fish);
  Allergy sesame = Allergy(11, 'Sesame', 'lib/assets/Sésamo.png');
  allergies.add(sesame);
  Allergy soy = Allergy(12, 'Soy', 'lib/assets/Soja.png');
  allergies.add(soy);
  Allergy sulphites = Allergy(13, 'Sulphites', 'lib/assets/Sulfitos.png');
  allergies.add(sulphites);
  //allergensBox.removeAll();
  allergies.forEach((element) {
    AddToBox(element);
    print(element.isSelected);
  });

  return allergies;
}

void AddToBox(Allergy allergy) {
  final query = allergensBox.query(AllergensData_.idAllergy.equals(allergy.id));
  final search = query.build().findFirst();
  if (search != null) return;
  AllergensData data = AllergensData(
      id: 0,
      idAllergy: allergy.id,
      name: allergy.name,
      isChecked: allergy.isSelected);
  allergensBox.put(data);
}

//-----------------------------------------------PRODUCT--------------------------------------------------------------
class ProductScreen extends StatelessWidget {
  final String? productId;

  const ProductScreen({
    required this.productId,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final product = productList[int.parse(productId!)];
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.primaryContainer,
        title: Text(
          'Product - ${product.productName}',
        ),
      ),
      body: Center(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child:SizedBox(
                  width: 200,
                  height: 200,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    child: Image.network(product.imageFrontSmallUrl!),
                  ),
                ),
                ),
                Expanded(
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Container( 
                        child: Wrap(
                          children: [
                            Container(
                              child:Text(product.productName!,
                              style:
                              (TextStyle(color: colors.primary, fontSize: 20))),
                            )
                          ]
                        )
                      )
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Container( 
                        child: Wrap(
                          children: [
                            Container(
                              child:Text(
                                product.brands!,
                                style: (TextStyle(
                                color: colors.primary,
                              )),
                              ),
                            )
                          ]
                        )
                      )
                    ),
                  ],
                ),
                )
              ],
            ),
            Row(children: [
              Flexible(
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  color: colors.secondaryContainer,
                  child: Text(
                    product.ingredientsText?.toString() ?? 'No hay ingredientes en la base de datos de OpenFoodFacts',
                    style: TextStyle(color: colors.onSecondaryContainer),
                  ),
                ),
              )
            ])
          ],
        ),
      ),
    );
  }
}

///-----------------------PRODUCT SCREEN CAMERA
class ProductScreenCamera extends StatelessWidget {
  final String? productName;
  final List<Ingredient>? productIngredients;
  final Allergens? allergies;

  const ProductScreenCamera({
    required this.productName,
    required this.productIngredients,
    required this.allergies,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final product = Producto('0', productName as String, 'Hacendado',
        'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl-2.jpg');
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.primaryContainer,
        title: Text(
          'Product - ${product.name}',
        ),
      ),
      body: Center(
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    child: Image.network(product.rutaImagen),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.contain,
                      child: Text(product.name,
                          style:
                              (TextStyle(color: colors.primary, fontSize: 20))),
                    ),
                    FittedBox(
                      fit: BoxFit.contain,
                      child: Text(
                        product.name,
                        style: (TextStyle(
                          color: colors.primary,
                        )),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Row(children: [
              Flexible(
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  color: colors.secondaryContainer,
                  child: Text(
                    productIngredients as String,
                    style: TextStyle(color: colors.onSecondaryContainer),
                  ),
                ),
              )
            ])
          ],
        ),
      ),
    );
  }
}

///-------------------------------------

///-------------------TILES----------------
class Producto {
  final String id;
  final String name;
  final String brand;
  final String rutaImagen;

  Producto(this.id, this.name, this.brand, this.rutaImagen);
}

class Allergy {
  final int id;
  final String name;
  final String imagePath;
  bool? isSelected;

  Allergy(this.id, this.name, this.imagePath) {
    final query = allergensBox.query(AllergensData_.idAllergy.equals(this.id));
    final data = query.build().findFirst();
    if (data != null) {
      print(data.idAllergy.toString() + data.isChecked.toString());
      this.isSelected = data.isChecked;
    } else {
      this.isSelected = false;
    }
  }

  String get fullId => '$name-$id';

  void ChangeBool() {
    isSelected = !isSelected!;
  }
}

class ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductTile({Key? key, required this.product, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      leading: SizedBox(
        width: 50,
        height: 50,
        child: Container(
          child: Image.network(
              product.imageFrontSmallUrl!),
        ),
      ),
      tileColor: colors.secondaryContainer,
      textColor: colors.onSecondaryContainer,
      title: Text(product.productName!),
      subtitle: Text(product.brands!),
      onTap: onTap,
    );
  }
}

class AllergyTile extends StatefulWidget {
  final Allergy allergy;
  final String imagePath;
  final VoidCallback? onTap;

  const AllergyTile(
      {Key? key, required this.allergy, required this.imagePath, this.onTap})
      : super(key: key);

  AllergyTileState createState() => AllergyTileState();
}

class AllergyTileState extends State<AllergyTile> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Color getColor(Set<MaterialState> states) {
      const Set<MaterialState> interactiveStates = <MaterialState>{
        MaterialState.pressed,
        MaterialState.hovered,
        MaterialState.focused,
      };
      if (states.any(interactiveStates.contains)) {
        return colors.primaryContainer;
      }
      return colors.secondaryContainer;
    }

    final Checkbox cb = Checkbox(
      checkColor: colors.primaryContainer,
      fillColor: MaterialStateProperty.resolveWith(getColor),
      value: widget.allergy.isSelected,
      onChanged: (bool? value) {
        setState(() {
          widget.allergy.isSelected = value!;
        });
      },
    );
    return ListTile(
        leading: SizedBox(
          width: 100,
          height: 50,
          child: Container(
            // ignore: sort_child_properties_last
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  cb,
                  Image.asset(widget.imagePath),
                ]),
            //color: allergy.image,
            margin: const EdgeInsets.all(8),
          ),
        ),
        tileColor: colors.secondaryContainer,
        textColor: colors.onSecondaryContainer,
        selectedTileColor: colors.errorContainer,
        title: Text(widget.allergy.name),
        onTap: () {
          //allergiesList[widget.allergy.id].ChangeBool();
          //print(allergiesList[widget.allergy.id].isSelected.toString());
          widget.allergy.isSelected = !widget.allergy.isSelected!;
          cb.onChanged!(widget.allergy.isSelected);
          final query = allergensBox
              .query(AllergensData_.idAllergy.equals(widget.allergy.id));
          AllergensData data = query.build().findFirst();
          data.isChecked = widget.allergy.isSelected;
          allergensBox.put(data);
        });
  }
}

////////////////
///////////////////////////////////
////////////////////////////////////
///////////////////A PARTIR DE AQUI ES OPENFOODFACTS//////
//////////////////////////
///////////
///
/// request a product from the OpenFoodFacts database
Future<Product?> getProduct(String barcode) async {
  final ProductQueryConfiguration configuration = ProductQueryConfiguration(
    barcode,
    language: OpenFoodFactsLanguage.SPANISH,
    fields: [ProductField.ALL],
    version: ProductQueryVersion.v3,
  );
  final ProductResultV3 result =
      await OpenFoodAPIClient.getProductV3(configuration);

  if (result.status == ProductResultV3.statusSuccess) {
    if (result.product?.productName != null) {
      scanName = result.product?.productName as String;
    }
    if (result.product?.ingredients != null) {
      scanIngredients = result.product?.ingredients as List<Ingredient>;
      if (scanIngredients.isEmpty) {
        scanIngredients.add(Ingredient(text: await extractIngredient(barcode)));
      }
    }
    if (result.product?.allergens != null) {
      scanAllergens = result.product?.allergens as Allergens?;
    }
    ProductScreenCamera(
      productName: scanName,
      productIngredients: scanIngredients,
      allergies: scanAllergens,
    );
    print("hola");
    print(scanName.toString());
    print(scanIngredients.toString());
    print(scanAllergens?.names.toString());
    return result.product;
  } else {
    //throw Exception('product not found, please insert data for $barcode');
    return null;
  }
}

/// add a new product to the OpenFoodFacts database
void addNewProduct() async {
  // define the product to be added.
  // more attributes available ...
  Product myProduct = Product(
    barcode: '0048151623426',
    productName: 'Maryland Choc Chip',
  );

  // a registered user login for https://world.openfoodfacts.org/ is required
  User myUser = User(userId: 'max@off.com', password: 'password');

  // query the OpenFoodFacts API
  Status result = await OpenFoodAPIClient.saveProduct(myUser, myProduct);

  if (result.status != 1) {
    throw Exception('product could not be added: ${result.error}');
  }
}

/// add a new image for an existing product of the OpenFoodFacts database
void addProductImage() async {
  // define the product image
  // set the uri to the local image file
  // choose the "imageField" as location / description of the image content.
  SendImage image = SendImage(
    lang: OpenFoodFactsLanguage.ENGLISH,
    barcode: '0048151623426',
    imageField: ImageField.INGREDIENTS,
    imageUri: Uri.parse('Path to you image'),
  );

  // a registered user login for https://world.openfoodfacts.org/ is required
  User myUser = User(userId: 'max@off.com', password: 'password');

  // query the OpenFoodFacts API
  Status result = await OpenFoodAPIClient.addProductImage(myUser, image);

  if (result.status != 'status ok') {
    throw Exception(
        'image could not be uploaded: ${result.error} ${result.imageId.toString()}');
  }
}

/// Extract the ingredients of an existing product of the OpenFoodFacts database
/// That has already ingredient image
/// Otherwise it should be added first to the server and then this can be called
Future<String?> extractIngredient(String barcode) async {
  // a registered user login for https://world.openfoodfacts.org/ is required
  User myUser = User(userId: 'max@off.com', password: 'password');

  // query the OpenFoodFacts API
  OcrIngredientsResult response = await OpenFoodAPIClient.extractIngredients(
      myUser, barcode, OpenFoodFactsLanguage.SPANISH);

  if (response.status != 0) {
    throw Exception("Text can't be extracted.");
  }
  return response.ingredientsTextFromImage;
}

/// Extract the ingredients of an existing product of the OpenFoodFacts database
/// That does not have ingredient image
/// And then save it back to the OFF server
void saveAndExtractIngredient() async {
  // a registered user login for https://world.openfoodfacts.org/ is required
  User myUser = User(userId: 'max@off.com', password: 'password');

  SendImage image = SendImage(
    lang: OpenFoodFactsLanguage.FRENCH,
    barcode: '3613042717385',
    imageField: ImageField.INGREDIENTS,
    imageUri: Uri.parse('Path to your image'),
  );

  //Add the ingredients image to the server
  Status results = await OpenFoodAPIClient.addProductImage(myUser, image);

  if (results.status == null) {
    throw Exception('Adding image failed');
  }

  OcrIngredientsResult ocrResponse = await OpenFoodAPIClient.extractIngredients(
      myUser, '3613042717385', OpenFoodFactsLanguage.FRENCH);

  if (ocrResponse.status != 0) {
    throw Exception("Text can't be extracted.");
  }

  // Save the extracted ingredients to the product on the OFF server
  results = await OpenFoodAPIClient.saveProduct(
      myUser,
      Product(
          barcode: '3613042717385',
          ingredientsText: ocrResponse.ingredientsTextFromImage));

  if (results.status != 1) {
    throw Exception('product could not be added');
  }

  //Get The saved product's ingredients from the server
  final ProductQueryConfiguration configurations = ProductQueryConfiguration(
      '3613042717385',
      version: ProductQueryVersion.v3,
      language: OpenFoodFactsLanguage.FRENCH,
      fields: [
        ProductField.INGREDIENTS_TEXT,
      ]);
  final ProductResultV3 productResult =
      await OpenFoodAPIClient.getProductV3(configurations, user: myUser);

  if (productResult.status != 1) {
    throw Exception('product not found, please insert data for 3613042717385');
  }
}

/// Get suggestion based on:
/// Your user input
/// The preference language
/// The TagType
void getSuggestions() async {
  // The result will be a List<dynamic> that can be parsed
  await OpenFoodAPIClient.getAutocompletedSuggestions(TagType.COUNTRIES,
      input: 'Tun', language: OpenFoodFactsLanguage.FRENCH);
}

///-----------------------------------

class FadeTransitionPage extends CustomTransitionPage<void> {
  FadeTransitionPage({
    required LocalKey key,
    required Widget child,
  }) : super(
            key: key,
            transitionsBuilder: (BuildContext context,
                    Animation<double> animation,
                    Animation<double> secondaryAnimation,
                    Widget child) =>
                FadeTransition(
                  opacity: animation.drive(_curveTween),
                  child: child,
                ),
            child: child);

  static final CurveTween _curveTween = CurveTween(curve: Curves.easeIn);
}
