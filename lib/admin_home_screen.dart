import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'notification_service.dart';

class AdminHomeScreen extends StatefulWidget {
  @override
  _AdminHomeScreenState createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  List<Map<String, dynamic>> _expiringSoonItems = [];
  List<DocumentSnapshot> _recipes = [];

  @override
  void initState() {
    super.initState();
    _fetchExpiringItems();
    _fetchRecipes();
  }

  Future<void> _fetchExpiringItems() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final threeDaysLater = now.add(Duration(days: 3));

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('products')
        .where('expirationDate', isLessThanOrEqualTo: Timestamp.fromDate(threeDaysLater))
        .get();

    setState(() {
      _expiringSoonItems = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'name': data['name'] ?? 'Unknown',
          'expirationDate': (data['expirationDate'] as Timestamp).toDate(),
        };
      }).toList();
    });
  }

  Future<void> _fetchRecipes() async {
    final snapshot = await FirebaseFirestore.instance.collection('recipes').limit(10).get();
    setState(() {
      _recipes = snapshot.docs;
    });
  }

  void _showRecipeDetails(DocumentSnapshot recipe) {
    final data = recipe.data() as Map<String, dynamic>;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(data['name'] ?? 'Recipe Details',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 20),
            if (data['imageUrl'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  data['imageUrl'],
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            SizedBox(height: 20),
            Text('Tags: ${data['recipeTags'] ?? ''}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Text(data['instructions'] ?? 'No instructions provided.',
                    style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [Icon(Icons.kitchen), SizedBox(width: 8), Text('FRESHLY admin')]),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.shopping_cart),
                  onPressed: () => Navigator.pushNamed(context, '/shoppinglist'),
                ),
                IconButton(
                  icon: Icon(Icons.logout),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Expiring Soon Row with buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Expiring Soon', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.assessment),
                      onPressed: () => Navigator.pushNamed(context, '/report'),
                    ),
                    IconButton(
                      icon: Icon(Icons.receipt_long),
                      onPressed: () => Navigator.pushNamed(context, '/item'),
                    ),
                    IconButton(
                      icon: Icon(Icons.receipt_long),
                      onPressed: () => Navigator.pushNamed(context, '/recipe'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Expiring Soon Items
          FirebaseAuth.instance.currentUser == null
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Text(
                    'Please log in to see expiring foods.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                )
              : SizedBox(
                  height: 130,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _expiringSoonItems.length,
                    itemBuilder: (context, index) {
                      final item = _expiringSoonItems[index];
                      final dateText = DateFormat('dd MMM').format(item['expirationDate']);
                      return Container(
                        width: 120,
                        margin: EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.food_bank, size: 40),
                              SizedBox(height: 8),
                              Text(item['name'], textAlign: TextAlign.center),
                              SizedBox(height: 4),
                              Text(dateText, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
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
                await notificationService.checkAndNotifyExpiry(currentUserId ?? 'demoAdminId');

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Checked for expiring products')),
                );
              },
              child: Text('Test Expiry Notification', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),

          // Recipe Recommendations
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Recipe Recommendations',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: _recipes.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _recipes.length,
                    itemBuilder: (context, index) {
                      final data = _recipes[index].data() as Map<String, dynamic>;
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          leading: data['imageUrl'] != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(data['imageUrl'],
                                      width: 60, height: 60, fit: BoxFit.cover),
                                )
                              : Icon(Icons.restaurant, size: 40, color: Colors.grey),
                          title: Text(data['name'] ?? 'Unnamed Recipe',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          onTap: () => _showRecipeDetails(_recipes[index]),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/product'),
        backgroundColor: Colors.green,
        child: Icon(Icons.add),
      ),
    );
  }
}
