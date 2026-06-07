import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/claim_models.dart';
import '../services/loyalty_api.dart';
import '../theme.dart';

enum _ScreenState {
  loading,
  valid,
  submitting,
  success,
  claimed,
  expired,
  cancelled,
  notFound,
  error,
}

class ClaimScreen extends StatefulWidget {
  final String token;

  const ClaimScreen({super.key, required this.token});

  @override
  State<ClaimScreen> createState() => _ClaimScreenState();
}

class _ClaimScreenState extends State<ClaimScreen> {
  final _api = LoyaltyApiService();
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();

  _ScreenState _state = _ScreenState.loading;
  ClaimValidation? _validation;
  ClaimResult? _result;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _validateToken();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _validateToken() async {
    setState(() => _state = _ScreenState.loading);
    try {
      final validation = await _api.validateToken(widget.token);
      if (!mounted) return;
      setState(() {
        _validation = validation;
        _state = switch (validation.status) {
          'valid' => _ScreenState.valid,
          'claimed' => _ScreenState.claimed,
          'expired' => _ScreenState.expired,
          'cancelled' => _ScreenState.cancelled,
          _ => _ScreenState.notFound,
        };
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _state =
            e.statusCode == 404 ? _ScreenState.notFound : _ScreenState.error;
        _errorMessage = 'Unable to reach the server. Please try again.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = _ScreenState.error;
        _errorMessage = 'Network error. Please check your connection.';
      });
    }
  }

  Future<void> _submitClaim() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _state = _ScreenState.submitting);

    try {
      final result = await _api.submitClaim(
        widget.token,
        _nameController.text.trim(),
        _phoneController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _state = _ScreenState.success;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _state = switch (e.statusCode) {
          409 => _ScreenState.claimed,
          410 => _ScreenState.expired,
          _ => _ScreenState.error,
        };
        _errorMessage = 'Something went wrong. Please try again.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = _ScreenState.valid);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error. Please check your connection.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _fmtAmount(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              child: _buildContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return switch (_state) {
      _ScreenState.loading => _buildLoading(),
      _ScreenState.valid => _buildClaimForm(),
      _ScreenState.submitting =>
        _buildLoading(message: 'Claiming your cashback…'),
      _ScreenState.success => _SuccessView(result: _result!),
      _ScreenState.claimed => _buildStatusCard(
          icon: Icons.check_circle_outline_rounded,
          iconColor: Colors.blue,
          title: 'Already Claimed',
          message:
              'This receipt has already been used to claim cashback.',
        ),
      _ScreenState.expired => _buildStatusCard(
          icon: Icons.timer_off_outlined,
          iconColor: Colors.orange,
          title: 'Link Expired',
          message:
              'This claim link has expired. Links are valid for 12 hours after purchase.',
        ),
      _ScreenState.cancelled => _buildStatusCard(
          icon: Icons.cancel_outlined,
          iconColor: Colors.red,
          title: 'Receipt Cancelled',
          message:
              'This receipt has been cancelled and cannot be used for cashback.',
        ),
      _ScreenState.notFound => _buildStatusCard(
          icon: Icons.link_off_rounded,
          iconColor: Colors.grey,
          title: 'Invalid Link',
          message:
              'This claim link is not valid. Please check your link and try again.',
        ),
      _ScreenState.error => _buildStatusCard(
          icon: Icons.error_outline_rounded,
          iconColor: Colors.red,
          title: 'Something Went Wrong',
          message: _errorMessage ?? 'An unexpected error occurred.',
          showRetry: true,
        ),
    };
  }

  Widget _buildLoading({String message = 'Validating your link…'}) {
    return Column(
      children: [
        _buildLogo(),
        const SizedBox(height: 64),
        const CircularProgressIndicator(color: kOrange),
        const SizedBox(height: 20),
        Text(message, style: const TextStyle(color: Colors.grey, fontSize: 15)),
      ],
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/images/animated_logo.png',
      height: 80,
    );
  }

  Widget _buildClaimForm() {
    final points = _validation!.pointsToEarn ?? 0.0;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildLogo(),
          const SizedBox(height: 40),

          // Headline
          const Text(
            'Earn Cashback Now',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 10),

          // Cashback amount
          Text(
            '+RM ${_fmtAmount(points)}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 54,
              fontWeight: FontWeight.bold,
              color: kOrange,
              height: 1,
            ),
          ),

          // Store address (shown only if API returns it)
          if (_validation!.storeAddress != null) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 15, color: Colors.grey),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    _validation!.storeAddress!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 36),
          const Divider(color: Color(0xFFEEEEEE)),
          const SizedBox(height: 28),

          // Form heading
          const Text(
            'Claim it with your mobile number and name',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Phone first
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Mobile Number',
              hintText: 'e.g. 0123456789',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Mobile number is required';
              }
              final cleaned = v.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
              if (!RegExp(r'^\+?[0-9]{9,15}$').hasMatch(cleaned)) {
                return 'Please enter a valid phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Name second
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              hintText: 'Enter your name',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            validator: (v) {
              if (v == null || v.trim().length < 2) {
                return 'Full name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitClaim,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                textStyle: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600),
              ),
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    bool showRetry = false,
  }) {
    return Column(
      children: [
        _buildLogo(),
        const SizedBox(height: 56),
        Icon(icon, size: 60, color: iconColor),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: const TextStyle(
              color: Colors.grey, height: 1.6, fontSize: 15),
          textAlign: TextAlign.center,
        ),
        if (showRetry) ...[
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: _validateToken,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ],
      ],
    );
  }
}

