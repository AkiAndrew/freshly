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
    _userId = _auth.currentUser?.uid;
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
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection(collectionName);
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
                  _selectedTimeRange == 'All'
                      ? _getUserCollection('consumed_items')
                          .orderBy('quantity', descending: true)
                          .limit(5)
                          .snapshots()
                      : _getUserCollection('consumed_items')
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
                          .orderBy('quantity', descending: true)
                          .limit(5)
                          .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Something went wrong');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                if (snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'No consumption data available',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    return ListTile(
                      title: Text(doc['food_name'] ?? 'Unknown'),
                      trailing: Text('${doc['quantity']} ${doc['unit'] ?? ''}'),
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
                  _selectedTimeRange == 'All'
                      ? _getUserCollection('wasted_items')
                          .orderBy('expired_count', descending: true)
                          .limit(5)
                          .snapshots()
                      : _getUserCollection('wasted_items')
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
                          .orderBy('expired_count', descending: true)
                          .limit(5)
                          .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Something went wrong');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                if (snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'No waste data available',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    return ListTile(
                      title: Text(doc['food_name'] ?? 'Unknown'),
                      subtitle: Text(
                        'Avg. days before expiry: ${doc['avg_days_before_expiry'] ?? 0}',
                      ),
                      trailing: Text('${doc['expired_count'] ?? 0} items'),
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

  Widget _buildExpiryStatistics() {
    if (_userId == null) return Text('Please log in to view reports');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timer, color: Color(0xFF266041)),
                SizedBox(width: 8),
                Text(
                  'Expiry Statistics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream:
                  _getUserCollection(
                    'expiry_stats',
                  ).orderBy('createdAt', descending: true).limit(1).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Something went wrong');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'No expiry data available for this period',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ),
                  );
                }

                var doc = snapshot.data!.docs.first;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatCard(
                            'Items Expired',
                            '${doc['expired_count'] ?? 0}',
                            Icons.warning,
                            Color(0xFFE57373),
                          ),
                          _buildStatCard(
                            'Near Expiry',
                            '${doc['expiring_soon_count'] ?? 0}',
                            Icons.timer,
                            Color(0xFFFFB74D),
                          ),
                          _buildStatCard(
                            'Money Saved',
                            '\$${doc['money_saved'] ?? 0}',
                            Icons.savings,
                            Color(0xFF81C784),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
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
                      'Average Item Lifetime',
                      '${doc['avg_item_lifetime'] ?? 0} days',
                    ),
                    SizedBox(height: 16),
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

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF266041),
          ),
        ),
        SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatTile(String title, String value) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF1C1C1C),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4D8C66),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(String name, int count, double percentage) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              Text(
                '$count items ($percentage%)',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4D8C66),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4D8C66)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
