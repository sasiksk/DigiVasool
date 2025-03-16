import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:DigiVasool/CollectionScreen.dart';
import 'package:DigiVasool/Data/Databasehelper.dart';
import 'package:DigiVasool/LendingScreen.dart';

import 'package:DigiVasool/Utilities/EmptyCard1.dart';

import 'package:DigiVasool/Utilities/FloatingActionButtonWithText.dart';
import 'package:DigiVasool/Utilities/Reports/CustomerReportScreen.dart';

import 'package:DigiVasool/Utilities/TransactionCard.dart';

import 'package:DigiVasool/lendingScreen2.dart';
import 'package:DigiVasool/linedetailScreen.dart';

import 'finance_provider.dart';
import 'package:intl/intl.dart';

class PartyDetailScreen extends ConsumerStatefulWidget {
  const PartyDetailScreen({super.key});

  @override
  _PartyDetailScreenState createState() => _PartyDetailScreenState();

  static Future<void> deleteEntry(BuildContext context, int cid,
      String linename, double drAmt, int lenId, String partyName) async {
    await CollectionDB.deleteEntry(cid);
    final lendingData = await dbLending.fetchLendingData(lenId);
    final amtrecievedLine = await dbline.fetchAmtRecieved(linename);
    final newamtrecived = amtrecievedLine + -drAmt;
    await dbline.updateLine(
      lineName: linename,
      updatedValues: {'Amtrecieved': newamtrecived},
    );

    final double currentAmtCollected = lendingData['amtcollected'];
    final double newAmtCollected = currentAmtCollected - drAmt;
    const String status = 'active';

    final updatedValues = {'amtcollected': newAmtCollected, 'status': status};
    await dbLending.updateAmtCollectedAndGiven(
      lineName: linename,
      partyName: partyName,
      lenId: lenId,
      updatedValues: updatedValues,
    );

    // Navigator.of(context).pop(); // Close the confirmation dialog
    // Close the options dialog
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const PartyDetailScreen(),
      ),
    );
  }
}

class _PartyDetailScreenState extends ConsumerState<PartyDetailScreen> {
  static Future<void> deleteEntry(BuildContext context, int cid,
      String linename, double drAmt, int lenId, String partyName) async {
    await CollectionDB.deleteEntry(cid);
    final lendingData = await dbLending.fetchLendingData(lenId);
    final amtrecievedLine = await dbline.fetchAmtRecieved(linename);
    final newamtrecived = amtrecievedLine + -drAmt;
    await dbline.updateLine(
      lineName: linename,
      updatedValues: {'Amtrecieved': newamtrecived},
    );

    final double currentAmtCollected = lendingData['amtcollected'];
    final double newAmtCollected = currentAmtCollected - drAmt;
    const String status = 'active';

    final updatedValues = {'amtcollected': newAmtCollected, 'status': status};
    await dbLending.updateAmtCollectedAndGiven(
      lineName: linename,
      partyName: partyName,
      lenId: lenId,
      updatedValues: updatedValues,
    );

    // Navigator.of(context).pop(); // Close the confirmation dialog
    // Close the options dialog
    /*Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const PartyDetailScreen(),
      ),
    );*/
  }

