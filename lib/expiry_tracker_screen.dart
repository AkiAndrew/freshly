import 'package:flutter/material.dart';

class ExpiryTrackerScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Expiry Tracker')),
      body: Center(child: Text('Track food expiry and show notifications')),
    );
  }
}
