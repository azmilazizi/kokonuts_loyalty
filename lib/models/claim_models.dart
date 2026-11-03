import 'claim_branch.dart';

class ClaimValidation {
  final String status;
  final double? amount;
  final double? pointsToEarn;
  final String? receiptNumber;
  final String? storeAddress;
  final ClaimBranch branch;

  const ClaimValidation({
    required this.status,
    this.amount,
    this.pointsToEarn,
    this.receiptNumber,
    this.storeAddress,
    this.branch = const ClaimBranch(),
  });

  factory ClaimValidation.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? json;
    return ClaimValidation(
      status: data['status'] as String,
      amount: (data['total_money'] as num?)?.toDouble(),
      pointsToEarn: (data['points_to_earn'] as num?)?.toDouble(),
      receiptNumber: data['receipt_number'] as String?,
      storeAddress: data['store_address'] as String?,
      branch: ClaimBranch.fromJson(data),
    );
  }
}

class ClaimResult {
  final double pointsEarned;
  final double totalPoints;
  final bool requiresReview;
  final ClaimBranch branch;

  const ClaimResult({
    required this.pointsEarned,
    required this.totalPoints,
    this.requiresReview = false,
    this.branch = const ClaimBranch(),
  });

  factory ClaimResult.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? json;
    return ClaimResult(
      pointsEarned: (data['points_earned'] as num).toDouble(),
      totalPoints: (data['total_points'] as num).toDouble(),
      requiresReview: data['requires_review'] as bool? ?? false,
      branch: ClaimBranch.fromJson(data),
    );
  }
}

class RegistrationRequirement {
  final String errorCode;
  final List<String> requiredFields;
  final bool needsConsent;

  const RegistrationRequirement({
    required this.errorCode,
    required this.requiredFields,
    required this.needsConsent,
  });

  bool get needsName => requiredFields.contains('name');
  bool get needsBirthday => requiredFields.contains('birthday');

  factory RegistrationRequirement.fromJson(Map<String, dynamic> json) {
    return RegistrationRequirement(
      errorCode: json['error'] as String? ?? 'needs_info',
      requiredFields: List<String>.from(json['required_fields'] ?? []),
      needsConsent: json['needs_consent'] as bool? ?? false,
    );
  }
}

class RegistrationRequiredException implements Exception {
  final RegistrationRequirement requirement;
  const RegistrationRequiredException(this.requirement);
}
