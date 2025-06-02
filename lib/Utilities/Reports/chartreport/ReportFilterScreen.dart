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

  Future<void> _fetchAndShowChart() async {
    final from = DateFormat('yyyy-MM-dd')
        .format(DateFormat('dd-MM-yyyy').parse(_fromDateController.text));
    final to = DateFormat('yyyy-MM-dd')
        .format(DateFormat('dd-MM-yyyy').parse(_toDateController.text));
    final data =
        await CollectionDB.getCollectionSumByDate(fromDate: from, toDate: to);
    setState(() {
      _chartData = data;
      _showChart = true;
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

    final weeks = _getWeeklyChunks(_chartData);
    final weekData = weeks[_currentWeekIndex];

    final totalCredit = weekData.fold<num>(
        0, (sum, item) => sum + ((item['totalCrAmt'] as num?) ?? 0));
    final totalDebit = weekData.fold<num>(
        0, (sum, item) => sum + ((item['totalDrAmt'] as num?) ?? 0));

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _showCredit
                  ? "Total Credit: ₹${totalCredit.toStringAsFixed(2)}"
                  : "Total Debit: ₹${totalDebit.toStringAsFixed(2)}",
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _currentWeekIndex > 0
                      ? () => setState(() => _currentWeekIndex--)
                      : null,
                ),
                Text('Week ${_currentWeekIndex + 1} of ${weeks.length}'),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _currentWeekIndex < weeks.length - 1
                      ? () => setState(() => _currentWeekIndex++)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 6),
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

            /// CHART
            SizedBox(
              height: 360, // Adjust as needed
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: weekData.length * 60,
                  child: BarChart(
                    BarChartData(
                      maxY: _getMaxY(weekData) * 1.2, // Adds headroom
                      alignment: BarChartAlignment.spaceAround,
                      barGroups: List.generate(weekData.length, (i) {
                        final item = weekData[i];
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
                              if (idx < 0 || idx >= weekData.length)
                                return const SizedBox();
                              final date = weekData[idx]['Date'] as String;
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
                        rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      barTouchData: BarTouchData(
                        enabled: false,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipMargin: 8,
                          tooltipPadding: const EdgeInsets.all(4),
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '₹${rod.toY.toStringAsFixed(0)}',
                              const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
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
        ),
      ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      "Select Period:",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _selectedPeriod,
                      items: const [
                        DropdownMenuItem(
                            value: 'This Month', child: Text('This Month')),
                        DropdownMenuItem(
                            value: 'Last Month', child: Text('Last Month')),
                        DropdownMenuItem(
                            value: 'Date Range', child: Text('Date Range')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedPeriod = value!;
                          _setDefaultDates();
                          _showChart = false;
                          _chartData = [];
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _fromDateController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'From Date',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _toDateController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'To Date',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (_fromDateController.text.isEmpty ||
                          _toDateController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please select both dates.')),
                        );
                        return;
                      }
                      await _fetchAndShowChart();
                    },
                    icon: const Icon(Icons.bar_chart),
                    label: const Text('Apply'),
                  ),
                ),
                const SizedBox(height: 16),
                if (_showChart) _buildChart(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
