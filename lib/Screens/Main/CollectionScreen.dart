import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vasool_diary/Data/Databasehelper.dart';
import 'package:vasool_diary/Screens/Main/PartyDetailScreen.dart';
import 'package:vasool_diary/Sms.dart';
import 'package:vasool_diary/Utilities/CustomDatePicker.dart';
import 'package:vasool_diary/finance_provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ...existing code...

class CollectionScreen extends ConsumerWidget {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _amtCollectedController = TextEditingController();
  final int? preloadedCid;
  final double? preloadedAmtCollected;

  CollectionScreen(
      {super.key,
      String? preloadedDate,
      this.preloadedAmtCollected,
      this.preloadedCid}) {
    if (preloadedDate != null) {
      _dateController.text = DateFormat('dd-MM-yyyy')
          .format(DateFormat('yyyy-MM-dd').parse(preloadedDate));
    } else {
      _dateController.text = DateFormat('dd-MM-yyyy').format(DateTime.now());
    }
    if (preloadedAmtCollected != null) {
      _amtCollectedController.text = preloadedAmtCollected.toString();
    }
  }

  static Future<void> updateLendingData(int lenId, double collectedAmt) async {
    final lendingData = await dbLending.fetchLendingData(lenId);

    final double amtCollected = (lendingData['amtcollected']);
    final double amtgiven = (lendingData['amtgiven']) + (lendingData['profit']);

    final updatedValues = {
      'amtcollected': amtCollected + collectedAmt,
      'status':
          (amtgiven - collectedAmt - amtCollected) == 0 ? 'passive' : 'active',
    };

    await dbLending.updateDueAmt(
      lenId: lenId,
      updatedValues: updatedValues,
    );
  }

  static Future<void> updateAmtRecieved(
      String lineName, double collectedAmt) async {
    final amtRecieved = await dbline.fetchAmtRecieved(lineName);
    final updatedAmtRecieved = amtRecieved + collectedAmt;

    await dbline.updateLine(
      lineName: lineName,
      updatedValues: {'Amtrecieved': updatedAmtRecieved},
    );
  }

  static Future<int> getNextCid() async {
    final db = await DatabaseHelper.getDatabase();
    final List<Map<String, dynamic>> result =
        await db.rawQuery('SELECT MAX(cid) as maxCid FROM Collection');
    final maxCid = result.first['maxCid'] as int?;
    return (maxCid ?? 0) + 1;
  }

  static Future<void> insertCollection(int lenId, double collectedAmt,
      [String? date]) async {
    final int cid = await getNextCid();
    final db = await DatabaseHelper.getDatabase();
    print(date);
    await db.insert('Collection', {
      'cid': cid,
      'LenId': lenId,
      'Date': date ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'CrAmt': 0.0,
      'DrAmt': collectedAmt,
    });
  }

