class LineModel {
  final String name;
  final double amtGiven;
  final double profit;
  final double expense;
  final double amtReceived;

  LineModel({
    required this.name,
    required this.amtGiven,
    required this.profit,
    required this.expense,
    required this.amtReceived,
  });

  double get balance => amtGiven + profit - expense - amtReceived;

  factory LineModel.fromMap(String name, Map<String, dynamic> map) {
    return LineModel(
      name: name,
      amtGiven: map['Amtgiven'] ?? 0.0,
      profit: map['Profit'] ?? 0.0,
      expense: map['expense'] ?? 0.0,
      amtReceived: map['Amtrecieved'] ?? 0.0,
    );
  }
}
