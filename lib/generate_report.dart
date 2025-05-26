import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class GenerateReportScreen extends StatefulWidget {
  @override
  _GenerateReportScreenState createState() => _GenerateReportScreenState();
}

class _GenerateReportScreenState extends State<GenerateReportScreen> {
  String _selectedTimeRange = 'Weekly';
  DateTime _startDate = DateTime.now().subtract(Duration(days: 7));
  DateTime _endDate = DateTime.now();

  // Initialize Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _updateTimeRange(String? value) {
    if (value == null) return;
    setState(() {
      _selectedTimeRange = value;
      switch (value) {
        case 'Weekly':
          _startDate = DateTime.now().subtract(Duration(days: 7));
          break;
        case 'Monthly':
          _startDate = DateTime.now().subtract(Duration(days: 30));
          break;
        case 'Yearly':
          _startDate = DateTime.now().subtract(Duration(days: 365));
          break;
      }
      _endDate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Generate Report')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterSection(),
            SizedBox(height: 20),
            _buildDateRangeDisplay(),
            SizedBox(height: 20),
            _buildMostConsumedSection(),
            SizedBox(height: 20),
            _buildMostWastedSection(),
            SizedBox(height: 20),
            _buildFoodCategoriesSection(),
            SizedBox(height: 20),
            _buildExpiryStatistics(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report Filter',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedTimeRange,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              items:
                  ['Weekly', 'Monthly', 'Yearly']
                      .map(
                        (String value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(),
              onChanged: _updateTimeRange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeDisplay() {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return Text(
      'Report Period: ${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}',
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    );
  }

  Widget _buildMostConsumedSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Most Consumed Foods',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream:
                  _firestore
                      .collection('consumed_items')
                      .where('date', isGreaterThanOrEqualTo: _startDate)
                      .where('date', isLessThanOrEqualTo: _endDate)
                      .orderBy('date', descending: true)
                      .limit(5)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Something went wrong');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    return ListTile(
                      title: Text(doc['name']),
                      trailing: Text('${doc['quantity']} times'),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMostWastedSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Most Wasted Foods',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream:
                  _firestore
                      .collection('wasted_items')
                      .where('date', isGreaterThanOrEqualTo: _startDate)
                      .where('date', isLessThanOrEqualTo: _endDate)
                      .orderBy('date', descending: true)
                      .limit(5)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Something went wrong');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    return ListTile(
                      title: Text(doc['name']),
                      trailing: Text('${doc['quantity']} items'),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodCategoriesSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Food Categories Distribution',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream:
                  _firestore
                      .collection('food_categories')
                      .where('date', isGreaterThanOrEqualTo: _startDate)
                      .where('date', isLessThanOrEqualTo: _endDate)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Something went wrong');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    return ListTile(
                      title: Text(doc['category']),
                      trailing: Text('${doc['percentage']}%'),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiryStatistics() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expiry Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream:
                  _firestore
                      .collection('expiry_stats')
                      .where('date', isGreaterThanOrEqualTo: _startDate)
                      .where('date', isLessThanOrEqualTo: _endDate)
                      .limit(1)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Something went wrong');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                if (snapshot.data!.docs.isEmpty) {
                  return Text('No expiry data available');
                }

                var doc = snapshot.data!.docs.first;
                return Column(
                  children: [
                    ListTile(
                      title: Text('Expired this week'),
                      trailing: Text('${doc['expired_this_week']} items'),
                    ),
                    ListTile(
                      title: Text('Expiring next week'),
                      trailing: Text('${doc['expiring_next_week']} items'),
                    ),
                    ListTile(
                      title: Text('Money saved from waste prevention'),
                      trailing: Text('\$${doc['money_saved']}'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
