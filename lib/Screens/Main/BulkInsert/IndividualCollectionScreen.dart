import 'package:flutter/material.dart';
import 'package:vasool_diary/Data/Databasehelper.dart';
import 'package:vasool_diary/Screens/Main/CollectionScreen.dart';
import 'package:intl/intl.dart';
import 'package:vasool_diary/Sms.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IndividualCollectionScreen extends StatefulWidget {
  const IndividualCollectionScreen({super.key});

  @override
  _IndividualCollectionScreenState createState() =>
      _IndividualCollectionScreenState();
}

class _IndividualCollectionScreenState
    extends State<IndividualCollectionScreen> {
  List<String> _lineNames = [];
  String? _selectedLineName;
  List<Map<String, dynamic>> lendingDetails = [];
  DateTime selectedDate = DateTime.now();
  final TextEditingController _dateController = TextEditingController(
    text: DateFormat('dd-MM-yyyy').format(DateTime.now()),
  );

  Map<int, TextEditingController> amountControllers = {};
  Map<int, bool> collectedStatus = {};
  Map<int, Map<String, dynamic>> collectionRecords = {};
  double totalCollected = 0.0;

  @override
  void initState() {
    super.initState();
    _loadLineNames();
  }

  @override
  void dispose() {
    for (var controller in amountControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadLineNames() async {
    final lineNames = await dbline.getLineNames();
    setState(() {
      _lineNames = lineNames;
    });
  }

  Future<void> _loadPartyNames(String lineName) async {
    final details = await dbLending.getLendingDetailsByLineName(lineName);
    if (details != null) {
      setState(() {
        lendingDetails =
            details.where((detail) => detail['status'] == 'active').toList();
        collectedStatus.clear();
        collectionRecords.clear();
        totalCollected = 0.0;

        for (var controller in amountControllers.values) {
          controller.dispose();
        }
        amountControllers.clear();

        for (var detail in lendingDetails) {
          final lenId = detail['LenId'];
          final perDayAmt =
              (detail['amtgiven'] + detail['profit']) / detail['duedays'];
          amountControllers[lenId] =
              TextEditingController(text: perDayAmt.toStringAsFixed(2));
          collectedStatus[lenId] = false;
        }
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        _dateController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  void _updateTotal() {
    double total = 0.0;
    for (int lenId in collectedStatus.keys) {
      if (collectedStatus[lenId] == true) {
        final record = collectionRecords[lenId];
        if (record != null) {
          total += record['collectedAmount'];
        }
      }
    }
    setState(() {
      totalCollected = total;
    });
  }

  Future<void> _processIndividualCollection(
      Map<String, dynamic> partyDetail) async {
    final lenId = partyDetail['LenId'];
    final controller = amountControllers[lenId];

    if (controller == null || controller.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter collection amount'),
            backgroundColor: Colors.red),
      );
      return;
    }

    final collectedAmt = double.tryParse(controller.text);
    if (collectedAmt == null || collectedAmt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter valid amount'),
            backgroundColor: Colors.red),
      );
      return;
    }

    final originalAmtCollected = partyDetail['amtcollected'];
    final originalAmtReceived =
        await dbline.fetchAmtRecieved(_selectedLineName!);

    await CollectionScreen.processCollection(
      context: context,
      lenid: lenId,
      lineName: _selectedLineName!,
      date: _dateController.text,
      collectedAmt: collectedAmt,
    );

    collectionRecords[lenId] = {
      'collectedAmount': collectedAmt,
      'originalAmtCollected': originalAmtCollected,
      'originalAmtReceived': originalAmtReceived,
      'date': _dateController.text,
    };

    setState(() {
      collectedStatus[lenId] = true;
      final index =
          lendingDetails.indexWhere((element) => element['LenId'] == lenId);
      if (index != -1) {
        lendingDetails[index] = Map<String, dynamic>.from(lendingDetails[index])
          ..['amtcollected'] = originalAmtCollected + collectedAmt;
      }
      controller.text = collectedAmt.toStringAsFixed(2);
    });
    _updateTotal();
  }

  Future<void> _undoCollection(Map<String, dynamic> partyDetail) async {
    final lenId = partyDetail['LenId'];
    final collectionRecord = collectionRecords[lenId];
    if (collectionRecord == null) return;

    try {
      await dbLending.updateLendingAmounts(
        lenId: lenId,
        newAmtCollected: collectionRecord['originalAmtCollected'],
        status: 'active',
      );

      await dbline.updateLine(
        lineName: _selectedLineName!,
        updatedValues: {'Amtrecieved': collectionRecord['originalAmtReceived']},
      );

      final db = await DatabaseHelper.getDatabase();
      await db.delete(
        'Collection',
        where: 'LenId = ? AND Date = ? AND DrAmt = ?',
        whereArgs: [
          lenId,
          DateFormat('yyyy-MM-dd')
              .format(DateFormat('dd-MM-yyyy').parse(collectionRecord['date'])),
          collectionRecord['collectedAmount']
        ],
      );

      // Send SMS
      final int sms = partyDetail['sms'] ?? 0;
      final String pno = partyDetail['PartyPhnone'] ?? 'Unknown';
      if (sms == 1 && pno != 'Unknown' && pno.isNotEmpty) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final financeName = prefs.getString('financeName') ?? '';
          final totalAmt = partyDetail['amtgiven'] + partyDetail['profit'];
          final newBalance =
              totalAmt - collectionRecord['originalAmtCollected'];
          final undoMessage =
              'Last entry ₹${collectionRecord['collectedAmount'].toStringAsFixed(2)} deleted. Balance: ₹${newBalance.toStringAsFixed(2)}. Thank You, $financeName';
          await sendSms(pno, undoMessage);
        } catch (e) {
          print('SMS failed: $e');
        }
      }

      final perDayAmt = (partyDetail['amtgiven'] + partyDetail['profit']) /
          partyDetail['duedays'];
      setState(() {
        collectedStatus[lenId] = false;
        final index =
            lendingDetails.indexWhere((element) => element['LenId'] == lenId);
        if (index != -1) {
          lendingDetails[index] =
              Map<String, dynamic>.from(lendingDetails[index])
                ..['amtcollected'] = collectionRecord['originalAmtCollected'];
        }
        amountControllers[lenId]?.text = perDayAmt.toStringAsFixed(2);
      });

      collectionRecords.remove(lenId);
      _updateTotal();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to undo collection'),
            backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildCompactPartyCard(Map<String, dynamic> partyDetail) {
    final balanceAmt = (partyDetail['amtgiven'] + partyDetail['profit']) -
        partyDetail['amtcollected'];
    final perDayAmt = (partyDetail['amtgiven'] + partyDetail['profit']) /
        partyDetail['duedays'];
    final lenId = partyDetail['LenId'];
    final isCollected = collectedStatus[lenId] ?? false;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(4),
      child: Padding(
        padding: const EdgeInsets.all(6), // Reduced from 8 to 6
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Party Name Row
            Row(
              children: [
                Expanded(
                  child: Text(
                    partyDetail['PartyName'] ?? 'Unknown',
                    style: const TextStyle(
                        fontSize: 13, // Reduced from 14 to 13
                        fontWeight: FontWeight.bold,
                        color: Colors.blue),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isCollected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 1), // Reduced padding
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('✓',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 9)), // Reduced font size
                  ),
              ],
            ),
            const SizedBox(height: 2), // Reduced from 4 to 2

            // Balance Amount
            Text(
              'Balance: ₹${balanceAmt.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 11,
                  color: Colors.red,
                  fontWeight: FontWeight.w500), // Reduced from 12 to 11
            ),
            const SizedBox(height: 4), // Reduced from 6 to 4

            // Amount Input
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: amountControllers[lenId] ??
                        TextEditingController(
                            text: perDayAmt.toStringAsFixed(2)),
                    keyboardType: TextInputType.number,
                    enabled: !isCollected,
                    style: TextStyle(
                        fontSize: 11, // Reduced from 12 to 11
                        color: isCollected ? Colors.grey : Colors.green),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2), // Reduced padding
                      border: OutlineInputBorder(),
                      prefixText: '₹',
                    ),
                  ),
                ),
                const SizedBox(width: 3), // Reduced from 4 to 3

                // Action Button
                SizedBox(
                  width: 55, // Reduced from 60 to 55
                  height: 28, // Reduced from 32 to 28
                  child: ElevatedButton(
                    onPressed: isCollected
                        ? () => _undoCollection(partyDetail)
                        : () => _processIndividualCollection(partyDetail),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isCollected ? Colors.orange : Colors.green,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(4)), // Reduced from 6 to 4
                    ),
                    child: Icon(
                      isCollected ? Icons.undo : Icons.check,
                      color: Colors.white,
                      size: 14, // Reduced from 16 to 14
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Individual Collection'),
        backgroundColor: Colors.teal.shade900,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Header Controls
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // Line Dropdown
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Line Name',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        ),
                        value: _selectedLineName,
                        items: _lineNames
                            .map((lineName) => DropdownMenuItem(
                                value: lineName, child: Text(lineName)))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedLineName = value;
                          });
                          if (value != null) _loadPartyNames(value);
                        },
                      ),
                      const SizedBox(height: 8),

                      // Date and Total Row
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _dateController,
                              decoration: const InputDecoration(
                                labelText: 'Date',
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 10),
                                suffixIcon:
                                    Icon(Icons.calendar_today, size: 18),
                              ),
                              readOnly: true,
                              onTap: _selectDate,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.purple),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Total: ₹${totalCollected.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Party Cards Grid
              Expanded(
                child: lendingDetails.isEmpty
                    ? const Center(
                        child: Text(
                          'No active parties found.\nSelect a line to view parties.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      )
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.9, // Increased from 1.8 to 1.9
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                        itemCount: lendingDetails.length,
                        itemBuilder: (context, index) =>
                            _buildCompactPartyCard(lendingDetails[index]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