  static Future<void> processCollection({
    required BuildContext context,
    required int lenid,
    required String lineName,
    required String date,
    required double collectedAmt,
    double? preloadedAmtCollected,
    int? preloadedCid,
  }) async {
    // Fetch the current amtCollected and dueAmt from Lending table
    final lendingData = await dbLending.fetchLendingData(lenid);

    final double currentAmtCollected = lendingData['amtcollected'];
    final double currentgivenamt =
        lendingData['amtgiven'] + lendingData['profit'];
    final int sms = lendingData['sms'];
    final String pno = lendingData['PartyPhnone'] ?? 'Unknown';

    // Calculate the new amtCollected
    final double newAmtCollected = preloadedCid != null
        ? currentAmtCollected + collectedAmt - preloadedAmtCollected!
        : currentAmtCollected + collectedAmt;

    if (currentgivenamt >= newAmtCollected) {
      final String status =
          currentgivenamt - newAmtCollected == 0 ? 'passive' : 'active';

      // Update Line Table
      final amtRecieved_Line = await dbline.fetchAmtRecieved(lineName);
      final double newAmtRecieved = preloadedCid != null
          ? amtRecieved_Line + collectedAmt - preloadedAmtCollected!
          : amtRecieved_Line + collectedAmt;

      await dbline.updateLine(
        lineName: lineName,
        updatedValues: {'Amtrecieved': newAmtRecieved},
      );

      // Update Lending Table
      await dbLending.updateLendingAmounts(
        lenId: lenid,
        newAmtCollected: newAmtCollected,
        status: status,
      );

      // Update or Insert Collection Table
      if (preloadedCid != null) {
        await CollectionDB.updateCollection(
          cid: preloadedCid,
          lenId: lenid,
          date: DateFormat('yyyy-MM-dd')
              .format(DateFormat('dd-MM-yyyy').parse(date)),
          crAmt: 0.0,
          drAmt: collectedAmt,
        );
      } else {
        final cid = await getNextCid();
        await CollectionDB.insertCollection(
          cid: cid,
          lenId: lenid,
          date: DateFormat('yyyy-MM-dd')
              .format(DateFormat('dd-MM-yyyy').parse(date)),
          crAmt: 0.0,
          drAmt: collectedAmt,
        );
      }

      // Send SMS if enabled
      if (sms == 1 && pno != 'Unknown') {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final financeName = prefs.getString('financeName') ?? '';
        await sendSms(
          pno,
          'Date: $date, Paid: $collectedAmt, Bal: ${currentgivenamt - newAmtCollected}. Thank You, $financeName',
        );
      }
    } else {
      // Show error dialog if amount exceeds
      Future.delayed(Duration.zero, () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Error"),
              content: const Text('Amount exceeds original. Can\'t Update.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PartyDetailScreen()),
                    );
                  },
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      });
    }
  }

  @override
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partyName = ref.watch(currentPartyNameProvider);
    final lenid = ref.watch(lenIdProvider);
    final lineName = ref.watch(currentLineNameProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(partyName ?? "Add Collection"),
        centerTitle: true,
        elevation: 2,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Summary Section
              const Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        "Collection Entry",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Form Section
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomDatePicker(
                          controller: _dateController,
                          labelText: "Date of Payment",
                          hintText: "Pick the date of payment",
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _amtCollectedController,
                          decoration: const InputDecoration(
                            labelText: "Amount Collected",
                            hintText: "Enter the amount collected",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the amount collected';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 150),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () async {
                                  if (_formKey.currentState?.validate() ==
                                      true) {
                                    if (lenid != null && lineName != null) {
                                      await processCollection(
                                        context: context,
                                        lenid: lenid,
                                        lineName: lineName,
                                        date: _dateController.text,
                                        collectedAmt: double.parse(
                                            _amtCollectedController.text),
                                        preloadedAmtCollected:
                                            preloadedAmtCollected,
                                        preloadedCid: preloadedCid,
                                      );
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text('Form Submitted')),
                                      );
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const PartyDetailScreen()),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Error: LenId or LineName is null')),
                                      );
                                    }
                                  }
                                },
                                child: Text(
                                  preloadedCid != null ? "Update" : "Submit",
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () async {
                                  if (preloadedCid != null) {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title:
                                              const Text("Delete Confirmation"),
                                          content: const Text(
                                              "Are you sure you want to delete this entry?"),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text("Cancel"),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                Navigator.of(context).pop();
                                                await PartyDetailScreen
                                                    .deleteEntry(
                                                  context,
                                                  preloadedCid!,
                                                  lineName!,
                                                  preloadedAmtCollected!,
                                                  lenid!,
                                                  partyName!,
                                                );
                                              },
                                              child: const Text("Delete",
                                                  style: TextStyle(
                                                      color: Colors.red)),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  } else {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const PartyDetailScreen()),
                                    );
                                  }
                                },
                                child: Text(
                                  preloadedCid != null ? "Delete" : "Cancel",
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
