import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/auth_models.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    AuthService().addListener(_onAuthChange);
    _loadProfile();
  }

  @override
  void dispose() {
    AuthService().removeListener(_onAuthChange);
    super.dispose();
  }

  void _onAuthChange() {
    if (mounted) {
      setState(() => _profile = AuthService().cachedProfile);
    }
  }

  Future<void> _loadProfile({bool refresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile =
          await AuthService().getProfile(forceRefresh: refresh);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        context.go('/login');
        return;
      }
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load profile.';
      });
    }
  }

  String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  String _initials(UserProfile p) {
    if (p.name != null && p.name!.isNotEmpty) {
      final parts = p.name!.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return parts[0][0].toUpperCase();
    }
    return p.phone.isNotEmpty ? p.phone[0] : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: kOrange))
            : _error != null
                ? _buildError()
                : _buildContent(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 52, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadProfile(refresh: true),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final p = _profile!;
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildProfileHeader(p),
          const SizedBox(height: 16),
          _buildInfoSection(p),
          const SizedBox(height: 12),
          _buildActionsSection(p),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(UserProfile p) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: kOrangeBg,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _initials(p),
                style: const TextStyle(
                  color: kOrange,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            p.name ?? 'Member',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            p.phone,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          // Cashback balance chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: kOrangeBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: kOrangeBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_balance_wallet_outlined,
                    color: kOrange, size: 18),
                const SizedBox(width: 8),
                Text(
                  'RM ${_fmt(p.totalPoints)} cashback',
                  style: const TextStyle(
                    color: kOrangeDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(UserProfile p) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Account Details',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey),
            ),
          ),
          _infoRow(Icons.person_outline_rounded, 'Name',
              p.name ?? 'Not set'),
          const Divider(height: 1, indent: 56),
          _infoRow(Icons.phone_outlined, 'Mobile', p.phone),
          const Divider(height: 1, indent: 56),
          _infoRow(
              Icons.cake_outlined,
              'Birthday',
              p.birthday != null
                  ? _formatBirthday(p.birthday!)
                  : 'Not set'),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 14,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(UserProfile p) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _actionTile(
            icon: Icons.edit_outlined,
            label: 'Edit Profile',
            onTap: () => context.push('/profile/edit'),
          ),
          const Divider(height: 1, indent: 56),
          _actionTile(
            icon: Icons.lock_outline_rounded,
            label: 'Change Password',
            onTap: _showChangePasswordDialog,
          ),
          const Divider(height: 1, indent: 56),
          _actionTile(
            icon: Icons.logout_rounded,
            label: 'Sign Out',
            color: Colors.red.shade400,
            onTap: _confirmLogout,
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? const Color(0xFF1A1A1A);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    fontSize: 15, color: c, fontWeight: FontWeight.w500)),
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => _ChangePasswordDialog(
        currentCtrl: currentCtrl,
        newCtrl: newCtrl,
        confirmCtrl: confirmCtrl,
        onSaved: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Password changed successfully'),
                backgroundColor: Colors.green.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        },
      ),
    );

    currentCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content:
            const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AuthService().logout();
      if (mounted) context.go('/login');
    }
  }

  String _formatBirthday(String raw) {
    // Expects YYYY-MM-DD or DD/MM/YYYY
    try {
      final parts = raw.contains('-') ? raw.split('-') : raw.split('/');
      if (parts.length == 3) {
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        if (raw.contains('-')) {
          // YYYY-MM-DD
          final month = int.tryParse(parts[1]) ?? 1;
          return '${parts[2]} ${months[month - 1]} ${parts[0]}';
        } else {
          // DD/MM/YYYY
          final month = int.tryParse(parts[1]) ?? 1;
          return '${parts[0]} ${months[month - 1]} ${parts[2]}';
        }
      }
    } catch (_) {}
    return raw;
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  final TextEditingController currentCtrl;
  final TextEditingController newCtrl;
  final TextEditingController confirmCtrl;
  final VoidCallback onSaved;

  const _ChangePasswordDialog({
    required this.currentCtrl,
    required this.newCtrl,
    required this.confirmCtrl,
    required this.onSaved,
  });

  @override
  State<_ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  bool _loading = false;
  String? _error;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  Future<void> _save() async {
    final current = widget.currentCtrl.text;
    final newPass = widget.newCtrl.text;
    final confirm = widget.confirmCtrl.text;

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      setState(() => _error = 'All fields are required');
      return;
    }
    if (newPass.length < 8) {
      setState(() => _error = 'New password must be at least 8 characters');
      return;
    }
    if (newPass != confirm) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService().changePassword(current, newPass);
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Network error. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Password'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(_error!,
                    style: TextStyle(
                        color: Colors.red.shade700, fontSize: 13)),
              ),
              const SizedBox(height: 12),
            ],
            _pwField(
              controller: widget.currentCtrl,
              label: 'Current Password',
              obscure: _obscureCurrent,
              onToggle: () =>
                  setState(() => _obscureCurrent = !_obscureCurrent),
            ),
            const SizedBox(height: 12),
            _pwField(
              controller: widget.newCtrl,
              label: 'New Password',
              obscure: _obscureNew,
              onToggle: () => setState(() => _obscureNew = !_obscureNew),
            ),
            const SizedBox(height: 12),
            _pwField(
              controller: widget.confirmCtrl,
              label: 'Confirm New Password',
              obscure: _obscureConfirm,
              onToggle: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _save,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Widget _pwField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: Icon(
              obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              size: 20),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
