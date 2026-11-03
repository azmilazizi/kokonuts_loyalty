import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kokonuts_loyalty/models/claim_branch.dart';
import 'package:kokonuts_loyalty/models/claim_models.dart';
import 'package:kokonuts_loyalty/screens/claim_screen.dart';
import 'package:kokonuts_loyalty/services/loyalty_api.dart';

class ClaimApi extends LoyaltyApiService {
  ClaimApi(this.result);
  final ClaimResult result;
  @override
  Future<ClaimValidation> validateToken(String token) async => ClaimValidation(
    status: 'valid',
    amount: 20,
    pointsToEarn: 2,
    branch: result.branch,
  );
  @override
  Future<ClaimResult> submitClaim(
    String token, {
    required String phone,
    String? name,
    String? birthday,
    bool? pdpaConsent,
  }) async => result;
}

void main() {
  test(
    'validation and claim responses carry the receipt branch and configured destination',
    () {
      final payload = {
        'warehouse_id': '27',
        'branch_name': 'Kokonuts Branch B',
        'store_address': 'Address B',
        'google_review_url': 'https://g.page/r/branch-b/review',
        'status': 'valid',
        'points_earned': 2,
        'total_points': 5,
        'requires_review': true,
      };
      final validation = ClaimValidation.fromJson({'data': payload});
      final result = ClaimResult.fromJson(payload);
      expect(validation.branch.warehouseId, 27);
      expect(validation.branch.name, 'Kokonuts Branch B');
      expect(validation.storeAddress, 'Address B');
      expect(
        result.branch.reviewUri.toString(),
        'https://g.page/r/branch-b/review',
      );
      expect(
        ClaimResult.fromJson({
          'points_earned': 2,
          'total_points': 5,
        }).branch.reviewUri,
        isNull,
      );
    },
  );

  test(
    'blank, unsafe, and unrelated links do not produce review destinations',
    () {
      for (final link in [
        null,
        '',
        'http://g.page/r/abc',
        'javascript:alert(1)',
        'https://g.page.evil.test/review',
        'https://g.page@evil.test',
        'https://g.page:444/r/abc',
        'https://g.page/r/a\nb',
      ]) {
        expect(ClaimBranch.parseReviewUri(link), isNull, reason: '$link');
      }
      expect(
        ClaimBranch.parseReviewUri('https://maps.app.goo.gl/abc'),
        isNotNull,
      );
    },
  );

  test(
    'review opening is sent with the claim token for branch attribution',
    () async {
      final api = LoyaltyApiService(
        client: MockClient((request) async {
          expect(request.url.path, '/loyalty/api/confirm_review');
          expect(jsonDecode(request.body), {
            'phone': '60123456789',
            'token': 'receipt-token',
          });
          return http.Response('{}', 200);
        }),
      );
      addTearDown(api.dispose);
      await api.confirmReview('60123456789', token: 'receipt-token');
    },
  );

  Future<void> completeClaim(WidgetTester tester, ClaimApi api) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(api.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ClaimScreen(token: 'token', api: api),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '0123456789');
    await tester.tap(find.text('Claim My Cashback'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'review invitation names the sale branch and can be skipped after cashback credit',
    (tester) async {
      await completeClaim(
        tester,
        ClaimApi(
          ClaimResult(
            pointsEarned: 2,
            totalPoints: 5,
            requiresReview: true,
            branch: ClaimBranch(
              warehouseId: 27,
              name: 'Branch B',
              reviewUri: Uri.parse('https://g.page/r/branch-b/review'),
            ),
          ),
        ),
      );
      expect(find.text('Share your experience at Branch B'), findsOneWidget);
      expect(
        find.textContaining('Your cashback has been credited.'),
        findsOneWidget,
      );
      await tester.tap(find.text('No thank you'));
      await tester.pumpAndSettle();
      expect(find.text('Cashback! 🎉'), findsOneWidget);
    },
  );

  testWidgets(
    'unconfigured branch skips review sheet without interrupting cashback',
    (tester) async {
      await completeClaim(
        tester,
        ClaimApi(
          const ClaimResult(
            pointsEarned: 2,
            totalPoints: 5,
            requiresReview: true,
            branch: ClaimBranch(warehouseId: 28, name: 'Branch C'),
          ),
        ),
      );
      expect(find.text('Leave a Review'), findsNothing);
      expect(find.text('Cashback! 🎉'), findsOneWidget);
    },
  );
}
