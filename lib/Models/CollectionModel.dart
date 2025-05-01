class CollectionModel {
  final double totalDrAmt;
  final double totalCrAmt;

  CollectionModel({
    required this.totalDrAmt,
    required this.totalCrAmt,
  });

  factory CollectionModel.fromMap(Map<String, dynamic> map) {
    return CollectionModel(
      totalDrAmt: map['totalDrAmt'] ?? 0.0,
      totalCrAmt: map['totalCrAmt'] ?? 0.0,
    );
  }
}
