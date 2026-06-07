import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/enums/app_enums.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/entities/service_request_entity.dart';
import '../providers/service_requests_provider.dart';
import '../widgets/profession_meta.dart';

class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({super.key});

  @override
  ConsumerState<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends ConsumerState<RequestsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.8) {
        ref.read(requestsListProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: const CustomAppBar(
          title: 'طلبات الخدمات',
          bottom: TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'الطلبات المفتوحة'),
              Tab(text: 'طلباتي'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/create-request'),
          icon: const Icon(Icons.add),
          label: const Text('اطلب خدمة'),
        ),
        body: TabBarView(
          children: [
            _openRequestsTab(),
            _myRequestsTab(),
          ],
        ),
      ),
    );
  }

  Widget _openRequestsTab() {
    final state = ref.watch(requestsListProvider);
    if (state.isLoading && state.requests.isEmpty) return const LoadingWidget();
    if (state.error != null && state.requests.isEmpty) {
      return AppErrorWidget(
        message: state.error!,
        onRetry: () => ref.read(requestsListProvider.notifier).refresh(),
      );
    }
    if (state.requests.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.assignment_outlined,
        message: 'لا توجد طلبات مفتوحة حالياً',
      );
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(requestsListProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.requests.length + (state.hasMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i >= state.requests.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _RequestCard(request: state.requests[i]);
        },
      ),
    );
  }

  Widget _myRequestsTab() {
    final async = ref.watch(myRequestsProvider);
    return async.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => AppErrorWidget(message: Helpers.friendlyError(e)),
      data: (list) {
        if (list.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.assignment_outlined,
            message: 'لم تنشئ أي طلبات بعد',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: list.length,
          itemBuilder: (_, i) => _RequestCard(request: list[i], mine: true),
        );
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  final ServiceRequest request;
  final bool mine;
  const _RequestCard({required this.request, this.mine = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: () => context.push('/requests/${request.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(ProfessionMeta.iconFor(request.category),
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      request.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _statusChip(request.status.arabicLabel),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                request.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 2),
                  Text(request.city,
                      style: Theme.of(context).textTheme.labelSmall),
                  const Spacer(),
                  if (request.budget != null) ...[
                    const Icon(Icons.payments_outlined,
                        size: 14, color: AppColors.success),
                    const SizedBox(width: 2),
                    Text(Helpers.formatPrice(request.budget!),
                        style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                    const SizedBox(width: 10),
                  ],
                  const Icon(Icons.forum_outlined,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 2),
                  Text('${request.responseCount}',
                      style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
    );
  }
}
