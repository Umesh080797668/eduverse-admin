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
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionExpiryDate;
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
    this.subscriptionStartDate,
    this.subscriptionExpiryDate,
    required this.totalEarnings,
    required this.studentCount,
    required this.classCount,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == 'active';

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['_id'] as String,
      teacherId: json['teacherId'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      status: json['status'] as String,
      profilePicture: json['profilePicture'] as String?,
      companyIds: json['companyIds'] ?? [],
      subscriptionType: json['subscriptionType'] as String,
      subscriptionStartDate: json['subscriptionStartDate'] != null 
          ? DateTime.parse(json['subscriptionStartDate'] as String)
          : null,
      subscriptionExpiryDate: json['subscriptionExpiryDate'] != null
          ? DateTime.parse(json['subscriptionExpiryDate'] as String)
          : null,
      totalEarnings: (json['totalEarnings'] ?? 0).toDouble(),
      studentCount: json['studentCount'] ?? 0,
      classCount: json['classCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}