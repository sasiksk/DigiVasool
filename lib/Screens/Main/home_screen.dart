import 'package:DigiVasool/Utilities/amtbuild.dart';
import 'package:DigiVasool/Utilities/backup_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:DigiVasool/Data/Databasehelper.dart';
import 'package:DigiVasool/Screens/Main/LineScreen.dart';
import 'package:DigiVasool/Utilities/AppBar.dart';
import 'package:DigiVasool/Utilities/EmptyCard1.dart';
import 'package:DigiVasool/Utilities/Reports/CustomerReportScreen.dart';
import 'package:DigiVasool/Utilities/drawer.dart';
import 'package:DigiVasool/Utilities/FloatingActionButtonWithText.dart';
import 'package:DigiVasool/Screens/Main/linedetailScreen.dart';
import '../../finance_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<String> lineNames = [];
  List<String> originalLineNames = [];
  double totalAmtGiven = 0.0;
  double totalProfit = 0.0;
  double totalAmtRecieved = 0.0;
  Map<String, Map<String, dynamic>> lineDetailsMap = {};
  double todaysTotalDrAmt = 0.0;
  double todaysTotalCrAmt = 0.0;
  double totalexpense = 0.0;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BackupHelper.backupDbIfNeeded(context);
    });
    loadLineNames();
    loadLineDetails();
    loadCollectionAndGivenByDate(selectedDate);
  }

  Future<void> loadCollectionAndGivenByDate(DateTime date) async {
    String queryDate = DateFormat('yyyy-MM-dd').format(date);
    print('Query Date: $queryDate');
    final result = await CollectionDB.getCollectionAndGivenByDate(queryDate);
    print('Result: $result');
    setState(() {
      todaysTotalDrAmt = result['totalDrAmt'] ?? 0.0;
      todaysTotalCrAmt = result['totalCrAmt'] ?? 0.0;
    });
  }

  Future<void> loadLineNames() async {
    final names = await dbline.getLineNames();
    final details =
        await Future.wait(names.map((name) => dbline.getLineDetails(name)));
    setState(() {
      originalLineNames = names;
      lineNames = names;
      for (int i = 0; i < names.length; i++) {
        lineDetailsMap[names[i]] = details[i];
      }
    });
  }

  Future<void> loadLineDetails() async {
    final details = await dbline.allLineDetails();
    setState(() {
      totalAmtGiven = details['totalAmtGiven'] ?? 0.0;
      totalProfit = details['totalProfit'] ?? 0.0;
      totalAmtRecieved = details['totalAmtRecieved'] ?? 0.0;
      totalexpense = details['totalexpense'] ?? 0.0;
    });
  }

  void handleLineSelected(String lineName) {
    ref.read(currentLineNameProvider.notifier).state = lineName;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LineDetailScreen()),
    );
  }

  void _showUpdateFinanceNameDialog(BuildContext context) {
    final TextEditingController _financeNameController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Your Name'),
          content: TextField(
            controller: _financeNameController,
            decoration: const InputDecoration(hintText: 'Enter Your Name'),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Update'),
              onPressed: () async {
                final newFinanceName = _financeNameController.text;
                if (newFinanceName.isNotEmpty) {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.setString('financeName', newFinanceName);
                  ref.read(financeProvider.notifier).state = newFinanceName;
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  TextStyle _textStyle(double fontSize, FontWeight fontWeight, Color color) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontFamily: GoogleFonts.tinos().fontFamily,
    );
  }

  Widget _buildPopupMenuButton(
      BuildContext context, String lineName, Map<String, dynamic> lineDetails) {
    return PopupMenuButton<String>(
      onSelected: (String value) async {
        if (value == 'Update') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LineScreen(entry: lineDetails),
            ),
          );
        } else if (value == 'Delete') {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Confirm Deletion'),
                content: const Text(
                    'Are you sure you want to delete ! All the Parties inside the Line will be deleted'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: const Text('OK'),
                    onPressed: () async {
                      Navigator.of(context).pop();
                      final lenIds =
                          await dbLending.getLenIdsByLineName(lineName);
                      await dbline.deleteLine(lineName);
                      await dbLending.deleteLendingByLineName(lineName);
                      for (final lenId in lenIds) {
                        await CollectionDB.deleteEntriesByLenId(lenId);
                      }
                      loadLineNames();
                      loadLineDetails();
                    },
                  ),
                ],
              );
            },
          );
        }
      },
      itemBuilder: (BuildContext context) {
        return {'Update', 'Delete'}.map((String choice) {
          return PopupMenuItem<String>(
            value: choice,
            child: Text(choice),
          );
        }).toList();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final financeName = ref.watch(financeProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: financeName,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_outlined),
            onPressed: () {
              _showUpdateFinanceNameDialog(context);
            },
          ),
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              }),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              // Handle close action
            },
          ),
        ],
      ),
      drawer: buildDrawer(context),
      body: Column(
        children: [
          EmptyCard1(
            screenHeight: MediaQuery.of(context).size.height * 1.50,
            screenWidth: MediaQuery.of(context).size.width,
            title: 'Account Details',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    buildAmountBlock('Total:', totalProfit + totalAmtGiven),
                    buildAmountBlock('Received:', totalAmtRecieved),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: buildAmountBlock(
                    'You will get:',
                    totalAmtGiven - totalAmtRecieved + totalProfit,
                    centerAlign: true,
                    textSize: 18,
                    labelColor: Colors.indigo,
                    valueColor: Colors.deepPurple,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 10.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15), // Rounded corners
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 235, 231, 208),
                      Color.fromARGB(255, 227, 228, 241),
                      Color.fromARGB(255, 243, 231, 245)
                    ], // Gradient background
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // First Row - Date Picker with Smaller Font
                      SizedBox(
                        height: 40, // Reduce height of the date picker field
                        child: Center(
                          child: TextFormField(
                            controller: TextEditingController(
                              text:
                                  DateFormat('dd-MM-yyyy').format(selectedDate),
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Pick Date',

                              hintText: 'Select a date',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today,
                                  size: 20), // Smaller icon
                              labelStyle: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black), // Small label
                              hintStyle:
                                  TextStyle(fontSize: 16), // Small hint text
                            ),
                            style: const TextStyle(
                                fontSize: 14), // Small text inside field
                            readOnly: true,
                            onTap: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  selectedDate = pickedDate;
                                  loadCollectionAndGivenByDate(pickedDate);
                                });
                              }
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 10), // Space between elements

                      // Second Row - Collection & Given
                      Text(
                        'Collection: ₹${todaysTotalDrAmt.toStringAsFixed(2)} - Given: ₹${todaysTotalCrAmt.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              height: 50, // Adjust the height as needed
              child: TextField(
                style: _textStyle(14, FontWeight.normal, Colors.black),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.add_chart_outlined,
                      color: Colors.blue,
                    ),
                    tooltip: 'View Report',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ViewReportsPage()),
                      );
                    },
                  ),
                  hintText: 'Search line',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) {
                  setState(() {
                    lineNames = originalLineNames
                        .where((lineName) => lineName
                            .toLowerCase()
                            .contains(value.toLowerCase()))
                        .toList();
                  });
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Line Name',
                    style: _textStyle(12, FontWeight.w600, Colors.black),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Amount in Line                               ',
                    textAlign: TextAlign.right,
                    style: _textStyle(12, FontWeight.w600, Colors.black),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: lineNames.length,
              itemBuilder: (context, index) {
                final lineName = lineNames[index];
                final lineDetails = lineDetailsMap[lineName] ?? {};
                final amtGiven = lineDetails['Amtgiven'] ?? 0.0;
                final profit = lineDetails['Profit'] ?? 0.0;
                final expense = lineDetails['expense'] ?? 0.0;
                final amtRecieved = lineDetails['Amtrecieved'] ?? 0.0;
                final calculatedValue =
                    amtGiven + profit - expense - amtRecieved;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 6.0),
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(20),
                    shadowColor: Colors.black26,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => handleLineSelected(lineName),
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF2196F3),
                              Color(0xFF42A5F5),
                              Color(0xFF81D4FA),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  lineName,
                                  style: _textStyle(
                                      16, FontWeight.w600, Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(
                                    begin: 0, end: calculatedValue),
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeOut,
                                builder: (context, value, child) {
                                  return Text(
                                    'Bal : ₹${NumberFormat.currency(
                                      decimalDigits: 2,
                                      symbol: '',
                                      locale: 'en_IN',
                                    ).format(value)}',
                                    style: _textStyle(
                                      15,
                                      FontWeight.bold,
                                      const Color.fromARGB(255, 255, 255, 160),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 10),
                              _buildPopupMenuButton(
                                  context, lineName, lineDetails),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
              separatorBuilder: (context, index) => const Divider(),
            ),
          ),
        ],
      ),
      floatingActionButton: const FloatingActionButtonWithText(
        label: 'Add New Book',
        navigateTo: LineScreen(),
        icon: Icons.add,
      ),
    );
  }
}
