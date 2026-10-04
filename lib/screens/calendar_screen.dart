import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:googleapis_auth/auth_io.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pet_track/components/google_auth.dart';
import 'package:pet_track/core/app_colors.dart';
import 'package:pet_track/core/app_styles.dart';
import 'package:pet_track/models/pets_db.dart';
import 'package:pet_track/screens/add_calendar_task_screen.dart';
import 'package:pet_track/services/calendar_service.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime? _selectedDay;
  late final AuthService _authService;
  CalendarService? _calendarService;
  String? _petTrackCalendarId;
  Map<DateTime, List<gcal.Event>> _events = {};
  List<gcal.Event> _selectedEvents = [];
  bool _isLoadingEvents = true;

  Future<List<Map<String, dynamic>>>? _petsFuture;
  List<Map<String, dynamic>> _availablePets = [];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('en_GB', null);
    _selectedDay = _focusedDay;
    _authService = AuthService();
    _loadAllInitialData();
  }

  Future<void> _loadAllInitialData() async {
    try {
      _petsFuture = getPets();
      _availablePets = await _petsFuture!;
      if (kDebugMode) debugPrint('Pets loaded.');
    } catch (_) {
      if (!mounted) return;
      if (kDebugMode) debugPrint('Could not load pets.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load pets.'),
          backgroundColor: Colors.red,
        ),
      );
    }

    final AuthClient? client = await _authService.getAuthenticatedClient();
    if (!mounted) return;
    if (client != null) {
      _calendarService = CalendarService(client);
      _petTrackCalendarId = await _calendarService!.createPetTrackCalendar();
      if (!mounted) return;
      if (_petTrackCalendarId != null) {
        await _fetchEventsForVisibleRange(_focusedDay, _calendarFormat);
      } else {
        setState(() {
          _isLoadingEvents = false;
        });
        if (kDebugMode) debugPrint('Could not initialize the PetTrack calendar.');
      }
    } else {
      setState(() {
        _isLoadingEvents = false;
      });
      if (kDebugMode) debugPrint('No authenticated Calendar client available.');
    }
  }

  Future<void> _fetchEventsForVisibleRange(
    DateTime focusedDay,
    CalendarFormat format,
  ) async {
    if (_calendarService == null || _petTrackCalendarId == null) {
      setState(() {
        _isLoadingEvents = false;
        _events = {};
        _selectedEvents = [];
      });
      return;
    }

    setState(() {
      _isLoadingEvents = true;
      _events = {};
      _selectedEvents = [];
    });

    try {
      DateTime rangeStart;
      DateTime rangeEnd;

      if (format == CalendarFormat.month) {
        rangeStart = DateTime.utc(focusedDay.year, focusedDay.month, 1);
        rangeEnd = DateTime.utc(
          focusedDay.year,
          focusedDay.month + 1,
          0,
          23,
          59,
          59,
        );
      } else {
        rangeStart = focusedDay.subtract(
          Duration(days: focusedDay.weekday - 1),
        );
        rangeStart = DateTime.utc(
          rangeStart.year,
          rangeStart.month,
          rangeStart.day,
        );
        rangeEnd = rangeStart.add(Duration(days: 6));
        rangeEnd = DateTime.utc(
          rangeEnd.year,
          rangeEnd.month,
          rangeEnd.day,
          23,
          59,
          59,
        );
      }

      final fetchedEvents = await _calendarService!.getEvents(
        _petTrackCalendarId!,
        rangeStart,
        rangeEnd,
      );

      if (!mounted) return;
      final Map<DateTime, List<gcal.Event>> newEventsMap = {};
      for (var event in fetchedEvents) {
        final eventDay = DateTime.utc(
          (event.start?.dateTime ?? event.start?.date)?.year ?? 0,
          (event.start?.dateTime ?? event.start?.date)?.month ?? 0,
          (event.start?.dateTime ?? event.start?.date)?.day ?? 0,
        );
        if (eventDay.year != 0) {
          if (newEventsMap[eventDay] == null) {
            newEventsMap[eventDay] = [];
          }
          newEventsMap[eventDay]!.add(event);
        }
      }

      setState(() {
        _events = newEventsMap;
        _selectedEvents = _getEventsForDay(_selectedDay!);
        _isLoadingEvents = false;
      });
    } catch (_) {
      if (kDebugMode) debugPrint('Could not fetch calendar events.');
      if (mounted) {
        setState(() {
          _isLoadingEvents = false;
          _events = {};
          _selectedEvents = [];
        });
      }
    }
  }

  List<gcal.Event> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime.utc(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  String _getPetNamesFromIds(List<String> petIds) {
    if (petIds.isEmpty) return '';
    final names =
        petIds.map((id) {
          final pet = _availablePets.firstWhere(
            (p) => p['id'] == id,
            orElse: () => {'name': 'Unknown pet'},
          );
          return pet['name'] as String;
        }).toList();
    return names.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _calendarFormat == CalendarFormat.month
                            ? AppColors.primary
                            : AppColors.backgroundComponentHover,
                  ),
                  onPressed: () {
                    setState(() {
                      _calendarFormat = CalendarFormat.month;
                    });
                    _fetchEventsForVisibleRange(_focusedDay, _calendarFormat);
                  },
                  child: Text(
                    'Month',
                    style: AppTextStyles.midText(
                      context,
                    ).copyWith(color: Colors.white),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _calendarFormat == CalendarFormat.week
                            ? AppColors.primary
                            : AppColors.backgroundComponentHover,
                  ),
                  onPressed: () {
                    setState(() {
                      _calendarFormat = CalendarFormat.week;
                    });
                    _fetchEventsForVisibleRange(_focusedDay, _calendarFormat);
                  },
                  child: Text(
                    'Week',
                    style: AppTextStyles.midText(
                      context,
                    ).copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          TableCalendar(
            firstDay: DateTime.utc(2010, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            locale: 'en_GB',
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _selectedEvents = _getEventsForDay(selectedDay);
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              _fetchEventsForVisibleRange(focusedDay, _calendarFormat);
            },
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
            ),
            calendarFormat: _calendarFormat,
            startingDayOfWeek: StartingDayOfWeek.monday,
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: AppColors.primary, fontSize: 15),
              weekendStyle: TextStyle(
                color: AppColors.accent,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 2),
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(color: Colors.black),
              markerDecoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              markerSize: 5.0,
              markersAutoAligned: false,
              markersMaxCount: 1,
            ),
            eventLoader: _getEventsForDay,
          ),
          const Divider(),
          Expanded(
            child:
                _isLoadingEvents
                    ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    )
                    : _selectedEvents.isEmpty
                    ? Center(
                      child: Text(
                        'Nothing scheduled for this day.',
                        style: AppTextStyles.midText(
                          context,
                        ).copyWith(color: AppColors.black),
                      ),
                    )
                    : ListView.builder(
                      itemCount: _selectedEvents.length,
                      itemBuilder: (context, index) {
                        final event = _selectedEvents[index];
                        final eventStartTime =
                            event.start?.dateTime ?? event.start?.date;
                        final eventEndTime =
                            event.end?.dateTime ?? event.end?.date;

                        List<String> associatedPetIds = [];
                        String associatedPetNames = '';
                        if (event.extendedProperties?.private?['petIds'] !=
                            null) {
                          try {
                            final decoded = json.decode(
                              event.extendedProperties!.private!['petIds']!,
                            );
                            if (decoded is List) {
                              associatedPetIds = List<String>.from(
                                decoded.map((id) => id.toString()),
                              );
                              associatedPetNames = _getPetNamesFromIds(
                                associatedPetIds,
                              );
                            }
                          } catch (_) {
                            if (kDebugMode) debugPrint('Could not decode event pet identifiers.');
                          }
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          color: AppColors.backgroundComponent,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.summary ?? 'Untitled',
                                  style: AppTextStyles.midText(
                                    context,
                                  ).copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (event.description != null &&
                                    event.description!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      event.description!,
                                      style: AppTextStyles.midText(
                                        context,
                                      ).copyWith(color: AppColors.black),
                                    ),
                                  ),
                                if (eventStartTime != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      'Start: ${eventStartTime.toLocal().toString().substring(0, 16)}',
                                      style: AppTextStyles.tinyText(
                                        context,
                                      ).copyWith(color: AppColors.black),
                                    ),
                                  ),
                                if (eventEndTime != null &&
                                    eventStartTime != eventEndTime)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      'End: ${eventEndTime.toLocal().toString().substring(0, 16)}',
                                      style: AppTextStyles.tinyText(
                                        context,
                                      ).copyWith(color: AppColors.black),
                                    ),
                                  ),
                                if (event.location != null &&
                                    event.location!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      'Location: ${event.location!}',
                                      style: AppTextStyles.tinyText(
                                        context,
                                      ).copyWith(color: AppColors.black),
                                    ),
                                  ),
                                if (associatedPetNames.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      'Pets: $associatedPetNames',
                                      style: AppTextStyles.tinyText(
                                        context,
                                      ).copyWith(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_calendarService == null || _petTrackCalendarId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Calendar service unavailable. Try again later.',
                ),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          final result = await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder:
                  (_, __, ___) => AddEditTaskScreen(
                    initialSelectedDay: _selectedDay,
                    calendarService: _calendarService!,
                    petTrackCalendarId: _petTrackCalendarId!,
                    availablePets: _availablePets,
                  ),
              transitionsBuilder: (_, animation, __, child) {
                final offsetAnimation = Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(animation);
                return SlideTransition(position: offsetAnimation, child: child);
              },
            ),
          );

          if (!mounted) return;
          if (result == true) {
            _fetchEventsForVisibleRange(_focusedDay, _calendarFormat);
          }
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppColors.gradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: screenHeight * 0.08,
            height: screenHeight * 0.08,
            alignment: Alignment.center,
            child: const Icon(Icons.add, color: Colors.white, size: 32),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
