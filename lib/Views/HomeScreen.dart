import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../ViewModels/HomeViewModel.dart';
import '../Models/LineModel.dart';

final homeViewModelProvider =
    StateNotifierProvider<HomeViewModel, List<LineModel>>(
  (ref) => HomeViewModel(),
);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = ref.watch(homeViewModelProvider);
    final viewModel = ref.read(homeViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await viewModel.loadLineNames();
              await viewModel.loadLineDetails();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Picker
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextFormField(
              controller: TextEditingController(
                text: DateFormat('dd-MM-yyyy').format(DateTime.now()),
              ),
              decoration: const InputDecoration(
                labelText: 'Pick Date',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (pickedDate != null) {
                  await viewModel.loadCollectionAndGivenByDate(pickedDate);
                }
              },
            ),
          ),
          // Line List
          Expanded(
            child: ListView.builder(
              itemCount: lines.length,
              itemBuilder: (context, index) {
                final line = lines[index];
                return ListTile(
                  title: Text(line.name),
                  subtitle:
                      Text('Balance: ₹${line.balance.toStringAsFixed(2)}'),
                  onTap: () {
                    // Handle line selection
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
