import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vasool_diary/Data/Databasehelper.dart';
import 'package:vasool_diary/Utilities/Reports/PendingReport/PendingFollowupTab.dart';

class PartyPendingDetailsScreen extends StatefulWidget {
  const PartyPendingDetailsScreen({super.key});

  @override
  State<PartyPendingDetailsScreen> createState() =>
      _PartyPendingDetailsScreenState();
}

enum PendingSort {
  highToLow,
  lowToHigh,
  dueDaysHighToLow,
  dueDaysLowToHigh,
  daysRemHighToLow,
  daysRemLowToHigh,
}

class _PartyPendingDetailsScreenState extends State<PartyPendingDetailsScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _pendingList = [];
  List<Map<String, dynamic>> _filteredList = [];
  bool _isLoading = true;
  String _searchText = '';
  PendingSort _sortOrder = PendingSort.highToLow;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchPendingParties();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchPendingParties() async {
    final result = await dbLending.getActiveParties();
    final filtered = result.where((party) {
      final amtGiven = (party['amtgiven'] as num?) ?? 0;
      final profit = (party['profit'] as num?) ?? 0;
      final amtCollected = (party['amtcollected'] as num?) ?? 0;
      return (amtGiven + profit - amtCollected) > 0;
    }).toList();

    setState(() {
      _pendingList = filtered;
      _applySearchAndSort();
      _isLoading = false;
    });
  }

  void _applySearchAndSort() {
    List<Map<String, dynamic>> tempList = List.from(_pendingList);

    if (_searchText.isNotEmpty) {
      tempList = tempList.where((party) {
        final name = (party['PartyName'] ?? '').toString().toLowerCase();
        return name.contains(_searchText.toLowerCase());
      }).toList();
    }

    tempList.sort((a, b) {
      double calcPendingPer(Map<String, dynamic> party) {
        final amtGiven = (party['amtgiven'] as num?) ?? 0;
        final profit = (party['profit'] as num?) ?? 0;
        final amtCollected = (party['amtcollected'] as num?) ?? 0;
        final dueDays = (party['duedays'] as int?) ?? 0;
        final lentDateStr = party['Lentdate'] ?? party['lentdate'] ?? '';

        final totalAmt = amtGiven + profit;
        final perDayAmt =
            (totalAmt > 0 && dueDays > 0) ? totalAmt / dueDays : 0;

        int? daysOver;
        if (lentDateStr.isNotEmpty) {
          try {
            daysOver = DateTime.now()
                .difference(DateFormat('yyyy-MM-dd').parse(lentDateStr))
                .inDays;
          } catch (_) {
            daysOver = null;
          }
        }
        final daysPaid = perDayAmt != 0 ? amtCollected / perDayAmt : 0.0;

        if (daysOver != null && daysOver > 0) {
          return ((daysOver - daysPaid) / daysOver) * 100;
        }
        return 0.0;
      }

      final aPer = calcPendingPer(a);
      final bPer = calcPendingPer(b);

      final aDueDays = (a['duedays'] as int?) ?? 0;
      final bDueDays = (b['duedays'] as int?) ?? 0;

      int getDaysRem(Map<String, dynamic> party) {
        final dueDays = (party['duedays'] as int?) ?? 0;
        final lentDateStr = party['Lentdate'] ?? party['lentdate'] ?? '';
        int? daysOver;
        if (lentDateStr.isNotEmpty) {
          try {
            daysOver = DateTime.now()
                .difference(DateFormat('yyyy-MM-dd').parse(lentDateStr))
                .inDays;
          } catch (_) {
            daysOver = null;
          }
        }
        return (dueDays != 0 && daysOver != null) ? dueDays - daysOver : 0;
      }

      final aDaysRem = getDaysRem(a);
      final bDaysRem = getDaysRem(b);

      switch (_sortOrder) {
        case PendingSort.highToLow:
          return bPer.compareTo(aPer);
        case PendingSort.lowToHigh:
          return aPer.compareTo(bPer);
        case PendingSort.dueDaysHighToLow:
          return bDueDays.compareTo(aDueDays);
        case PendingSort.dueDaysLowToHigh:
          return aDueDays.compareTo(bDueDays);
        case PendingSort.daysRemHighToLow:
          return bDaysRem.compareTo(aDaysRem);
        case PendingSort.daysRemLowToHigh:
          return aDaysRem.compareTo(bDaysRem);
      }
    });

    _filteredList = tempList;
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchText = value;
      _applySearchAndSort();
    });
  }

  void _onSortChanged(PendingSort sort) {
    setState(() {
      _sortOrder = sort;
      _applySearchAndSort();
    });
  }

  void _callPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pending Parties',
              style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.primaryColor, theme.primaryColorDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          bottom: const TabBar(
            labelColor: Colors.white, // Selected tab text color
            unselectedLabelColor: Colors.grey, // Unselected tab text color
            indicatorColor: Colors.white, // Optional: underline color
            tabs: [
              Tab(text: 'Overall Pending'),
              Tab(text: 'Day Wise Pending'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Your existing content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Search Bar
                  _buildSearchBar(theme),
                  const SizedBox(height: 16),

                  // Sorting Controls
                  _buildSortingControls(theme),
                  const SizedBox(height: 16),

                  // Party List
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredList.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.assignment,
                                        size: 64, color: theme.disabledColor),
                                    const SizedBox(height: 16),
                                    Text(
                                      "No pending parties found",
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                              color: theme.disabledColor),
                                    ),
                                  ],
                                ),
                              )
                            : _buildPartyList(),
                  ),
                ],
              ),
            ),
            // Tab 2: Empty for now
            const PendingFollowupTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search by party name...',
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
      onChanged: _onSearchChanged,
    );
  }

  Widget _buildSortingControls(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Sort by:',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButton<PendingSort>(
            value: _sortOrder,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down),
            isDense: true,
            style: theme.textTheme.bodyMedium,
            items: const [
              DropdownMenuItem(
                value: PendingSort.highToLow,
                child: Text('Pending % High to Low'),
              ),
              DropdownMenuItem(
                value: PendingSort.lowToHigh,
                child: Text('Pending % Low to High'),
              ),
              DropdownMenuItem(
                value: PendingSort.daysRemHighToLow,
                child: Text('Days Rem High to Low'),
              ),
              DropdownMenuItem(
                value: PendingSort.daysRemLowToHigh,
                child: Text('Days Rem Low to High'),
              ),
            ],
            onChanged: (value) => value != null ? _onSortChanged(value) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildPartyList() {
    return ListView.separated(
      itemCount: _filteredList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final party = _filteredList[index];
        return PartyCard(
          party: party,
          callPhone: _callPhone,
        );
      },
    );
  }
}

