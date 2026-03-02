import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ReminderService {
  ReminderService._();
  static final ReminderService _i = ReminderService._();
  factory ReminderService() => _i;

  final _notifs = FlutterLocalNotificationsPlugin();
  bool _tzInited = false;

  static const _kId = 'reminder.lastId';
  static const _kAt = 'reminder.lastScheduledEpoch';     // actual scheduled time (after preAlert)
  static const _kTarget = 'reminder.targetWhenEpoch';    // the user-chosen target time

  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    print('\x1B[34m[REMINDER] init() - initializing notifications\x1B[0m');
    await _notifs.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) async {
        print('\x1B[34m[REMINDER] tapped notification payload=${resp.payload}\x1B[0m');
      },
    );

    // Android 13+: request POST_NOTIFICATIONS if available
    try {
      final androidImpl = _notifs.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final dyn = androidImpl as dynamic;
        await dyn.requestNotificationsPermission?.call();
        print('\x1B[34m[REMINDER] Android permission requested (if supported)\x1B[0m');
      }
    } catch (e) {
      print('\x1B[34m[REMINDER] Android permission call not available: $e\x1B[0m');
    }

    if (!_tzInited) {
      tz.initializeTimeZones();
      _tzInited = true;
      print('\x1B[34m[REMINDER] timezone initialized\x1B[0m');
    }
  }

  //  status helpers (for green bell) 
  Future<void> _saveScheduled(int id, DateTime scheduledAt, DateTime targetWhen) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kId, id);
    await p.setInt(_kAt, scheduledAt.millisecondsSinceEpoch);
    await p.setInt(_kTarget, targetWhen.millisecondsSinceEpoch);
  }

  Future<void> _clearSaved() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kId);
    await p.remove(_kAt);
    await p.remove(_kTarget);
  }

  /// Returns true if we still have a pending local notification in the future.
  Future<bool> hasUpcomingReminder() async {
    final p = await SharedPreferences.getInstance();
    final id = p.getInt(_kId);
    final atMs = p.getInt(_kAt);
    if (id == null || atMs == null) return false;

    final at = DateTime.fromMillisecondsSinceEpoch(atMs);
    if (at.isBefore(DateTime.now())) {
      await _clearSaved();
      return false;
    }

    final pending = await _notifs.pendingNotificationRequests();
    final stillPending = pending.any((r) => r.id == id);
    if (!stillPending) {
      await _clearSaved();
      return false;
    }
    return true;
  }

  Future<DateTime?> getTargetWhen() async {
    final p = await SharedPreferences.getInstance();
    final t = p.getInt(_kTarget);
    return t == null ? null : DateTime.fromMillisecondsSinceEpoch(t);
  }

  Future<void> cancelLastReminder() async {
    final p = await SharedPreferences.getInstance();
    final id = p.getInt(_kId);
    if (id != null) {
      print('\x1B[34m[REMINDER] cancelLastReminder id=$id\x1B[0m');
      await _notifs.cancel(id);
    }
    await _clearSaved();
  }

  //  scheduling 

  Future<void> scheduleLocalNotification({
    required DateTime when,
    Duration preAlert = Duration.zero,
    String title = 'Groceries reminder',
    String body = 'Time to check your shopping list.',
    String payload = 'open_shopping',
  }) async {
    // Compute schedule moment (inexact)
    var scheduled = when.subtract(preAlert);
    final floor = DateTime.now().add(const Duration(minutes: 1));
    if (scheduled.isBefore(floor)) scheduled = floor;

    // a stable id that differs for different scheduled times
    final id = scheduled.millisecondsSinceEpoch % 100000000;
    final tzWhen = tz.TZDateTime.from(scheduled, tz.local);

    const android = AndroidNotificationDetails(
      'shopping_reminders',
      'Shopping Reminders',
      channelDescription: 'Reminders to check your shopping list',
      importance: Importance.high,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    const details = NotificationDetails(android: android, iOS: ios);

    await _notifs.zonedSchedule(
      id,
      title,
      body,
      tzWhen,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );

    await _saveScheduled(id, scheduled, when);
  }

  /// Opens native add-to-calendar sheet.
  /// create a 1-minute event so it behaves like a one-time reminder.
  Future<void> openCalendarSheet({
    required DateTime start,
    Duration preAlert = Duration.zero, // iOS supports this via iosParams
    String title = 'Buy groceries',
    String description = 'Open the Shopping List in the app',
    String? location,
  }) async {
    final event = Event(
      title: title,
      description: description,
      location: location,
      startDate: start,
      endDate: start.add(const Duration(minutes: 1)), // one-minute event
      iosParams: IOSParams(reminder: preAlert == Duration.zero ? null : preAlert),
      androidParams: const AndroidParams(), // Android reminders depend on the calendar app
    );
    await Add2Calendar.addEvent2Cal(event);
  }

  /// Helper: do both (calendar sheet + local notification).
  Future<void> addCalendarAndNotify({
    required DateTime when,
    Duration preAlert = Duration.zero,
    String title = 'Buy groceries',
    String description = 'Check your Shopping List',
  }) async {
    await openCalendarSheet(
      start: when,
      preAlert: preAlert,
      title: title,
      description: description,
    );
    await scheduleLocalNotification(
      when: when,
      preAlert: preAlert,
      title: title,
      body: description,
    );
  }
}
