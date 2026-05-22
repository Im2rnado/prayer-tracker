import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';
import '../../models/prayer_log_model.dart';

final childLogsProvider =
    StreamProvider.autoDispose.family<List<PrayerLogModel>, String>(
  (ref, childId) => ref.watch(databaseProvider).getChildLogs(childId),
);

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  Map<DateTime, List<PrayerLogModel>> _groupLogsByDate(
      List<PrayerLogModel> logs) {
    final Map<DateTime, List<PrayerLogModel>> grouped = {};
    for (final log in logs) {
      final date =
          DateTime(log.timestamp.year, log.timestamp.month, log.timestamp.day);
      grouped.putIfAbsent(date, () => []).add(log);
    }
    return grouped;
  }

  bool _isAllPrayersLogged(List<PrayerLogModel>? dailyLogs) {
    if (dailyLogs == null || dailyLogs.isEmpty) return false;
    final logged = dailyLogs.map((e) => e.prayerName).toSet();
    return logged.containsAll({'Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'});
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Prayer Calendar')),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('User not found'));

          final logsAsync = ref.watch(childLogsProvider(user.uid));

          return logsAsync.when(
            data: (logs) {
              final grouped = _groupLogsByDate(logs);
              final normSelected = DateTime(
                  _selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
              final selectedLogs = grouped[normSelected] ?? [];

              return Column(
                children: [
                  // Calendar
                  Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TableCalendar<PrayerLogModel>(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      onDaySelected: (sel, foc) {
                        setState(() {
                          _selectedDay = sel;
                          _focusedDay = foc;
                        });
                      },
                      calendarFormat: CalendarFormat.month,
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                      ),
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          final norm = DateTime(day.year, day.month, day.day);
                          final dailyLogs = grouped[norm];
                          if (_isAllPrayersLogged(dailyLogs)) {
                            return Container(
                              margin: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondary
                                    .withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: theme.colorScheme.secondary,
                                    width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            );
                          } else if (dailyLogs != null &&
                              dailyLogs.isNotEmpty) {
                            return Container(
                              margin: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.4),
                                    width: 1.5),
                              ),
                              child: Center(child: Text('${day.day}')),
                            );
                          }
                          return null;
                        },
                      ),
                    ),
                  ),

                  // Day summary header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('EEEE, d MMMM').format(_selectedDay!),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: selectedLogs.length == 5
                                ? Colors.green.withOpacity(0.1)
                                : theme.colorScheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${selectedLogs.length}/5 Prayers',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: selectedLogs.length == 5
                                  ? Colors.green
                                  : theme.colorScheme.primary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Log list
                  Expanded(
                    child: selectedLogs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.event_busy_rounded,
                                    size: 48, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text(
                                  'No prayers logged this day',
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemCount: selectedLogs.length,
                            itemBuilder: (context, i) {
                              final log = selectedLogs[i];
                              final isOnTime = log.status ==
                                      PrayerStatus.onTime ||
                                  log.status == PrayerStatus.onTimeJamaah;
                              final isJamaah =
                                  log.status == PrayerStatus.onTimeJamaah ||
                                      log.status == PrayerStatus.lateJamaah;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 6),
                                  leading: CircleAvatar(
                                    backgroundColor: isOnTime
                                        ? Colors.green.withOpacity(0.15)
                                        : Colors.orange.withOpacity(0.15),
                                    child: Icon(
                                      isOnTime
                                          ? Icons.check_circle_outline
                                          : Icons.access_time_rounded,
                                      color:
                                          isOnTime ? Colors.green : Colors.orange,
                                    ),
                                  ),
                                  title: Text(
                                    log.prayerName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  subtitle: Text(
                                    '${isOnTime ? "On Time" : "Late"}'
                                    '${isJamaah ? " • Jama\'ah" : ""}'
                                    ' • ${DateFormat.jm().format(log.timestamp)}',
                                    style:
                                        TextStyle(color: Colors.grey.shade600),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '+${log.pointsEarned} pts',
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