class PartyCard extends StatefulWidget {
  final Map<String, dynamic> party;
  final void Function(String) callPhone;

  const PartyCard({required this.party, required this.callPhone, super.key});

  @override
  State<PartyCard> createState() => _PartyCardState();
}

class _PartyCardState extends State<PartyCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final party = widget.party;
    final amtGiven = (party['amtgiven'] as num?) ?? 0;
    final profit = (party['profit'] as num?) ?? 0;
    final amtCollected = (party['amtcollected'] as num?) ?? 0;
    final dueDays = (party['duedays'] as int?) ?? 0;
    final lentDateStr = party['Lentdate'] ?? party['lentdate'] ?? '';
    final phone = party['PartyPhnone']?.toString() ?? '';

    final totalAmt = amtGiven + profit;
    final pendingAmt = totalAmt - amtCollected;
    final perDayAmt = (totalAmt > 0 && dueDays > 0) ? totalAmt / dueDays : 0;

    int? daysOver;
    if (lentDateStr.isNotEmpty) {
      try {
        daysOver = DateTime.now()
            .difference(DateFormat('yyyy-MM-dd').parse(lentDateStr))
            .inDays;
      } catch (_) {
        daysOver = null;
      }
    }

    final daysRem = (dueDays != 0 && daysOver != null) ? dueDays - daysOver : 0;

    String dueDateStr = '-';
    if (lentDateStr.isNotEmpty && dueDays > 0) {
      try {
        final lentDate = DateFormat('yyyy-MM-dd').parse(lentDateStr);
        final dueDate = lentDate.add(Duration(days: dueDays));
        dueDateStr = DateFormat('dd MMM yyyy').format(dueDate);
      } catch (_) {}
    }

    final daysPaid = perDayAmt != 0 ? amtCollected / perDayAmt : 0.0;
    final pendingDays =
        daysRem > 0 ? ((daysOver ?? 0) - daysPaid) : ((dueDays) - daysPaid);
    final pendingPer = (daysOver != null && daysOver > 0)
        ? ((daysOver - daysPaid) / daysOver) * 100
        : 0.0;
    final isOverdue = daysRem != null && daysRem < 0;
    final progress = totalAmt > 0 ? amtCollected / totalAmt : 0.0;

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Party header
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${party['PartyName'] ?? 'Unknown Party'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                if (phone.isNotEmpty)
                  IconButton(
                    icon:
                        const Icon(Icons.phone, color: Colors.green, size: 28),
                    onPressed: () => widget.callPhone(phone),
                    tooltip: 'Call $phone',
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Days overview
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDaysBox('Over', '${daysOver ?? 0}', Colors.blue),
                _buildDaysBox(
                    'Paid', daysPaid.toStringAsFixed(1), Colors.green),
                _buildDaysBox(
                  pendingDays < 0 ? 'Advance' : 'Pending',
                  pendingDays.abs().toStringAsFixed(1),
                  pendingDays < 0 ? Colors.orange : Colors.red,
                ),
                const SizedBox(height: 8),
                IconButton(
                  icon: Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.deepPurple,
                  ),
                  onPressed: () {
                    setState(() {
                      _expanded = !_expanded;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Expanded details
            if (_expanded) ...[
              const Divider(),
              const SizedBox(height: 8),

              // Amounts row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAmountCard(
                      'Total', '₹${NumberFormat('#,##0.00').format(totalAmt)}'),
                  _buildAmountCard('Collected',
                      '₹${NumberFormat('#,##0.00').format(amtCollected)}'),
                  _buildAmountCard(
                    'Pending',
                    '₹${NumberFormat('#,##0.00').format(pendingAmt)}',
                    isHighlighted: true,
                    color: isOverdue ? Colors.red : Colors.deepPurple,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Progress bar
              Stack(
                children: [
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 25,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress == 1 ? Colors.green : theme.primaryColor,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Text(
                        '${(progress * 100).toStringAsFixed(1)}% Collected',
                        style: const TextStyle(
                            color: Color.fromARGB(255, 1, 37, 25),
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Date info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDateCard('Lent Date', lentDateStr),
                  _buildDateCard('Due Date', dueDateStr),
                ],
              ),
              const SizedBox(height: 8),

              // Due status
              if (isOverdue)
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning, color: Colors.red, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'OVERDUE: ${daysRem.abs()} days',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else if (daysRem > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time,
                          color: Colors.green, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'DUE IN: $daysRem days',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              // Call button
              if (phone.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.phone),
                    label: const Text('Call Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => widget.callPhone(phone),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDaysBox(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              )),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              )),
        ],
      ),
    );
  }

  Widget _buildAmountCard(String label, String value,
      {bool isHighlighted = false, Color? color}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            color: color ?? Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildDateCard(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