  @override
  Widget build(BuildContext context) {
    final linename = ref.watch(currentLineNameProvider);
    final partyName = ref.watch(currentPartyNameProvider);
    final lenId = ref.watch(lenIdProvider);
    final status = ref.watch(lenStatusProvider);
    final finname = ref.watch(financeNameProvider);
    double amt;

    return Scaffold(
      appBar: AppBar(
        title: Text(partyName ?? 'Party Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const LineDetailScreen(),
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Center(
            child: EmptyCard1(
              screenHeight: MediaQuery.of(context).size.height * 1.50,
              screenWidth: MediaQuery.of(context).size.width,
              title: 'Party Details',
              content: Consumer(
                builder: (context, ref, child) {
                  final lenId = ref.watch(lenIdProvider);
                  return FutureBuilder<Map<String, dynamic>>(
                    future: dbLending.getPartySums(lenId!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData) {
                        return const Center(child: Text('No data found.'));
                      } else {
                        final data = snapshot.data!;
                        final daysover = data['lentdate'] != null &&
                                data['lentdate'].isNotEmpty
                            ? DateTime.now()
                                .difference(DateFormat('dd-MM-yyyy')
                                    .parse(data['lentdate']))
                                .inDays
                            : null;
                        final daysrem =
                            data['duedays'] != null && daysover != null
                                ? data['duedays'] - daysover
                                : 0.0;

                        final duedate = data['lentdate'] != null &&
                                data['lentdate'].isNotEmpty
                            ? DateFormat('dd-MM-yyyy')
                                .parse(data['lentdate'])
                                .add(Duration(days: data['duedays']))
                                .toString()
                            : null;

                        final perrday = (data['totalAmtGiven'] != null &&
                                data['totalProfit'] != null &&
                                data['duedays'] != null &&
                                data['duedays'] != 0)
                            ? (data['totalAmtGiven'] + data['totalProfit']) /
                                data['duedays']
                            : 0.0;

                        final totalAmtCollected =
                            data['totalAmtCollected'] ?? 0.0;
                        final givendays =
                            perrday != 0 ? totalAmtCollected / perrday : 0.0;
                        double pendays;
                        if (daysrem > 0) {
                          pendays = ((daysover ?? 0) - givendays).toDouble();
                        } else {
                          pendays =
                              ((data['duedays'] ?? 0) - givendays).toDouble();
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Total Given:',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900),
                                    ),
                                    Text(
                                      '₹${(data['totalAmtGiven'] ?? 0.0) + (data['totalProfit'] ?? 0.0)}',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900),
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
                                          fontWeight: FontWeight.w900),
                                    ),
                                    Text(
                                      '₹${data['totalAmtCollected']?.toStringAsFixed(2) ?? '0.00'}',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Pending:',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900),
                                    ),
                                    Text(
                                      '₹${(data['totalAmtGiven'] ?? 0.0) + (data['totalProfit'] ?? 0.0) - (data['totalAmtCollected'] ?? 0.0)}',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Days Over:',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900),
                                    ),
                                    Text(
                                      '${daysover ?? 0}',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Days',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900),
                                    ),
                                    Text(
                                      daysrem != null && daysrem < 0
                                          ? 'Overdue: ${daysrem.abs()}'
                                          : 'Remaining: $daysrem',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: daysrem != null && daysrem < 0
                                            ? Colors.red
                                            : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Days Paid:',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900),
                                    ),
                                    Text(
                                      '${'${givendays.toStringAsFixed(2)}' ?? 0}',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pendays < 0
                                          ? 'Advance Days Paid: ${pendays.abs().toStringAsFixed(2)}'
                                          : 'Pending Days: ${pendays.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: pendays < 0
                                            ? const Color.fromARGB(
                                                255, 94, 80, 3)
                                            : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Lent Date:',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900),
                                    ),
                                    Text(
                                      data['lentdate']?.toString() ?? 'N/A',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Due Date:',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900),
                                    ),
                                    Text(
                                      duedate != null
                                          ? DateFormat('dd-MM-yyyy')
                                              .format(DateTime.parse(duedate))
                                          : 'N/A',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ),
          // i need a card with single row .which contains 3 icon buttons
          // 1. party report 2. sms reminder  3. watsup reminder
          Padding(
              padding: const EdgeInsets.fromLTRB(15, 2, 25, 15),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Party Report
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.picture_as_pdf,
                              color: Colors.blue),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ViewReportsPage(),
                              ),
                            );
                          },
                        ),
                        const Text('Report', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    // SMS Reminder
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.sms, color: Colors.blue),
                          onPressed: () {
                            // Add your logic here
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Coming Soon...'),
                              ),
                            );
                          },
                        ),
                        const Text('SMS', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    // WhatsApp Reminder
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.telegram, color: Colors.blue),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Coming Soon...'),
                              ),
                            );
                          },
                        ),
                        const Text('WhatsApp', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              )),

          const Padding(
            padding: EdgeInsets.only(right: 25),
            child: Row(
              children: [
                // Centered "Cr"
                Expanded(
                  child: Center(
                    child: Text(
                      '                                      You Gave',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                Text(
                  'You Got',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: CollectionDB.getCollectionEntries(lenId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No entries found.'));
                } else {
                  // Create a modifiable copy of the entries list
                  final List<Map<String, dynamic>> entries =
                      List.from(snapshot.data!);

                  // Sort by date (latest first)
                  entries.sort((a, b) => DateFormat('dd-MM-yyyy')
                      .parse(b['Date'])
                      .compareTo(DateFormat('dd-MM-yyyy').parse(a['Date'])));

                  return ListView.separated(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final date = entry['Date'];
                      final crAmt = entry['CrAmt'] ?? 0.0;
                      final drAmt = entry['DrAmt'] ?? 0.0;
                      final cid = entry['cid'];

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: GestureDetector(
                          onTap: () async {
                            if (drAmt > 0) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => CollectionScreen(
                                    preloadedDate: date,
                                    preloadedAmtCollected: drAmt,
                                    preloadedCid: cid,
                                  ),
                                ),
                              );
                            }
                            if (crAmt > 0) {
                              final partyDetails =
                                  await dbLending.getPartyDetails(lenId);
                              amt = 0;
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      LendingCombinedDetailsScreen(
                                    preloadedamtgiven:
                                        partyDetails?['amtgiven'] ?? 0.0,
                                    preladedprofit:
                                        partyDetails?['profit'] ?? 0.0,
                                    preladedlendate:
                                        partyDetails?['Lentdate'] ?? '',
                                    preladedduedays:
                                        partyDetails?['duedays'] ?? 0,
                                    cid: cid,
                                  ),
                                ),
                              );
                            }
                          },
                          child: TransactionCard(
                            dateTime: date,
                            balance: crAmt,
                            cramount: crAmt,
                            dramount: drAmt,
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (context, index) => const Divider(),
                  );
                }
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FloatingActionButtonWithText(
                label: 'You Gave',
                navigateTo: LendingCombinedDetailsScreen2(),
                icon: Icons.add,
              ),
              FloatingActionButtonWithText(
                label: 'You Got',
                navigateTo: CollectionScreen(),
                icon: Icons.add,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
