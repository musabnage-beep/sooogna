import 'package:flutter/material.dart';

import '../../../../core/enums/app_enums.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../domain/entities/report_entity.dart';

class ReportCard extends StatelessWidget {
  final Report report;
  final VoidCallback? onResolve;
  final VoidCallback? onViewItem;

  const ReportCard({
    super.key,
    required this.report,
    this.onResolve,
    this.onViewItem,
  });

  @override
  Widget build(BuildContext context) {
    final typeLabel = report.type == ReportType.ad ? 'إعلان' : 'مستخدم';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    typeLabel,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (report.isResolved)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'تم الحل',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const Spacer(),
                Text(
                  Helpers.timeAgo(report.createdAt),
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'بلّغ: ${report.reporterName}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              report.reason,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (report.adminNote != null &&
                report.adminNote!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ملاحظة الإدارة:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      report.adminNote!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
            if (onViewItem != null || onResolve != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (onViewItem != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('عرض'),
                        onPressed: onViewItem,
                      ),
                    ),
                  if (onViewItem != null && onResolve != null)
                    const SizedBox(width: 8),
                  if (onResolve != null && !report.isResolved)
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('حل البلاغ'),
                        onPressed: onResolve,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
