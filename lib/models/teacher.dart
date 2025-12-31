class Teacher {
  final String id;
  final String teacherId;
  final String name;
  final String email;
  final String? phone;
  final String status;
  final String? profilePicture;
  final List<dynamic> companyIds;
  final String subscriptionType;
  final DateTime subscriptionStartDate;
  final DateTime subscriptionExpiryDate;
  final double totalEarnings;
  final int studentCount;
  final int classCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Teacher({
    required this.id,
    required this.teacherId,
    required this.name,
    required this.email,
    this.phone,
    required this.status,
    this.profilePicture,
    required this.companyIds,
    required this.subscriptionType,
    required this.subscriptionStartDate,
    required this.subscriptionExpiryDate,
    required this.totalEarnings,
    required this.studentCount,
    required this.classCount,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == 'active';

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['_id'],
      teacherId: json['teacherId'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      status: json['status'],
      profilePicture: json['profilePicture'],
      companyIds: json['companyIds'] ?? [],
      subscriptionType: json['subscriptionType'],
      subscriptionStartDate: DateTime.parse(json['subscriptionStartDate']),
      subscriptionExpiryDate: DateTime.parse(json['subscriptionExpiryDate']),
      totalEarnings: (json['totalEarnings'] ?? 0).toDouble(),
      studentCount: json['studentCount'] ?? 0,
      classCount: json['classCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}