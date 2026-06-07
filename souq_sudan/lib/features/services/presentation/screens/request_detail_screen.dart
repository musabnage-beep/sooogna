import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/service_request_entity.dart';
import '../providers/service_requests_provider.dart';
import '../widgets/profession_meta.dart';

class RequestDetailScreen extends ConsumerWidget {
  final String requestId;
  const RequestDetailScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(requestByIdProvider(requestId));

    return Scaffold(
      appBar: const CustomAppBar(title: 'تفاصيل الطلب'),
      body: async.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(message: Helpers.friendlyError(e)),
        data: (request) {
          if (request == null) {
            return const Center(child: Text('لم يتم العثور على الطلب'));
          }
          return _Body(request: request);
        },
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  final ServiceRequest request;
  const _Body({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final isOwner = user != null && user.id == request.userId;
    final responsesAsync = ref.watch(requestResponsesProvider(request.id));

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(ProfessionMeta.iconFor(request.category),
                              color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(request.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(request.description),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 14,
                        runSpacing: 6,
                        children: [
                          _meta(Icons.person_outline, request.userName),
                          _meta(Icons.location_on_outlined, request.city),
                          _meta(Icons.category_outlined,
                              ProfessionMeta.nameFor(request.category)),
                          if (request.budget != null)
                            _meta(Icons.payments_outlined,
                                Helpers.formatPrice(request.budget!)),
                          _meta(Icons.flag_outlined, request.status.arabicLabel),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (isOwner && request.status != RequestStatus.closed)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      final ok = await ref
                          .read(requestActionProvider.notifier)
                          .setStatus(request.id, RequestStatus.closed.value);
                      if (ok && context.mounted) {
                        ref.invalidate(requestByIdProvider(request.id));
                      }
                    },
                    icon: const Icon(Icons.lock_outline),
                    label: const Text('إغلاق الطلب'),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('العروض (${request.responseCount})',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              responsesAsync.when(
                loading: () => const Padding(
                    padding: EdgeInsets.all(16), child: LoadingWidget()),
                error: (e, _) => AppErrorWidget(message: Helpers.friendlyError(e)),
                data: (responses) {
                  if (responses.isEmpty) {
                    return const EmptyStateWidget(
                      icon: Icons.forum_outlined,
                      message: 'لا توجد عروض بعد',
                    );
                  }
                  return Column(
                    children: responses.map((r) => _responseTile(context, r)).toList(),
                  );
                },
              ),
            ],
          ),
        ),
        if (!isOwner && request.status == RequestStatus.open)
          _RespondBar(requestId: request.id),
      ],
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _responseTile(BuildContext context, ServiceResponse r) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.background,
          child: r.providerImage != null
              ? ClipOval(
                  child: CachedImageWidget(
                      imageUrl: r.providerImage,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover))
              : const Icon(Icons.person, color: AppColors.primary),
        ),
        title: Text(r.providerName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(r.message),
        trailing: r.price != null
            ? Text(Helpers.formatPrice(r.price!),
                style: const TextStyle(
                    color: AppColors.success, fontWeight: FontWeight.bold))
            : null,
      ),
    );
  }
}

class _RespondBar extends ConsumerStatefulWidget {
  final String requestId;
  const _RespondBar({required this.requestId});

  @override
  ConsumerState<_RespondBar> createState() => _RespondBarState();
}

class _RespondBarState extends ConsumerState<_RespondBar> {
  final _msgCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  @override
  void dispose() {
    _msgCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final msg = _msgCtrl.text.trim();
    if (msg.isEmpty) return;
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    final response = ServiceResponse(
      id: '',
      providerId: user.id,
      providerName: user.name,
      providerImage: user.profileImage,
      message: msg,
      price: double.tryParse(_priceCtrl.text.trim()),
      createdAt: DateTime.now(),
    );
    final ok = await ref
        .read(requestActionProvider.notifier)
        .respond(widget.requestId, response);
    if (!mounted) return;
    if (ok) {
      _msgCtrl.clear();
      _priceCtrl.clear();
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تم إرسال عرضك'), backgroundColor: AppColors.success),
      );
    } else {
      final err = ref.read(requestActionProvider).error?.toString() ?? 'تعذر الإرسال';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sending = ref.watch(requestActionProvider).isLoading;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _msgCtrl,
                    maxLength: AppConstants.maxResponseMessageLength,
                    decoration: const InputDecoration(
                      hintText: 'اكتب عرضك...',
                      counterText: '',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'السعر',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send, color: AppColors.primary),
                  onPressed: sending ? null : _send,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
