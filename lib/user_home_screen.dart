import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Firebase Core
import 'scanner_screen.dart';
import 'inventory_screen.dart';
import 'expiry_tracker_screen.dart';
import 'waste_reduction_screen.dart';
import 'recommendations_screen.dart';
import 'item_screen.dart';
import 'login_screen.dart'; // import the login screen
import 'package:firebase_auth/firebase_auth.dart';



class UserHomeScreen extends StatelessWidget {
  final List<Map<String, dynamic>> _pages = [
    {'title': 'Scan Receipt', 'route': '/scanner'},
    {'title': 'Add Item', 'route': '/inventory'},
    {'title': 'View Pantry', 'route': '/inventory'},
    {'title': 'Report', 'route': '/waste'},

  ];

  final List<Map<String, String>> expiringSoonItems = [
    {'name': 'Vegetable', 'image': ''},
    {'name': 'Banana', 'image': ''},
    {'name': 'Spicy', 'image': ''},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [Icon(Icons.kitchen), SizedBox(width: 8), Text('FRESHLY user')]),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.shopping_cart),
                  onPressed: () => Navigator.pushNamed(context, '/item'),
                ),
                IconButton(
                  icon: Icon(Icons.logout),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
              ],
            )
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Expiring Soon', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: expiringSoonItems.length,
              itemBuilder: (context, index) {
                final item = expiringSoonItems[index];
                return Container(
                  width: 100,
                  margin: EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image, size: 60),
                      SizedBox(height: 10),
                      Text(item['name']!, textAlign: TextAlign.center),
                    ],
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _pages.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Colors.black,
                  ),
                  child: Text(_pages[index]['title'], style: TextStyle(fontSize: 18, color: Colors.white)),
                  onPressed: () => Navigator.pushNamed(context, _pages[index]['route']),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
