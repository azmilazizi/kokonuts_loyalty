import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/claim_models.dart';
import '../services/loyalty_api.dart';
import '../theme.dart';

enum _Phase {
  loading,
  phoneEntry,
  supplemental,
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
  final _phoneFormKey = GlobalKey<FormState>();
  final _supplementalFormKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _birthdayDisplayController = TextEditingController();

  _Phase _phase = _Phase.loading;
  ClaimValidation? _validation;
  ClaimResult? _result;
  RegistrationRequirement? _requirement;
  String? _errorMessage;
  DateTime? _selectedBirthday;
  bool _pdpaConsent = false;

  @override
  void initState() {
    super.initState();
    _validateToken();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _birthdayDisplayController.dispose();
    super.dispose();
  }

  Future<void> _validateToken() async {
    setState(() => _phase = _Phase.loading);
    try {
      final validation = await _api.validateToken(widget.token);
      if (!mounted) return;
      setState(() {
        _validation = validation;
        _phase = switch (validation.status) {
          'valid' => _Phase.phoneEntry,
          'claimed' => _Phase.claimed,
          'expired' => _Phase.expired,
          'cancelled' => _Phase.cancelled,
          _ => _Phase.notFound,
        };
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = e.statusCode == 404 ? _Phase.notFound : _Phase.error;
        _errorMessage = 'Unable to reach the server. Please try again.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _errorMessage = 'Network error. Please check your connection.';
      });
    }
  }

