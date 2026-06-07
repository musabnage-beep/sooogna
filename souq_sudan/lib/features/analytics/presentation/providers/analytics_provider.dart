import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/analytics_remote_datasource.dart';
import '../../data/repositories/analytics_repository_impl.dart';
import '../../domain/entities/analytics_summary.dart';
import '../../domain/repositories/analytics_repository.dart';

final analyticsRemoteDataSourceProvider =
    Provider<AnalyticsRemoteDataSource>((ref) {
  return AnalyticsRemoteDataSource(firestore: ref.watch(firestoreProvider));
});

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepositoryImpl(
      ref.watch(analyticsRemoteDataSourceProvider));
});

/// Live analytics summary for the signed-in seller.
final myAnalyticsProvider = StreamProvider<AnalyticsSummary>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value(AnalyticsSummary.empty);
  return ref.watch(analyticsRepositoryProvider).watchSummary(user.id);
});
