import 'package:assignment/admin_home_screen.dart';
import 'package:assignment/user_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Firebase Core
import 'scanner_screen.dart';
import 'waste_reduction_screen.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'item_screen.dart';
import 'product_screen.dart'; 
import 'recipe_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(FridgeApp());
}

class FridgeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fridge Manager',
      theme: ThemeData(primarySwatch: Colors.green),
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        '/scanner': (context) => ScannerScreen(),
        '/waste': (context) => WasteReductionScreen(),
        '/login': (context) => LoginScreen(), 
        '/admin_home_screen': (ctx) => AdminHomeScreen(),
        '/user_home_screen': (ctx) => UserHomeScreen(),
        '/item': (ctx) => ItemScreen(),
        '/product': (context) =>  ProductScreen(),
        '/recipe': (context) => RecipeScreen(),
      },
    );
  }
}
