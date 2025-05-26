import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class GenerateReportScreen extends StatefulWidget {
  @override
  _GenerateReportScreenState createState() => _GenerateReportScreenState();
}

class _GenerateReportScreenState extends State<GenerateReportScreen> {
  String _selectedTimeRange = 'Weekly';
  DateTime _startDate = DateTime.now().subtract(Duration(days: 7));
  DateTime _endDate = DateTime.now();

  // Dummy data - In real app, this would come from a database
  final List<Map<String, dynamic>> _mostConsumedFoods = [
    {'name': 'Chicken', 'amount': 5},
    {'name': 'Rice', 'amount': 4},
    {'name': 'Eggs', 'amount': 4},
    {'name': 'Bread', 'amount': 3},
    {'name': 'Milk', 'amount': 3},
  ];

  final List<Map<String, dynamic>> _mostWastedFoods = [
    {'name': 'Vegetables', 'amount': 3},
    {'name': 'Fruits', 'amount': 2},
    {'name': 'Dairy', 'amount': 2},
    {'name': 'Leftovers', 'amount': 1},
    {'name': 'Bread', 'amount': 1},
  ];

  final Map<String, double> _foodCategories = {
    'Protein': 35,
    'Carbs': 25,
    'Vegetables': 20,
    'Fruits': 15,
    'Dairy': 5,
  };

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
            _buildFoodCategoriesChart(),
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
            Column(
              children:
                  _mostConsumedFoods
                      .map(
                        (food) => ListTile(
                          title: Text(food['name']),
                          trailing: Text('${food['amount']} times'),
                        ),
                      )
                      .toList(),
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
            Column(
              children:
                  _mostWastedFoods
                      .map(
                        (food) => ListTile(
                          title: Text(food['name']),
                          trailing: Text('${food['amount']} items'),
                        ),
                      )
                      .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodCategoriesChart() {
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
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections:
                      _foodCategories.entries
                          .map(
                            (entry) => PieChartSectionData(
                              color:
                                  Colors.primaries[_foodCategories.keys
                                          .toList()
                                          .indexOf(entry.key) %
                                      Colors.primaries.length],
                              value: entry.value,
                              title: '${entry.key}\n${entry.value}%',
                              radius: 100,
                              titleStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          )
                          .toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 0,
                ),
              ),
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
            ListTile(
              title: Text('Expired this week'),
              trailing: Text('3 items'),
            ),
            ListTile(
              title: Text('Expiring next week'),
              trailing: Text('5 items'),
            ),
            ListTile(
              title: Text('Money saved from waste prevention'),
              trailing: Text('\$25.50'),
            ),
          ],
        ),
      ),
    );
  }
}
