import 'package:comida/color_schemes.g.dart';
import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:openfoodfacts/openfoodfacts.dart';

import 'package:openfoodfacts/model/OcrIngredientsResult.dart';
import 'package:openfoodfacts/utils/TagType.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightColorScheme,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkColorScheme,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const MyHomePage(title: 'Feed Yourself'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  final List<String> entries = <String>['A', 'B', 'C'];
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          actions: <Widget>[
            IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.dark_mode,
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          ]),
      body: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: entries.length,
        itemBuilder: (BuildContext context, int index) {
          return Container(
            color: Theme.of(context).colorScheme.secondaryContainer,
            height: 100,
            child: Row(
              children: [
                Image(
                  image: NetworkImage(
                      "https://www.gstatic.com/webp/gallery/1.jpg"),
                ),
                SizedBox(width: 10),
                Text(
                  'Entry ${entries[index]}',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
        separatorBuilder: (BuildContext context, int index) => const Divider(),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add_a_photo_outlined),
      ), // This trailing comma makes auto-formatting nicer for build methods.
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
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
      ),
    );
  }

////////////////
///////////////////////////////////
////////////////////////////////////
///////////////////A PARTIR DE AQUI ES OPENFOODFACTS//////
//////////////////////////
///////////
  ///
  /// request a product from the OpenFoodFacts database
  Future<Product?> getProduct() async {
    var barcode = '0048151623426';

    ProductQueryConfiguration configuration = ProductQueryConfiguration(barcode,
        language: OpenFoodFactsLanguage.GERMAN, fields: [ProductField.ALL]);
    ProductResult result = await OpenFoodAPIClient.getProduct(configuration);

    if (result.status == 1) {
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

    OcrIngredientsResult ocrResponse =
        await OpenFoodAPIClient.extractIngredients(
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
    ProductResult productResult =
        await OpenFoodAPIClient.getProduct(configurations, user: myUser);

    if (productResult.status != 1) {
      throw Exception(
          'product not found, please insert data for 3613042717385');
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
}
