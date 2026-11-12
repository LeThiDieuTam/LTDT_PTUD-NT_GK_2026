import 'package:flutter/material.dart';

import '../models/teacher.dart';
import '../services/teacher_exporter.dart';
import '../services/teacher_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/teacher_detail_sheet.dart';
import '../widgets/teacher_form_dialog.dart';
import '../widgets/interactive_workload_chart.dart';
import '../widgets/teacher_import_dialog.dart';

enum TeacherSort { idAsc, idDesc, nameAsc, classDesc, classAsc }

extension on TeacherSort {
  String get label => switch (this) {
    TeacherSort.idAsc => 'Mã A → Z',
    TeacherSort.idDesc => 'Mã Z → A',
    TeacherSort.nameAsc => 'Tên A → Z',
    TeacherSort.classDesc => 'Nhiều lớp nhất',
    TeacherSort.classAsc => 'Ít lớp nhất',
  };

  IconData get icon => switch (this) {
    TeacherSort.idAsc || TeacherSort.idDesc => Icons.badge_outlined,
    TeacherSort.nameAsc => Icons.sort_by_alpha_rounded,
    TeacherSort.classDesc => Icons.trending_up_rounded,
    TeacherSort.classAsc => Icons.trending_down_rounded,
  };

  int compare(Teacher a, Teacher b) => switch (this) {
    TeacherSort.idAsc => a.idgv.compareTo(b.idgv),
    TeacherSort.idDesc => b.idgv.compareTo(a.idgv),
    TeacherSort.nameAsc => a.fullname.compareTo(b.fullname),
    TeacherSort.classDesc => b.sumClass.compareTo(a.sumClass),
    TeacherSort.classAsc => a.sumClass.compareTo(b.sumClass),
  };
}

