import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:googleapis_auth/auth_io.dart';

class CalendarService {
  final AuthClient _client;
  late final gcal.CalendarApi _calendarApi;

  CalendarService(this._client) {
    _calendarApi = gcal.CalendarApi(_client);
  }

  /// Reuses a calendar named PetTrack or creates one in Europe/Madrid.
  /// The supplied authenticated client remains owned by the caller.
  Future<String?> createPetTrackCalendar() async {
    try {
      final calendarList = await _calendarApi.calendarList.list();
      final List<gcal.CalendarListEntry> userCalendars =
          calendarList.items ?? [];
      gcal.CalendarListEntry? petTrackCalendar;
      for (var cal in userCalendars) {
        if (cal.summary != null &&
            cal.summary!.trim().toLowerCase() == 'pettrack') {
          petTrackCalendar = cal;
          break;
        }
      }

      if (petTrackCalendar != null && petTrackCalendar.id != null) {
        if (kDebugMode) debugPrint('PetTrack calendar found.');
        return petTrackCalendar.id;
      } else {
        final newCalendar =
            gcal.Calendar()
              ..summary = 'PetTrack'
              ..description =
                  'Calendar for pet-related events in PetTrack.'
              ..timeZone = 'Europe/Madrid';

        final createdCalendar = await _calendarApi.calendars.insert(
          newCalendar,
        );
        if (createdCalendar.id != null) {
          if (kDebugMode) debugPrint('PetTrack calendar created.');
          return createdCalendar.id;
        } else {
          if (kDebugMode) debugPrint('Calendar creation returned no ID.');
          return null;
        }
      }
    } catch (_) {
      if (kDebugMode) debugPrint('Calendar initialization failed.');
      return null;
    }
  }

  Future<List<gcal.Event>> getEvents(
    String calendarId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final events = await _calendarApi.events.list(
        calendarId,
        timeMin: startDate.toUtc(),
        timeMax: endDate.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
      );
      return events.items ?? [];
    } catch (_) {
      if (kDebugMode) debugPrint('Could not fetch calendar events.');
      return [];
    }
  }

  Future<gcal.Event?> createEvent(String calendarId, gcal.Event event) async {
    try {
      final createdEvent = await _calendarApi.events.insert(
        event,
        calendarId,
      );
      return createdEvent;
    } catch (_) {
      if (kDebugMode) debugPrint('Could not create calendar event.');
      return null;
    }
  }
}
