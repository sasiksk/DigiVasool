import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vasool_diary/Data/Databasehelper.dart';
import 'package:vasool_diary/Screens/Main/CollectionScreen.dart';
import 'package:intl/intl.dart';
import 'package:vasool_diary/Sms.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EnhancedBulkInsertScreen extends StatefulWidget {
  const EnhancedBulkInsertScreen({super.key});

  @override
  _EnhancedBulkInsertScreenState createState() =>
      _EnhancedBulkInsertScreenState();
}

class _EnhancedBulkInsertScreenState extends State<EnhancedBulkInsertScreen> {
  List<String> _lineNames = [];
  String? _selectedLineName;
  List<Map<String, dynamic>> lendingDetails = [];
  Map<int, bool> selectedParties = {};
  Map<int, TextEditingController> amountControllers = {};
  DateTime selectedDate = DateTime.now();
  final TextEditingController _dateController = TextEditingController(
    text: DateFormat('dd-MM-yyyy').format(DateTime.now()),
  );
  final TextEditingController _searchController = TextEditingController();

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
    _dateController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Utility Methods
  Future<void> _loadLineNames() async {
    final lineNames = await dbline.getLineNames();
    setState(() {
      _lineNames = lineNames;
    });
    _showInfoDialog();
  }

  Future<void> _showInfoDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enhanced Bulk Entry'),
          content: const Text(
              'Select parties and amounts, then use Bulk Update. SMS will be sent individually with confirmation.'),
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

  Future<void> _loadPartyNames(String lineName) async {
    final details = await dbLending.getLendingDetailsByLineName(lineName);
    if (details != null) {
      setState(() {
        lendingDetails = details
            .where((detail) => detail['status'] == 'active')
            .map((detail) => Map<String, dynamic>.from(detail))
            .toList();
        _resetData();
        _initializeControllers();
      });
    }
  }

  void _resetData() {
    selectedParties.clear();
    pendingSmsMessages.clear();
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
      // This will trigger a rebuild with filtered results in the ListView
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

  // Main Processing Methods
  void _processBulkUpdate() {
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
      _showSnackBar('No parties selected or amounts entered', Colors.orange);
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
          title: const Text('Bulk Update Confirmation'),
          content: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxHeight: 300),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Line:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(_selectedLineName ?? ''),
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
                            const Text('Parties:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('${entries.length}'),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total:',
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
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return ListTile(
                        dense: true,
                        title: Text(entry['party']['PartyName'] ?? 'Unknown',
                            style: const TextStyle(fontSize: 12)),
                        trailing: Text('₹${entry['amount'].toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                      );
                    },
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
                _executeUpdates(entries, totalAmount);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Confirm Update',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _executeUpdates(
      List<Map<String, dynamic>> entries, double totalAmount) async {
    setState(() {
      isProcessing = true;
    });

    _showProcessingDialog(entries.length);

    try {
      final dateString = DateFormat('yyyy-MM-dd').format(selectedDate);
      List<Map<String, String>> smsQueue = [];
      int successCount = 0;

      for (var entry in entries) {
        try {
          final party = entry['party'];
          final amount = entry['amount'];
          final lenId = entry['lenId'];

          // Use existing CollectionScreen methods
          await CollectionScreen.updateLendingData(lenId, amount);
          await CollectionScreen.updateAmtRecieved(_selectedLineName!, amount);
          await CollectionScreen.insertCollection(lenId, amount, dateString);

          // Prepare SMS
          await _prepareSmsForParty(party, amount, smsQueue);

          // Update UI state
          final partyIndex =
              lendingDetails.indexWhere((p) => p['LenId'] == lenId);
          if (partyIndex != -1) {
            setState(() {
              lendingDetails[partyIndex]['amtcollected'] += amount;
              selectedParties[lenId] = false;
              amountControllers[lenId]?.clear();
            });
          }

          successCount++;
        } catch (e) {
          print('Error updating party ${entry['party']['PartyName']}: $e');
        }
      }

      Navigator.of(context).pop(); // Close processing dialog

      // Send SMS if any
      if (smsQueue.isNotEmpty) {
        await _sendSmsSequentially(smsQueue);
      }

      // Show success message
      _showSuccessDialog(successCount, totalAmount, smsQueue.length);
    } catch (e) {
      Navigator.of(context).pop();
      _showSnackBar('Update failed: $e', Colors.red);
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  Future<void> _prepareSmsForParty(Map<String, dynamic> party, double amount,
      List<Map<String, String>> smsQueue) async {
    final int sms = party['sms'] ?? 0;
    final String phone = party['PartyPhnone'] ?? '';

    if (sms == 1 && phone.isNotEmpty && phone != 'Unknown') {
      final prefs = await SharedPreferences.getInstance();
      final financeName = prefs.getString('financeName') ?? '';
      final totalAmt = party['amtgiven'] + party['profit'];
      final newBalance = totalAmt - (party['amtcollected'] + amount);

      // Format the date for SMS (without time)
      final dateForSms = DateFormat('dd-MM-yyyy').format(selectedDate);

      // Compact SMS message with date but no time
      final smsMessage =
          'Payment Received!\nDate: $dateForSms\nAmount: ₹${amount.toStringAsFixed(2)}\nBalance: ₹${newBalance.toStringAsFixed(2)}\nThank You! - $financeName';

      smsQueue.add({
        'phone': phone,
        'message': smsMessage,
        'partyName': party['PartyName'] ?? 'Unknown',
      });
    }
  }

  Future<void> _sendSmsSequentially(List<Map<String, String>> smsQueue) async {
    for (int i = 0; i < smsQueue.length; i++) {
      if (!mounted) break;

      final smsData = smsQueue[i];
      bool? sendThis =
          await _showSmsConfirmationDialog(smsData, i + 1, smsQueue.length);

      if (sendThis == true) {
        try {
          await sendSms(smsData['phone']!, smsData['message']!);
          if (mounted) {
            _showSnackBar('SMS sent to ${smsData['partyName']}', Colors.green);
          }
        } catch (e) {
          if (mounted) {
            _showSnackBar('SMS failed for ${smsData['partyName']}', Colors.red);
          }
        }
      } else if (sendThis == null) {
        break; // User cancelled
      }

      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  Future<bool?> _showSmsConfirmationDialog(
      Map<String, String> smsData, int current, int total) async {
    if (!mounted) return null;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
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
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(smsData['message'] ?? '',
                    style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel All'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child:
                  const Text('Send SMS', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // UI Helper Methods
  void _showProcessingDialog(int count) {
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
              Text('Processing $count collections...'),
              const Text('Please wait...',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessDialog(int count, double total, int smsCount) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Complete'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('✅ Successfully updated $count collections'),
              Text('💰 Total amount: ₹${total.toStringAsFixed(2)}'),
              Text('📱 SMS processed: $smsCount'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to previous screen
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Done', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color),
      );
    }
  }

  List<Map<String, dynamic>> get filteredLendingDetails {
    if (_searchController.text.isEmpty) {
      return lendingDetails;
    }
    return lendingDetails
        .where((party) => party['PartyName']
            .toString()
            .toLowerCase()
            .contains(_searchController.text.toLowerCase()))
        .toList();
  }

  Widget _buildHeaderControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildLineAndDateRow(),
            const SizedBox(height: 12),
            _buildSearchField(),
          ],
        ),
      ),
    );
  }

  Widget _buildLineAndDateRow() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _buildLineDropdown(),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: _buildDateInput(),
        ),
      ],
    );
  }

