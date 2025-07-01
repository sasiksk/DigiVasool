import 'package:flutter/material.dart';
import 'package:vasool_diary/Data/Databasehelper.dart';
import 'package:vasool_diary/Utilities/CustomDatePicker.dart';
import 'package:intl/intl.dart';
import 'package:vasool_diary/Utilities/Reports/CusFullTrans/pdf_generator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vasool_diary/finance_provider.dart';

class ReportScreen2 extends StatefulWidget {
  final int? lenId; // Make lenId optional

  const ReportScreen2({Key? key, this.lenId}) : super(key: key);

  @override
  _ReportScreen2State createState() => _ReportScreen2State();
}

class _ReportScreen2State extends State<ReportScreen2> {
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  String _selectedType = 'All'; // Default

  final List<String> _entryTypes = ['All', 'Debit', 'Credit'];
  List<PdfEntry> _entries = [];
  double _totalYouGave = 0.0;
  double _totalYouGot = 0.0;

  @override
  void initState() {
    super.initState();
    _startDateController.text = DateFormat('dd-MM-yyyy')
        .format(DateTime(DateTime.now().year, DateTime.now().month, 1));
    _endDateController.text = DateFormat('dd-MM-yyyy').format(DateTime.now());
  }

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
      List<Map<String, dynamic>> entries;
      if (widget.lenId != null) {
        // Fetch entries for the specific customer
        entries = await CollectionDB.getEntriesForCustomerBetweenDates(
            widget.lenId!, startDate, endDate);
      } else {
        // Fetch entries for all customers
        entries = await CollectionDB.getEntriesBetweenDates(startDate, endDate);
      }

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
      if (_selectedType == 'Debit') {
        pdfEntries = pdfEntries.where((e) => e.drAmt != 0.0).toList();
      } else if (_selectedType == 'Credit') {
        pdfEntries = pdfEntries.where((e) => e.crAmt != 0.0).toList();
      }

      setState(() {
        _entries = pdfEntries;
        _totalYouGave = totalYouGave;
        _totalYouGot = totalYouGot;
      });
    }
  }

  void _showDownloadOptions(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Download Options"),
          content: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.blue.shade300, width: 1),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    "Choose how you want to group the report:",
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _generateDateWisePdf(ref); // Generate Date-wise PDF
              },
              child: const Text("Date-wise"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _generatePartyWisePdf(ref); // Generate Party-wise PDF
              },
              child: const Text("Party-wise"),
            ),
          ],
        );
      },
    );
  }

  void _generatePartyWisePdf(WidgetRef ref) {
    final finnaame = ref.watch(financeProvider);

    // Group entries by partyName
    final groupedEntries = <String, List<PdfEntry>>{};
    for (var entry in _entries) {
      if (!groupedEntries.containsKey(entry.partyName)) {
        groupedEntries[entry.partyName] = [];
      }
      groupedEntries[entry.partyName]!.add(entry);
    }

    // Flatten grouped entries into a single list for PDF generation
    final List<PdfEntry> partyWiseEntries = [];
    groupedEntries.forEach((partyName, entries) {
      partyWiseEntries.addAll(entries);
    });

    generatePdf(
      partyWiseEntries,
      _totalYouGave,
      _totalYouGot,
      _startDateController.text,
      _endDateController.text,
      ref,
      finnaame,
      isPartyWise: true, // Pass a flag to indicate Party-wise grouping
    );
  }

  void _generateDateWisePdf(WidgetRef ref) {
    final finnaame = ref.watch(financeProvider);
    generatePdf(
      _entries,
      _totalYouGave,
      _totalYouGot,
      _startDateController.text,
      _endDateController.text,
      ref,
      finnaame,
    );
  }

  @override
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
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Selection Row
            // Date pickers row
            Row(
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
                    lastDate: DateTime.now(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Show: ', style: TextStyle(fontSize: 15)),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _selectedType,
                      items: _entryTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                        });
                      },
                    ),
                    const SizedBox(width: 24),
                    SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: _fetchEntries,
                        icon: const Icon(Icons.check_circle,
                            color: Colors.white, size: 20),
                        label: const Text('OK',
                            style:
                                TextStyle(color: Colors.white, fontSize: 15)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 8),
                          minimumSize: const Size(100, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
// Totals section (old color scheme)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
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

            const SizedBox(height: 8),
            // Entries List
            Expanded(
              child: _entries.isEmpty
                  ? const Center(
                      child: Text(
                        'No entries found',
                        style: TextStyle(fontSize: 15, color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _entries.length,
                      itemBuilder: (context, index) {
                        var entry = _entries[index];
                        return Card(
                          elevation: 1,
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat('dd-MM-yy').format(
                                        DateFormat('yyyy-MM-dd')
                                            .parse(entry.date),
                                      ),
                                      style: const TextStyle(
                                          fontSize: 13, color: Colors.black54),
                                    ),
                                    Text(
                                      entry.partyName,
                                      style: TextStyle(
                                          color: Colors.deepPurple.shade900,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text(
                                      entry.crAmt != 0.0
                                          ? '₹${entry.crAmt}'
                                          : '',
                                      style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text(
                                      entry.drAmt != 0.0
                                          ? '₹${entry.drAmt}'
                                          : '',
                                      style: const TextStyle(
                                          color: Colors.green,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 6),
                    ),
            ),
            // Download Button in SafeArea
            SafeArea(
              child: Consumer(
                builder: (context, ref, child) {
                  final finnaame = ref.watch(financeProvider);
                  return Center(
                    child: ElevatedButton.icon(
                      onPressed: () => _showDownloadOptions(context, ref),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('DOWNLOAD'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
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
