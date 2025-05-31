import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShoppingList extends StatefulWidget {
  @override
  _ShoppingListState createState() => _ShoppingListState();
}

class _ShoppingListState extends State<ShoppingList> {
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  DateTime? _selectedDate;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = _auth.currentUser?.uid;
  }

  @override
  void dispose() {
    _itemController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  // Helper method to get user's shopping list collection
  CollectionReference _getShoppingListCollection() {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('shopping_list');
  }

  Future<void> _addItem() async {
    if (_itemController.text.trim().isEmpty || _userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter an item name')));
      return;
    }

    try {
      await _getShoppingListCollection().add({
        'name': _itemController.text.trim(),
        'quantity':
            _quantityController.text.trim().isEmpty
                ? '1'
                : _quantityController.text.trim(),
        'reminderDate': _selectedDate?.toIso8601String(),
        'isBought': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _itemController.clear();
      _quantityController.clear();
      setState(() {
        _selectedDate = null;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Item added successfully!')));
    } catch (e) {
      print('Error adding item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add item. Please try again.')),
      );
    }
  }

  Future<void> _removeItem(String docId) async {
    try {
      await _getShoppingListCollection().doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item removed from shopping list')),
      );
    } catch (e) {
      print('Error removing item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove item. Please try again.')),
      );
    }
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showAddItemDialog() {
    // Reset controllers and date when opening dialog
    _itemController.clear();
    _quantityController.clear();
    _selectedDate = null;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Add New Item'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: _itemController,
                      decoration: InputDecoration(
                        labelText: 'Item Name *',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: 'Quantity (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            _selectedDate == null
                                ? 'No reminder date set'
                                : 'Reminder: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            _selectDate(dialogContext);
                            setDialogState(() {});
                          },
                          icon: Icon(Icons.calendar_today),
                          label: Text('Set Date'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
                ElevatedButton(
                  child: Text('Add Item'),
                  onPressed: () {
                    _addItem();
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showMealPlanDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Meal Plan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.restaurant),
                title: Text('Spaghetti Bolognese'),
                onTap: () {
                  _autoGenerateList('Spaghetti Bolognese');
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.rice_bowl),
                title: Text('Fried Rice'),
                onTap: () {
                  _autoGenerateList('Fried Rice');
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _autoGenerateList(String mealPlan) async {
    if (_userId == null) return;

    List<Map<String, dynamic>> mealPlanItems = [];

    if (mealPlan == 'Spaghetti Bolognese') {
      mealPlanItems = [
        {'name': 'Pasta', 'quantity': '1 pack'},
        {'name': 'Ground beef', 'quantity': '500g'},
        {'name': 'Tomato sauce', 'quantity': '1 can'},
        {'name': 'Onion', 'quantity': '1 medium'},
        {'name': 'Garlic', 'quantity': '3 cloves'},
        {'name': 'Parmesan cheese', 'quantity': '200g'},
        {'name': 'Olive oil', 'quantity': '1 bottle'},
      ];
    } else if (mealPlan == 'Fried Rice') {
      mealPlanItems = [
        {'name': 'Rice', 'quantity': '2 cups'},
        {'name': 'Eggs', 'quantity': '3 pieces'},
        {'name': 'Cooking oil', 'quantity': '1 bottle'},
        {'name': 'Garlic', 'quantity': '2 cloves'},
        {'name': 'Onion', 'quantity': '1 medium'},
        {'name': 'Spring onions', 'quantity': '2 stalks'},
        {'name': 'Sausage', 'quantity': '200g'},
        {'name': 'Soy sauce', 'quantity': '1 bottle'},
        {'name': 'Salt', 'quantity': '1 pack'},
        {'name': 'Black pepper', 'quantity': '1 pack'},
      ];
    }

    try {
      // Add items to Firestore using batch for better performance
      WriteBatch batch = _firestore.batch();

      for (var item in mealPlanItems) {
        DocumentReference docRef = _getShoppingListCollection().doc();
        batch.set(docRef, {
          'name': item['name'],
          'quantity': item['quantity'],
          'reminderDate': null,
          'isBought': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$mealPlan items added to your shopping list!')),
      );
    } catch (e) {
      print('Error auto-generating list: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate meal plan. Please try again.'),
        ),
      );
    }
  }

  Future<void> _addToProducts(Map<String, dynamic> item, String docId) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('products')
          .add({
            'name': item['name'],
            'quantity': item['quantity'],
            'purchaseDate': DateTime.now().toIso8601String(),
            'expiryDate':
                DateTime.now()
                    .add(Duration(days: 7))
                    .toIso8601String(), // Default expiry of 7 days
            'createdAt': FieldValue.serverTimestamp(),
          });

      // Remove from shopping list after adding to products
      await _removeItem(docId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item['name']} added to your products!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error adding to products: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add item to products. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // This is the key function - shows dialog when checkbox is clicked
  void _showPurchaseConfirmationDialog(DocumentSnapshot doc) {
    final item = doc.data() as Map<String, dynamic>;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.shopping_cart, color: Colors.green),
              SizedBox(width: 8),
              Text('Item Purchased?'),
            ],
          ),
          content: Text(
            'What would you like to do with "${item['name']}"?',
            style: TextStyle(fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 20),
                  SizedBox(width: 4),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
              onPressed: () {
                _removeItem(doc.id);
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, size: 20),
                  SizedBox(width: 4),
                  Text('Confirm Purchase'),
                ],
              ),
              onPressed: () {
                _addToProducts(item, doc.id);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Shopping List')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Please log in to view your shopping list',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Shopping List'),
        backgroundColor: Color(0xFF266041),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.restaurant_menu),
            onPressed: _showMealPlanDialog,
            tooltip: 'Meal Plans',
          ),
        ],
      ),
      body: Container(
        color: Color(0xFFD9D9D9),
        child: Column(
          children: <Widget>[
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    _getShoppingListCollection()
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, size: 64, color: Colors.red),
                          SizedBox(height: 16),
                          Text('Something went wrong'),
                        ],
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Your shopping list is empty',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Add items or generate from meal plans',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.all(8),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;

                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        elevation: 2,
                        child: ListTile(
                          leading: Checkbox(
                            value: data['isBought'] ?? false,
                            onChanged: (bool? value) {
                              // This is where the dialog shows when checkbox is clicked
                              if (value == true) {
                                _showPurchaseConfirmationDialog(doc);
                              }
                            },
                            activeColor: Colors.green,
                          ),
                          title: Text(
                            data['name'] ?? '',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quantity: ${data['quantity'] ?? 'Not specified'}',
                              ),
                              if (data['reminderDate'] != null)
                                Text(
                                  'Reminder: ${DateTime.parse(data['reminderDate']).day}/${DateTime.parse(data['reminderDate']).month}/${DateTime.parse(data['reminderDate']).year}',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeItem(doc.id),
                            tooltip: 'Delete item',
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showAddItemDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4D8C66),
                        foregroundColor: Color(0xFFC1FF72),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: Icon(Icons.add),
                      label: Text('Add Item'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showMealPlanDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF602646),
                        foregroundColor: Color(0xFFC1FF72),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: Icon(Icons.restaurant_menu),
                      label: Text('Meal Plans'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