  Widget _buildLineDropdown() {
    return DropdownButtonFormField<String>(
      decoration: _buildInputDecoration(label: 'Line Name'),
      value: _selectedLineName,
      items: _lineNames.map(_buildDropdownItem).toList(),
      onChanged: _handleLineChange,
    );
  }

  DropdownMenuItem<String> _buildDropdownItem(String value) {
    return DropdownMenuItem(
      value: value,
      child: Text(value),
    );
  }

  void _handleLineChange(String? value) {
    setState(() => _selectedLineName = value);
    if (value != null) _loadPartyNames(value);
  }

  Widget _buildDateInput() {
    return TextFormField(
      controller: _dateController,
      decoration: _buildInputDecoration(
        label: 'Date',
        suffixIcon: const Icon(Icons.calendar_today, size: 12),
      ),
      readOnly: true,
      onTap: _selectDate,
    );
  }

  Widget _buildSearchField() {
    return TextFormField(
      controller: _searchController,
      decoration: _buildInputDecoration(
        label: 'Search Party',
        prefixIcon: const Icon(Icons.search, size: 18),
      ),
      onChanged: _filterParties,
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal.shade900,
        elevation: 0,
        title: const Text('Collection Entry ',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                      TextFormField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Search Party',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                          prefixIcon: Icon(Icons.search, size: 18),
                        ),
                        onChanged: _filterParties,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Party List
              Expanded(
                child: filteredLendingDetails.isEmpty
                    ? const Center(
                        child: Text(
                          'No active parties found.\nSelect a line to view parties.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredLendingDetails.length,
                        itemBuilder: (context, index) {
                          final detail = filteredLendingDetails[index];
                          final lenId = detail['LenId'];
                          final balanceAmt =
                              (detail['amtgiven'] + detail['profit']) -
                                  detail['amtcollected'];
                          final isSelected = selectedParties[lenId] ?? false;

                          return Card(
                            color: isSelected ? Colors.blue.shade50 : null,
                            child: ListTile(
                              leading: Checkbox(
                                value: isSelected,
                                onChanged: (value) =>
                                    _togglePartySelection(lenId),
                              ),
                              title: Text(detail['PartyName'] ?? 'Unknown',
                                  style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal)),
                              subtitle: Text(
                                  'Balance: ₹${balanceAmt.toStringAsFixed(2)}'),
                              trailing: SizedBox(
                                width: 80,
                                child: TextFormField(
                                  controller: amountControllers[lenId],
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d{0,2}'))
                                  ],
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 6, horizontal: 6),
                                    border: OutlineInputBorder(),
                                  ),
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
                            ),
                          );
                        },
                      ),
              ),

              // Bottom Panel
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
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                            'Total: ₹${_calculateTotalSelected().toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: isProcessing ? null : _processBulkUpdate,
                        icon: isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.upload_file,
                                color: Colors.white),
                        label: Text(
                            isProcessing
                                ? 'Processing...'
                                : 'Bulk Update & Send SMS',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isProcessing ? Colors.grey : Colors.green,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
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
