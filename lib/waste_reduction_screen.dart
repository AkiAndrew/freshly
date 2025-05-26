import 'package:flutter/material.dart';

class WasteReductionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Waste Reduction'),
        backgroundColor: Color(0xFF266041),
      ),
      body: Center(child: Text('Suggest recipes and track waste')),
    );
  }
}
