import 'package:flutter/material.dart';

class ShoppingList extends StatefulWidget {
  @override
  _ShoppingListState createState() => _ShoppingListState();
}

class _ShoppingListState extends State<ShoppingList> {
  final List<ShoppingItem> _items = [];
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _reminderController = TextEditingController();

  void _addItem() {
    if (_itemController.text.isNotEmpty) {
      setState(() {
        _items.add(
          ShoppingItem(
            name: _itemController.text,
            quantity: _quantityController.text,
            unit: _unitController.text,
            reminderDate: _reminderController.text,
          ),
        );
        _itemController.clear();
        _quantityController.clear();
        _unitController.clear();
        _reminderController.clear();
      });
    }
  }

  void _toggleBought(int index) {
    setState(() {
      _items[index].isBought = !_items[index].isBought;
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
              TextField(
                controller: _unitController,
                decoration: InputDecoration(labelText: 'Unit'),
              ),
              TextField(
                controller: _reminderController,
                decoration: InputDecoration(labelText: 'Reminder Date'),
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
            child: ElevatedButton(
              onPressed: _showAddItemDialog,
              child: Text('Add Item'),
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
  final String unit;
  final String reminderDate;
  bool isBought;

  ShoppingItem({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.reminderDate,
    this.isBought = false,
  });
}

// TODO: Implement auto-generate list from meal plans feature.
