import 'package:flutter/material.dart';

class ItemScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [Icon(Icons.kitchen), SizedBox(width: 8), Text('FRESHLY')]),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.shopping_cart),
                  onPressed: () => Navigator.pushNamed(context, '/item'),
                ),
                Icon(Icons.settings),
              ],
            )
          ],
        ),
      ),
      body: Center(child: Text('Show all the items in the fridge')),
    );
  }
}
