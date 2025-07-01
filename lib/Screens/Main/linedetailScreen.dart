import 'package:vasool_diary/Utilities/amtbuild.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vasool_diary/Data/Databasehelper.dart';

import 'package:vasool_diary/Screens/Main/PartyDetailScreen.dart';
import 'package:vasool_diary/Utilities/AppBar.dart';
import 'package:vasool_diary/Utilities/EmptyCard1.dart';

import 'package:vasool_diary/Utilities/FloatingActionButtonWithText.dart';

import 'package:vasool_diary/Screens/Main/PartyScreen.dart';
import 'package:vasool_diary/Utilities/drawer.dart';
import '../../finance_provider.dart';

class LineDetailScreen extends ConsumerStatefulWidget {
  const LineDetailScreen({super.key});

  @override
  _LineDetailScreenState createState() => _LineDetailScreenState();
}

class _LineDetailScreenState extends ConsumerState<LineDetailScreen> {
  List<String> partyNames = [];
  ValueNotifier<List<String>> filteredPartyNamesNotifier = ValueNotifier([]);
  Map<String, Map<String, double>> partyDetailsMap = {};

  @override
  void initState() {
    super.initState();
    loadPartyNames();
  }

  void loadPartyNames() async {
    final lineName = ref.read(currentLineNameProvider);
    if (lineName != null) {
      final names = await dbLending.getPartyNames(lineName);
      final details = await Future.wait(
          names.map((name) => dbLending.getPartyDetailss(lineName, name)));

      setState(() {
        partyNames = names;
        filteredPartyNamesNotifier.value = names;
        for (int i = 0; i < names.length; i++) {
          partyDetailsMap[names[i]] = details[i];
        }
      });
    }
  }

