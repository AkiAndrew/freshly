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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Shopping List')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _itemController,
              decoration: InputDecoration(labelText: 'Item'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _quantityController,
              decoration: InputDecoration(labelText: 'Quantity'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _unitController,
              decoration: InputDecoration(labelText: 'Unit'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _reminderController,
              decoration: InputDecoration(labelText: 'Reminder Date'),
            ),
          ),
          ElevatedButton(onPressed: _addItem, child: Text('Add Item')),
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text(
                    '${item.quantity} ${item.unit} - Reminder: ${item.reminderDate}',
                  ),
                  trailing: Checkbox(
                    value: item.isBought,
                    onChanged: (value) {
                      _toggleBought(index);
                    },
                  ),
                );
              },
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
