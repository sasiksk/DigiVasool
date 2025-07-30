import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vasool_diary/Data/Databasehelper.dart';

class PendingFollowupTab extends StatefulWidget {
  const PendingFollowupTab({super.key});

  @override
  State<PendingFollowupTab> createState() => _PendingFollowupTabState();
}

enum PendingFilter {
  notPaidToday,
  notPaidTodayYesterday,
  notPaidPast3Days,
  notPaidPast4OrMore,
}

class _PendingFollowupTabState extends State<PendingFollowupTab> {
  String? _selectedLine;
  List<String> _lineNames = [];
  List<Map<String, dynamic>> _pendingParties = [];
  bool _loading = false;
  bool _hasSearched = false;
  PendingFilter? _pendingFilter;
  bool _sortDescending = false;
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchLineNames();
  }

  Future<void> _fetchLineNames() async {
    final lines = await dbline.getLineNames();
    setState(() {
      _lineNames = lines;
    });
  }

  Future<void> _fetchPendingParties() async {
    if (_selectedLine == null || _pendingFilter == null) return;
    setState(() {
      _loading = true;
      _hasSearched = true;
    });

    final parties = await dbLending.getLendingDetailsByLineName(_selectedLine!);
    if (parties == null) {
      setState(() {
        _pendingParties = [];
        _loading = false;
      });
      return;
    }

    final now = DateTime.now();
    List<Map<String, dynamic>> result = [];

    for (final party in parties) {
      final lenId = party['LenId'] as int;
      final partyName = party['PartyName'] ?? '';
      final phone = party['PartyPhnone'] ?? '';
      int pendingDays = 0;

      final allCollections = await CollectionDB.getCollectionEntries(lenId);
      if (allCollections.isNotEmpty) {
        final lastDate = allCollections
            .map((e) => e['Date'] as String)
            .reduce((a, b) => a.compareTo(b) > 0 ? a : b);
        final lastCollectionDate = DateTime.parse(lastDate);
        pendingDays = now.difference(lastCollectionDate).inDays;
      } else {
        pendingDays = 9999;
      }

      bool add = false;
      switch (_pendingFilter) {
        case PendingFilter.notPaidToday:
          add = pendingDays >= 1;
          break;
        case PendingFilter.notPaidTodayYesterday:
          add = pendingDays >= 2;
          break;
        case PendingFilter.notPaidPast3Days:
          add = pendingDays >= 3;
          break;
        case PendingFilter.notPaidPast4OrMore:
          add = pendingDays >= 4 || pendingDays == 9999;
          break;
        default:
          add = false;
      }

      if (add) {
        result.add({
          'PartyName': partyName,
          'PartyPhnone': phone,
          'pendingDays': pendingDays == 9999 ? 'Never Paid' : pendingDays,
        });
      }
    }

    setState(() {
      _pendingParties = result;
      _loading = false;
    });
  }

  void _callPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Widget _buildDropdowns() => Row(
        children: [
          Expanded(
            child: DropdownButton<String>(
              value: _selectedLine,
              hint: const Text('Select Line'),
              isExpanded: true,
              items: _lineNames
                  .map((name) =>
                      DropdownMenuItem(value: name, child: Text(name)))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedLine = value);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButton<PendingFilter>(
              value: _pendingFilter,
              isExpanded: true,
              hint: const Text('Select Option'),
              items: const [
                DropdownMenuItem(
                  value: PendingFilter.notPaidToday,
                  child: Text('Not Paid Today'),
                ),
                DropdownMenuItem(
                  value: PendingFilter.notPaidTodayYesterday,
                  child: Text('Not Paid Yesterday'),
                ),
                DropdownMenuItem(
                  value: PendingFilter.notPaidPast3Days,
                  child: Text('Not Paid Past 3 Days'),
                ),
                DropdownMenuItem(
                  value: PendingFilter.notPaidPast4OrMore,
                  child: Text('Not Paid 4+ Days'),
                ),
              ],
              onChanged: (val) {
                setState(() => _pendingFilter = val);
              },
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 32),
            tooltip: 'Show Pending Parties',
            onPressed:
                (_selectedLine != null && _pendingFilter != null && !_loading)
                    ? _fetchPendingParties
                    : null,
          ),
        ],
      );

  Widget _buildSearchAndSort() => Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search party...',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: (val) => setState(() => _searchText = val),
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              const Text('Sort by Days:'),
              IconButton(
                icon: Icon(
                  (_loading || !_sortDescending)
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  color: Colors.deepPurple,
                ),
                tooltip: (_loading || !_sortDescending)
                    ? 'Lowest to Highest'
                    : 'Highest to Lowest',
                onPressed: _loading
                    ? null
                    : () => setState(() => _sortDescending = !_sortDescending),
              ),
            ],
          ),
        ],
      );

  Widget _buildPartyCard(Map<String, dynamic> party) {
    final isNeverPaid = party['pendingDays'] == 'Never Paid';
    final pendingDays = isNeverPaid ? null : party['pendingDays'];
    final badgeColor = isNeverPaid
        ? Colors.red
        : (pendingDays >= 4
            ? Colors.deepOrange
            : (pendingDays >= 2 ? Colors.amber : Colors.green));
    final badgeText = isNeverPaid ? 'Never Paid' : '$pendingDays days';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          party['PartyName'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: badgeColor, width: 1),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            color: badgeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isNeverPaid
                        ? 'No collection has been made yet.'
                        : (pendingDays == 1
                            ? 'Not Paid Today'
                            : 'Not Paid for the Past $pendingDays days'),
                    style: TextStyle(
                      color: isNeverPaid
                          ? Colors.red
                          : (pendingDays >= 4
                              ? Colors.deepOrange
                              : Colors.black54),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            (party['PartyPhnone']?.toString().isEmpty ?? true)
                ? Tooltip(
                    message: 'Phone number not available',
                    child: Icon(Icons.phone_disabled, color: Colors.red[300]),
                  )
                : Tooltip(
                    message: 'Call ${party['PartyPhnone']}',
                    child: IconButton(
                      icon: const Icon(Icons.phone,
                          color: Colors.green, size: 28),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Call Party'),
                            content: Text('Call ${party['PartyPhnone']}?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _callPhone(
                                      party['PartyPhnone']?.toString() ?? '');
                                },
                                child: const Text('Call'),
                              ),
                            ],
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: _buildDropdowns(),
            ),
          ),
          const SizedBox(height: 10),
          if (_hasSearched) _buildSearchAndSort(),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_hasSearched)
            Expanded(
              child: Builder(
                builder: (context) {
                  List<Map<String, dynamic>> filteredList = _pendingParties
                      .where((party) => party['PartyName']
                          .toString()
                          .toLowerCase()
                          .contains(_searchText.toLowerCase()))
                      .toList();

                  filteredList.sort((a, b) {
                    final aDays = a['pendingDays'] == 'Never Paid'
                        ? 9999
                        : (a['pendingDays'] as int);
                    final bDays = b['pendingDays'] == 'Never Paid'
                        ? 9999
                        : (b['pendingDays'] as int);
                    if (_loading) {
                      return aDays.compareTo(bDays);
                    }
                    return _sortDescending
                        ? bDays.compareTo(aDays)
                        : aDays.compareTo(bDays);
                  });

                  return ListView.builder(
                    itemCount: filteredList.length,
                    itemBuilder: (context, idx) =>
                        _buildPartyCard(filteredList[idx]),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
