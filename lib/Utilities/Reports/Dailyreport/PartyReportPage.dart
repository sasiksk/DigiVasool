import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vasool_diary/finance_provider.dart';
import 'party_report_pdf.dart';
import 'package:vasool_diary/Data/Databasehelper.dart';

class PartyReportPage extends ConsumerStatefulWidget {
  const PartyReportPage({Key? key}) : super(key: key);

  @override
  ConsumerState<PartyReportPage> createState() => _PartyReportPageState();
}

class _PartyReportPageState extends ConsumerState<PartyReportPage> {
  bool _loading = false;
  List<Map<String, dynamic>> _summaryList = [];
  List<String> _partyNames = [];
  String _selectedParty = 'All';

  @override
  void initState() {
    super.initState();
    _fetchSummaryList();
  }

  Future<void> _fetchSummaryList() async {
    final summaryList =
        await dbLending.getActiveLendingSummaryWithCollections();
    setState(() {
      _summaryList = summaryList;
      _partyNames = [
        'All',
        ...{for (var s in summaryList) (s['PartyName'] ?? '').toString()}
      ];
    });
  }

  Future<void> _onGeneratePdfPressed() async {
    setState(() => _loading = true);

    final financeName = ref.watch(financeProvider);

    final filteredList = _selectedParty == 'All'
        ? _summaryList
        : _summaryList
            .where((s) => (s['PartyName'] ?? '') == _selectedParty)
            .toList();

    await generatePartyReportPdf(filteredList, financeName);

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('📄 Party-wise Lending Report'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '📋 Lending Summary',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColorDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'View detailed lending and collection history by party. '
                'Select a party or generate the full report.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),

              // Dropdown Section
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select Party', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: _selectedParty,
                      isExpanded: true,
                      items: _partyNames
                          .map((name) => DropdownMenuItem(
                                value: name,
                                child: Text(name.isEmpty ? '(Unnamed)' : name),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedParty = value);
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '💡 This report helps you track each party’s total lent amount, due dates, and collections. '
                  'Perfect for printing or sharing as a professional PDF summary.',
                  style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16),
                  textAlign: TextAlign.justify,
                ),
              ),

              const SizedBox(height: 30),

              // Generate Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.picture_as_pdf),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      _loading ? 'Generating PDF...' : 'Download & Save PDF',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _loading ? null : _onGeneratePdfPressed,
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
