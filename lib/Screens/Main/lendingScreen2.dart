import 'package:DigiVasool/Sms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:DigiVasool/Data/Databasehelper.dart';

import 'package:DigiVasool/Utilities/AppBar.dart';
import 'package:DigiVasool/Utilities/CustomDatePicker.dart';
import 'package:DigiVasool/Utilities/CustomTextField.dart';
import 'package:DigiVasool/finance_provider.dart';
import 'package:intl/intl.dart';

class LendingCombinedDetailsScreen2 extends ConsumerWidget {
  LendingCombinedDetailsScreen2({
    super.key,
  });

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amtGivenController = TextEditingController();
  final TextEditingController _profitController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  final TextEditingController _lentDateController = TextEditingController();
  final TextEditingController _dueDaysController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();

  void _updateLending(BuildContext context, String lineName, String partyName,
      int lentid) async {
    if (_formKey.currentState?.validate() == true) {
      try {
        final double amtGiven = double.parse(_amtGivenController.text);
        final double profit = double.parse(_profitController.text);

        final updatedValues = {
          'LenId': lentid,
          'amtgiven': amtGiven,
          'profit': profit,
          'Lentdate': DateFormat('yyyy-MM-dd')
              .format(DateFormat('dd-MM-yyyy').parse(_lentDateController.text)),
          'duedays': int.parse(_dueDaysController.text),
          'amtcollected': 0.0,
          'status': 'active',
        };

        await dbLending.updateLending(
          lineName: lineName,
          partyName: partyName,
          lenId: lentid,
          updatedValues: updatedValues,
        );

        // Fetch existing values from the Line table
        final db = await DatabaseHelper.getDatabase();
        final List<Map<String, dynamic>> existingEntries = await db.query(
          'Line',
          where: 'LOWER(Linename) = ?',
          whereArgs: [lineName.toLowerCase()],
        );

        if (existingEntries.isNotEmpty) {
          final existingEntry = existingEntries.first;
          final double existingAmtGiven = existingEntry['Amtgiven'];
          final double existingProfit = existingEntry['Profit'];

          final double newAmtGiven = existingAmtGiven + amtGiven;

          final double newProfit = existingProfit + profit;

          // Update the Line table with new values
          await dbline.updateLineAmounts(
            lineName: lineName,
            amtGiven: newAmtGiven,
            profit: newProfit,
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lending details updated successfully')),
        );

        /*Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PartyDetailScreen()),
        );*/
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating lending details: $e')),
        );
      }
    }
  }

  void _calculateTotal() {
    final amtGiven = double.tryParse(_amtGivenController.text) ?? 0.0;
    final profit = double.tryParse(_profitController.text) ?? 0.0;
    final total = amtGiven + profit;
    _totalController.text = total.toString();
  }

  void _calculateDueDate() {
    if (_lentDateController.text.isNotEmpty &&
        _dueDaysController.text.isNotEmpty) {
      DateTime lentDate =
          DateFormat('dd-MM-yyyy').parse(_lentDateController.text);
      int dueDays = int.parse(_dueDaysController.text);
      DateTime dueDate = lentDate.add(Duration(days: dueDays));
      _dueDateController.text = DateFormat('dd-MM-yyyy').format(dueDate);
    }
  }

