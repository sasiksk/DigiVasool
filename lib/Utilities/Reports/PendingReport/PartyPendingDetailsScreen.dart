import 'package:flutter/material.dart';
import 'package:googleapis/cloudsearch/v1.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:DigiVasool/Data/Databasehelper.dart';

class PartyPendingDetailsScreen extends StatefulWidget {
  const PartyPendingDetailsScreen({super.key});

  @override
  State<PartyPendingDetailsScreen> createState() =>
      _PartyPendingDetailsScreenState();
}

enum PendingSort { highToLow, lowToHigh }

class _PartyPendingDetailsScreenState extends State<PartyPendingDetailsScreen> {
  List<Map<String, dynamic>> _pendingList = [];
  List<Map<String, dynamic>> _filteredList = [];
  bool _isLoading = true;
  String _searchText = '';
  PendingSort _sortOrder = PendingSort.highToLow;

  @override
  void initState() {
    super.initState();
    _fetchPendingParties();
  }

  Future<void> _fetchPendingParties() async {
    final result = await dbLending.getActiveParties();
    final filtered = result.where((party) {
      final amtGiven = (party['amtgiven'] as num?) ?? 0;
      final profit = (party['profit'] as num?) ?? 0;
      final amtCollected = (party['amtcollected'] as num?) ?? 0;
      final pendingAmt = amtGiven + profit - amtCollected;
      return pendingAmt > 0;
    }).toList();

    setState(() {
      _pendingList = filtered;
      _applySearchAndSort();
      _isLoading = false;
    });
  }

  void _applySearchAndSort() {
    List<Map<String, dynamic>> tempList = List.from(_pendingList);

    // Search filter
    if (_searchText.isNotEmpty) {
      tempList = tempList.where((party) {
        final name = (party['PartyName'] ?? '').toString().toLowerCase();
        return name.contains(_searchText.toLowerCase());
      }).toList();
    }

    // Sort
    tempList.sort((a, b) {
      final aAmt = ((a['amtgiven'] as num?) ?? 0) +
          ((a['profit'] as num?) ?? 0) -
          ((a['amtcollected'] as num?) ?? 0);
      final bAmt = ((b['amtgiven'] as num?) ?? 0) +
          ((b['profit'] as num?) ?? 0) -
          ((b['amtcollected'] as num?) ?? 0);
      if (_sortOrder == PendingSort.highToLow) {
        return bAmt.compareTo(aAmt);
      } else {
        return aAmt.compareTo(bAmt);
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
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Party Pending Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Search bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search Party Name',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 10),
            // Filter Row
            Row(
              children: [
                Icon(Icons.filter_alt, color: theme.primaryColor),
                const SizedBox(width: 8),
                Text("Filter", style: theme.textTheme.titleMedium),
                const Spacer(),
                PopupMenuButton<PendingSort>(
                  icon: const Icon(Icons.sort),
                  onSelected: _onSortChanged,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: PendingSort.highToLow,
                      child: const Text('High Pending to Low'),
                    ),
                    PopupMenuItem(
                      value: PendingSort.lowToHigh,
                      child: const Text('Low Pending to High'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredList.isEmpty
                      ? const Center(child: Text("No pending parties found."))
                      : ListView.separated(
                          itemCount: _filteredList.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final party = _filteredList[index];
                            final amtGiven = (party['amtgiven'] as num?) ?? 0;
                            final profit = (party['profit'] as num?) ?? 0;
                            final amtCollected =
                                (party['amtcollected'] as num?) ?? 0;
                            final dueDays = (party['duedays'] as int?) ?? 0;
                            final pendingAmt = amtGiven + profit - amtCollected;
                            final totalAmt = amtGiven + profit;

                            // Calculate per day amount and pending days
                            double perDayAmt = 0;
                            if (totalAmt > 0 && dueDays > 0) {
                              perDayAmt = totalAmt / dueDays;
                            }
                            double pendingDays = 0;
                            if (perDayAmt > 0) {
                              pendingDays = pendingAmt / perDayAmt;
                            }

                            final phone =
                                party['PartyPhnone']?.toString() ?? '';

                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  (party['PartyName'] ?? '')
                                          .toString()
                                          .isNotEmpty
                                      ? party['PartyName']
                                          .toString()
                                          .substring(0, 1)
                                          .toUpperCase()
                                      : '?',
                                ),
                              ),
                              title: Text(party['PartyName'] ?? ''),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      "Pending Amt: ₹${pendingAmt.toStringAsFixed(2)}"),
                                  Text(
                                      "Pending Days: ${pendingDays.isNaN ? '-' : pendingDays.toStringAsFixed(1)}"),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.phone,
                                    color: Colors.green),
                                onPressed: phone.isNotEmpty
                                    ? () => _callPhone(phone)
                                    : null,
                                tooltip: phone.isNotEmpty
                                    ? "Call $phone"
                                    : "No phone",
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
