import '../../domain/entities/analytics_summary.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../datasources/analytics_remote_datasource.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final AnalyticsRemoteDataSource _remote;

  AnalyticsRepositoryImpl(this._remote);

  @override
  Stream<AnalyticsSummary> watchSummary(String userId) =>
      _remote.watchSummary(userId);

  @override
  Future<void> bumpViews(String sellerId) => _safeBump(sellerId, 'totalViews');

  @override
  Future<void> bumpContacts(String sellerId) =>
      _safeBump(sellerId, 'totalContacts');

  @override
  Future<void> bumpSaved(String sellerId) => _safeBump(sellerId, 'totalSaved');

  @override
  Future<void> bumpProfileVisits(String userId) =>
      _safeBump(userId, 'profileVisits');

  Future<void> _safeBump(String userId, String field) async {
    if (userId.isEmpty) return;
    try {
      await _remote.bump(userId, field);
    } catch (_) {
      // Analytics are non-critical; never surface failures to the caller.
    }
  }
}