  Future<void> checkAndSendSms({
    required BuildContext context,
    required int lenId,
    required String financeName,
    required String lentDate,
    required double amount,
    required int dueDays,
    required String dueDate,
  }) async {
    try {
      // Fetch party details from the database
      final db = await DatabaseHelper.getDatabase();
      final List<Map<String, dynamic>> partyDetails = await db.query(
        'Lending',
        columns: ['PartyPhnone', 'sms'], // Fetch phone number and SMS flag
        where: 'LenId = ?',
        whereArgs: [lenId],
      );

      if (partyDetails.isNotEmpty) {
        final String phoneNumber = partyDetails.first['PartyPhnone'] ?? '';
        final int smsFlag = partyDetails.first['sms'] ?? 0;

        // Check if SMS flag is set to 1
        if (smsFlag == 1 && phoneNumber.isNotEmpty) {
          final String message = '''
Date: $lentDate 
Amount: ₹${amount.toStringAsFixed(2)}
Due Days: $dueDays
Due Date: $dueDate
Thank you,
$financeName
''';

          // Send SMS
          await sendSms(phoneNumber, message);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('SMS sent successfully')),
          );
        } else if (smsFlag == 0) {
          // SMS flag is not set, skip sending SMS
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('SMS not enabled for this party')),
          );
        } else {
          // Handle case where phone number is empty
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Phone number not available')),
          );
        }
      } else {
        // Handle case where party details are not found
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Party details not found')),
        );
      }
    } catch (e) {
      // Handle errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send SMS: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lineName = ref.watch(currentLineNameProvider);
    final partyName = ref.watch(currentPartyNameProvider);
    final lenId = ref.watch(lenIdProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: "Lending to - ${partyName ?? ''}",
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Header
                const Text(
                  "Financial Details",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 10),

                // Card for Form Fields
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Amount Given Field
                        TextFormField(
                          controller: _amtGivenController,
                          decoration: const InputDecoration(
                            labelText: "Amount Given",
                            hintText: "Enter the amount given",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the amount given';
                            }
                            return null;
                          },
                          onChanged: (value) => _calculateTotal(),
                          onTap: () {
                            _amtGivenController.clear();
                          },
                        ),
                        const SizedBox(height: 10),

                        // Profit Field
                        TextFormField(
                          controller: _profitController,
                          decoration: const InputDecoration(
                            labelText: "Profit",
                            hintText: "Enter the profit",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the profit';
                            }
                            return null;
                          },
                          onChanged: (value) => _calculateTotal(),
                          onTap: () {
                            _profitController.clear();
                          },
                        ),
                        const SizedBox(height: 10),

                        // Total Field
                        CustomTextField(
                          controller: _totalController,
                          labelText: "Total",
                          hintText: "Calculated total",
                          readOnly: true,
                        ),
                        const SizedBox(height: 10),

                        // Lent Date and Due Days
                        Row(
                          children: [
                            Expanded(
                              child: CustomDatePicker(
                                controller: _lentDateController,
                                labelText: "Lent Date",
                                hintText: "Pick a lent date",
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _dueDaysController,
                                decoration: const InputDecoration(
                                  labelText: "Due Days",
                                  hintText: "Enter the due days",
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter the due days';
                                  }
                                  return null;
                                },
                                onTap: () {
                                  _dueDaysController.clear();
                                },
                                onChanged: (value) => _calculateDueDate(),
                                onFieldSubmitted: (value) =>
                                    _calculateDueDate(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Due Date Field
                        CustomTextField(
                          controller: _dueDateController,
                          labelText: "Due Date",
                          hintText: "Calculated due date",
                          readOnly: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Reset and Cancel Buttons in One Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        _formKey.currentState?.reset();
                        _lentDateController.clear();
                        _dueDaysController.clear();
                        _dueDateController.clear();
                        _amtGivenController.clear();
                        _profitController.clear();
                        _totalController.clear();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text("Reset"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.cancel),
                      label: const Text("Cancel"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.shade100,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Submit Button at the End
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_formKey.currentState?.validate() == true) {
                        DatabaseHelper.getLenId(lineName!, partyName!)
                            .then((lenid) async {
                          if (lenid != null) {
                            final lenStatus =
                                await dbLending.getStatusByLenId(lenid);
                            if (lenStatus == 'passive') {
                              _updateLending(
                                  context, lineName, partyName, lenid);

                              // Show success SnackBar
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Form Submitted')),
                              );

                              // Send SMS
                              await checkAndSendSms(
                                context: context,
                                lenId: lenid,
                                financeName: ref.watch(financeNameProvider),
                                lentDate: _lentDateController.text,
                                amount:
                                    (double.parse(_amtGivenController.text) +
                                        double.parse(_profitController.text)),
                                dueDays: int.parse(_dueDaysController.text),
                                dueDate: _dueDateController.text,
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Error: Cannot lend amount to active state party')),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Error: LenId is null')),
                            );
                          }
                        });
                      }
                    },
                    icon: const Icon(Icons.check),
                    label: const Text("Submit"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