  void handleLineSelected(String partyName) async {
    final lineName = ref.read(currentLineNameProvider);
    ref.read(currentPartyNameProvider.notifier).state = partyName;

    final lenId = await DatabaseHelper.getLenId(lineName!, partyName);
    ref.read(lenIdProvider.notifier).state = lenId;

    final String? stat = await DatabaseHelper.getStatus(lenId!);
    if (stat != null) {
      ref.read(lenStatusProvider.notifier).updateLenStatus(stat);
    }

    ref.read(lenIdProvider.notifier).state = lenId;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => PartyDetailScreen()),
    ).then((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final lineName = ref.watch(currentLineNameProvider);

    if (lineName == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      drawer: buildDrawer(context),
      appBar: CustomAppBar(
        title: lineName!,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadPartyNames,
          ),
        ],
      ),
      body: Column(
        children: [
          FutureBuilder<Map<String, double>>(
            future: dbLending.getLineSums(lineName),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData) {
                return const Center(child: Text('No data found.'));
              } else {
                final data = snapshot.data!;

                return EmptyCard1(
                  screenHeight: MediaQuery.of(context).size.height * 1.35,
                  screenWidth: MediaQuery.of(context).size.width * 1.10,
                  title: 'Book Details',
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          buildAmountBlock(
                            'Total Given:',
                            data['totalAmtGiven']! + data['totalProfit']!,
                          ),
                          buildAmountBlock(
                            'Collected:',
                            data['totalAmtCollected'] ?? 0.0,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: buildAmountBlock(
                          'You Will Get:',
                          data['totalAmtGiven']! +
                              data['totalProfit']! -
                              data['totalAmtCollected']! -
                              data['totalexpense']!,
                          centerAlign: true,
                          textSize: 18,
                          labelColor: Colors.indigo,
                          valueColor: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),

                  /* EmptyCard(
                    screenHeight: MediaQuery.of(context).size.height,
                    screenWidth: MediaQuery.of(context).size.width,
                    items: [
                      /*Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                        'Given:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white),
                        ),
                        Text(
                        '₹${data['totalAmtGiven']?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white),
                        ),
                      ],
                      ),
                      Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                        'Profit:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white),
                        ),
                        Text(
                        '₹${data['totalProfit']?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white),
                        ),
                      ],
                      ),*/
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Given:',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white),
                          ),
                          Text(
                            '₹${(data['totalAmtGiven']! + data['totalProfit']!).toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Collected:',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white),
                          ),
                          Text(
                            '₹${data['totalAmtCollected']?.toStringAsFixed(2) ?? '0.00'}',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white),
                          ),
                        ],
                      ),
                      /*Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                        'Expense:',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white),
                        ),
                        Text(
                        '₹${data['totalexpense']?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white),
                        ),
                      ],
                      ),*/
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Amount:',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white),
                          ),
                          Text(
                            '₹${(data['totalAmtGiven']! + data['totalProfit']! - data['totalAmtCollected']! - data['totalexpense']!).toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),*/
                );
              }
            },
          ),
          const SizedBox(
            height: 5,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              height: 50,
              child: TextField(
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: GoogleFonts.tinos().fontFamily,
                ),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search Party',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) {
                  filteredPartyNamesNotifier.value = partyNames
                      .where((partyName) =>
                          partyName.toLowerCase().contains(value.toLowerCase()))
                      .toList();
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
                    'Party Name',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: GoogleFonts.tinos().fontFamily,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Amount                              ',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: GoogleFonts.tinos().fontFamily,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<List<String>>(
              valueListenable: filteredPartyNamesNotifier,
              builder: (context, filteredPartyNames, _) {
                if (filteredPartyNames.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 50, color: Colors.grey),
                        SizedBox(height: 10),
                        Text(
                          'No Parties Found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return AnimationLimiter(
                  child: ListView.separated(
                    itemCount: filteredPartyNames.length,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final partyName = filteredPartyNames[index];
                      final details = partyDetailsMap[partyName] ?? {};
                      final amtGiven = details['amtgiven'] ?? 0.0;
                      final profit = details['profit'] ?? 0.0;
                      final amtCollected = details['amtcollected'] ?? 0.0;
                      final calculatedValue = amtGiven + profit - amtCollected;

                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 400),
                        child: SlideAnimation(
                          verticalOffset: 40.0,
                          child: FadeInAnimation(
                            child: GestureDetector(
                              onTap: () => handleLineSelected(partyName),
                              child: Card(
                                elevation: 6,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 4),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF26A69A), // Light Teal
                                        Color(0xFF004D40), // Dark Teal
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withAlpha((0.1 * 255).toInt()),
                                        blurRadius: 6,
                                        offset: const Offset(2, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      // Avatar
                                      CircleAvatar(
                                        backgroundColor: Colors.white
                                            .withAlpha((0.2 * 255).toInt()),
                                        radius: 22,
                                        child: const Icon(Icons.account_circle,
                                            color: Colors.white),
                                      ),
                                      const SizedBox(width: 12),

                                      // Party Name
                                      Expanded(
                                        child: Text(
                                          partyName,
                                          style: GoogleFonts.tinos(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),

                                      // Balance Display
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withAlpha((0.15 * 255).toInt()),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '₹${calculatedValue.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (match) => '${match[1]},')}',
                                          style: GoogleFonts.tinos(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),

                                      // Menu
                                      PopupMenuButton<String>(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        color: Colors.white,
                                        icon: const Icon(Icons.more_vert,
                                            color: Colors.white),
                                        onSelected: (String value) async {
                                          if (value == 'Update') {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    PartyScreen(
                                                        partyName: partyName),
                                              ),
                                            );
                                          } else if (value == 'Delete') {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  title: const Text(
                                                      'Confirm Deletion'),
                                                  content: const Text(
                                                    'Are you sure you want to delete this party and related collections?',
                                                    style:
                                                        TextStyle(fontSize: 14),
                                                  ),
                                                  actions: <Widget>[
                                                    TextButton(
                                                      child: const Text(
                                                          'Cancel',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.grey)),
                                                      onPressed: () {
                                                        if (mounted) {
                                                          Navigator.of(context)
                                                              .pop();
                                                        }
                                                      },
                                                    ),
                                                    TextButton(
                                                      child: const Text('OK',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.red)),
                                                      onPressed: () async {
                                                        final parentContext =
                                                            context;
                                                        Navigator.of(
                                                                parentContext)
                                                            .pop();
                                                        final lenId =
                                                            await DatabaseHelper
                                                                .getLenId(
                                                                    lineName!,
                                                                    partyName);
                                                        if (lenId != null) {
                                                          await dbLending
                                                              .deleteLendingAndCollections(
                                                                  lenId,
                                                                  lineName);
                                                          if (mounted) {
                                                            setState(() {
                                                              loadPartyNames();
                                                            });
                                                          }
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          }
                                        },
                                        itemBuilder: (BuildContext context) {
                                          return [
                                            const PopupMenuItem<String>(
                                              value: 'Update',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit,
                                                      color: Colors.blue),
                                                  SizedBox(width: 8),
                                                  Text('Update'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem<String>(
                                              value: 'Delete',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete,
                                                      color: Colors.red),
                                                  SizedBox(width: 8),
                                                  Text('Delete'),
                                                ],
                                              ),
                                            ),
                                          ];
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: const FloatingActionButtonWithText(
        label: 'Add New Party',
        navigateTo: PartyScreen(),
        icon: Icons.add,
      ),
    );
  }
}
