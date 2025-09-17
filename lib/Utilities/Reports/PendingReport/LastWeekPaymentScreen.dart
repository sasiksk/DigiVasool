// Create a new file: LastWeekPaymentScreen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vasool_diary/Data/Databasehelper.dart';

class LastWeekPaymentScreen extends StatefulWidget {
  const LastWeekPaymentScreen({super.key});

  @override
  State<LastWeekPaymentScreen> createState() => _LastWeekPaymentScreenState();
}

class _LastWeekPaymentScreenState extends State<LastWeekPaymentScreen> {
  List<String> _lineNames = [];
  String? _selectedLine;
  List<Map<String, dynamic>> _partyPaymentData = [];
  bool _isLoading = false;
  String _searchText = '';
  List<Map<String, dynamic>> _filteredParties = [];

  // Add these new variables for date range
  DateTime _startDate = DateTime.now().subtract(Duration(days: 7));
  DateTime _endDate = DateTime.now();
  bool _isCustomDateRange = false;

  @override
  void initState() {
    super.initState();
    _loadLineNames();
  }

  Future<void> _loadLineNames() async {
    final lineNames = await dbline.getLineNames();
    setState(() {
      _lineNames = lineNames;
    });
  }

  Future<void> _loadPartyPaymentData(String lineName) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get all parties for the selected line
      final parties = await dbLending.getLendingDetailsByLineName(lineName);
      if (parties == null) {
        setState(() {
          _partyPaymentData = [];
          _filteredParties = [];
          _isLoading = false;
        });
        return;
      }

      // Use selected date range instead of fixed last week
      final String startDateStr = DateFormat('yyyy-MM-dd').format(_startDate);
      final String endDateStr = DateFormat('yyyy-MM-dd').format(_endDate);

      List<Map<String, dynamic>> partyData = [];

      for (var party in parties) {
        final int lenId = party['LenId'];
        final String partyName = party['PartyName'] ?? 'Unknown';
        final double amtGiven = (party['amtgiven'] as num?)?.toDouble() ?? 0.0;
        final double profit = (party['profit'] as num?)?.toDouble() ?? 0.0;
        final double amtCollected =
            (party['amtcollected'] as num?)?.toDouble() ?? 0.0;
        final int dueDays = party['duedays'] ?? 0;
        final String phone = party['PartyPhnone']?.toString() ?? '';

        // Get collections for selected date range
        final collections =
            await _getDateRangeCollections(lenId, startDateStr, endDateStr);

        // Calculate payment days and total amount for selected period
        final paymentDays = _calculatePaymentDays(collections);
        final periodAmount = _calculateWeeklyAmount(collections);

        // Calculate daily expected amount
        final totalAmount = amtGiven + profit;
        final dailyExpected = dueDays > 0 ? totalAmount / dueDays : 0.0;

        // Calculate balance
        final balance = totalAmount - amtCollected;

        partyData.add({
          'lenId': lenId,
          'partyName': partyName,
          'phone': phone,
          'totalAmount': totalAmount,
          'amtCollected': amtCollected,
          'balance': balance,
          'dailyExpected': dailyExpected,
          'lastWeekPaymentDays': paymentDays,
          'lastWeekAmount': periodAmount,
          'collections': collections,
          'dueDays': dueDays,
        });
      }

