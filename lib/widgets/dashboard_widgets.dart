import 'package:flutter/material.dart';

import '../models/teacher.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// Thẻ thống kê (KPI) với icon gradient, số liệu lớn và dòng phụ.
class StatCard extends StatelessWidget {
  const StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.colors,
    this.caption,
    this.trend,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final List<Color> colors;
  final String? caption;
  final String? trend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.lineColor),
        boxShadow: context.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: colors.first.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 21),
              ),
              const Spacer(),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.first.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    trend!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colors.first,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.mutedColor,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 6),
            Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, color: context.mutedColor),
            ),
          ],
        ],
      ),
    );
  }
}

/// Thẻ giảng viên dạng lưới (card) — dùng cho chế độ xem "Lưới".
class TeacherGridCard extends StatelessWidget {
  const TeacherGridCard({
    required this.teacher,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.rank,
    super.key,
  });

  final Teacher teacher;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final int? rank;

  @override
  Widget build(BuildContext context) {
    final accent = colorForId(teacher.idgv);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.lineColor),
            boxShadow: context.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(19),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      accent.withValues(alpha: 0.9),
                      Color.lerp(accent, AppColors.sky, 0.55)!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    if (rank != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '#$rank',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    const Spacer(),
                    _MiniAction(
                      icon: Icons.edit_outlined,
                      tooltip: 'Sửa',
                      onTap: onEdit,
                    ),
                    const SizedBox(width: 6),
                    _MiniAction(
                      icon: Icons.delete_outline_rounded,
                      tooltip: 'Xóa',
                      onTap: onDelete,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Transform.translate(
                  offset: const Offset(0, -24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      TeacherAvatar(teacher: teacher, size: 58),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          teacher.fullname,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        teacher.idgv,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.mutedColor,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: _Metric(
                                value: '${teacher.sumClass}',
                                label: 'lớp',
                                color: accent,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 30,
                              color: context.lineColor,
                            ),
                            Expanded(
                              child: _Metric(
                                value: teacher.loadLabel,
                                label: 'tải',
                                color: accent,
                                small: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.value,
    required this.label,
    required this.color,
    this.small = false,
  });

  final String value;
  final String label;
  final Color color;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: small ? 13 : 17,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: context.mutedColor)),
      ],
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.2),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 15, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Hàng giảng viên dạng danh sách (bảng) — dùng cho chế độ xem "Danh sách".
class TeacherListRow extends StatelessWidget {
  const TeacherListRow({
    required this.teacher,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.rank,
    super.key,
  });

  final Teacher teacher;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final int? rank;

  @override
  Widget build(BuildContext context) {
    final accent = colorForId(teacher.idgv);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.lineColor),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                if (rank != null) ...[
                  SizedBox(
                    width: 30,
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: rank! <= 3 ? accent : context.mutedColor,
                      ),
                    ),
                  ),
                ],
                TeacherAvatar(teacher: teacher, size: 46),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teacher.fullname,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              teacher.idgv,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: accent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '${teacher.sumClass} lớp • Tải ${teacher.loadLabel.toLowerCase()}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: context.mutedColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Sửa',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 19),
                ),
                IconButton(
                  tooltip: 'Xóa',
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 19,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bảng xếp hạng giảng viên theo số lớp (top 5).
class LeaderboardCard extends StatelessWidget {
  const LeaderboardCard({
    required this.teachers,
    required this.onSelect,
    super.key,
  });

  final List<Teacher> teachers;
  final ValueChanged<Teacher> onSelect;

  @override
  Widget build(BuildContext context) {
    final top = [...teachers]..sort((a, b) => b.sumClass.compareTo(a.sumClass));
    final maxClass = top.isEmpty
        ? 1
        : (top.first.sumClass == 0 ? 1 : top.first.sumClass);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.lineColor),
        boxShadow: context.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Giảng viên nổi bật',
            subtitle: 'Xếp theo tổng số lớp phụ trách',
            icon: Icons.emoji_events_outlined,
          ),
          const SizedBox(height: 16),
          if (top.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  'Chưa có dữ liệu xếp hạng.',
                  style: TextStyle(color: context.mutedColor, fontSize: 13),
                ),
              ),
            )
          else
            ...top.take(5).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final teacher = entry.value;
              final accent = colorForId(teacher.idgv);
              return InkWell(
                onTap: () => onSelect(teacher),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 22,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: index < 3 ? accent : context.mutedColor,
                          ),
                        ),
                      ),
                      TeacherAvatar(teacher: teacher, size: 34),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              teacher.fullname,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 5),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: teacher.sumClass / maxClass,
                                minHeight: 5,
                                backgroundColor: accent.withValues(alpha: 0.12),
                                valueColor: AlwaysStoppedAnimation(accent),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${teacher.sumClass}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: accent,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

/// Phân bố số lớp: thanh ngang theo nhóm tải.
class LoadDistributionCard extends StatelessWidget {
  const LoadDistributionCard({required this.teachers, super.key});

  final List<Teacher> teachers;

  @override
  Widget build(BuildContext context) {
    final groups = <String, int>{
      'Thấp (0-2)': 0,
      'Trung bình (3-5)': 0,
      'Cao (6-9)': 0,
      'Rất cao (10+)': 0,
    };
    for (final teacher in teachers) {
      if (teacher.sumClass >= 10) {
        groups['Rất cao (10+)'] = groups['Rất cao (10+)']! + 1;
      } else if (teacher.sumClass >= 6) {
        groups['Cao (6-9)'] = groups['Cao (6-9)']! + 1;
      } else if (teacher.sumClass >= 3) {
        groups['Trung bình (3-5)'] = groups['Trung bình (3-5)']! + 1;
      } else {
        groups['Thấp (0-2)'] = groups['Thấp (0-2)']! + 1;
      }
    }
    final total = teachers.isEmpty ? 1 : teachers.length;
    const colors = [
      AppColors.emeraldLight,
      AppColors.sky,
      AppColors.amber,
      AppColors.coral,
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.lineColor),
        boxShadow: context.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Phân bố khối lượng',
            subtitle: 'Số giảng viên theo số lớp phụ trách',
            icon: Icons.insights_outlined,
          ),
          const SizedBox(height: 18),
          ...groups.entries.toList().asMap().entries.map((entry) {
            final color = colors[entry.key];
            final count = entry.value.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.value.key,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '$count GV',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: context.mutedColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: count / total,
                      minHeight: 7,
                      backgroundColor: color.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
