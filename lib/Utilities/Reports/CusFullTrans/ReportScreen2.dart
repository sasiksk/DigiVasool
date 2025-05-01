import 'package:flutter/material.dart';
import 'package:DigiVasool/Data/Databasehelper.dart';
import 'package:DigiVasool/Utilities/CustomDatePicker.dart';
import 'package:intl/intl.dart';
import 'package:DigiVasool/Utilities/Reports/CusFullTrans/pdf_generator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:DigiVasool/finance_provider.dart';

class ReportScreen2 extends StatefulWidget {
  const ReportScreen2({super.key});

  @override
  _ReportScreen2State createState() => _ReportScreen2State();
}

class _ReportScreen2State extends State<ReportScreen2> {
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  List<PdfEntry> _entries = [];
  double _totalYouGave = 0.0;
  double _totalYouGot = 0.0;

  Future<void> _fetchEntries() async {
    if (_startDateController.text.isNotEmpty &&
        _endDateController.text.isNotEmpty) {
      // Parse the start and end dates from the controllers
      DateTime startDate =
          DateFormat('dd-MM-yyyy').parse(_startDateController.text);
      DateTime endDate =
          DateFormat('dd-MM-yyyy').parse(_endDateController.text);

      // Validate the dates
      if (endDate.isBefore(startDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End date cannot be before start date')),
        );
        return;
      }

      if (startDate.isAfter(DateTime.now()) ||
          endDate.isAfter(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dates cannot go beyond today')),
        );
        return;
      }

      // Convert to yyyy-MM-dd format
      String formattedStartDate = DateFormat('yyyy-MM-dd').format(startDate);
      String formattedEndDate = DateFormat('yyyy-MM-dd').format(endDate);

      startDate = DateFormat('yyyy-MM-dd').parse(formattedStartDate);
      endDate = DateFormat('yyyy-MM-dd').parse(formattedEndDate);

      // Fetch entries from the database
      List<Map<String, dynamic>> entries =
          await CollectionDB.getEntriesBetweenDates(startDate, endDate);

      double totalYouGave = 0.0;
      double totalYouGot = 0.0;

      List<PdfEntry> pdfEntries = [];

      for (var entry in entries) {
        if (entry['CrAmt'] != null) {
          totalYouGave += entry['CrAmt'];
        }
        if (entry['DrAmt'] != null) {
          totalYouGot += entry['DrAmt'];
        }

        // Fetch party name
        String partyName =
            await DatabaseHelper.getPartyNameByLenId(entry['LenId']) ??
                'Unknown';

        // Create PdfEntry
        PdfEntry pdfEntry = PdfEntry(
          partyName: partyName,
          date: entry['Date'], // Keep the date as it is from the database
          drAmt: entry['DrAmt'] ?? 0.0,
          crAmt: entry['CrAmt'] ?? 0.0,
        );

        pdfEntries.add(pdfEntry);
      }

      setState(() {
        _entries = pdfEntries;
        _totalYouGave = totalYouGave;
        _totalYouGot = totalYouGot;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Report'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Selection Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: CustomDatePicker(
                    controller: _startDateController,
                    labelText: 'Start Date',
                    hintText: 'Pick a start date',
                    lastDate: DateTime.now(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomDatePicker(
                    controller: _endDateController,
                    labelText: 'End Date',
                    hintText: 'Pick an end date',
                    lastDate:
                        DateTime.now(), // Ensure end date does not exceed today
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchEntries,
              child: const Text('Fetch Entries'),
            ),
            const SizedBox(height: 16),

            // Net Balance Section
            const Text(
              'Net Balance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.green.shade900,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total',
                          style: TextStyle(color: Colors.white)),
                      Text('${_entries.length} Entries',
                          style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('You Gave',
                          style: TextStyle(color: Colors.yellow)),
                      Text('₹ $_totalYouGave',
                          style: const TextStyle(color: Colors.yellow)),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('You Got',
                          style: TextStyle(color: Colors.white)),
                      Text('₹ $_totalYouGot',
                          style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Entries List
            Expanded(
              child: _entries.isEmpty
                  ? const Center(
                      child: Text(
                        'No entries found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _entries.length,
                      itemBuilder: (context, index) {
                        var entry = _entries[index];

                        return Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    // Format the date as dd-MM-yyyy
                                    DateFormat('dd-MM-yy').format(
                                      DateFormat('yyyy-MM-dd')
                                          .parse(entry.date),
                                    ),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    entry.partyName,
                                    style: TextStyle(
                                        color: Colors.deepPurple.shade900,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Text(
                                    entry.crAmt != 0.0 ? '₹${entry.crAmt}' : '',
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Text(
                                    entry.drAmt != 0.0 ? '₹${entry.drAmt}' : '',
                                    style: const TextStyle(color: Colors.green),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                      separatorBuilder: (context, index) => const Divider(),
                    ),
            ),

            // Download Button in SafeArea
            SafeArea(
              child: Consumer(
                builder: (context, ref, child) {
                  final finnaame = ref.watch(financeProvider);
                  return Center(
                    child: ElevatedButton.icon(
                      onPressed: () => generatePdf(
                        _entries,
                        _totalYouGave,
                        _totalYouGot,
                        _startDateController.text,
                        _endDateController.text,
                        ref,
                        finnaame,
                      ),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('DOWNLOAD'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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