/// Màn hình quản trị chính: thống kê, tìm kiếm, lọc, sắp xếp, lưới/danh sách,
/// thêm/sửa/xóa, xuất CSV/JSON, đổi sáng/tối, đăng xuất.
class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({
    required this.service,
    this.onSignOut,
    this.userLabel,
    this.onToggleTheme,
    this.isDark = false,
    super.key,
  });

  final TeacherService service;
  final Future<void> Function()? onSignOut;
  final String? userLabel;
  final VoidCallback? onToggleTheme;
  final bool isDark;

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final _searchController = TextEditingController();
  String _query = '';
  TeacherSort _sort = TeacherSort.idAsc;
  bool _gridView = true;
  bool _onlyHighLoad = false;
  bool _seeding = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                error
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: error
                    ? const Color(0xFFFFB4AB)
                    : const Color(0xFF86EFAC),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  Future<void> _openForm([Teacher? teacher]) async {
    final result = await showDialog<TeacherFormResult>(
      context: context,
      builder: (context) => TeacherFormDialog(teacher: teacher),
    );
    if (result == null) return;
    try {
      await widget.service.save(
        result.teacher,
        result.imageBytes,
        isNew: teacher == null,
        imageMimeType: result.imageMimeType,
      );
      _showMessage(
        teacher == null
            ? 'Đã thêm giảng viên ${result.teacher.fullname}.'
            : 'Đã cập nhật giảng viên ${result.teacher.fullname}.',
      );
    } catch (error) {
      _showMessage('$error', error: true);
    }
  }

  Future<void> _openImport() async {
    final teachers = await showDialog<List<Teacher>>(
      context: context,
      builder: (context) => const TeacherImportDialog(),
    );
    if (teachers == null || teachers.isEmpty) return;
    try {
      final inserted = await widget.service.importBatch(teachers);
      _showMessage('Đã nạp thành công $inserted giảng viên vào CSDL.');
    } catch (error) {
      _showMessage('Lỗi khi nạp dữ liệu: $error', error: true);
    }
  }

  Future<void> _deleteTeacher(Teacher teacher) async {
    final confirmed = await showDeleteConfirmDialog(context, teacher);
    if (!confirmed) return;
    try {
      await widget.service.delete(teacher);
      _showMessage('Đã xóa giảng viên ${teacher.fullname}.');
    } catch (error) {
      _showMessage('$error', error: true);
    }
  }

  Future<void> _seed() async {
    setState(() => _seeding = true);
    try {
      final inserted = await widget.service.seedSampleData();
      _showMessage(
        inserted == 0
            ? 'Dữ liệu mẫu đã tồn tại, không có gì để thêm.'
            : 'Đã nạp $inserted giảng viên mẫu.',
      );
    } catch (error) {
      _showMessage('$error', error: true);
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text('Bạn sẽ cần đăng nhập lại để quản lý dữ liệu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ở lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (confirmed == true) await widget.onSignOut?.call();
  }

  List<Teacher> _applyFilters(List<Teacher> all) {
    final query = _query.trim().toLowerCase();
    final filtered = all.where((teacher) {
      final matchesQuery =
          query.isEmpty ||
          teacher.idgv.toLowerCase().contains(query) ||
          teacher.fullname.toLowerCase().contains(query);
      final matchesLoad = !_onlyHighLoad || teacher.sumClass >= 6;
      return matchesQuery && matchesLoad;
    }).toList()..sort(_sort.compare);
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuroraBackground(
        intensity: context.isDark ? 0.9 : 1.1,
        child: SafeArea(
          child: StreamBuilder<List<Teacher>>(
            stream: widget.service.watchAll(),
            builder: (context, snapshot) {
              final loading =
                  snapshot.connectionState == ConnectionState.waiting;
              final all = snapshot.data ?? const <Teacher>[];
              final teachers = _applyFilters(all);

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1240),
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        sliver: SliverToBoxAdapter(
                          child: _TopBar(
                            userLabel: widget.userLabel,
                            isDark: widget.isDark,
                            onToggleTheme: widget.onToggleTheme,
                            onSignOut: widget.onSignOut == null
                                ? null
                                : _confirmSignOut,
                            isDemo: !widget.service.useFirebase,
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        sliver: SliverToBoxAdapter(
                          child: _HeroBanner(
                            totalTeachers: all.length,
                            totalClasses: all.fold<int>(
                              0,
                              (sum, t) => sum + t.sumClass,
                            ),
                            onAdd: () => _openForm(),
                          ),
                        ),
                      ),
                      if (snapshot.hasError)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          sliver: SliverToBoxAdapter(
                            child: MessagePanel(
                              message:
                                  'Không tải được dữ liệu: ${snapshot.error}',
                              action: TextButton(
                                onPressed: () => setState(() {}),
                                child: const Text('Thử lại'),
                              ),
                            ),
                          ),
                        ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        sliver: SliverToBoxAdapter(
                          child: _StatsSection(teachers: all, loading: loading),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        sliver: SliverToBoxAdapter(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final wide = constraints.maxWidth > 900;
                              final leaderboard = LeaderboardCard(
                                teachers: all,
                                onSelect: (teacher) => _openDetail(teacher),
                              );
                              final distribution = InteractiveWorkloadChart(
                                teachers: all,
                              );
                              if (!wide) {
                                return Column(
                                  children: [
                                    leaderboard,
                                    const SizedBox(height: 16),
                                    distribution,
                                  ],
                                );
                              }
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: leaderboard),
                                  const SizedBox(width: 16),
                                  Expanded(child: distribution),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                        sliver: SliverToBoxAdapter(
                          child: _Toolbar(
                            controller: _searchController,
                            query: _query,
                            onQueryChanged: (value) =>
                                setState(() => _query = value),
                            sort: _sort,
                            onSortChanged: (value) =>
                                setState(() => _sort = value),
                            gridView: _gridView,
                            onViewChanged: (value) =>
                                setState(() => _gridView = value),
                            onlyHighLoad: _onlyHighLoad,
                            onHighLoadChanged: (value) =>
                                setState(() => _onlyHighLoad = value),
                            resultCount: teachers.length,
                            totalCount: all.length,
                            onAdd: () => _openForm(),
                            onImport: () => _openImport(),
                            onExportCsv: all.isEmpty
                                ? null
                                : () => TeacherExporter.saveCsv(
                                    context,
                                    teachers,
                                  ),
                            onExportJson: all.isEmpty
                                ? null
                                : () => TeacherExporter.saveJson(
                                    context,
                                    teachers,
                                  ),
                          ),
                        ),
                      ),
                      if (loading)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Padding(
                            padding: EdgeInsets.all(60),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        )
                      else if (teachers.isEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                          sliver: SliverToBoxAdapter(
                            child: _EmptyState(
                              hasQuery: _query.isNotEmpty || _onlyHighLoad,
                              onAdd: () => _openForm(),
                              onSeed: all.isEmpty ? _seed : null,
                              seeding: _seeding,
                            ),
                          ),
                        )
                      else if (_gridView)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                          sliver: SliverLayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.crossAxisExtent;
                              final columns = width > 1080
                                  ? 4
                                  : width > 820
                                  ? 3
                                  : width > 520
                                  ? 2
                                  : 1;
                              return SliverGrid(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: columns,
                                      mainAxisSpacing: 16,
                                      crossAxisSpacing: 16,
                                      mainAxisExtent: 236,
                                    ),
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final teacher = teachers[index];
                                  return TeacherGridCard(
                                    teacher: teacher,
                                    rank: _sort == TeacherSort.classDesc
                                        ? index + 1
                                        : null,
                                    onTap: () => _openDetail(teacher),
                                    onEdit: () => _openForm(teacher),
                                    onDelete: () => _deleteTeacher(teacher),
                                  );
                                }, childCount: teachers.length),
                              );
                            },
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                          sliver: SliverList.separated(
                            itemCount: teachers.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final teacher = teachers[index];
                              return TeacherListRow(
                                teacher: teacher,
                                rank: _sort == TeacherSort.classDesc
                                    ? index + 1
                                    : null,
                                onTap: () => _openDetail(teacher),
                                onEdit: () => _openForm(teacher),
                                onDelete: () => _deleteTeacher(teacher),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _openDetail(Teacher teacher) {
    showTeacherDetailSheet(
      context,
      teacher: teacher,
      onEdit: () => _openForm(teacher),
      onDelete: () => _deleteTeacher(teacher),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.userLabel,
    required this.isDark,
    required this.onToggleTheme,
    required this.onSignOut,
    required this.isDemo,
  });

  final String? userLabel;
  final bool isDark;
  final VoidCallback? onToggleTheme;
  final Future<void> Function()? onSignOut;
  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    final initial = (userLabel?.trim().isNotEmpty ?? false)
        ? userLabel!.trim()[0].toUpperCase()
        : 'A';
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: AppColors.emerald.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.school_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'QLHocPhan',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.2),
            ),
            Text(
              'Quản lý giảng viên',
              style: TextStyle(fontSize: 11.5, color: context.mutedColor),
            ),
          ],
        ),
        const Spacer(),
        if (isDemo)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.amber.withValues(alpha: 0.35),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.science_outlined,
                  size: 14,
                  color: Color(0xFFB45309),
                ),
                SizedBox(width: 5),
                Text(
                  'Chế độ demo',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
        if (onToggleTheme != null)
          IconButton(
            tooltip: isDark ? 'Chế độ sáng' : 'Chế độ tối',
            onPressed: onToggleTheme,
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 20,
            ),
          ),
        if (onSignOut != null)
          PopupMenuButton<String>(
            tooltip: 'Tài khoản',
            offset: const Offset(0, 46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (value) {
              if (value == 'signout') onSignOut!();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userLabel ?? 'Quản trị viên',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Quyền: Admin',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: context.mutedColor,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'signout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 18),
                    SizedBox(width: 10),
                    Text('Đăng xuất'),
                  ],
                ),
              ),
            ],
            child: Container(
              margin: const EdgeInsets.only(left: 4),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: context.lineColor),
              ),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.totalTeachers,
    required this.totalClasses,
    required this.onAdd,
  });

  final int totalTeachers;
  final int totalClasses;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald.withValues(alpha: 0.28),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -50,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            right: 60,
            bottom: -70,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.sky.withValues(alpha: 0.18),
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 640;
              final text = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          size: 14,
                          color: Color(0xFFB9F6CA),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Đồng bộ realtime',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Xin chào, Quản trị viên 👋',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: wide ? 26 : 21,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Hôm nay bạn đang quản lý $totalTeachers giảng viên '
                    'với tổng cộng $totalClasses lớp học phần.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13.5,
                      height: 1.5,
                    ),
                  ),
                ],
              );
              final button = FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.emeraldDeep,
                  minimumSize: const Size(0, 48),
                ),
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Thêm giảng viên'),
              );
              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [text, const SizedBox(height: 18), button],
                );
              }
              return Row(
                children: [
                  Expanded(child: text),
                  const SizedBox(width: 20),
                  button,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({required this.teachers, required this.loading});

  final List<Teacher> teachers;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final total = teachers.length;
    final totalClasses = teachers.fold<int>(0, (sum, t) => sum + t.sumClass);
    final average = total == 0 ? 0.0 : totalClasses / total;
    final top = teachers.isEmpty
        ? null
        : teachers.reduce((a, b) => a.sumClass >= b.sumClass ? a : b);

    final cards = [
      StatCard(
        label: 'Tổng giảng viên',
        value: loading ? '—' : '$total',
        icon: Icons.groups_rounded,
        colors: const [AppColors.emerald, AppColors.emeraldLight],
        caption: 'Collection GiangVien',
        trend: 'Realtime',
      ),
      StatCard(
        label: 'Tổng số lớp',
        value: loading ? '—' : '$totalClasses',
        icon: Icons.menu_book_rounded,
        colors: const [AppColors.sky, Color(0xFF6366F1)],
        caption: 'Tổng trường SumClass',
      ),
      StatCard(
        label: 'Lớp / giảng viên',
        value: loading ? '—' : average.toStringAsFixed(1),
        icon: Icons.balance_rounded,
        colors: const [AppColors.violet, Color(0xFFEC4899)],
        caption: 'Trung bình khối lượng',
      ),
      StatCard(
        label: 'Phụ trách nhiều nhất',
        value: loading ? '—' : '${top?.sumClass ?? 0}',
        icon: Icons.emoji_events_rounded,
        colors: const [AppColors.amber, AppColors.coral],
        caption: top?.fullname ?? 'Chưa có dữ liệu',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width > 1000
            ? 4
            : width > 700
            ? 2
            : 2;
        final spacing = 14.0;
        final itemWidth = (width - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final card in cards) SizedBox(width: itemWidth, child: card),
          ],
        );
      },
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.controller,
    required this.query,
    required this.onQueryChanged,
    required this.sort,
    required this.onSortChanged,
    required this.gridView,
    required this.onViewChanged,
    required this.onlyHighLoad,
    required this.onHighLoadChanged,
    required this.resultCount,
    required this.totalCount,
    required this.onAdd,
    required this.onImport,
    required this.onExportCsv,
    required this.onExportJson,
  });

  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final TeacherSort sort;
  final ValueChanged<TeacherSort> onSortChanged;
  final bool gridView;
  final ValueChanged<bool> onViewChanged;
  final bool onlyHighLoad;
  final ValueChanged<bool> onHighLoadChanged;
  final int resultCount;
  final int totalCount;
  final VoidCallback onAdd;
  final VoidCallback onImport;
  final VoidCallback? onExportCsv;
  final VoidCallback? onExportJson;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Danh sách giảng viên',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Hiển thị $resultCount / $totalCount giảng viên',
                    style: TextStyle(fontSize: 12.5, color: context.mutedColor),
                  ),
                ],
              ),
            ),
            _ViewToggle(gridView: gridView, onChanged: onViewChanged),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 760;
            final search = TextField(
              controller: controller,
              onChanged: onQueryChanged,
              decoration: InputDecoration(
                hintText: 'Tìm theo mã hoặc họ tên giảng viên...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Xóa tìm kiếm',
                        onPressed: () {
                          controller.clear();
                          onQueryChanged('');
                        },
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
                isDense: true,
              ),
            );
            final actions = Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SortMenu(sort: sort, onChanged: onSortChanged),
                PillButton(
                  label: 'Tải cao (≥6)',
                  icon: Icons.local_fire_department_outlined,
                  selected: onlyHighLoad,
                  onPressed: () => onHighLoadChanged(!onlyHighLoad),
                ),
                OutlinedButton.icon(
                  onPressed: onImport,
                  icon: const Icon(Icons.file_upload_outlined, size: 18),
                  label: const Text('Nhập CSV/JSON'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                  ),
                ),
                _ExportMenu(onCsv: onExportCsv, onJson: onExportJson),
                FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Thêm'),
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                ),
              ],
            );
            if (!wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [search, const SizedBox(height: 10), actions],
              );
            }
            return Row(
              children: [
                Expanded(child: search),
                const SizedBox(width: 10),
                actions,
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.gridView, required this.onChanged});

  final bool gridView;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.softFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.lineColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleIcon(
            icon: Icons.grid_view_rounded,
            tooltip: 'Xem dạng lưới',
            active: gridView,
            onTap: () => onChanged(true),
          ),
          _ToggleIcon(
            icon: Icons.view_list_rounded,
            tooltip: 'Xem dạng danh sách',
            active: !gridView,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _ToggleIcon extends StatelessWidget {
  const _ToggleIcon({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: active ? context.surfaceColor : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: active ? context.softShadow : null,
          ),
          child: Icon(
            icon,
            size: 18,
            color: active
                ? Theme.of(context).colorScheme.primary
                : context.mutedColor,
          ),
        ),
      ),
    );
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.sort, required this.onChanged});

  final TeacherSort sort;
  final ValueChanged<TeacherSort> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<TeacherSort>(
      tooltip: 'Sắp xếp',
      initialValue: sort,
      onSelected: onChanged,
      offset: const Offset(0, 46),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (context) => [
        for (final option in TeacherSort.values)
          PopupMenuItem(
            value: option,
            child: Row(
              children: [
                Icon(option.icon, size: 18),
                const SizedBox(width: 10),
                Text(option.label),
                if (option == sort) ...[
                  const Spacer(),
                  Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: context.lineColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(sort.icon, size: 16, color: context.mutedColor),
            const SizedBox(width: 6),
            Text(
              sort.label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.expand_more_rounded,
              size: 16,
              color: context.mutedColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportMenu extends StatelessWidget {
  const _ExportMenu({required this.onCsv, required this.onJson});

  final VoidCallback? onCsv;
  final VoidCallback? onJson;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Xuất dữ liệu',
      enabled: onCsv != null || onJson != null,
      offset: const Offset(0, 46),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (value) => value == 'csv' ? onCsv?.call() : onJson?.call(),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'csv',
          child: Row(
            children: [
              Icon(Icons.table_view_rounded, size: 18),
              SizedBox(width: 10),
              Text('Xuất CSV (Excel)'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'json',
          child: Row(
            children: [
              Icon(Icons.data_object_rounded, size: 18),
              SizedBox(width: 10),
              Text('Xuất JSON (nộp bài)'),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: context.lineColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.file_download_outlined,
              size: 16,
              color: context.mutedColor,
            ),
            const SizedBox(width: 6),
            const Text(
              'Xuất file',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.hasQuery,
    required this.onAdd,
    required this.onSeed,
    required this.seeding,
  });

  final bool hasQuery;
  final VoidCallback onAdd;
  final Future<void> Function()? onSeed;
  final bool seeding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 44),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.lineColor),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasQuery ? Icons.search_off_rounded : Icons.person_search_rounded,
              size: 34,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            hasQuery
                ? 'Không tìm thấy giảng viên phù hợp'
                : 'Chưa có giảng viên nào',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            hasQuery ? 'Thử từ khóa khác hoặc bỏ bộ lọc "Tải cao".' : 'Bắt đầu bằng cách thêm giảng viên đầu tiên hoặc nạp dữ liệu mẫu.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: context.mutedColor),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Thêm giảng viên'),
              ),
              if (onSeed != null)
                OutlinedButton.icon(
                  onPressed: seeding ? null : onSeed,
                  icon: seeding
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: const Text('Nạp dữ liệu mẫu'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
