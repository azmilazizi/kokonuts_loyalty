class AuthUser {
  final String token;
  final int customerId;
  final String phone;
  final String? name;

  const AuthUser({
    required this.token,
    required this.customerId,
    required this.phone,
    this.name,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? json;
    final customer = data['customer'] as Map<String, dynamic>? ?? data;
    return AuthUser(
      token: data['token'] as String,
      customerId: (customer['id'] as num).toInt(),
      phone: customer['phone'] as String? ?? '',
      name: customer['name'] as String?,
    );
  }
}

class UserProfile {
  final int id;
  final String phone;
  final String? name;
  final String? birthday;
  final double totalPoints;
  final String? tier;

  const UserProfile({
    required this.id,
    required this.phone,
    this.name,
    this.birthday,
    required this.totalPoints,
    this.tier,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? json;
    final customer = data['customer'] as Map<String, dynamic>? ?? data;
    return UserProfile(
      id: (customer['id'] as num?)?.toInt() ?? 0,
      phone: customer['phone'] as String? ?? '',
      name: customer['name'] as String?,
      birthday: customer['birthday'] as String?,
      totalPoints: (customer['total_points'] as num?)?.toDouble() ?? 0.0,
      tier: customer['tier'] as String?,
    );
  }

  UserProfile copyWith({String? name, String? birthday, double? totalPoints}) {
    return UserProfile(
      id: id,
      phone: phone,
      name: name ?? this.name,
      birthday: birthday ?? this.birthday,
      totalPoints: totalPoints ?? this.totalPoints,
      tier: tier,
    );
  }
}

class CashbackTransaction {
  final String id;
  final double amount;
  final DateTime date;
  final String? description;
  final String? storeAddress;
  final String? receiptNumber;
  final String type; // 'earn' | 'redeem'

  const CashbackTransaction({
    required this.id,
    required this.amount,
    required this.date,
    this.description,
    this.storeAddress,
    this.receiptNumber,
    this.type = 'earn',
  });

  factory CashbackTransaction.fromJson(Map<String, dynamic> json) {
    final rawDate = json['created_at'] as String? ??
        json['date'] as String? ??
        json['transaction_date'] as String? ??
        '';
    return CashbackTransaction(
      id: json['id']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ??
          (json['points'] as num?)?.toDouble() ??
          0.0,
      date: DateTime.tryParse(rawDate) ?? DateTime.now(),
      description: json['description'] as String?,
      storeAddress: json['store_address'] as String? ??
          json['location'] as String?,
      receiptNumber: json['receipt_number'] as String? ??
          json['reference'] as String?,
      type: json['type'] as String? ?? 'earn',
    );
  }
}
