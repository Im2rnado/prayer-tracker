import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';
import '../../models/prayer_log_model.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final childLogsForDashboardProvider =
    StreamProvider.autoDispose.family<List<PrayerLogModel>, String>(
  (ref, childId) => ref.watch(databaseProvider).getChildLogs(childId),
);

class ChildDashboard extends ConsumerWidget {
  const ChildDashboard({super.key});

  /// Calculates consecutive days where all 5 prayers were logged.
  int _calculateStreak(List<PrayerLogModel> logs) {
    if (logs.isEmpty) return 0;

    final Map<String, Set<String>> byDate = {};
    for (final log in logs) {
      final key = DateFormat('yyyy-MM-dd').format(log.timestamp);
      byDate.putIfAbsent(key, () => {}).add(log.prayerName);
    }

    const all5 = {'Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'};
    int streak = 0;
    DateTime day = DateTime.now();

    while (true) {
      final key = DateFormat('yyyy-MM-dd').format(day);
      final prayed = byDate[key] ?? {};
      if (prayed.containsAll(all5)) {
        streak++;
        day = day.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  /// Greeting based on time of day
  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('User not found'));

          final logsAsync =
              ref.watch(childLogsForDashboardProvider(user.uid));

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(currentUserProvider);
              ref.invalidate(childLogsForDashboardProvider(user.uid));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Hero card ─────────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withOpacity(0.75),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        Text(
                          '${_greeting()}, ${user.name.split(' ').first}!',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '${user.totalPoints}',
                          style: theme.textTheme.displayLarge?.copyWith(
                            color: const Color(0xFFE2B93B),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text('Total Points',
                            style: TextStyle(color: Colors.white70, fontSize: 16)),
                        const SizedBox(height: 20),

                        // Streak + Guardian count
                        logsAsync.when(
                          data: (logs) {
                            final streak = _calculateStreak(logs);
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _statChip(
                                    Icons.local_fire_department_rounded,
                                    '$streak',
                                    'Day Streak',
                                    Colors.orangeAccent),
                                _statChip(
                                    Icons.link_rounded,
                                    '${user.linkedGuardianIds.length}',
                                    'Guardians',
                                    Colors.lightBlueAccent),
                                _statChip(
                                    Icons.mosque_rounded,
                                    '${logs.where((l) => l.method == "Jama\'ah").length}',
                                    "Jama'ah",
                                    Colors.greenAccent),
                              ],
                            );
                          },
                          loading: () => const SizedBox(
                            height: 40,
                            child: Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white54),
                            ),
                          ),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  Text('Quick Actions',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  _buildActionCard(
                    context,
                    title: 'Log a Prayer',
                    subtitle: 'Record your prayer now',
                    icon: Icons.add_task_rounded,
                    color: theme.colorScheme.primary,
                    onTap: () => context.push('/child/log-prayer'),
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    context,
                    title: 'Rewards Store',
                    subtitle: 'Redeem your points',
                    icon: Icons.storefront_rounded,
                    color: const Color(0xFFE2B93B),
                    onTap: () => context.push('/child/rewards'),
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    context,
                    title: 'Prayer Calendar',
                    subtitle: 'View your history',
                    icon: Icons.calendar_month_rounded,
                    color: Colors.teal,
                    onTap: () => context.push('/child/calendar'),
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    context,
                    title: 'Link a Guardian',
                    subtitle: 'Enter an invite code',
                    icon: Icons.link_rounded,
                    color: Colors.blueGrey,
                    onTap: () => context.push('/shared/invite'),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }
}
