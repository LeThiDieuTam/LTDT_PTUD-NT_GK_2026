import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_errors.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Cổng xác thực: chưa đăng nhập → trang đăng nhập, đã đăng nhập → dashboard.
class FirebaseAuthGate extends StatelessWidget {
  const FirebaseAuthGate({
    required this.builder,
    this.onLocalSignOut,
    super.key,
  });

  /// Builder dashboard sau khi đăng nhập thành công.
  final Widget Function(
    BuildContext context,
    User user,
    Future<void> Function() signOut,
  )
  builder;

  /// Callback dùng khi đăng xuất ở chế độ demo (không có Firebase Auth).
  final Future<void> Function()? onLocalSignOut;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: MessagePanel(
                  message: 'Không thể xác thực tài khoản: ${snapshot.error}',
                ),
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AuthSplash();
        }
        final user = snapshot.data;
        if (user == null) {
          return AdminLoginPage(onDemoSignIn: onLocalSignOut);
        }
        return builder(context, user, FirebaseAuth.instance.signOut);
      },
    );
  }
}

class _AuthSplash extends StatelessWidget {
  const _AuthSplash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuroraBackground(
        intensity: 1.4,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _BrandMark(size: 72),
              const SizedBox(height: 20),
              Text(
                'QLHocPhan',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.2),
              ),
              const SizedBox(height: 18),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Logo tạm của ứng dụng: khối vuông gradient + icon mũ tốt nghiệp.
class _BrandMark extends StatelessWidget {
  const _BrandMark({this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald.withValues(alpha: 0.32),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(Icons.school_rounded, color: Colors.white, size: size * 0.54),
    );
  }
}

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({this.onDemoSignIn, super.key});

  /// Khi khác null: hiển thị lối vào chế độ demo (chấm offline).
  final Future<void> Function()? onDemoSignIn;

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

enum _AuthMode { signIn, signUp }

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  _AuthMode _mode = _AuthMode.signIn;
  bool _busy = false;
  bool _hidePassword = true;
  String? _errorMessage;
  String? _infoMessage;

