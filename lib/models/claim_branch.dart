/// Branch identity is supplied by the claim API from the stored receipt.
class ClaimBranch {
  const ClaimBranch({
    this.warehouseId,
    this.name,
    this.storeAddress,
    this.reviewUri,
  });

  final int? warehouseId;
  final String? name;
  final String? storeAddress;
  final Uri? reviewUri;

  factory ClaimBranch.fromJson(Map<String, dynamic> data) => ClaimBranch(
    warehouseId: int.tryParse(data['warehouse_id']?.toString() ?? ''),
    name: data['branch_name'] as String?,
    storeAddress: data['store_address'] as String?,
    reviewUri: parseReviewUri(data['google_review_url']),
  );

  static Uri? parseReviewUri(Object? value) {
    if (value is! String) return null;
    final text = value.trim();
    if (text.isEmpty ||
        text.length > 2048 ||
        RegExp(r'[\x00-\x20\x7f]').hasMatch(text)) {
      return null;
    }
    final uri = Uri.tryParse(text);
    const hosts = {
      'g.page',
      'maps.app.goo.gl',
      'search.google.com',
      'maps.google.com',
      'www.google.com',
      'google.com',
    };
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.userInfo.isNotEmpty ||
        (uri.hasPort && uri.port != 443) ||
        !hosts.contains(uri.host.toLowerCase())) {
      return null;
    }
    return uri;
  }
}
