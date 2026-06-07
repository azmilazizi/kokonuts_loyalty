class ClaimValidation {
  final String status;
  final double? amount;
  final double? pointsToEarn;
  final String? receiptNumber;
  final String? storeAddress;

  const ClaimValidation({
    required this.status,
    this.amount,
    this.pointsToEarn,
    this.receiptNumber,
    this.storeAddress,
  });

  factory ClaimValidation.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? json;
    return ClaimValidation(
      status: data['status'] as String,
      amount: (data['total_money'] as num?)?.toDouble(),
      pointsToEarn: (data['points_to_earn'] as num?)?.toDouble(),
      receiptNumber: data['receipt_number'] as String?,
      storeAddress: data['store_address'] as String?,
    );
  }
}

class ClaimResult {
  final double pointsEarned;
  final double totalPoints;

  const ClaimResult({required this.pointsEarned, required this.totalPoints});

  factory ClaimResult.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? json;
    return ClaimResult(
      pointsEarned: (data['points_earned'] as num).toDouble(),
      totalPoints: (data['total_points'] as num).toDouble(),
    );
  }
}
