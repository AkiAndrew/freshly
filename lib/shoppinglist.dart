import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ShoppingList extends StatefulWidget {
  @override
  _ShoppingListState createState() => _ShoppingListState();
}

class _ShoppingListState extends State<ShoppingList> {
  final List<ShoppingItem> _items = [];
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? itemsJson = prefs.getString('shopping_items');
    if (itemsJson != null) {
      List<dynamic> itemsList = jsonDecode(itemsJson);
      setState(() {
        _items.clear();
        _items.addAll(
          itemsList.map((item) => ShoppingItem.fromJson(item)).toList(),
        );
      });
    }
  }

  void _saveItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String itemsJson = jsonEncode(_items.map((item) => item.toJson()).toList());
    prefs.setString('shopping_items', itemsJson);
  }

  void _addItem() {
    if (_itemController.text.isNotEmpty && _selectedDate != null) {
      setState(() {
        _items.add(
          ShoppingItem(
            name: _itemController.text,
            quantity: _quantityController.text,
            reminderDate: _selectedDate.toString(),
          ),
        );
        _itemController.clear();
        _quantityController.clear();
        _selectedDate = null;
        _saveItems();
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      _saveItems();
    });
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
    List<ShoppingItem> mealPlanItems = [];

    if (mealPlan == 'Spaghetti Bolognese') {
      mealPlanItems = [
        ShoppingItem(name: 'Pasta', quantity: '1 pack', reminderDate: ''),
        ShoppingItem(name: 'Ground beef', quantity: '500g', reminderDate: ''),
        ShoppingItem(name: 'Tomato sauce', quantity: '1 can', reminderDate: ''),
        ShoppingItem(name: 'Cheese', quantity: '200g', reminderDate: ''),
      ];
    } else if (mealPlan == 'Fried Rice') {
      mealPlanItems = [
        ShoppingItem(name: 'Cooked rice', quantity: '2 cups', reminderDate: ''),
        ShoppingItem(name: 'Eggs', quantity: '2', reminderDate: ''),
        ShoppingItem(name: 'Oil', quantity: '2 tbsp', reminderDate: ''),
        ShoppingItem(name: 'Garlic', quantity: '2 cloves', reminderDate: ''),
        ShoppingItem(name: 'Onion', quantity: '1', reminderDate: ''),
        ShoppingItem(
          name: 'Spring onions',
          quantity: '2 stalks',
          reminderDate: '',
        ),
        ShoppingItem(name: 'Sausage', quantity: '1', reminderDate: ''),
        ShoppingItem(name: 'Soy sauce', quantity: '2 tbsp', reminderDate: ''),
        ShoppingItem(name: 'Salt', quantity: 'to taste', reminderDate: ''),
        ShoppingItem(name: 'Pepper', quantity: 'to taste', reminderDate: ''),
      ];
    }

    setState(() {
      _items.addAll(mealPlanItems);
      _saveItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shopping List'),
        actions: [
          IconButton(icon: Icon(Icons.shopping_cart), onPressed: () {}),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return ListTile(
                  leading: Checkbox(
                    value: item.isBought,
                    onChanged: (bool? value) {
                      _removeItem(index);
                    },
                  ),
                  title: Text(
                    item.name,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {},
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
                  child: Text('Add Item'),
                ),
                ElevatedButton(
                  onPressed: _showMealPlanDialog,
                  child: Text('Auto-generate List'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ShoppingItem {
  final String name;
  final String quantity;
  final String reminderDate;
  bool isBought;

  ShoppingItem({
    required this.name,
    required this.quantity,
    required this.reminderDate,
    this.isBought = false,
  });

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      name: json['name'],
      quantity: json['quantity'],
      reminderDate: json['reminderDate'],
      isBought: json['isBought'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'reminderDate': reminderDate,
      'isBought': isBought,
    };
  }
}

// TODO: Implement auto-generate list from meal plans feature.
