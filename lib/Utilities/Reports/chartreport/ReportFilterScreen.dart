import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:DigiVasool/Utilities/CustomDatePicker.dart';
import 'package:DigiVasool/Data/Databasehelper.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportFilterScreen extends StatefulWidget {
  const ReportFilterScreen({super.key});

  @override
  State<ReportFilterScreen> createState() => _ReportFilterScreenState();
}

class _ReportFilterScreenState extends State<ReportFilterScreen> {
  String _selectedPeriod = 'This Month';
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  List<Map<String, dynamic>> _chartData = [];
  bool _showCredit = true;
  bool _showChart = false;
  int _currentWeekIndex = 0;

  // 1. Add a loading state
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _setDefaultDates();
    _fetchAndShowChart();
  }

  void _setDefaultDates() {
    final now = DateTime.now();
    final sunday = now.subtract(Duration(days: now.weekday % 7));
    _fromDateController.text = DateFormat('dd-MM-yyyy').format(sunday);
    _toDateController.text = DateFormat('dd-MM-yyyy').format(now);
    _selectedPeriod = 'Date Range';
  }

  // 2. Update _fetchAndShowChart to show loading spinner
  Future<void> _fetchAndShowChart() async {
    setState(() {
      _isLoading = true;
    });
    final from = DateFormat('yyyy-MM-dd')
        .format(DateFormat('dd-MM-yyyy').parse(_fromDateController.text));
    final to = DateFormat('yyyy-MM-dd')
        .format(DateFormat('dd-MM-yyyy').parse(_toDateController.text));
    final data =
        await CollectionDB.getCollectionSumByDate(fromDate: from, toDate: to);
    setState(() {
      _chartData = data;
      _showChart = true;
      _isLoading = false;
      _currentWeekIndex = 0;
    });
  }

  List<List<Map<String, dynamic>>> _getWeeklyChunks(
      List<Map<String, dynamic>> data) {
    List<List<Map<String, dynamic>>> weeks = [];
    for (int i = 0; i < data.length; i += 7) {
      weeks.add(data.sublist(i, i + 7 > data.length ? data.length : i + 7));
    }
    return weeks;
  }

  Widget _buildChart() {
    if (_chartData.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Text('No data for selected range'),
      );
    }

    final totalCredit = _chartData.fold<num>(
        0, (sum, item) => sum + ((item['totalCrAmt'] as num?) ?? 0));
    final totalDebit = _chartData.fold<num>(
        0, (sum, item) => sum + ((item['totalDrAmt'] as num?) ?? 0));

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Show: "),
            ChoiceChip(
              label: const Text("Credit"),
              selected: _showCredit,
              onSelected: (v) => setState(() => _showCredit = true),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text("Debit"),
              selected: !_showCredit,
              onSelected: (v) => setState(() => _showCredit = false),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 360,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: _chartData.length * 60,
              child: BarChart(
                BarChartData(
                  maxY: _getMaxY(_chartData) * 1.2,
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: List.generate(_chartData.length, (i) {
                    final item = _chartData[i];
                    final value = _showCredit
                        ? (item['totalCrAmt'] as num?) ?? 0
                        : (item['totalDrAmt'] as num?) ?? 0;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: value.toDouble(),
                          color: _showCredit ? Colors.green : Colors.red,
                          width: 30,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                      showingTooltipIndicators: [0],
                    );
                  }),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles:
                          SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= _chartData.length)
                            return const SizedBox();
                          final date = _chartData[idx]['Date'] as String;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              date.length >= 10 ? date.substring(5) : date,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  barTouchData: BarTouchData(
                    enabled: false,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "Summary for Selected Range:",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text("Total Credit: ₹${totalCredit.toStringAsFixed(2)}"),
        Text("Total Debit : ₹${totalDebit.toStringAsFixed(2)}"),
      ],
    );
  }

  double _getMaxY(List<Map<String, dynamic>> data) {
    double maxVal = 0;
    for (var item in data) {
      final value = _showCredit
          ? (item['totalCrAmt'] as num?) ?? 0
          : (item['totalDrAmt'] as num?) ?? 0;
      if (value > maxVal) maxVal = value.toDouble();
    }
    return maxVal == 0 ? 100 : maxVal;
  }

  @override
  // ...existing code...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Filter'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Filter Card ---
                Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              "Period:",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButton<String>(
                                value: _selectedPeriod,
                                isExpanded: true,
                                borderRadius: BorderRadius.circular(12),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'This Month',
                                      child: Text('This Month')),
                                  DropdownMenuItem(
                                      value: 'Last Month',
                                      child: Text('Last Month')),
                                  DropdownMenuItem(
                                      value: 'Date Range',
                                      child: Text('Date Range')),
                                  DropdownMenuItem(
                                      value: 'Single Day',
                                      child: Text('Single Day')),
                                ],
                                onChanged: (value) async {
                                  setState(() {
                                    _selectedPeriod = value!;
                                  });

                                  if (_selectedPeriod == 'This Month') {
                                    final now = DateTime.now();
                                    final monthStart =
                                        DateTime(now.year, now.month, 1);
                                    _fromDateController.text =
                                        DateFormat('dd-MM-yyyy')
                                            .format(monthStart);
                                    _toDateController.text =
                                        DateFormat('dd-MM-yyyy').format(now);
                                    await _fetchAndShowChart();
                                  } else if (_selectedPeriod == 'Last Month') {
                                    final now = DateTime.now();
                                    final lastMonth =
                                        DateTime(now.year, now.month - 1, 1);
                                    final lastMonthEnd =
                                        DateTime(now.year, now.month, 0);
                                    _fromDateController.text =
                                        DateFormat('dd-MM-yyyy')
                                            .format(lastMonth);
                                    _toDateController.text =
                                        DateFormat('dd-MM-yyyy')
                                            .format(lastMonthEnd);
                                    await _fetchAndShowChart();
                                  } else if (_selectedPeriod == 'Single Day') {
                                    final today = DateTime.now();
                                    final todayStr =
                                        DateFormat('dd-MM-yyyy').format(today);
                                    setState(() {
                                      _fromDateController.text = todayStr;
                                      _toDateController.text = todayStr;
                                      _showChart = false;
                                      _chartData = [];
                                    });
                                  } else {
                                    setState(() {
                                      _showChart = false;
                                      _chartData = [];
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (_selectedPeriod == 'Date Range') ...[
                          Row(
                            children: [
                              Expanded(
                                child: CustomDatePicker(
                                  controller: _fromDateController,
                                  labelText: 'From Date',
                                  hintText: 'Pick from date',
                                  lastDate: DateTime.now(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: CustomDatePicker(
                                  controller: _toDateController,
                                  labelText: 'To Date',
                                  hintText: 'Pick to date',
                                  lastDate: DateTime.now(),
                                ),
                              ),
                            ],
                          ),
                        ] else if (_selectedPeriod == 'Single Day') ...[
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _fromDateController,
                                  readOnly: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Select Date',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.calendar_today),
                                  ),
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime.now(),
                                    );
                                    if (picked != null) {
                                      final pickedStr = DateFormat('dd-MM-yyyy')
                                          .format(picked);
                                      setState(() {
                                        _fromDateController.text = pickedStr;
                                        _toDateController.text = pickedStr;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (_selectedPeriod == 'This Month' ||
                            _selectedPeriod == 'Last Month')
                          Padding(
                            padding:
                                const EdgeInsets.only(top: 12.0, bottom: 8.0),
                            child: Row(
                              children: [
                                const Icon(Icons.date_range,
                                    size: 18, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text(
                                  "From: ${_fromDateController.text}  To: ${_toDateController.text}",
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        if (_selectedPeriod == 'Date Range' ||
                            _selectedPeriod == 'Single Day')
                          Center(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue,
                                side: const BorderSide(color: Colors.blue),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () async {
                                if (_fromDateController.text.isEmpty ||
                                    _toDateController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Please select both dates.')),
                                  );
                                  return;
                                }
                                await _fetchAndShowChart();
                              },
                              icon: const Icon(Icons.bar_chart),
                              label: const Text('Apply'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                // 6. Show loading spinner while fetching
                if (_isLoading)
                  const Center(
                      child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  )),
                // 7. Wrap chart and summary in a Card
                if (_showChart && !_isLoading)
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildChart(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
// ...existing code...
}
