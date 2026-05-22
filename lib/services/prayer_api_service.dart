import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'location_service.dart';

final prayerApiServiceProvider = Provider((ref) => PrayerApiService(ref));

/// Prayer names as returned by the Aladhan API
class PrayerTimings {
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final DateTime midnight;

  PrayerTimings({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.midnight,
  });
}

class PrayerApiService {
  final Ref ref;
  PrayerApiService(this.ref);

  /// Fetches today's prayer timings based on device location (Aladhan API, method 2 = ISNA).
  Future<PrayerTimings> fetchPrayerTimes() async {
    final position = await ref.read(locationServiceProvider).getCurrentPosition();
    final now = DateTime.now();
    final date = '${now.day}-${now.month}-${now.year}';
    final url = Uri.parse(
      'https://api.aladhan.com/v1/timings/$date'
      '?latitude=${position.latitude}'
      '&longitude=${position.longitude}'
      '&method=2',
    );

    final response = await http.get(url).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Failed to load prayer times (${response.statusCode})');
    }

    final data = json.decode(response.body);
    final timings = data['data']['timings'] as Map<String, dynamic>;
    return _parsePrayerTimings(timings);
  }

  PrayerTimings _parsePrayerTimings(Map<String, dynamic> timings) {
    return PrayerTimings(
      fajr: _parseTime(timings['Fajr'] as String),
      sunrise: _parseTime(timings['Sunrise'] as String),
      dhuhr: _parseTime(timings['Dhuhr'] as String),
      asr: _parseTime(timings['Asr'] as String),
      maghrib: _parseTime(timings['Maghrib'] as String),
      isha: _parseTime(timings['Isha'] as String),
      midnight: _parseMidnight(timings['Midnight'] as String),
    );
  }

  /// Parse "HH:MM" into a DateTime for today
  DateTime _parseTime(String timeStr) {
    final now = DateTime.now();
    // Strip timezone suffix if present (e.g. "05:30 (EET)")
    final cleaned = timeStr.split(' ').first;
    final parts = cleaned.split(':');
    return DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
  }

  /// Midnight can be after 00:00 next day — handle the crossing
  DateTime _parseMidnight(String timeStr) {
    final t = _parseTime(timeStr);
    // If midnight parsed is before noon, it's actually tomorrow's early hours
    if (t.hour < 12) {
      return t.add(const Duration(days: 1));
    }
    return t;
  }

  /// Determines if [logTime] falls within the waqt al-fadila (preferred time) window
  /// for [prayerName]. Windows are:
  ///   Fajr    → [Fajr, Sunrise) or custom buffer
  ///   Dhuhr   → [Dhuhr, Asr) or custom buffer
  ///   Asr     → [Asr, Maghrib) or custom buffer
  ///   Maghrib → [Maghrib, Isha) or custom buffer
  ///   Isha    → [Isha, Midnight) or custom buffer
  bool isOnTime(String prayerName, DateTime logTime, PrayerTimings timings, {int? customBufferMinutes}) {
    DateTime start;
    DateTime end;

    switch (prayerName) {
      case 'Fajr':
        start = timings.fajr;
        end = customBufferMinutes != null
            ? start.add(Duration(minutes: customBufferMinutes))
            : timings.sunrise;
        break;
      case 'Dhuhr':
        start = timings.dhuhr;
        end = customBufferMinutes != null
            ? start.add(Duration(minutes: customBufferMinutes))
            : timings.asr;
        break;
      case 'Asr':
        start = timings.asr;
        end = customBufferMinutes != null
            ? start.add(Duration(minutes: customBufferMinutes))
            : timings.maghrib;
        break;
      case 'Maghrib':
        start = timings.maghrib;
        end = customBufferMinutes != null
            ? start.add(Duration(minutes: customBufferMinutes))
            : timings.isha;
        break;
      case 'Isha':
        start = timings.isha;
        end = customBufferMinutes != null
            ? start.add(Duration(minutes: customBufferMinutes))
            : timings.midnight;
        break;
      default:
        return false;
    }

    return !logTime.isBefore(start) && logTime.isBefore(end);
  }
}