      setState(() {
        _partyPaymentData = partyData;
        _applySearchFilter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  // Rename and update this method (around line 100):
  Future<List<Map<String, dynamic>>> _getDateRangeCollections(
      int lenId, String startDate, String endDate) async {
    final db = await DatabaseHelper.getDatabase();
    return await db.query(
      'Collection',
      where: 'LenId = ? AND Date BETWEEN ? AND ? AND DrAmt > 0',
      whereArgs: [lenId, startDate, endDate],
      orderBy: 'Date DESC',
    );
  }

  // Add these new methods for date selection:
  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        _isCustomDateRange = true;
      });
      if (_selectedLine != null) {
        _loadPartyPaymentData(_selectedLine!);
      }
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
        _isCustomDateRange = true;
      });
      if (_selectedLine != null) {
        _loadPartyPaymentData(_selectedLine!);
      }
    }
  }

  void _resetToLastWeek() {
    setState(() {
      _startDate = DateTime.now().subtract(Duration(days: 7));
      _endDate = DateTime.now();
      _isCustomDateRange = false;
    });
    if (_selectedLine != null) {
      _loadPartyPaymentData(_selectedLine!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo.shade50, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 16),
              if (_selectedLine != null) _buildSearchBar(),
              const SizedBox(height: 16),
              Expanded(child: _buildPartyList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Line Selector
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Line Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.timeline),
              ),
              value: _selectedLine,
              items: _lineNames.map((line) {
                return DropdownMenuItem(value: line, child: Text(line));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedLine = value;
                  _partyPaymentData = [];
                  _filteredParties = [];
                });
                if (value != null) {
                  _loadPartyPaymentData(value);
                }
              },
            ),

            const SizedBox(height: 16),

            // Date Range Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectStartDate,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                      'From: ${DateFormat('dd MMM').format(_startDate)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectEndDate,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                      'To: ${DateFormat('dd MMM').format(_endDate)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: _resetToLastWeek,
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Reset',
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Date Range Info
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _isCustomDateRange
                    ? '📅 ${DateFormat('dd MMM').format(_startDate)} - ${DateFormat('dd MMM').format(_endDate)} (${_endDate.difference(_startDate).inDays + 1} days)'
                    : 'Last 7 days (${DateFormat('dd MMM').format(_startDate)} - ${DateFormat('dd MMM').format(_endDate)})',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _isCustomDateRange
                      ? Colors.orange.shade700
                      : Colors.blue.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search by party name...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
      onChanged: _onSearchChanged,
    );
  }

  Widget _buildPartyList() {
    if (_selectedLine == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Please select a line to view payment history',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredParties.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No parties found for selected line',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredParties.length,
      itemBuilder: (context, index) {
        final party = _filteredParties[index];
        return _buildPartyCard(party);
      },
    );
  }

  Widget _buildPartyCard(Map<String, dynamic> party) {
    final paymentDays = party['lastWeekPaymentDays'] as int;
    final weeklyAmount = party['lastWeekAmount'] as double;
    final balance = party['balance'] as double;
    final dailyExpected = party['dailyExpected'] as double;
    final phone = party['phone'] as String;
    final collections = party['collections'] as List<Map<String, dynamic>>;

    // Determine status color based on payment days
    Color statusColor;
    String statusText;
    if (paymentDays == 0) {
      statusColor = Colors.red;
      statusText = 'No Payment';
    } else if (paymentDays <= 2) {
      statusColor = Colors.orange;
      statusText = 'Low Activity';
    } else if (paymentDays <= 4) {
      statusColor = Colors.amber;
      statusText = 'Moderate';
    } else {
      statusColor = Colors.green;
      statusText = 'Regular';
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.white, statusColor.withOpacity(0.05)],
          ),
        ),
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: statusColor,
            child: Text(
              '$paymentDays',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  party['partyName'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                'Paid $paymentDays days in selected period • ₹${weeklyAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Balance: ₹${balance.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          trailing: phone.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.phone, color: Colors.green),
                  onPressed: () => _callPhone(phone),
                )
              : null,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Summary Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard('Expected/Day',
                          '₹${dailyExpected.toStringAsFixed(2)}'),
                      _buildStatCard('Period Total',
                          '₹${weeklyAmount.toStringAsFixed(2)}'),
                      _buildStatCard('Payment Days',
                          '$paymentDays/${_endDate.difference(_startDate).inDays + 1}'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Recent Collections
                  if (collections.isNotEmpty) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Recent Payments:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...collections.take(5).map((collection) {
                      final date = collection['Date'];
                      final amount =
                          (collection['DrAmt'] as num?)?.toDouble() ?? 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd MMM yyyy').format(
                                DateFormat('yyyy-MM-dd').parse(date),
                              ),
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              '₹${amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ] else
                    const Text(
                      'No payments in last week',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  int _calculatePaymentDays(List<Map<String, dynamic>> collections) {
    // Count unique days when payments were made
    Set<String> paymentDates = {};
    for (var collection in collections) {
      final date = collection['Date'];
      if (date != null) {
        paymentDates.add(date);
      }
    }
    return paymentDates.length;
  }

  double _calculateWeeklyAmount(List<Map<String, dynamic>> collections) {
    double total = 0.0;
    for (var collection in collections) {
      final drAmt = (collection['DrAmt'] as num?)?.toDouble() ?? 0.0;
      total += drAmt;
    }
    return total;
  }

  void _applySearchFilter() {
    if (_searchText.isEmpty) {
      _filteredParties = List.from(_partyPaymentData);
    } else {
      _filteredParties = _partyPaymentData.where((party) {
        final name = party['partyName'].toString().toLowerCase();
        return name.contains(_searchText.toLowerCase());
      }).toList();
    }

    // Sort by payment days (ascending - least payments first)
    _filteredParties.sort((a, b) {
      final aDays = a['lastWeekPaymentDays'] as int;
      final bDays = b['lastWeekPaymentDays'] as int;
      return aDays.compareTo(bDays);
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchText = value;
      _applySearchFilter();
    });
  }

  void _callPhone(String phone) async {
    // Add your phone calling implementation here
    // You can import url_launcher and use this:

    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch phone dialer')),
      );
    }

    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling $phone...')),
    );
  }
}
