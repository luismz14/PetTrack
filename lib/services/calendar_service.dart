import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:googleapis_auth/auth_io.dart';

// Aquest fixter conté la lògica per gestionar el servei de Google Calendar API.

class CalendarService {
  final AuthClient _client;
  late final gcal.CalendarApi _calendarApi;

  CalendarService(this._client) {
    _calendarApi = gcal.CalendarApi(_client);
  }

  // Crea el calendari "PetTrack" en cas de que aquest no existeixi a la llista de l'usuari, retornant en el seu ID.
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
        print(
          'El calendario "PetTrack" ya existe con ID: ${petTrackCalendar.id}',
        );
        return petTrackCalendar.id;
      } else {
        final newCalendar =
            gcal.Calendar()
              ..summary = 'PetTrack'
              ..description =
                  'Calendario para eventos relacionados con tus mascotas en PetTrack App.'
              ..timeZone = 'Europe/Madrid';

        final createdCalendar = await _calendarApi.calendars.insert(
          newCalendar,
        );
        if (createdCalendar.id != null) {
          print('Calendario "PetTrack" creado con ID: ${createdCalendar.id}');
          return createdCalendar.id;
        } else {
          print(
            'Error: El calendario "PetTrack" no se pudo crear o no devolvió un ID válido.',
          );
          return null;
        }
      }
    } catch (e) {
      print('Error en createPetTrackCalendar: $e');
      return null;
    }
  }

  // Retorna la llista d'events existents al calendari entre les dates pasades per paràmetre.
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
    } catch (e) {
      print('Error fetching events from $calendarId: $e');
      return [];
    }
  }

  // Afegeix un event al calendari pasat per paràmetre.
  Future<gcal.Event?> createEvent(String calendarId, gcal.Event event) async {
    try {
      final createdEvent = await _calendarApi.events.insert(
        event,
        calendarId,
      );
      return createdEvent;
    } catch (e) {
      print('Error creating event in $calendarId: $e');
      return null;
    }
  }
}
