// Add these models to your Flutter app

class LocationAnalytics {
  final int totalUsers;
  final int activeLocationUsers;
  final int inactiveLocationUsers;
  final double locationSharingRate;
  final List<TopLocation> topLocations;
  final List<RecentActivity> recentActivities;
  final List<UserLocationStats> userLocationStats;

  LocationAnalytics({
    required this.totalUsers,
    required this.activeLocationUsers,
    required this.inactiveLocationUsers,
    required this.locationSharingRate,
    required this.topLocations,
    required this.recentActivities,
    required this.userLocationStats,
  });

  factory LocationAnalytics.fromJson(Map<String, dynamic> json) {
    return LocationAnalytics(
      totalUsers: json['total_users'] ?? 0,
      activeLocationUsers: json['active_location_users'] ?? 0,
      inactiveLocationUsers: json['inactive_location_users'] ?? 0,
      locationSharingRate: (json['location_sharing_rate'] ?? 0.0).toDouble(),
      topLocations: (json['top_locations'] as List? ?? [])
          .map((item) => TopLocation.fromJson(item))
          .toList(),
      recentActivities: (json['recent_activities'] as List? ?? [])
          .map((item) => RecentActivity.fromJson(item))
          .toList(),
      userLocationStats: (json['user_location_stats'] as List? ?? [])
          .map((item) => UserLocationStats.fromJson(item))
          .toList(),
    );
  }
}

class TopLocation {
  final double latitude;
  final double longitude;
  final int visitCount;

  TopLocation({
    required this.latitude,
    required this.longitude,
    required this.visitCount,
  });

  factory TopLocation.fromJson(Map<String, dynamic> json) {
    return TopLocation(
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      visitCount: json['visit_count'] ?? 0,
    );
  }
}

class RecentActivity {
  final String userEmail;
  final double latitude;
  final double longitude;
  final String activityName;
  final DateTime recordedAt;

  RecentActivity({
    required this.userEmail,
    required this.latitude,
    required this.longitude,
    required this.activityName,
    required this.recordedAt,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      userEmail: json['user_email'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      activityName: json['activity_name'] ?? '',
      recordedAt: DateTime.parse(json['recorded_at']),
    );
  }
}

class UserLocationStats {
  final String userId;
  final int totalLogs;
  final int uniqueLocations;
  final DateTime lastRecorded;
  final DateTime firstRecorded;

  UserLocationStats({
    required this.userId,
    required this.totalLogs,
    required this.uniqueLocations,
    required this.lastRecorded,
    required this.firstRecorded,
  });

  factory UserLocationStats.fromJson(Map<String, dynamic> json) {
    return UserLocationStats(
      userId: json['user_id'] ?? '',
      totalLogs: json['total_logs'] ?? 0,
      uniqueLocations: json['unique_locations'] ?? 0,
      lastRecorded: DateTime.parse(json['last_recorded']),
      firstRecorded: DateTime.parse(json['first_recorded']),
    );
  }
}
