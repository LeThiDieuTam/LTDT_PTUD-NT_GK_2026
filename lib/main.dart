import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'auth/auth_gate.dart';
import 'screens/teacher_dashboard.dart';
import 'services/teacher_service.dart';
import 'theme/app_theme.dart';

/// Bật chế độ Firebase khi build:
/// `flutter run --dart-define=USE_FIREBASE=true --dart-define-from-file=firebase.json`
const _useFirebase = bool.fromEnvironment('USE_FIREBASE');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool isFirebaseReady = false;
  String? initError;

  if (_useFirebase) {
    try {
      await Firebase.initializeApp(options: _firebaseOptionsFromDefines());
      isFirebaseReady = true;
    } catch (e, stack) {
      initError = e.toString();
      debugPrint('====================================');
      debugPrint('LỖI KHỞI TẠO FIREBASE: $e');
      debugPrint('====================================\n$stack');
    }
  }
  runApp(GiangVienApp(useFirebase: isFirebaseReady, initError: initError));
}

/// Đọc cấu hình Firebase từ `--dart-define` để không commit key vào repo.
FirebaseOptions _firebaseOptionsFromDefines() {
  const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  const appId = String.fromEnvironment('FIREBASE_APP_ID');
  const senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  const authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  const storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');

  if (apiKey.isEmpty ||
      appId.isEmpty ||
      senderId.isEmpty ||
      projectId.isEmpty) {
    throw StateError(
      'Thiếu cấu hình Firebase. Hãy xem README.md và truyền đủ '
      'FIREBASE_API_KEY, FIREBASE_APP_ID, FIREBASE_MESSAGING_SENDER_ID '
      'và FIREBASE_PROJECT_ID (khuyến nghị: --dart-define-from-file=firebase.json).',
    );
  }
  return FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: senderId,
    projectId: projectId,
    authDomain: authDomain.isEmpty ? null : authDomain,
    storageBucket: storageBucket.isEmpty ? null : storageBucket,
  );
}

/// Root app: quản lý theme sáng/tối + điều hướng đăng nhập.
class GiangVienApp extends StatefulWidget {
  const GiangVienApp({this.useFirebase, this.initError, super.key});

  /// Cho phép test/embed ép chế độ dữ liệu (mặc định theo `USE_FIREBASE`).
  final bool? useFirebase;
  final String? initError;

  bool get firebaseEnabled => useFirebase ?? _useFirebase;

  @override
  State<GiangVienApp> createState() => _GiangVienAppState();
}

class _GiangVienAppState extends State<GiangVienApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _themeMode == ThemeMode.dark;
    final service = TeacherService(useFirebase: widget.firebaseEnabled);

    Widget dashboard({String? userLabel, Future<void> Function()? onSignOut}) {
      return TeacherDashboard(
        service: service,
        userLabel: userLabel,
        onSignOut: onSignOut,
        onToggleTheme: _toggleTheme,
        isDark: isDark,
      );
    }

    return MaterialApp(
      title: 'QLHocPhan – Quản lý giảng viên',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      locale: const Locale('vi', 'VN'),
      supportedLocales: const [Locale('vi', 'VN'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // Giới hạn scale chữ để layout bảng không vỡ trên máy cấu hình lớn.
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.25,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: widget.initError != null
          ? Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off_outlined,
                          size: 48,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Không thể khởi tạo Firebase',
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        SelectableText(
                          widget.initError!,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : widget.firebaseEnabled
          ? FirebaseAuthGate(
              builder: (context, user, signOut) => dashboard(
                userLabel: user.email ?? user.displayName ?? 'Quản trị viên',
                onSignOut: signOut,
              ),
            )
          : dashboard(userLabel: 'Quản trị viên (demo)', onSignOut: null),
    );
  }
}
