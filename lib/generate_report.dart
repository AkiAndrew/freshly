import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GenerateReportScreen extends StatefulWidget {
  const GenerateReportScreen({super.key});

  @override
  _GenerateReportScreenState createState() => _GenerateReportScreenState();
}

class _GenerateReportScreenState extends State<GenerateReportScreen> {
  String _selectedTimeRange = 'Weekly';
  DateTime _startDate = DateTime.now().subtract(Duration(days: 7));
  DateTime _endDate = DateTime.now();

  // Initialize Firestore and Auth
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = _auth.currentUser?.uid;
  }

  // Helper method to get user's collection reference
  CollectionReference _getUserCollection(String collectionName) {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection(collectionName);
  }

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
      appBar: AppBar(
        title: Text('Generate Report'),
        backgroundColor: Color(0xFF266041),
      ),
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
    if (_userId == null) return Text('Please log in to view reports');

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
                  _getUserCollection('consumed_items')
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
    if (_userId == null) return Text('Please log in to view reports');

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
                  _getUserCollection('wasted_items')
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
    if (_userId == null) return Text('Please log in to view reports');

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
                  _getUserCollection('food_categories')
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
    if (_userId == null) return Text('Please log in to view reports');

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
                  _getUserCollection('expiry_stats')
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
                    _buildStatTile(
                      'Items Expired',
                      '${doc['expired_count'] ?? 0} items',
                    ),
                    _buildStatTile(
                      'Items Near Expiry (7 days)',
                      '${doc['expiring_soon_count'] ?? 0} items',
                    ),
                    _buildStatTile(
                      'Total Waste Value',
                      '\$${doc['waste_value'] ?? 0}',
                    ),
                    _buildStatTile(
                      'Most Wasted Category',
                      doc['most_wasted_category'] ?? 'N/A',
                    ),
                    _buildStatTile(
                      'Waste Reduction',
                      '${doc['waste_reduction_percentage'] ?? 0}%',
                    ),
                    _buildStatTile(
                      'Money Saved',
                      '\$${doc['money_saved'] ?? 0}',
                    ),
                    _buildStatTile(
                      'Average Item Lifetime',
                      '${doc['avg_item_lifetime'] ?? 0} days',
                    ),
                    Divider(),
                    Text(
                      'Waste by Category',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF266041),
                      ),
                    ),
                    SizedBox(height: 8),
                    if (doc['waste_by_category'] != null)
                      ...List<Map<String, dynamic>>.from(
                        doc['waste_by_category'] ?? [],
                      ).map(
                        (category) => _buildCategoryTile(
                          category['name'],
                          category['count'],
                          category['percentage'],
                        ),
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

  Widget _buildStatTile(String title, String value) {
    return ListTile(
      dense: true,
      title: Text(
        title,
        style: TextStyle(fontSize: 14, color: Color(0xFF1C1C1C)),
      ),
      trailing: Text(
        value,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4D8C66),
        ),
      ),
    );
  }

  Widget _buildCategoryTile(String name, int count, double percentage) {
    return ListTile(
      dense: true,
      title: Text(name),
      subtitle: LinearProgressIndicator(
        value: percentage / 100,
        backgroundColor: Colors.grey[200],
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4D8C66)),
      ),
      trailing: Text('$count items ($percentage%)'),
    );
  }
}