  Future<void> _submitPhone() async {
    if (!_phoneFormKey.currentState!.validate()) return;
    setState(() => _phase = _Phase.submitting);

    try {
      final result = await _api.submitClaim(
        widget.token,
        phone: _phoneController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _phase = _Phase.success;
      });
    } on RegistrationRequiredException catch (e) {
      if (!mounted) return;
      setState(() {
        _requirement = e.requirement;
        _phase = _Phase.supplemental;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = switch (e.statusCode) {
          409 => _Phase.claimed,
          410 => _Phase.expired,
          _ => _Phase.error,
        };
        _errorMessage = 'Something went wrong. Please try again.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _phase = _Phase.phoneEntry);
      _showNetworkError();
    }
  }

  Future<void> _submitSupplemental() async {
    if (!_supplementalFormKey.currentState!.validate()) return;

    final req = _requirement!;
    if (req.needsConsent && !_pdpaConsent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Please give your consent to proceed — it keeps your data safe!'),
          backgroundColor: kOrange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _phase = _Phase.submitting);

    try {
      final result = await _api.submitClaim(
        widget.token,
        phone: _phoneController.text.trim(),
        name: req.needsName ? _nameController.text.trim() : null,
        birthday: req.needsBirthday && _selectedBirthday != null
            ? _formatDateForApi(_selectedBirthday!)
            : null,
        pdpaConsent: req.needsConsent ? true : null,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _phase = _Phase.success;
      });
    } on RegistrationRequiredException catch (e) {
      if (!mounted) return;
      setState(() {
        _requirement = e.requirement;
        _phase = _Phase.supplemental;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = switch (e.statusCode) {
          409 => _Phase.claimed,
          410 => _Phase.expired,
          _ => _Phase.error,
        };
        _errorMessage = 'Something went wrong. Please try again.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _phase = _Phase.supplemental);
      _showNetworkError();
    }
  }

  void _showNetworkError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Network error. Please check your connection.'),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _pickBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthday ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      helpText: 'Select your birthday',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: kOrange),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedBirthday = picked;
        _birthdayDisplayController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  String _formatDateForApi(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

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
    return switch (_phase) {
      _Phase.loading => _buildLoading(),
      _Phase.phoneEntry => _buildPhoneForm(),
      _Phase.supplemental => _buildSupplementalForm(),
      _Phase.submitting => _buildLoading(message: 'Claiming your cashback…'),
      _Phase.success => _SuccessView(result: _result!),
      _Phase.claimed => _buildStatusCard(
          emoji: '✅',
          emojiColor: Colors.blue.shade100,
          title: 'Already Claimed',
          message:
              'This receipt has already been used to claim cashback. See you on your next visit!',
        ),
      _Phase.expired => _buildStatusCard(
          emoji: '⏰',
          emojiColor: Colors.orange.shade50,
          title: 'Link Expired',
          message:
              'This claim link has expired. Links are valid for 12 hours after purchase. Come back soon!',
        ),
      _Phase.cancelled => _buildStatusCard(
          emoji: '🚫',
          emojiColor: Colors.red.shade50,
          title: 'Receipt Cancelled',
          message:
              'This receipt has been cancelled and cannot be used for cashback.',
        ),
      _Phase.notFound => _buildStatusCard(
          emoji: '🔍',
          emojiColor: Colors.grey.shade100,
          title: 'Invalid Link',
          message:
              'This claim link is not valid. Please check your link and try again.',
        ),
      _Phase.error => _buildStatusCard(
          emoji: '😬',
          emojiColor: Colors.red.shade50,
          title: 'Oops, Something Went Wrong',
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
        Text(message,
            style: const TextStyle(color: Colors.grey, fontSize: 15)),
      ],
    );
  }

  Widget _buildLogo() {
    return Image.asset('assets/images/animated_logo.png', height: 80);
  }

  Widget _buildCashbackHero() {
    final points = _validation!.pointsToEarn ?? 0.0;
    return Column(
      children: [
        _buildLogo(),
        const SizedBox(height: 32),
        Text(
          '+RM ${_fmtAmount(points)}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 58,
            fontWeight: FontWeight.bold,
            color: kOrange,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Cashback waiting for you!',
          style: TextStyle(fontSize: 15, color: Colors.grey),
        ),
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
      ],
    );
  }

  Widget _buildPhoneForm() {
    return Form(
      key: _phoneFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildCashbackHero(),
          const SizedBox(height: 36),
          const Divider(color: Color(0xFFEEEEEE)),
          const SizedBox(height: 28),
          const Text(
            'Claim it now! 🎉',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter your mobile number to get started',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\+\-\s\(\)]'))],
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
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitPhone,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                textStyle: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600),
              ),
              child: const Text('Claim My Cashback'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplementalForm() {
    final req = _requirement!;
    final (headline, subtitle) = switch (req.errorCode) {
      'needs_registration' => (
          'Welcome aboard! 🥥',
          'You\'re just a few details away from your very first cashback reward. Let\'s get you set up!',
        ),
      'needs_consent' => (
          'One last step! 🌟',
          'We need your consent to safely look after your info and keep rewarding you.',
        ),
      _ => (
          'Almost there! ✨',
          'Your account just needs a little more info to unlock this cashback.',
        ),
    };

    return Form(
      key: _supplementalFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildCashbackHero(),
          const SizedBox(height: 36),
          const Divider(color: Color(0xFFEEEEEE)),
          const SizedBox(height: 28),

          Text(
            headline,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style:
                const TextStyle(fontSize: 15, color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 8),

          // Phone display (read-only, tap to go back)
          GestureDetector(
            onTap: () => setState(() {
              _phase = _Phase.phoneEntry;
              _requirement = null;
            }),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_outlined,
                      size: 18, color: Colors.grey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _phoneController.text,
                      style: const TextStyle(
                          fontSize: 15, color: Color(0xFF1A1A1A)),
                    ),
                  ),
                  const Text(
                    'Change',
                    style: TextStyle(
                        fontSize: 13,
                        color: kOrange,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),

          if (req.needsName || req.needsBirthday) ...[
            const SizedBox(height: 14),
          ],

          if (req.needsName) ...[
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
                  return 'Please enter your full name';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
          ],

          if (req.needsBirthday) ...[
            TextFormField(
              controller: _birthdayDisplayController,
              readOnly: true,
              onTap: _pickBirthday,
              decoration: InputDecoration(
                labelText: 'Date of Birth',
                hintText: 'Tap to select',
                prefixIcon: const Icon(Icons.cake_outlined),
                suffixIcon: const Icon(Icons.calendar_today_outlined,
                    size: 18, color: Colors.grey),
              ),
              validator: (_) {
                if (_selectedBirthday == null) {
                  return 'Please select your date of birth';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
          ],

          if (req.needsConsent) ...[
            const SizedBox(height: 4),
            _buildConsentCard(),
          ],

          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitSupplemental,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                textStyle: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600),
              ),
              child: const Text('Claim My Cashback'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsentCard() {
    return GestureDetector(
      onTap: () => setState(() => _pdpaConsent = !_pdpaConsent),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _pdpaConsent ? kOrangeBg : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _pdpaConsent ? kOrangeBorder : const Color(0xFFDDDDDD),
            width: _pdpaConsent ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _pdpaConsent,
                onChanged: (v) =>
                    setState(() => _pdpaConsent = v ?? false),
                activeColor: kOrange,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'I consent to Kokonuts collecting and storing my personal data (name, phone, date of birth) for the loyalty programme, in accordance with Malaysia\'s Personal Data Protection Act (PDPA).',
                style: TextStyle(
                    fontSize: 13, color: Color(0xFF555555), height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required String emoji,
    required Color emojiColor,
    required String title,
    required String message,
    bool showRetry = false,
  }) {
    return Column(
      children: [
        _buildLogo(),
        const SizedBox(height: 48),
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: emojiColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 40)),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
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
        ScaleTransition(
          scale: _checkScale,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.green.shade200, width: 2),
            ),
            child: Icon(
              Icons.check_rounded,
              color: Colors.green.shade600,
              size: 54,
            ),
          ),
        ),

        const SizedBox(height: 28),

        FadeTransition(
          opacity: _contentFade,
          child: SlideTransition(
            position: _contentSlide,
            child: Column(
              children: [
                const Text(
                  'Woohoo! You\'ve Earned',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  '+RM ${_fmt(widget.result.pointsEarned)}',
                  style: const TextStyle(
                    fontSize: 58,
                    fontWeight: FontWeight.bold,
                    color: kOrange,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Cashback! 🎉',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 6),
                Text(
                  'Total cashback balance: RM ${_fmt(widget.result.totalPoints)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),

                const SizedBox(height: 36),
                const Divider(color: Color(0xFFEEEEEE)),
                const SizedBox(height: 20),

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