// ─── Animated success screen ──────────────────────────────────────────────────

class _SuccessView extends StatefulWidget {
  final ClaimResult result;

  const _SuccessView({required this.result});

  @override
  State<_SuccessView> createState() => _SuccessViewState();
}

class _SuccessViewState extends State<_SuccessView>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _checkScale;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
      ),
    );
    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOut),
      ),
    );
    _contentSlide =
        Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.45, 0.9, curve: Curves.easeOut),
      ),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  Future<void> _openReview() async {
    final uri = Uri.parse('https://g.page/r/CciDQI8LclZEEBM/review');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Animated checkmark
        ScaleTransition(
          scale: _checkScale,
          child: Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.green.shade200, width: 2),
            ),
            child: Icon(
              Icons.check_rounded,
              color: Colors.green.shade600,
              size: 50,
            ),
          ),
        ),

        const SizedBox(height: 28),

        // Content slides in
        FadeTransition(
          opacity: _contentFade,
          child: SlideTransition(
            position: _contentSlide,
            child: Column(
              children: [
                const Text(
                  "You've Earned",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  '+RM ${_fmt(widget.result.pointsEarned)}',
                  style: const TextStyle(
                    fontSize: 54,
                    fontWeight: FontWeight.bold,
                    color: kOrange,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Cashback!',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 6),
                Text(
                  'Total cashback balance: RM ${_fmt(widget.result.totalPoints)}',
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 13),
                ),

                const SizedBox(height: 36),
                const Divider(color: Color(0xFFEEEEEE)),
                const SizedBox(height: 20),

                // How to redeem
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: kOrangeBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.info_outline_rounded,
                          color: kOrange, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'How to redeem',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'On your next visit, tell our staff your registered phone number at the counter. Your cashback will be applied to your bill automatically.',
                  style: TextStyle(
                      color: Colors.grey, height: 1.6, fontSize: 14),
                ),

                const SizedBox(height: 32),

                // Subtle review button
                OutlinedButton.icon(
                  onPressed: _openReview,
                  icon: const Icon(Icons.star_border_rounded, size: 17),
                  label: const Text('Leave us a Google Review'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF5A623),
                    side: const BorderSide(color: Color(0xFFFFD980)),
                    backgroundColor: const Color(0xFFFFFBF2),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
