/*import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:DigiVasool/Data/Databasehelper.dart';
import 'package:DigiVasool/Utilities/Reports/Custrans/pdf_generator2.dart';
import 'package:DigiVasool/finance_provider.dart';

class ReportScreen1 extends ConsumerWidget {
  const ReportScreen1({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final financeName = ref.watch(financeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Wise Report'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            try {
              // Fetch data from the database
              Map<String, double> totals = await dbline.allLineDetails();

              List<PdfEntry> entries = await dbLending.fetchLendingEntries();
              double totalAmtGiven = totals['totalAmtGiven'] ?? 0.0;
              double totalProfit = totals['totalProfit'] ?? 0.0;
              double totalAmtReceived = totals['totalAmtRecieved'] ?? 0.0;
              double totalExpense = await fetchTotalExpense();

              // Generate the PDF
              await generateNewPdf(
                entries,
                totalAmtGiven,
                totalProfit,
                totalAmtReceived,
                totalExpense,
                financeName,
              );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PDF generated successfully!')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error generating PDF: $e')),
              );
            }
          },
          child: const Text('Generate PDF'),
        ),
      ),
    );
  }

  Future<double> fetchTotalExpense() async {
    // Implement your logic to fetch total expense from the database
    // Example:
    return 0.0;
  }
}*/
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:DigiVasool/Data/Databasehelper.dart';
import 'package:DigiVasool/Utilities/Reports/Custrans/pdf_generator2.dart';
import 'package:DigiVasool/finance_provider.dart';

class ReportScreen1 extends ConsumerStatefulWidget {
  const ReportScreen1({super.key});

  @override
  ConsumerState<ReportScreen1> createState() => _ReportScreen1State();
}

class _ReportScreen1State extends ConsumerState<ReportScreen1> {
  Map<String, List<PdfEntry>> groupedEntries = {};
  List<PdfEntry> filteredEntries = [];
  String searchQuery = '';
  String sortColumn = 'Party Name';
  bool isAscending = true;

  double totalAmtGiven = 0.0;
  double totalAmtCollected = 0.0;
  double totalBalance = 0.0;
  bool isLoading = true;
  String? selectedLineName; // Holds the selected line name

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      // Fetch data from the database
      List<PdfEntry> fetchedEntries = await dbLending.fetchLendingEntries();

      // Group entries by line name
      Map<String, List<PdfEntry>> grouped = {};
      for (var entry in fetchedEntries) {
        if (!grouped.containsKey(entry.lineName)) {
          grouped[entry.lineName] = [];
        }
        grouped[entry.lineName]!.add(entry);
      }

      setState(() {
        groupedEntries = grouped;
        selectedLineName = groupedEntries.keys.isNotEmpty
            ? groupedEntries.keys.first
            : null; // Default to the first line name
        filteredEntries =
            selectedLineName != null ? groupedEntries[selectedLineName]! : [];
        calculateTotals();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    }
  }

  void calculateTotals() {
    totalAmtGiven = filteredEntries.fold(
        0.0, (sum, entry) => sum + (entry.amtGiven + entry.profit));
    totalAmtCollected =
        filteredEntries.fold(0.0, (sum, entry) => sum + entry.amtCollected);
    totalBalance = filteredEntries.fold(
        0.0,
        (sum, entry) =>
            sum + ((entry.amtGiven + entry.profit) - entry.amtCollected));
  }

  void filterEntries(String query) {
    setState(() {
      searchQuery = query;
      filteredEntries = groupedEntries.values
          .expand((e) => e)
          .where((entry) =>
              entry.partyName.toLowerCase().contains(query.toLowerCase()))
          .toList();
      calculateTotals();
    });
  }

