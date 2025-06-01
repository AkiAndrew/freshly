import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class GenerateReportScreen extends StatefulWidget {
  const GenerateReportScreen({super.key});

  @override
  _GenerateReportScreenState createState() => _GenerateReportScreenState();
}

class _GenerateReportScreenState extends State<GenerateReportScreen> {
  String _selectedTimeRange = 'All';
  DateTime _startDate = DateTime.now().subtract(Duration(days: 7));
  DateTime _endDate = DateTime.now();
  bool _isCustomDate = false;

  // Initialize Firestore and Auth
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _userId;

  final List<String> _timeRanges = [
    'All',
    'Weekly',
    'Monthly',
    'Yearly',
    'Custom',
  ];

  @override
  void initState() {
    super.initState();
    print('GenerateReportScreen - initState called'); // Debug print
    _userId = _auth.currentUser?.uid;
    print('GenerateReportScreen - User ID: $_userId'); // Debug print
    // Set initial date range based on 'All'
    _updateTimeRange('All');
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF266041),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _isCustomDate = true;
        _selectedTimeRange = 'Custom';
      });
    }
  }

  void _updateTimeRange(String? value) {
    if (value == null) return;
    setState(() {
      _selectedTimeRange = value;
      _isCustomDate = false;

      switch (value) {
        case 'All':
          _startDate = DateTime(2020); // Or any reasonable start date
          _endDate = DateTime.now();
          break;
        case 'Weekly':
          _startDate = DateTime.now().subtract(Duration(days: 7));
          _endDate = DateTime.now();
          break;
        case 'Monthly':
          _startDate = DateTime.now().subtract(Duration(days: 30));
          _endDate = DateTime.now();
          break;
        case 'Yearly':
          _startDate = DateTime.now().subtract(Duration(days: 365));
          _endDate = DateTime.now();
          break;
        case 'Custom':
          _selectDateRange();
          break;
      }
    });
  }

  // Helper method to get user's collection reference
  CollectionReference _getUserCollection(String collectionName) {
    print(
      'Getting collection $collectionName for user $_userId',
    ); // Debug print
    final collection = _firestore
        .collection('users')
        .doc(_userId)
        .collection(collectionName);
    print('Collection path: ${collection.path}'); // Debug print
    return collection;
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
            Container(
              width: double.infinity,
              child: DropdownButtonFormField<String>(
                value: _selectedTimeRange,
                isExpanded: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                items:
                    _timeRanges.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    _updateTimeRange(newValue);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeDisplay() {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return Text(
      _selectedTimeRange == 'All'
          ? 'Report Period: All Time'
          : 'Report Period: ${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}',
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    );
  }

  Widget _buildMostConsumedSection() {
    if (_userId == null) {
      print('Report - No user ID available for consumed items query');
      return Text('Please log in to view reports');
    }

    print('Report - Building consumed section for user: $_userId');
    print('Report - Selected time range: $_selectedTimeRange');
    print(
      'Report - Date range: ${_startDate.toIso8601String()} to ${_endDate.toIso8601String()}',
    );

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.green.shade600),
                SizedBox(width: 8),
                Text(
                  'Consumption Report',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: () {
                final baseQuery = _getUserCollection('consumed_items');
                if (_selectedTimeRange == 'All') {
                  print('Report - Using "All" time query');
                  final query = baseQuery
                      .orderBy('quantity', descending: true)
                      .limit(5);
                  print('Report - Query path: ${query.parameters}');
                  return query.snapshots();
                } else {
                  print('Report - Using date-filtered query');
                  final query = baseQuery
                      .where(
                        'createdAt',
                        isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate),
                      )
                      .where(
                        'createdAt',
                        isLessThanOrEqualTo: Timestamp.fromDate(_endDate),
                      )
                      .orderBy('createdAt', descending: true)
                      .orderBy('quantity', descending: true)
                      .limit(5);
                  print('Report - Query path: ${query.parameters}');
                  return query.snapshots();
                }
              }(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print(
                    'Report - Error in consumed items query: ${snapshot.error}',
                  );
                  if (snapshot.error is FirebaseException) {
                    final error = snapshot.error as FirebaseException;
                    print('Report - Firebase error code: ${error.code}');
                    print('Report - Firebase error message: ${error.message}');
                  }
                  return Text('Something went wrong');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  print('Report - Query is loading...');
                  return Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                print('Report - Query returned ${docs.length} documents');

                if (docs.isEmpty) {
                  print('Report - No consumed items found');
                  return Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No consumption data for this period',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Calculate total items consumed
                int totalConsumed = 0;
                Map<String, int> itemCounts = {};

                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final foodName = data['food_name'] as String;
                  final quantity = data['quantity'] as int;

                  totalConsumed += quantity;
                  itemCounts[foodName] = (itemCounts[foodName] ?? 0) + quantity;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            totalConsumed.toString(),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                          Text(
                            'Total items consumed',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      _selectedTimeRange == 'All'
                          ? 'All Consumed Items'
                          : 'Most Consumed Items',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Column(
                      children:
                          itemCounts.entries.map((entry) {
                            return Container(
                              margin: EdgeInsets.symmetric(vertical: 4),
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green.shade100,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    entry.key,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${entry.value} items',
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
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

  Widget _buildMostWastedSection() {
    if (_userId == null) return Text('Please log in to view reports');

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_down, color: Colors.red.shade600),
                SizedBox(width: 8),
                Text(
                  'Waste Report',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade900,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: () {
                final baseQuery = _getUserCollection('wasted_items');
                if (_selectedTimeRange == 'All') {
                  return baseQuery
                      .orderBy('expired_count', descending: true)
                      .limit(5)
                      .snapshots();
                } else {
                  return baseQuery
                      .where(
                        'createdAt',
                        isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate),
                      )
                      .where(
                        'createdAt',
                        isLessThanOrEqualTo: Timestamp.fromDate(_endDate),
                      )
                      .orderBy('createdAt', descending: true)
                      .orderBy('expired_count', descending: true)
                      .limit(5)
                      .snapshots();
                }
              }(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Something went wrong');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.trending_down,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No waste data for this period',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Calculate total items wasted
                int totalWasted = 0;
                Map<String, int> itemCounts = {};

                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final foodName = data['food_name'] as String;
                  final expiredCount = data['expired_count'] as int;

                  totalWasted += expiredCount;
                  itemCounts[foodName] =
                      (itemCounts[foodName] ?? 0) + expiredCount;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            totalWasted.toString(),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                          Text(
                            'Total items wasted',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      _selectedTimeRange == 'All'
                          ? 'All Wasted Items'
                          : 'Most Wasted Items',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Column(
                      children:
                          itemCounts.entries.map((entry) {
                            return Container(
                              margin: EdgeInsets.symmetric(vertical: 4),
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade100),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.key,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          'Avg. days before expiry: ${_calculateAvgDaysBeforeExpiry(docs, entry.key)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${entry.value} items',
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
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

  double _calculateAvgDaysBeforeExpiry(
    List<QueryDocumentSnapshot> docs,
    String foodName,
  ) {
    var matchingDocs =
        docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['food_name'] == foodName;
        }).toList();

    if (matchingDocs.isEmpty) return 0;

    double totalDays = 0;
    int count = 0;

    for (var doc in matchingDocs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['avg_days_before_expiry'] != null) {
        totalDays += (data['avg_days_before_expiry'] as num).toDouble();
        count++;
      }
    }

    return count > 0 ? (totalDays / count).roundToDouble() : 0;
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
                  _selectedTimeRange == 'All'
                      ? _getUserCollection(
                        'food_categories',
                      ).orderBy('percentage', descending: true).snapshots()
                      : _getUserCollection('food_categories')
                          .where(
                            'createdAt',
                            isGreaterThanOrEqualTo: Timestamp.fromDate(
                              _startDate,
                            ),
                          )
                          .where(
                            'createdAt',
                            isLessThanOrEqualTo: Timestamp.fromDate(_endDate),
                          )
                          .orderBy('createdAt', descending: true)
                          .orderBy('percentage', descending: true)
                          .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Something went wrong');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.pie_chart,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No category data available',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Process the data for pie chart
                List<PieChartSectionData> sections = [];
                List<Widget> indicators = [];

                final List<Color> colors = [
                  Color(0xFF266041), // Dark green
                  Color(0xFF4D8C66), // Medium green
                  Color(0xFF6FB58A), // Light green
                  Color(0xFF98D4AA), // Very light green
                  Color(0xFFBEE3C7), // Pale green
                ];

                int colorIndex = 0;
                double totalPercentage = 0;

                for (var doc in snapshot.data!.docs) {
                  final category = doc['category'] as String;
                  final percentage = (doc['percentage'] as num).toDouble();
                  final color = colors[colorIndex % colors.length];

                  sections.add(
                    PieChartSectionData(
                      value: percentage,
                      title: '${percentage.toStringAsFixed(1)}%',
                      color: color,
                      radius: 100,
                      titleStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  );

                  indicators.add(
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              category,
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );

                  colorIndex++;
                  totalPercentage += percentage;
                }

                return Column(
                  children: [
                    SizedBox(
                      height: 250,
                      child: PieChart(
                        PieChartData(
                          sections: sections,
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          startDegreeOffset: -90,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Column(children: indicators),
                    SizedBox(height: 10),
                    Text(
                      'Total Distribution: ${totalPercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF266041),
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
}
