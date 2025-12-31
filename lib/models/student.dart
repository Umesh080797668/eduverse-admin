class Student {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final Map<String, dynamic>? classId;
  final Map<String, dynamic>? companyId;
  final double totalPaid;
  final int paymentCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Student({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.classId,
    this.companyId,
    required this.totalPaid,
    required this.paymentCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['_id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      classId: json['classId'],
      companyId: json['companyId'],
      totalPaid: (json['totalPaid'] ?? 0).toDouble(),
      paymentCount: json['paymentCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}