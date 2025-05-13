import 'package:flutter/material.dart';

class InventoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pantry Inventory')),
      body: Center(child: Text('Display list of food items with details')),
    );
  }
}
