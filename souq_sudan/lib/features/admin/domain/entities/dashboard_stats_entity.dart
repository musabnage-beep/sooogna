class DashboardStats {
  final int totalUsers;
  final int totalAds;
  final int activeAds;
  final int pendingAds;
  final int unresolvedReports;
  final int adsPostedToday;

  const DashboardStats({
    required this.totalUsers,
    required this.totalAds,
    required this.activeAds,
    required this.pendingAds,
    required this.unresolvedReports,
    required this.adsPostedToday,
  });
}
