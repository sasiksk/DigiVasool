import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  List<Map<String, dynamic>> filteredLendingDetails = [];
  DateTime selectedDate = DateTime.now();
  final TextEditingController _dateController = TextEditingController(
    text: DateFormat('dd-MM-yyyy').format(DateTime.now()),
  );
  final TextEditingController _searchController = TextEditingController();

  Map<int, TextEditingController> amountControllers = {};
  Map<int, bool> selectedParties = {}; // Changed from collectedStatus
  Map<int, Map<String, dynamic>> collectionRecords = {};
  List<Map<String, String>> pendingSmsMessages = [];
  bool isProcessing = false;

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
    _searchController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> showSmsNotSentDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Note'),
          content: const Text(
              'Select parties and amounts, then use Bulk Update for efficient processing.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadLineNames() async {
    final lineNames = await dbline.getLineNames();
    setState(() {
      _lineNames = lineNames;
      showSmsNotSentDialog();
    });
  }

  Future<void> _loadPartyNames(String lineName) async {
    final details = await dbLending.getLendingDetailsByLineName(lineName);
    if (details != null) {
      setState(() {
        // Create mutable copies of the party data
        lendingDetails = details
            .where((detail) => detail['status'] == 'active')
            .map((detail) => Map<String, dynamic>.from(detail))
            .toList();
        filteredLendingDetails = lendingDetails
            .map((detail) => Map<String, dynamic>.from(detail))
            .toList();
        _resetCollectionData();
        _initializeControllers();
      });
    }
  }

  void _resetCollectionData() {
    selectedParties.clear();
    collectionRecords.clear();
    for (var controller in amountControllers.values) {
      controller.dispose();
    }
    amountControllers.clear();
  }

  void _initializeControllers() {
    for (var detail in lendingDetails) {
      final lenId = detail['LenId'];
      final perDayAmt =
          (detail['amtgiven'] + detail['profit']) / detail['duedays'];
      amountControllers[lenId] =
          TextEditingController(text: perDayAmt.toStringAsFixed(2));
      selectedParties[lenId] = false;
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

  void _filterParties(String query) {
    setState(() {
      filteredLendingDetails = query.isEmpty
          ? lendingDetails
          : lendingDetails
              .where((party) => party['PartyName']
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()))
              .toList();
    });
  }

  double _calculateTotalSelected() {
    double total = 0.0;
    for (var party in lendingDetails) {
      final lenId = party['LenId'];
      if (selectedParties[lenId] == true) {
        final controller = amountControllers[lenId];
        final amount = double.tryParse(controller?.text ?? '0') ?? 0.0;
        total += amount;
      }
    }
    return total;
  }

  void _togglePartySelection(int lenId) {
    setState(() {
      selectedParties[lenId] = !(selectedParties[lenId] ?? false);
    });
  }

  void _calculateAndShowBulkSummary() {
    List<Map<String, dynamic>> selectedEntries = [];
    double totalAmount = 0.0;

    for (var party in lendingDetails) {
      final lenId = party['LenId'];
      if (selectedParties[lenId] == true) {
        final controller = amountControllers[lenId];
        final amount = double.tryParse(controller?.text ?? '0') ?? 0.0;

        if (amount > 0) {
          selectedEntries.add({
            'party': party,
            'amount': amount,
            'lenId': lenId,
          });
          totalAmount += amount;
        }
      }
    }

    if (selectedEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No parties selected or amounts entered'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _showBulkUpdateDialog(selectedEntries, totalAmount);
  }

  void _showBulkUpdateDialog(
      List<Map<String, dynamic>> entries, double totalAmount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.upload, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              const Text('Bulk Update Confirmation'),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxHeight: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Line:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(_selectedLineName ?? '',
                              style: const TextStyle(color: Colors.blue)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Date:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(DateFormat('dd-MM-yyyy').format(selectedDate)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Parties:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('${entries.length}',
                              style: const TextStyle(color: Colors.green)),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('₹${totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Selected Parties:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Flexible(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        final party = entry['party'];
                        final amount = entry['amount'];

                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: index < entries.length - 1
                                  ? BorderSide(color: Colors.grey.shade200)
                                  : BorderSide.none,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  party['PartyName'] ?? 'Unknown',
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '₹${amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning,
                          color: Colors.orange.shade700, size: 16),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'This will update all selected collections. SMS will be queued.',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _processBulkUpdate(entries, totalAmount);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text(
                'Confirm Update',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processBulkUpdate(
      List<Map<String, dynamic>> entries, double totalAmount) async {
    setState(() {
      isProcessing = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Processing ${entries.length} collections...'),
              const SizedBox(height: 8),
              const Text('Please wait...',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        );
      },
    );

    try {
      final db = await DatabaseHelper.getDatabase();
      final dateString = DateFormat('yyyy-MM-dd').format(selectedDate);

      final currentLineAmount =
          await dbline.fetchAmtRecieved(_selectedLineName!);
      double totalLineIncrease = 0.0;

      List<Map<String, dynamic>> successfulUpdates = [];
      List<Map<String, dynamic>> failedUpdates = [];

      for (var entry in entries) {
        try {
          final party = entry['party'];
          final amount = entry['amount'];
          final lenId = entry['lenId'];

          final currentAmtCollected = party['amtcollected'] ?? 0.0;
          final newAmtCollected = currentAmtCollected + amount;

          // Update party amount in Lending table
          await dbLending.updateLendingAmounts(
            lenId: lenId,
            newAmtCollected: newAmtCollected,
            status: 'active',
          );

          // Insert collection record
          await db.insert('Collection', {
            'LenId': lenId,
            'Date': dateString,
            'DrAmt': amount,
            'CrAmt': 0.0,
          });

          totalLineIncrease += amount;
          successfulUpdates.add({
            'party': party,
            'amount': amount,
          });

          // Add SMS message (this will update the UI state)
          await _addBulkSms(party, amount, currentAmtCollected);

          // Fix: Create a new mutable copy of the party data
          final partyIndex =
              lendingDetails.indexWhere((p) => p['LenId'] == lenId);
          if (partyIndex != -1) {
            // Create a new mutable map instead of modifying the read-only one
            final updatedParty =
                Map<String, dynamic>.from(lendingDetails[partyIndex]);
            updatedParty['amtcollected'] = newAmtCollected;

            setState(() {
              lendingDetails[partyIndex] = updatedParty;
              selectedParties[lenId] = false;
              amountControllers[lenId]?.clear();
            });

            // Also update filtered list if it contains this party
            final filteredIndex =
                filteredLendingDetails.indexWhere((p) => p['LenId'] == lenId);
            if (filteredIndex != -1) {
              filteredLendingDetails[filteredIndex] = updatedParty;
            }
          }
        } catch (e) {
          failedUpdates.add({
            'party': entry['party'],
            'amount': entry['amount'],
            'error': e.toString(),
          });
        }
      }

      // Update line amount only once at the end
      if (totalLineIncrease > 0) {
        await dbline.updateLine(
          lineName: _selectedLineName!,
          updatedValues: {'Amtrecieved': currentLineAmount + totalLineIncrease},
        );
      }

      Navigator.of(context).pop();
      _showBulkUpdateResults(
          successfulUpdates, failedUpdates, totalLineIncrease);
    } catch (e) {
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bulk update failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  Future<void> _addBulkSms(Map<String, dynamic> partyDetail,
      double collectedAmt, double originalAmtCollected) async {
    final int sms = partyDetail['sms'] ?? 0;
    final String pno = partyDetail['PartyPhnone'] ?? 'Unknown';

    if (sms == 1 && pno != 'Unknown' && pno.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final financeName = prefs.getString('financeName') ?? '';
      final totalAmt = partyDetail['amtgiven'] + partyDetail['profit'];
      final newBalance = totalAmt - (originalAmtCollected + collectedAmt);

      // Fix: Use setState to properly update the SMS queue
      setState(() {
        pendingSmsMessages.add({
          'phone': pno,
          'message':
              'Received ₹${collectedAmt.toStringAsFixed(2)}. Balance: ₹${newBalance.toStringAsFixed(2)}. Thank You, $financeName',
          'partyName': partyDetail['PartyName'] ?? 'Unknown',
          'type': 'collection'
        });
      });
    }
  }

  void _showBulkUpdateResults(List<Map<String, dynamic>> successful,
      List<Map<String, dynamic>> failed, double totalAmount) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                successful.isNotEmpty ? Icons.check_circle : Icons.error,
                color: successful.isNotEmpty ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              const Text('Bulk Update Results'),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxHeight: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('✅ Successful:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('${successful.length}',
                              style: const TextStyle(color: Colors.green)),
                        ],
                      ),
                      if (failed.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('❌ Failed:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('${failed.length}',
                                style: const TextStyle(color: Colors.red)),
                          ],
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('📱 SMS Queued:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('${pendingSmsMessages.length}',
                              style: const TextStyle(color: Colors.blue)),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Collected:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('₹${totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Add SMS notification
                if (pendingSmsMessages.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.sms, color: Colors.blue.shade700, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${pendingSmsMessages.length} SMS messages are ready to send. Use the SMS panel below to send them.',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                if (successful.isNotEmpty) ...[
                  const Text('✅ Successful Updates:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 4),
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ListView.builder(
                      itemCount: successful.length,
                      itemBuilder: (context, index) {
                        final update = successful[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.check_circle,
                              color: Colors.green, size: 16),
                          title: Text(
                            update['party']['PartyName'] ?? 'Unknown',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Text(
                            '₹${update['amount'].toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.green),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                if (failed.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('❌ Failed Updates:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 4),
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ListView.builder(
                      itemCount: failed.length,
                      itemBuilder: (context, index) {
                        final update = failed[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.error,
                              color: Colors.red, size: 16),
                          title: Text(
                            update['party']['PartyName'] ?? 'Unknown',
                            style: const TextStyle(fontSize: 12),
                          ),
                          subtitle: Text(
                            update['error'],
                            style: const TextStyle(
                                fontSize: 10, color: Colors.red),
                          ),
                          trailing: Text(
                            '₹${update['amount'].toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.red),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (failed.isNotEmpty)
              TextButton(
                onPressed: () {
                  for (var failedUpdate in failed) {
                    final party = failedUpdate['party'];
                    final lenId = party['LenId'];
                    setState(() {
                      selectedParties[lenId] = true;
                      amountControllers[lenId]?.text =
                          failedUpdate['amount'].toStringAsFixed(2);
                    });
                  }
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Failed entries have been re-selected for retry'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                child: const Text('Retry Failed'),
              ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();

                // Show different message based on SMS status
                String message =
                    'Bulk update completed! ${successful.length} collections processed successfully.';
                if (pendingSmsMessages.isNotEmpty) {
                  message +=
                      ' ${pendingSmsMessages.length} SMS messages are ready to send.';
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 4),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Done', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendAllPendingSms() async {
    if (pendingSmsMessages.isEmpty) {
      _showSnackBar('No SMS to send', Colors.orange);
      return;
    }

    bool? confirmed = await _showConfirmationDialog('Send SMS',
        'Send ${pendingSmsMessages.length} SMS messages?\n\nNote: SMS will open one by one. Please send each SMS and return to the app.');

    if (confirmed == true) {
      await _sendSmsOneByOne();
    }
  }

  Future<bool?> _showConfirmationDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Send All'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendSmsOneByOne() async {
    List<Map<String, String>> sentMessages = [];
    List<Map<String, String>> failedMessages = [];

    for (int i = 0; i < pendingSmsMessages.length; i++) {
      var smsData = pendingSmsMessages[i];

      bool? sendThis =
          await _showSmsDialog(smsData, i + 1, pendingSmsMessages.length);

      if (sendThis == true) {
        try {
          await sendSms(smsData['phone']!, smsData['message']!);
          sentMessages.add(smsData);
          _showSnackBar('SMS sent to ${smsData['partyName']}', Colors.green);
        } catch (e) {
          failedMessages.add(smsData);
          _showSnackBar('SMS failed for ${smsData['partyName']}', Colors.red);
        }
      }

      setState(() {
        pendingSmsMessages.removeWhere((msg) =>
            msg['phone'] == smsData['phone'] &&
            msg['message'] == smsData['message']);
      });

      await Future.delayed(const Duration(milliseconds: 500));
    }

    _showSmsResults(sentMessages, failedMessages);
  }

  Future<bool?> _showSmsDialog(
      Map<String, String> smsData, int current, int total) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('SMS $current of $total'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Party: ${smsData['partyName']}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Phone: ${smsData['phone']}'),
              const SizedBox(height: 8),
              const Text('Message:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(smsData['message']!,
                    style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  void _showSmsResults(
      List<Map<String, String>> sent, List<Map<String, String>> failed) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('SMS Summary'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('✅ Sent: ${sent.length}'),
              Text('❌ Failed: ${failed.length}'),
              if (failed.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Failed messages:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...failed.map((msg) => Text('• ${msg['partyName']}')),
              ],
            ],
          ),
          actions: [
            if (failed.isNotEmpty)
              TextButton(
                onPressed: () {
                  setState(() {
                    pendingSmsMessages.addAll(failed);
                  });
                  Navigator.of(context).pop();
                  _showSnackBar(
                      'Failed SMS added back to pending list', Colors.orange);
                },
                child: const Text('Retry Failed'),
              ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Widget _buildCompactPartyCard(Map<String, dynamic> partyDetail) {
    final balanceAmt = (partyDetail['amtgiven'] + partyDetail['profit']) -
        partyDetail['amtcollected'];
    final perDayAmt = (partyDetail['amtgiven'] + partyDetail['profit']) /
        partyDetail['duedays'];
    final lenId = partyDetail['LenId'];
    final isSelected = selectedParties[lenId] ?? false;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: isSelected ? Colors.blue.shade50 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    partyDetail['PartyName'] ?? 'Unknown',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.blue.shade700 : Colors.blue),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    Text('Balance: ₹${balanceAmt.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Checkbox(
                      value: isSelected,
                      onChanged: (value) => _togglePartySelection(lenId),
                      activeColor: Colors.blue.shade700,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Amount: ',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87)),
                Expanded(
                  child: TextFormField(
                    controller: amountControllers[lenId] ??
                        TextEditingController(
                            text: perDayAmt.toStringAsFixed(2)),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            isSelected ? Colors.blue.shade700 : Colors.green),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isSelected
                              ? Colors.blue.shade300
                              : Colors.grey.shade300,
                        ),
                      ),
                      prefixText: '₹',
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'))
                    ],
                    onTap: () {
                      amountControllers[lenId]?.clear();
                      if (!isSelected) {
                        _togglePartySelection(lenId);
                      }
                    },
                    onChanged: (value) {
                      if (value.isNotEmpty && !isSelected) {
                        _togglePartySelection(lenId);
                      }
                    },
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
        backgroundColor: Colors.teal.shade900,
        elevation: 0,
        title: const Text('Bulk Collection Entry',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Line Name',
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 10),
                              ),
                              value: _selectedLineName,
                              items: _lineNames
                                  .map((lineName) => DropdownMenuItem(
                                      value: lineName, child: Text(lineName)))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedLineName = value;
                                  _searchController.clear();
                                });
                                if (value != null) _loadPartyNames(value);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
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
                                    Icon(Icons.calendar_today, size: 12),
                              ),
                              readOnly: true,
                              onTap: _selectDate,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: SizedBox(
                              height: 38,
                              child: TextFormField(
                                controller: _searchController,
                                decoration: const InputDecoration(
                                  labelText: 'Search Party',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 10),
                                  prefixIcon: Icon(Icons.search, size: 18),
                                ),
                                style: const TextStyle(fontSize: 13),
                                onChanged: _filterParties,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.purple),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Selected: ${selectedParties.values.where((selected) => selected).length}',
                                style: const TextStyle(
                                    fontSize: 13,
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

              Expanded(
                child: filteredLendingDetails.isEmpty
                    ? Center(
                        child: Text(
                          lendingDetails.isEmpty
                              ? 'No active parties found.\nSelect a line to view parties.'
                              : 'No parties found matching your search.',
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredLendingDetails.length,
                        itemBuilder: (context, index) => _buildCompactPartyCard(
                            filteredLendingDetails[index]),
                      ),
              ),

              if (pendingSmsMessages.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    border: Border.all(color: Colors.blue.shade200),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.sms, color: Colors.blue.shade700, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('${pendingSmsMessages.length} SMS pending',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500)),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            pendingSmsMessages.clear();
                          });
                          _showSnackBar('Pending SMS cleared', Colors.grey);
                        },
                        child:
                            const Text('Clear', style: TextStyle(fontSize: 12)),
                      ),
                      ElevatedButton(
                        onPressed: _sendAllPendingSms,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                        ),
                        child: const Text('Send All',
                            style:
                                TextStyle(fontSize: 12, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ],

              // Bulk Update Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Selected: ${selectedParties.values.where((selected) => selected).length}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Total: ₹${_calculateTotalSelected().toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed:
                            isProcessing ? null : _calculateAndShowBulkSummary,
                        icon: isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.upload_file,
                                color: Colors.white),
                        label: Text(
                          isProcessing
                              ? 'Processing...'
                              : 'Bulk Update Collections',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isProcessing ? Colors.grey : Colors.blue.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
