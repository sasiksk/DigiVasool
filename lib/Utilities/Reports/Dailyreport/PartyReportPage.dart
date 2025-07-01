import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  Future<void> _onGeneratePdfPressed() async {
    setState(() {
      _loading = true;
    });

    final summaryList =
        await dbLending.getActiveLendingSummaryWithCollections();

    final financeName = ref.watch(financeProvider);

    await generatePartyReportPdf(summaryList, financeName);

    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Parties Report'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Descriptive Header
            Text(
              '📋 Your Lending Diary in One Place',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primaryColorDark,
              ),
            ),
            const SizedBox(height: 12),

            // Description Paragraph
            Text(
              'This report shows all your active parties with their transaction history. '
              'It is just like your diary — tracking how much was given, when it was lent, the due dates, '
              'and how the money is coming back through collections. '
              'You can generate a professional-looking PDF and save or share it anytime.',
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
              textAlign: TextAlign.justify,
            ),

            const Spacer(),

            // Generate Button
            _loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text(
                      "Download & Save PDF",
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 24),
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                    onPressed: _onGeneratePdfPressed,
                  ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