  void sortEntries(String column) {
    setState(() {
      if (sortColumn == column) {
        isAscending = !isAscending;
      } else {
        sortColumn = column;
        isAscending = true;
      }

      filteredEntries.sort((a, b) {
        int compare;
        switch (column) {
          case 'Given':
            compare = (a.amtGiven + a.profit).compareTo(b.amtGiven + b.profit);
            break;
          case 'Collected':
            compare = a.amtCollected.compareTo(b.amtCollected);
            break;
          case 'Balance':
            compare = ((a.amtGiven + a.profit) - a.amtCollected)
                .compareTo((b.amtGiven + b.profit) - b.amtCollected);
            break;
          default: // 'Party Name'
            compare = a.partyName.compareTo(b.partyName);
        }
        return isAscending ? compare : -compare;
      });
    });
  }

  Future<double> fetchTotalExpense() async {
    // Implement your logic to fetch total expense from the database
    // Example:
    return 0.0;
  }

  Future<void> generatePdf() async {
    final financeName = ref.watch(financeProvider);
    try {
      // Fetch data from the database
      Map<String, double> totals = await dbline.allLineDetails();

      List<PdfEntry> entries = await dbLending.fetchLendingEntries();
      double totalAmtGiven = totals['totalAmtGiven'] ?? 0.0;
      double totalProfit = totals['totalProfit'] ?? 0.0;
      double totalAmtReceived = totals['totalAmtRecieved'] ?? 0.0;
      double totalExpense = await fetchTotalExpense();

      // Generate the PDF
      await generateNewPdf(
        entries,
        totalAmtGiven,
        totalProfit,
        totalAmtReceived,
        totalExpense,
        financeName,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF generated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final financeName = ref.watch(financeProvider);
    final today = DateTime.now();
    final formattedDate = "${today.day}-${today.month}-${today.year}";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Wise Report'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header Section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        financeName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Account Statements as on $formattedDate',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: Row(
                    children: [
                      // Label
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          'Pick Line Name:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),

                      // Dropdown
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value:
                              selectedLineName, // Ensure this has a valid initial value
                          isExpanded: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade400),
                            ),
                          ),
                          hint: Text(
                            'Select Line Name',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          items: groupedEntries.keys.map((lineName) {
                            return DropdownMenuItem<String>(
                              value: lineName,
                              child: Text(
                                lineName,
                                style: TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedLineName =
                                  value ?? ""; // Ensuring it never becomes null
                              filteredEntries = (value != null &&
                                      groupedEntries.containsKey(value))
                                  ? groupedEntries[value]!
                                  : [];
                              calculateTotals();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(),
                // Search Box
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search, size: 20),
                      contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                    ),
                    style: const TextStyle(fontSize: 14),
                    onChanged: filterEntries,
                  ),
                ),
                SizedBox(height: 8),

                // Table Header with Sort Options
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 3,
                        child: GestureDetector(
                          onTap: () => sortEntries('Party Name'),
                          child: const Text(
                            'Party Name',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () => sortEntries('Given'),
                          child: const Text(
                            'Given',
                            textAlign: TextAlign.right,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () => sortEntries('Collected'),
                          child: const Text(
                            'Collected',
                            textAlign: TextAlign.right,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () => sortEntries('Balance'),
                          child: const Text(
                            'Balance',
                            textAlign: TextAlign.right,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),

                // Entries List
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredEntries.length,
                    itemBuilder: (context, index) {
                      final entry = filteredEntries[index];
                      final balance =
                          entry.amtGiven + entry.profit - entry.amtCollected;
                      final isEven = index % 2 == 0; // Alternating row colors

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 4.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isEven ? Colors.grey[200] : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    entry.partyName,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '\u20B9${entry.amtGiven + entry.profit}',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '\u20B9${entry.amtCollected}',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '\u20B9$balance',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      color: balance >= 0
                                          ? Colors.black
                                          : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Total Row
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        flex: 3,
                        child: Text(
                          'Total',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '\u20B9$totalAmtGiven',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '\u20B9$totalAmtCollected',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '\u20B9$totalBalance',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                // Download Button
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: generatePdf,
                      child: const Text('Download PDF'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