  bool get _isSignUp => _mode == _AuthMode.signUp;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _switchMode() {
    setState(() {
      _mode = _isSignUp ? _AuthMode.signIn : _AuthMode.signUp;
      _errorMessage = null;
      _infoMessage = null;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _errorMessage = null;
      _infoMessage = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) {
        setState(
          () => _errorMessage = authErrorMessage(error, isSignUp: _isSignUp),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signIn() => _run(() async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  });

  Future<void> _signUp() => _run(() async {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    await FirebaseAuth.instance.currentUser?.updateDisplayName(
      _emailController.text.split('@').first,
    );
  });

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorMessage = 'Nhập email quản trị trước khi đặt lại mật khẩu.';
        _infoMessage = null;
      });
      return;
    }
    setState(() {
      _busy = true;
      _errorMessage = null;
      _infoMessage = null;
    });
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      setState(
        () => _infoMessage = 'Đã gửi email đặt lại mật khẩu tới $email.',
      );
    } catch (error) {
      if (mounted) setState(() => _errorMessage = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      body: AuroraBackground(
        intensity: isDark ? 1.2 : 1.6,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1060),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface.withValues(alpha: 0.94)
                      : Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: context.lineColor),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F0F172A),
                      blurRadius: 48,
                      offset: Offset(0, 24),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final showHero = constraints.maxWidth > 820;
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showHero)
                            Expanded(flex: 5, child: const _LoginHero()),
                          Expanded(
                            flex: showHero ? 4 : 1,
                            child: Padding(
                              padding: EdgeInsets.all(showHero ? 44 : 26),
                              child: _buildForm(context, compact: !showHero),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, {required bool compact}) {
    final theme = Theme.of(context);
    final title = _isSignUp ? 'Tạo tài khoản quản trị' : 'Chào mừng trở lại';
    final subtitle = _isSignUp
        ? 'Đăng ký để bắt đầu quản lý danh sách giảng viên.'
        : 'Đăng nhập vào QLHocPhan để tiếp tục.';

    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (compact) ...[
              const Row(
                children: [
                  _BrandMark(size: 46),
                  SizedBox(width: 12),
                  Text(
                    'QLHocPhan',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 22),
            ],
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(subtitle, style: TextStyle(color: context.mutedColor)),
            const SizedBox(height: 26),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [
                AutofillHints.username,
                AutofillHints.email,
              ],
              decoration: const InputDecoration(
                labelText: 'Email quản trị',
                hintText: 'admin@qlhocphan.edu.vn',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return 'Vui lòng nhập email.';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
                  return 'Email không đúng định dạng.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: _hidePassword,
              textInputAction: _isSignUp
                  ? TextInputAction.next
                  : TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _isSignUp ? null : _signIn(),
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _hidePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                  onPressed: () =>
                      setState(() => _hidePassword = !_hidePassword),
                  icon: Icon(
                    _hidePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập mật khẩu.';
                }
                if (_isSignUp && value.length < 6) {
                  return 'Mật khẩu cần tối thiểu 6 ký tự.';
                }
                return null;
              },
            ),
            if (_isSignUp) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirmController,
                obscureText: _hidePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _signUp(),
                decoration: const InputDecoration(
                  labelText: 'Nhập lại mật khẩu',
                  prefixIcon: Icon(Icons.verified_user_outlined),
                ),
                validator: (value) => value != _passwordController.text
                    ? 'Mật khẩu nhập lại không khớp.'
                    : null,
              ),
            ],
            if (!_isSignUp)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _busy ? null : _resetPassword,
                  child: const Text('Quên mật khẩu?'),
                ),
              ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              MessagePanel(message: _errorMessage!),
            ],
            if (_infoMessage != null) ...[
              const SizedBox(height: 8),
              MessagePanel(
                message: _infoMessage!,
                icon: Icons.mark_email_read_outlined,
                tone: MessageTone.success,
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : (_isSignUp ? _signUp : _signIn),
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_isSignUp ? 'Đăng ký tài khoản' : 'Đăng nhập'),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isSignUp ? 'Đã có tài khoản?' : 'Chưa có tài khoản?',
                  style: TextStyle(color: context.mutedColor, fontSize: 13),
                ),
                TextButton(
                  onPressed: _busy ? null : _switchMode,
                  child: Text(_isSignUp ? 'Đăng nhập' : 'Đăng ký ngay'),
                ),
              ],
            ),
            if (widget.onDemoSignIn != null) ...[
              const Divider(height: 28),
              OutlinedButton.icon(
                onPressed: _busy ? null : widget.onDemoSignIn,
                icon: const Icon(Icons.science_outlined, size: 18),
                label: const Text('Vào chế độ demo (không cần Firebase)'),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 14,
                  color: context.mutedColor,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Chỉ tài khoản được cấp quyền mới xem được dữ liệu.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.mutedColor, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginHero extends StatelessWidget {
  const _LoginHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 600),
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: Stack(
        children: [
          Positioned(
            right: -70,
            top: -60,
            child: _Glow(
              size: 260,
              color: Colors.white.withValues(alpha: 0.16),
            ),
          ),
          Positioned(
            left: -90,
            bottom: -80,
            child: _Glow(
              size: 300,
              color: AppColors.sky.withValues(alpha: 0.28),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(42),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    _BrandMark(size: 42),
                    SizedBox(width: 12),
                    Text(
                      'QLHocPhan',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        color: Color(0xFFB9F6CA),
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Realtime • Firebase • Đa nền tảng',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Quản lý giảng viên,\nđơn giản và hiệu quả.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    height: 1.18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Thêm, chỉnh sửa, xóa và theo dõi đội ngũ giảng viên\n'
                  'của khoa trên một không gian quản trị duy nhất.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 30),
                const Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _HeroFeature(
                      icon: Icons.bolt_rounded,
                      label: 'Đồng bộ realtime',
                    ),
                    _HeroFeature(
                      icon: Icons.lock_outline_rounded,
                      label: 'Firebase Auth',
                    ),
                    _HeroFeature(
                      icon: Icons.cloud_upload_outlined,
                      label: 'Ảnh trên Storage',
                    ),
                    _HeroFeature(
                      icon: Icons.file_download_outlined,
                      label: 'Xuất CSV / JSON',
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  'ADMIN CONSOLE  •  HỌC PHẦN',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 2,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroFeature extends StatelessWidget {
  const _HeroFeature({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white.withValues(alpha: 0.12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}
