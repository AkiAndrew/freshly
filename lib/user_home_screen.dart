import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart'; // import your notification service

class UserHomeScreen extends StatelessWidget {
  final List<Map<String, dynamic>> _pages = [
    {'title': 'Add Item', 'route': '/product'},
    {'title': 'Report', 'route': '/waste'},
  ];

  final List<Map<String, String>> expiringSoonItems = [
    {'name': 'Vegetable', 'image': ''},
    {'name': 'Banana', 'image': ''},
    {'name': 'Spicy', 'image': ''},
  ];

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'demoUserId';

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

          // Test Notification Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final notificationService = NotificationService();
                await notificationService.init();
                await notificationService.checkAndNotifyExpiry(currentUserId);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Checked for expiring products')),
                );
              },
              child: Text('Test Expiry Notification', style: TextStyle(fontSize: 16, color: Colors.white)),
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
