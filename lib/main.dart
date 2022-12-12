import 'dart:isolate';

import 'package:comida/color_schemes.g.dart';
import 'package:flutter/material.dart';
import 'package:openfoodfacts/model/ProductResultV3.dart';
import 'package:sembast/sembast.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/theme.dart';
import 'package:openfoodfacts/openfoodfacts.dart';

import 'package:openfoodfacts/model/OcrIngredientsResult.dart';
import 'package:openfoodfacts/utils/TagType.dart';

import 'dart:math' as math;

import 'package:go_router/go_router.dart';
import 'package:english_words/english_words.dart';

import 'package:barcode_scan2/barcode_scan2.dart';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

void main() {
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
var scanIngredients = "";
var scanAllergens = "";
var db;

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
class RecentsScreen extends StatelessWidget {
  var name = "";
  var ingredients = "";
  var allergies = "";
  var store = intMapStoreFactory.store();
  RecentsScreen({Key? key}) : super(key: key);
  SetupDatabase() async {
    // get the application documents directory
    var dir = await getApplicationDocumentsDirectory();
// make sure it exists
    await dir.create(recursive: true);
// build the database path
    var dbPath = join(dir.path, 'productos.db');
// open the database
    db = await databaseFactoryIo.openDatabase(dbPath);

    //var store = StoreRef.main();
    var key = await store.add(db, {
      'Pipa': {'Ingredients': 'Muchos', 'Allergies': 'Allergies'}
    });

    var record = await store.record(key).getSnapshot(db);
    name = "Pipa";
    ingredients = record!['Pipa.Ingredients'] as String;
    allergies = record!['Pipa.Allergies'] as String;

    // await store.record('Name').put(db, 'Pipa');
    // await store.record('Ingredients').put(db, "Muchos");
    // await store.record('Allergies').put(db, "none");

    // name = await store.record('Name').get(db) as String;
    // ingredients = await store.record('Ingredients').get(db) as String;
    // allergies = await store.record('Allergies').get(db) as String;
    print(name + ingredients + allergies);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    SetupDatabase();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recents'),
        backgroundColor: colors.primaryContainer,
      ),
      body: ListView.builder(
        itemCount: 4,
        itemBuilder: (context, productId) {
          final product = Producto(name, ingredients, allergies,
              'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl-2.jpg');
          return ProductTile(
            product: product,
            onTap: () {
              GoRouter.of(context).go('/recents/product/$productId');
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
          backgroundColor: colors.tertiaryContainer,
          onPressed: () {
            startCamera();
          },
          tooltip: 'Camera',
          child: const Icon(Icons.add_a_photo_outlined)),
    );
  }
}

void startCamera() async {
  var result = await BarcodeScanner.scan();

  print(result.type); // The result type (barcode, cancelled, failed)
  print(result.rawContent); // The barcode content
  print(result.format); // The barcode format (as enum)
  String code = result.rawContent;

  if (result.format == 'qr') {
    print("esto es un qr");
  } else {
    Future<Product?> product = getProduct(code);
  }
}

//----------------------------ALLERGIES----------------------------------------
List<bool> isSelected = List<bool>.generate(10, (index) => false);

class AlergiesScreen extends StatelessWidget {
  const AlergiesScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.primaryContainer,
        title: const Text('Allergies'),
      ),
      body: ListView.builder(
        itemBuilder: (context, index) {
          final allergy =
              Allergy('01011233F', 'TestProduct', Color.fromARGB(255, 0, 0, 0));
          return AllergyTile(
            allergy: allergy,
            onTap: () {},
          );
        },
      ),
    );
  }
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
    final product = Producto('01011233F', 'TestProduct', 'Hacendado',
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
                    "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin pharetra leo non tempus congue. Nam iaculis nunc et velit ornare, a imperdiet dui faucibus. Integer ac pharetra tellus, et imperdiet augue. Aenean sit amet velit orci. Aliquam vehicula leo vel lectus tincidunt vestibulum. Nullam enim justo, luctus ut molestie non, eleifend eget elit. Vivamus eros nulla, euismod et commodo tempus, ultricies ut urna. Suspendisse fermentum malesuada dui, vel ultricies quam. Vivamus sed finibus tellus. Phasellus sed mauris sed enim auctor sagittis. Ut molestie in nunc eget lacinia.",
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
  final String? productIngredients;
  final String? allergies;

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
  final String id;
  final String name;
  final Color color;
  bool isSelected = false;

  Allergy(this.id, this.name, this.color);

  String get fullId => '$name-$id';
}

class ProductTile extends StatelessWidget {
  final Producto product;
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
              'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl-2.jpg'),
        ),
      ),
      tileColor: colors.secondaryContainer,
      textColor: colors.onSecondaryContainer,
      title: Text(product.name),
      subtitle: Text(product.brand),
      onTap: onTap,
    );
  }
}

class AllergyTile extends StatelessWidget {
  final Allergy allergy;
  final VoidCallback? onTap;

  const AllergyTile({Key? key, required this.allergy, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      leading: SizedBox(
        width: 50,
        height: 50,
        child: Container(
          color: allergy.color,
          margin: const EdgeInsets.all(8),
        ),
      ),
      tileColor: colors.secondaryContainer,
      textColor: colors.onSecondaryContainer,
      selectedTileColor: colors.errorContainer,
      title: Text(allergy.name),
      onTap: onTap,
    );
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
      scanIngredients = result.product?.ingredients as String;
    }
    if (result.product?.allergens != null) {
      scanAllergens = "none";
    }
    ProductScreenCamera(
      productName: scanName,
      productIngredients: scanIngredients,
      allergies: scanAllergens,
    );
    return result.product;
  } else {
    throw Exception('product not found, please insert data for $barcode');
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
Future<String?> extractIngredient() async {
  // a registered user login for https://world.openfoodfacts.org/ is required
  User myUser = User(userId: 'max@off.com', password: 'password');

  // query the OpenFoodFacts API
  OcrIngredientsResult response = await OpenFoodAPIClient.extractIngredients(
      myUser, '0041220576920', OpenFoodFactsLanguage.ENGLISH);

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
  ProductQueryConfiguration configurations = ProductQueryConfiguration(
      '3613042717385',
      language: OpenFoodFactsLanguage.FRENCH,
      fields: [
        ProductField.INGREDIENTS_TEXT,
      ]);
  ProductResultV3 productResult =
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
