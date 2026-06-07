import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/enums/app_enums.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/admin_provider.dart';
import '../widgets/report_card.dart';
import 'package:souq_sudan/core/utils/helpers.dart';

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'البلاغات',
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'قيد المعالجة'),
              Tab(text: 'تم حلها'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ReportsTab(isResolved: false),
            _ReportsTab(isResolved: true),
          ],
        ),
      ),
    );
  }
}

class _ReportsTab extends ConsumerWidget {
  final bool isResolved;

  const _ReportsTab({required this.isResolved});

  Future<String?> _promptResolution(BuildContext context) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حل البلاغ'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          maxLength: 300,
          decoration: const InputDecoration(
            hintText: 'ملاحظة عن الإجراء المتخذ...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    final note = ctrl.text.trim();
    ctrl.dispose();
    if (ok != true || note.isEmpty) return null;
    return note;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(reportsProvider(isResolved));
    final currentUser = ref.watch(currentUserProvider).value;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(reportsProvider(isResolved)),
      child: reportsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(
          message: Helpers.friendlyError(e),
          onRetry: () => ref.invalidate(reportsProvider(isResolved)),
        ),
        data: (reports) {
          if (reports.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.flag_outlined,
              message: isResolved
                  ? 'لا توجد بلاغات محلولة'
                  : 'لا توجد بلاغات قيد المعالجة',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: reports.length,
            itemBuilder: (_, i) {
              final report = reports[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ReportCard(
                  report: report,
                  onViewItem: () {
                    if (report.type == ReportType.ad) {
                      context.push(
                          '/admin/ads/${report.reportedItemId}');
                    } else {
                      context.push(
                          '/admin/users/${report.reportedItemId}');
                    }
                  },
                  onResolve: currentUser == null
                      ? null
                      : () async {
                          final note = await _promptResolution(context);
                          if (note == null) return;
                          final ok = await ref
                              .read(adminNotifierProvider.notifier)
                              .resolveReport(
                                  report.id, currentUser.id, note);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  ok ? 'تم حل البلاغ' : 'تعذر حل البلاغ'),
                              backgroundColor:
                                  ok ? AppColors.success : AppColors.error,
                            ),
                          );
                        },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
