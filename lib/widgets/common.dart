import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/teacher.dart';
import '../../theme/app_theme.dart';

/// Avatar giảng viên: ưu tiên ảnh (Storage URL hoặc base64), fallback chữ cái
/// đầu với nền gradient theo mã giảng viên.
class TeacherAvatar extends StatelessWidget {
  const TeacherAvatar({
    required this.teacher,
    this.size = 56,
    this.border,
    super.key,
  });

  final Teacher teacher;
  final double size;
  final Border? border;

  @override
  Widget build(BuildContext context) {
    final color = colorForId(teacher.idgv);
    final bytes = Teacher.decodeDataImage(teacher.image);

    Widget fallback = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, Color.lerp(color, Colors.white, 0.42)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        teacher.initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.34,
          letterSpacing: 0.5,
        ),
      ),
    );

    Widget child;
    if (bytes != null) {
      child = Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, _, _) => fallback,
      );
    } else if (teacher.image.isNotEmpty) {
      child = Image.network(
        teacher.image,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, _, _) => fallback,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) return child;
          return Container(
            color: context.softFill,
            alignment: Alignment.center,
            child: SizedBox(
              width: size * 0.35,
              height: size * 0.35,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      );
    } else {
      child = fallback;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border:
            border ??
            Border.all(color: Colors.white.withValues(alpha: 0.85), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(child: child),
    );
  }
}

/// Khối trang trí nền mờ (aurora blobs) tạo chiều sâu cho màn hình.
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({required this.child, this.intensity = 1, super.key});

  final Widget child;
  final double intensity;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    final base = dark ? AppColors.darkBg : AppColors.canvas;
    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: base)),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.value;
                return CustomPaint(
                  painter: _AuroraPainter(
                    progress: t,
                    intensity: widget.intensity,
                    dark: dark,
                  ),
                );
              },
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({
    required this.progress,
    required this.intensity,
    required this.dark,
  });

  final double progress;
  final double intensity;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final alpha = dark ? 0.16 : 0.20;
    final blobs = [
      (
        color: AppColors.emeraldLight,
        center: Offset(
          size.width * (0.12 + 0.05 * math.sin(progress * math.pi)),
          -size.height * 0.05,
        ),
        radius: size.shortestSide * 0.55,
      ),
      (
        color: AppColors.sky,
        center: Offset(
          size.width * 0.92,
          size.height * (0.1 + 0.05 * math.cos(progress * math.pi)),
        ),
        radius: size.shortestSide * 0.45,
      ),
      (
        color: AppColors.violet,
        center: Offset(
          size.width * 0.25,
          size.height * (0.92 + 0.03 * math.sin(progress * math.pi)),
        ),
        radius: size.shortestSide * 0.42,
      ),
    ];
    for (final blob in blobs) {
      final paint = Paint()
        ..shader =
            RadialGradient(
              colors: [
                blob.color.withValues(alpha: alpha * intensity),
                blob.color.withValues(alpha: 0),
              ],
            ).createShader(
              Rect.fromCircle(center: blob.center, radius: blob.radius),
            );
      canvas.drawCircle(blob.center, blob.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.dark != dark;
}

/// Tiêu đề mục nhỏ: icon + chữ + dòng phụ.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.mutedColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Hộp thông báo lỗi/thông tin có icon.
class MessagePanel extends StatelessWidget {
  const MessagePanel({
    required this.message,
    this.icon = Icons.error_outline_rounded,
    this.action,
    this.tone = MessageTone.error,
    super.key,
  });

  final String message;
  final IconData icon;
  final Widget? action;
  final MessageTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      MessageTone.error => Theme.of(context).colorScheme.error,
      MessageTone.info => Theme.of(context).colorScheme.primary,
      MessageTone.success => const Color(0xFF15803D),
      MessageTone.warning => AppColors.amber,
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.isDark ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.isDark ? null : AppColors.ink,
                height: 1.45,
              ),
            ),
          ),
          if (action != null) const SizedBox(width: 8),
          ?action,
        ],
      ),
    );
  }
}

enum MessageTone { error, info, success, warning }

/// Nút bo tròn dạng pill (filter/sort/theme).
class PillButton extends StatelessWidget {
  const PillButton({
    required this.label,
    this.icon,
    this.selected = false,
    this.onPressed,
    this.onRemove,
    super.key,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onPressed;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: selected ? primary : context.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(color: selected ? primary : context.lineColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: Padding(
          padding: EdgeInsets.fromLTRB(14, 9, onRemove != null ? 6 : 14, 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: selected ? Colors.white : context.mutedColor,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : null,
                ),
              ),
              if (onRemove != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 26,
                    height: 26,
                  ),
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: selected ? Colors.white : context.mutedColor,
                  ),
                  onPressed: onRemove,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
