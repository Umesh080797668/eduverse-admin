class Earnings {
  final double totalAmount;
  final int totalStudents;

  Earnings({
    required this.totalAmount,
    required this.totalStudents,
  });

  factory Earnings.fromJson(Map<String, dynamic> json) {
    return Earnings(
      totalAmount: json['totalAmount'].toDouble(),
      totalStudents: json['totalStudents'],
    );
  }
}