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

  // Helper method to get user's shopping list collection
  CollectionReference _getShoppingListCollection() {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('shopping_list');
  }

  Future<void> _addItem() async {
    if (_itemController.text.isEmpty ||
        _userId == null ||
        _selectedDate == null)
      return;

    try {
      await _getShoppingListCollection().add({
        'name': _itemController.text,
        'quantity': _quantityController.text,
        'reminderDate': _selectedDate?.toIso8601String(),
        'isBought': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _itemController.clear();
      _quantityController.clear();
      _selectedDate = null;
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
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate)
      setState(() {
        _selectedDate = picked;
      });
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: _itemController,
                decoration: InputDecoration(labelText: 'Item'),
              ),
              TextField(
                controller: _quantityController,
                decoration: InputDecoration(labelText: 'Quantity'),
              ),
              Row(
                children: <Widget>[
                  Text(
                    _selectedDate == null
                        ? ''
                        : 'Picked Date: ${_selectedDate.toString()}',
                  ),
                  TextButton(
                    onPressed: () => _selectDate(context),
                    child: Text('Choose Date'),
                  ),
                ],
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
            TextButton(
              child: Text('Add'),
              onPressed: () {
                _addItem();
                Navigator.of(context).pop();
              },
            ),
          ],
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
                title: Text('Spaghetti Bolognese'),
                onTap: () {
                  _autoGenerateList('Spaghetti Bolognese');
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
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

  void _autoGenerateList(String mealPlan) {
    if (_userId == null) return;

    List<Map<String, dynamic>> mealPlanItems = [];

    if (mealPlan == 'Spaghetti Bolognese') {
      mealPlanItems = [
        {
          'name': 'Pasta',
          'quantity': '1 pack',
          'reminderDate': '',
          'isBought': false,
        },
        {
          'name': 'Ground beef',
          'quantity': '500g',
          'reminderDate': '',
          'isBought': false,
        },
        {
          'name': 'Tomato sauce',
          'quantity': '1 can',
          'reminderDate': '',
          'isBought': false,
        },
        {
          'name': 'Cheese',
          'quantity': '200g',
          'reminderDate': '',
          'isBought': false,
        },
      ];
    } else if (mealPlan == 'Fried Rice') {
      mealPlanItems = [
        {
          'name': 'Cooked rice',
          'quantity': '2 cups',
          'reminderDate': '',
          'isBought': false,
        },
        {
          'name': 'Eggs',
          'quantity': '2',
          'reminderDate': '',
          'isBought': false,
        },
        {
          'name': 'Oil',
          'quantity': '2 tbsp',
          'reminderDate': '',
          'isBought': false,
        },
        {
          'name': 'Garlic',
          'quantity': '2 cloves',
          'reminderDate': '',
          'isBought': false,
        },
        {
          'name': 'Onion',
          'quantity': '1',
          'reminderDate': '',
          'isBought': false,
        },
        {
          'name': 'Spring onions',
          'quantity': '2 stalks',
          'reminderDate': '',
          'isBought': false,
        },
        {
          'name': 'Sausage',
          'quantity': '1',
          'reminderDate': '',
          'isBought': false,
        },
        {
          'name': 'Soy sauce',
          'quantity': '2 tbsp',
          'reminderDate': '',
          'isBought': false,
        },
        {
          'name': 'Salt',
          'quantity': 'to taste',
          'reminderDate': '',
          'isBought': false,
        },
        {
          'name': 'Pepper',
          'quantity': 'to taste',
          'reminderDate': '',
          'isBought': false,
        },
      ];
    }

    // Add items to Firestore
    for (var item in mealPlanItems) {
      _getShoppingListCollection().add({
        ...item,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null)
      return Scaffold(
        appBar: AppBar(title: Text('Shopping List')),
        body: Center(child: Text('Please log in to view your shopping list')),
      );

    return Scaffold(
      appBar: AppBar(
        title: Text('Shopping List'),
        backgroundColor: Color(0xFF266041),
        actions: [
          IconButton(icon: Icon(Icons.shopping_cart), onPressed: () {}),
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
                    return Center(child: Text('Something went wrong'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final data = doc.data() as Map<String, dynamic>;

                      return ListTile(
                        leading: Checkbox(
                          value: data['isBought'] ?? false,
                          onChanged: (bool? value) {
                            _removeItem(doc.id);
                          },
                        ),
                        title: Text(
                          data['name'] ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C1C1C),
                          ),
                        ),
                        subtitle: Text(
                          'Quantity: ${data['quantity'] ?? ''}',
                          style: TextStyle(color: Color(0xFF1C1C1C)),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          color: Color(0xFF1C1C1C),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _showAddItemDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4D8C66),
                    ),
                    child: Text(
                      'Add Item',
                      style: TextStyle(color: Color(0xFFC1FF72)),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _showMealPlanDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF602646),
                    ),
                    child: Text(
                      'Auto-generate List',
                      style: TextStyle(color: Color(0xFFC1FF72)),
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

// TODO: Implement auto-generate list from meal plans feature.
