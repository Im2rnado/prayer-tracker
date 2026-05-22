import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/database_provider.dart';
import '../../../models/prayer_log_model.dart';
import '../../../models/rules_model.dart';
import '../../../services/prayer_api_service.dart';

// ── State for today's prayer times ───────────────────────────────────────────
final prayerTimingsProvider = FutureProvider<PrayerTimings>((ref) {
  return ref.read(prayerApiServiceProvider).fetchPrayerTimes();
});

class LogPrayerScreen extends ConsumerStatefulWidget {
  const LogPrayerScreen({super.key});

  @override
  ConsumerState<LogPrayerScreen> createState() => _LogPrayerScreenState();
}

class _LogPrayerScreenState extends ConsumerState<LogPrayerScreen>
    with TickerProviderStateMixin {
  String _selectedPrayer = 'Fajr';
  bool _isJamaah = false;
  bool _isSubmitting = false;

  static const _prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  static const _prayerIcons = {
    'Fajr': Icons.wb_twilight_rounded,
    'Dhuhr': Icons.wb_sunny_rounded,
    'Asr': Icons.cloud_rounded,
    'Maghrib': Icons.wb_twilight_rounded,
    'Isha': Icons.nightlight_round,
  };

  /// Determines PrayerStatus from on-time flag + jama'ah toggle
  PrayerStatus _resolveStatus(bool onTime, bool jamaah) {
    if (onTime && jamaah) return PrayerStatus.onTimeJamaah;
    if (onTime && !jamaah) return PrayerStatus.onTime;
    if (!onTime && jamaah) return PrayerStatus.lateJamaah;
    return PrayerStatus.late;
  }

  /// Calculates points for a given status using guardian rules
  int _pointsForStatus(PrayerStatus status, RulesModel rules) {
    switch (status) {
      case PrayerStatus.onTime:
        return rules.onTimePoints;
      case PrayerStatus.late:
        return rules.latePoints;
      case PrayerStatus.onTimeJamaah:
        return rules.onTimeJamaahPoints;
      case PrayerStatus.lateJamaah:
        return rules.lateJamaahPoints;
    }
  }

  Future<void> _submitPrayer(PrayerTimings timings) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) throw Exception('User not found. Please log in again.');

      final logTime = DateTime.now();
      final db = ref.read(databaseProvider);

      // Determine on-time status
      final onTime = ref
          .read(prayerApiServiceProvider)
          .isOnTime(_selectedPrayer, logTime, timings);
      final status = _resolveStatus(onTime, _isJamaah);

      // Fetch rules from all linked guardians and average the points
      int totalPoints = 0;
      if (user.linkedGuardianIds.isEmpty) {
        // No guardian linked — use default rules
        final defaultRules = RulesModel(guardianId: '');
        totalPoints = _pointsForStatus(status, defaultRules);
      } else {
        final rulesList = await Future.wait(
          user.linkedGuardianIds.map((gId) => db.getRules(gId)),
        );
        final pointsList = rulesList
            .map((rules) => _pointsForStatus(status, rules))
            .toList();
        // Average across all guardians (rounded)
        totalPoints =
            (pointsList.reduce((a, b) => a + b) / pointsList.length).round();
      }

      final log = PrayerLogModel(
        id: const Uuid().v4(),
        childId: user.uid,
        prayerName: _selectedPrayer,
        method: _isJamaah ? "Jama'ah" : 'Single',
        timestamp: logTime,
        status: status,
        pointsEarned: totalPoints,
      );

      await db.addPrayerLog(log);

      if (mounted) {
        _showSuccessOverlay(totalPoints, status);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ));
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessOverlay(int points, PrayerStatus status) {
    final statusLabel = {
      PrayerStatus.onTime: 'On Time ✓',
      PrayerStatus.onTimeJamaah: "On Time + Jama'ah ✓✓",
      PrayerStatus.late: 'Late',
      PrayerStatus.lateJamaah: "Late + Jama'ah",
    }[status]!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SuccessDialog(points: points, statusLabel: statusLabel),
    ).then((_) {
      if (mounted) context.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final timingsAsync = ref.watch(prayerTimingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Log Prayer')),
      body: timingsAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Fetching prayer times…', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text('Could not fetch prayer times.\n$e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => ref.refresh(prayerTimingsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (timings) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Select Prayer',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your prayer will be timestamped at the moment you submit.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 24),

              // Prayer selector cards
              ...List.generate(_prayers.length, (i) {
                final prayer = _prayers[i];
                final selected = prayer == _selectedPrayer;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: selected
                          ? theme.colorScheme.primary
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: selected
                              ? theme.colorScheme.primary.withOpacity(0.3)
                              : Colors.black.withOpacity(0.04),
                          blurRadius: selected ? 12 : 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: () => setState(() => _selectedPrayer = prayer),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            Icon(
                              _prayerIcons[prayer],
                              color: selected ? Colors.white : theme.colorScheme.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                prayer,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: selected ? Colors.white : const Color(0xFF2D3748),
                                ),
                              ),
                            ),
                            if (selected)
                              const Icon(Icons.check_circle_rounded,
                                  color: Colors.white, size: 22),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 24),

              // Jama'ah toggle
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.people_rounded,
                          color: Colors.teal, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Prayed in Jama'ah",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isJamaah,
                      onChanged: (v) => setState(() => _isJamaah = v),
                      activeColor: Colors.teal,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Submit
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: theme.colorScheme.primary,
                ),
                onPressed: _isSubmitting ? null : () => _submitPrayer(timings),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'Submit ${_selectedPrayer}${_isJamaah ? " (Jama\'ah)" : ""}',
                        style: const TextStyle(fontSize: 18),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Success Dialog ────────────────────────────────────────────────────────────
class _SuccessDialog extends StatefulWidget {
  final int points;
  final String statusLabel;

  const _SuccessDialog({required this.points, required this.statusLabel});

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        contentPadding: const EdgeInsets.all(40),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF006B5F),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Prayer Logged!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(widget.statusLabel,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE2B93B).withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '+${widget.points} points',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE2B93B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
