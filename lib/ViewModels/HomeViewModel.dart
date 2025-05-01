import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../Models/LineModel.dart';
import '../Models/CollectionModel.dart';
import '../Data/Databasehelper.dart';

class HomeViewModel extends StateNotifier<List<LineModel>> {
  HomeViewModel() : super([]);

  double totalAmtGiven = 0.0;
  double totalProfit = 0.0;
  double totalAmtReceived = 0.0;
  double totalExpense = 0.0;
  double todaysTotalDrAmt = 0.0;
  double todaysTotalCrAmt = 0.0;

  Future<void> loadLineNames() async {
    final names = await dbline.getLineNames();
    final details =
        await Future.wait(names.map((name) => dbline.getLineDetails(name)));

    state = List.generate(
      names.length,
      (index) => LineModel.fromMap(names[index], details[index]),
    );
  }

  Future<void> loadLineDetails() async {
    final details = await dbline.allLineDetails();
    totalAmtGiven = details['totalAmtGiven'] ?? 0.0;
    totalProfit = details['totalProfit'] ?? 0.0;
    totalAmtReceived = details['totalAmtRecieved'] ?? 0.0;
    totalExpense = details['totalexpense'] ?? 0.0;
  }

  Future<void> loadCollectionAndGivenByDate(DateTime date) async {
    String queryDate = DateFormat('yyyy-MM-dd').format(date);
    final result = await CollectionDB.getCollectionAndGivenByDate(queryDate);

    todaysTotalDrAmt = result['totalDrAmt'] ?? 0.0;
    todaysTotalCrAmt = result['totalCrAmt'] ?? 0.0;
  }
}
