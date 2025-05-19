import 'package:assignment/admin_home_screen.dart';
import 'package:assignment/user_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Firebase Core
import 'scanner_screen.dart';
import 'inventory_screen.dart';
import 'expiry_tracker_screen.dart';
import 'waste_reduction_screen.dart';
import 'recommendations_screen.dart';
import 'item_screen.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'database_screen.dart';


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
        '/inventory': (context) => InventoryScreen(),
        '/expiry': (context) => ExpiryTrackerScreen(),
        '/waste': (context) => WasteReductionScreen(),
        '/recommendations': (context) => RecommendationsScreen(),
        '/item': (context) => ItemScreen(),
        '/login': (context) => LoginScreen(), // add login route
        '/admin_home_screen': (ctx) => AdminHomeScreen(),
        '/user_home_screen': (ctx) => UserHomeScreen(),
        '/database': (ctx) => DatabaseScreen(),

      },
    );
  }
}
