import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/teacher.dart';
import '../theme/app_theme.dart';
import 'common.dart';

enum ChartType { donut, bar }

class WorkloadCategory {
  const WorkloadCategory({
    required this.name,
    required this.range,
    required this.count,
    required this.color,
  });

  final String name;
  final String range;
  final int count;
  final Color color;
}

/// Biểu đồ tương tác phân bố khối lượng giảng viên (chuyển đổi Donut ↔ Cột).
class InteractiveWorkloadChart extends StatefulWidget {
  const InteractiveWorkloadChart({required this.teachers, super.key});

  final List<Teacher> teachers;

  @override
  State<InteractiveWorkloadChart> createState() =>
      _InteractiveWorkloadChartState();
}

class _InteractiveWorkloadChartState extends State<InteractiveWorkloadChart>
    with SingleTickerProviderStateMixin {
  ChartType _chartType = ChartType.donut;
  int? _hoveredIndex;
  late final AnimationController _animController;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void didUpdateWidget(InteractiveWorkloadChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.teachers != widget.teachers) {
      _animController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  List<WorkloadCategory> _getCategories() {
    var low = 0;
    var med = 0;
    var high = 0;
    var vhigh = 0;

    for (final t in widget.teachers) {
      if (t.sumClass >= 10) {
        vhigh++;
      } else if (t.sumClass >= 6) {
        high++;
      } else if (t.sumClass >= 3) {
        med++;
      } else {
        low++;
      }
    }

    return [
      WorkloadCategory(
        name: 'Thấp',
        range: '0-2 lớp',
        count: low,
        color: AppColors.emeraldLight,
      ),
      WorkloadCategory(
        name: 'T.Bình',
        range: '3-5 lớp',
        count: med,
        color: AppColors.sky,
      ),
      WorkloadCategory(
        name: 'Cao',
        range: '6-9 lớp',
        count: high,
        color: AppColors.amber,
      ),
      WorkloadCategory(
        name: 'Rất cao',
        range: '10+ lớp',
        count: vhigh,
        color: AppColors.coral,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final categories = _getCategories();
    final total = widget.teachers.isEmpty ? 1 : widget.teachers.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.lineColor),
        boxShadow: context.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with Chart Type switcher
          Row(
            children: [
              Expanded(
                child: const SectionHeader(
                  title: 'Phân bố khối lượng',
                  subtitle: 'Biểu đồ trực quan cơ cấu giảng dạy',
                  icon: Icons.pie_chart_outline_rounded,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: context.softFill,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.lineColor),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TypeButton(
                      icon: Icons.donut_large_rounded,
                      tooltip: 'Biểu đồ Tròn',
                      selected: _chartType == ChartType.donut,
                      onTap: () {
                        setState(() => _chartType = ChartType.donut);
                        _animController.forward(from: 0);
                      },
                    ),
                    _TypeButton(
                      icon: Icons.bar_chart_rounded,
                      tooltip: 'Biểu đồ Cột',
                      selected: _chartType == ChartType.bar,
                      onTap: () {
                        setState(() => _chartType = ChartType.bar);
                        _animController.forward(from: 0);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Main Interactive Chart Canvas
          AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              if (_chartType == ChartType.donut) {
                return _buildDonutView(categories, total);
              } else {
                return _buildBarView(categories, total);
              }
            },
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: categories.asMap().entries.map((entry) {
              final idx = entry.key;
              final cat = entry.value;
              final percent = widget.teachers.isEmpty
                  ? 0
                  : ((cat.count / total) * 100).round();
              final isHovered = _hoveredIndex == idx;

              return InkWell(
                onTap: () {
                  setState(() {
                    _hoveredIndex = _hoveredIndex == idx ? null : idx;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isHovered
                        ? cat.color.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: cat.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${cat.name}: ',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${cat.count} ($percent%)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: cat.color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutView(List<WorkloadCategory> categories, int total) {
    final activeCat =
        _hoveredIndex != null ? categories[_hoveredIndex!] : null;

    return Center(
      child: SizedBox(
        width: 190,
        height: 190,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(190, 190),
              painter: _DonutChartPainter(
                categories: categories,
                total: total,
                progress: _animation.value,
                hoveredIndex: _hoveredIndex,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  activeCat != null
                      ? '${activeCat.count}'
                      : '${widget.teachers.length}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  activeCat != null ? activeCat.name : 'Giảng viên',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: activeCat?.color ?? context.mutedColor,
                  ),
                ),
                if (activeCat != null)
                  Text(
                    activeCat.range,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: context.mutedColor,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarView(List<WorkloadCategory> categories, int total) {
    final maxCount = categories.map((c) => c.count).fold<int>(
      1,
      (prev, el) => math.max(prev, el),
    );

    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: categories.asMap().entries.map((entry) {
          final idx = entry.key;
          final cat = entry.value;
          final targetHeight = maxCount == 0
              ? 0.0
              : (cat.count / maxCount) * 120.0 * _animation.value;
          final isHovered = _hoveredIndex == idx;

          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _hoveredIndex = _hoveredIndex == idx ? null : idx;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${cat.count}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: cat.color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 38,
                    height: math.max(6.0, targetHeight),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          cat.color,
                          Color.lerp(cat.color, Colors.white, 0.3)!,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                      boxShadow: isHovered
                          ? [
                              BoxShadow(
                                color: cat.color.withValues(alpha: 0.5),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cat.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isHovered ? cat.color : null,
                    ),
                  ),
                  Text(
                    cat.range,
                    style: TextStyle(
                      fontSize: 10,
                      color: context.mutedColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: selected
            ? Theme.of(context).colorScheme.primary
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              icon,
              size: 17,
              color: selected ? Colors.white : context.mutedColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter({
    required this.categories,
    required this.total,
    required this.progress,
    required this.hoveredIndex,
  });

  final List<WorkloadCategory> categories;
  final int total;
  final double progress;
  final int? hoveredIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 24.0;
    final totalAngles = 2 * math.pi * progress;

    var startAngle = -math.pi / 2;

    for (var i = 0; i < categories.length; i++) {
      final cat = categories[i];
      if (cat.count == 0) continue;

      final sweepAngle = (cat.count / total) * totalAngles;
      final isHovered = hoveredIndex == i;

      final paint = Paint()
        ..color = cat.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHovered ? strokeWidth + 6 : strokeWidth
        ..strokeCap = StrokeCap.round;

      final arcRadius = isHovered ? radius - strokeWidth / 2 + 3 : radius - strokeWidth / 2;
      final rect = Rect.fromCircle(center: center, radius: arcRadius);

      // Thêm khoảng cách nhỏ giữa các cung
      const gap = 0.05;
      final effectiveSweep = math.max(0.01, sweepAngle - gap);

      canvas.drawArc(rect, startAngle + gap / 2, effectiveSweep, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(_DonutChartPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.hoveredIndex != hoveredIndex ||
      oldDelegate.categories != categories;
}
