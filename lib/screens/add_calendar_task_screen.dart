import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:intl/intl.dart';
import 'package:pet_track/core/app_colors.dart';
import 'package:pet_track/core/app_styles.dart';
import 'package:pet_track/services/calendar_service.dart';

class AddEditTaskScreen extends StatefulWidget {
  final DateTime? initialSelectedDay;
  final CalendarService calendarService;
  final String petTrackCalendarId;
  final List<Map<String, dynamic>> availablePets;

  const AddEditTaskScreen({
    super.key,
    this.initialSelectedDay,
    required this.calendarService,
    required this.petTrackCalendarId,
    required this.availablePets,
  });

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  bool _isAllDay = false;

  CalendarService get _calendarService => widget.calendarService;
  String get _petTrackCalendarId => widget.petTrackCalendarId;

  final List<String> _selectedPetIds = [];

  @override
  void initState() {
    super.initState();

    _selectedDate = widget.initialSelectedDay ?? DateTime.now();
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    _selectedStartTime = TimeOfDay.now();
    _selectedEndTime = TimeOfDay.fromDateTime(
      DateTime.now().add(const Duration(hours: 1)),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedStartTime != null && _startTimeController.text.isEmpty) {
      _startTimeController.text = _selectedStartTime!.format(context);
    }
    if (_selectedEndTime != null &&
        _endTimeController.text.isEmpty &&
        !_isAllDay) {
      _endTimeController.text = _selectedEndTime!.format(context);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
          child: child!,
        );
      },
    );
    if (!mounted || !context.mounted) return;
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? (_selectedStartTime ?? TimeOfDay.now())
          : (_selectedEndTime ?? TimeOfDay.now()),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
          child: child!,
        );
      },
    );
    if (!mounted || !context.mounted) return;
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _selectedStartTime = picked;
          _startTimeController.text = _selectedStartTime!.format(context);
        } else {
          _selectedEndTime = picked;
          _endTimeController.text = _selectedEndTime!.format(context);
        }
      });
    }
  }

  Future<void> _saveTask() async {
    if (_petTrackCalendarId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Calendar ID unavailable.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The task title cannot be empty.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a date for the task.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    gcal.Event newEvent = gcal.Event();
    newEvent.summary = _titleController.text.trim();
    newEvent.description = _descriptionController.text.trim();

    if (_isAllDay) {
      newEvent.start = gcal.EventDateTime(date: _selectedDate);
      // Google Calendar treats an all-day event end date as exclusive.
      newEvent.end = gcal.EventDateTime(
        date: _selectedDate!.add(const Duration(days: 1)),
      );
    } else {
      if (_selectedStartTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Select a start time for the task.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      DateTime startDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedStartTime!.hour,
        _selectedStartTime!.minute,
      );

      DateTime endDateTime;
      if (_selectedEndTime != null) {
        endDateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedEndTime!.hour,
          _selectedEndTime!.minute,
        );
        if (endDateTime.isBefore(startDateTime)) {
          endDateTime = endDateTime.add(const Duration(days: 1));
        }
      } else {
        endDateTime = startDateTime.add(const Duration(hours: 1));
      }

      newEvent.start = gcal.EventDateTime(dateTime: startDateTime.toUtc());
      // Google Calendar treats an all-day event end date as exclusive.
      newEvent.end = gcal.EventDateTime(dateTime: endDateTime.toUtc());
    }

    if (_selectedPetIds.isNotEmpty) {
      newEvent.extendedProperties = gcal.EventExtendedProperties(
        private: {
          'petIds': json.encode(
            _selectedPetIds,
          ),
        },
      );
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(color: AppColors.accent),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                'Adding task...',
                style: AppTextStyles.midText(context),
              ),
            ),
          ],
        ),
      ),
    );

    try {
      gcal.Event? resultEvent;
      resultEvent = await _calendarService.createEvent(
        _petTrackCalendarId,
        newEvent,
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (resultEvent != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Task "${resultEvent.summary}" added successfully.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save the task.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      if (kDebugMode) debugPrint('Could not save calendar task.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save the task.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final inputDecorationTheme = theme.inputDecorationTheme.copyWith(
      labelStyle: const TextStyle(color: AppColors.primary),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.primary),
      ),
    );

    return Theme(
      data: theme.copyWith(
        inputDecorationTheme: inputDecorationTheme,
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: AppColors.primary,
          selectionColor: AppColors.primary.withAlpha((255 * 0.4).toInt()),
          selectionHandleColor: AppColors.primary,
        ),
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: Text(
            'Add task',
            style: AppTextStyles.titleText(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(screenHeight * 0.008),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Task title',
                  ),
                ),
                SizedBox(height: screenHeight * 0.008),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                  ),
                  maxLines: 3,
                  keyboardType: TextInputType.multiline,
                ),
                SizedBox(height: screenHeight * 0.025),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: AbsorbPointer(
                    child: TextField(
                      controller: _dateController,
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        suffixIcon: Icon(
                          Icons.calendar_today,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.0125),
                Row(
                  children: [
                    Text('All day:', style: AppTextStyles.midText(context)),
                    const Spacer(),
                    Switch(
                      value: _isAllDay,
                      onChanged: (value) {
                        setState(() {
                          _isAllDay = value;
                          if (_isAllDay) {
                            _selectedStartTime = null;
                            _selectedEndTime = null;
                            _startTimeController.clear();
                            _endTimeController.clear();
                          } else {
                            _selectedStartTime = TimeOfDay.now();
                            _selectedEndTime = TimeOfDay.fromDateTime(
                              DateTime.now().add(const Duration(hours: 1)),
                            );
                            _startTimeController.text =
                                _selectedStartTime!.format(context);
                            _endTimeController.text =
                                _selectedEndTime!.format(context);
                          }
                        });
                      },
                      activeColor: AppColors.primary,
                      inactiveTrackColor: AppColors.backgroundComponent,
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.0125),
                if (!_isAllDay) ...[
                  GestureDetector(
                    onTap: () => _selectTime(context, true),
                    child: AbsorbPointer(
                      child: TextField(
                        controller: _startTimeController,
                        decoration: const InputDecoration(
                          labelText: 'Start time',
                          suffixIcon: Icon(
                            Icons.access_time,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.008),
                  GestureDetector(
                    onTap: () => _selectTime(context, false),
                    child: AbsorbPointer(
                      child: TextField(
                        controller: _endTimeController,
                        decoration: const InputDecoration(
                          labelText: 'End time',
                          suffixIcon: Icon(
                            Icons.access_time,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                ],
                Text(
                  'Associated pets:',
                  style: AppTextStyles.midText(context),
                ),
                SizedBox(height: screenHeight * 0.0125),
                widget.availablePets.isEmpty
                    ? Text(
                        'No pets available.',
                        style: AppTextStyles.tinyText(
                          context,
                        ).copyWith(color: AppColors.black),
                      )
                    : Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: widget.availablePets.map((pet) {
                          final petId = pet['id'] as String;
                          final petName = pet['name'] as String;
                          final isSelected = _selectedPetIds.contains(petId);

                          return FilterChip(
                            label: Text(petName),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedPetIds.add(petId);
                                } else {
                                  _selectedPetIds.remove(petId);
                                }
                              });
                            },
                            selectedColor: AppColors.primary,
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                            backgroundColor: AppColors.backgroundComponent,
                          );
                        }).toList(),
                      ),
                SizedBox(height: screenHeight * 0.02),
                Material(
                  borderRadius: BorderRadius.circular(screenHeight * 0.015),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: AppColors.gradient,
                      borderRadius:
                          BorderRadius.circular(screenHeight * 0.015),
                    ),
                    child: InkWell(
                      borderRadius:
                          BorderRadius.circular(screenHeight * 0.015),
                      onTap: _saveTask,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.02,
                        ),
                        child: Center(
                          child: Text(
                            'Add task',
                            style: AppTextStyles.bigText(context).copyWith(
                              color: Colors.white,
                              fontSize: screenHeight * 0.03,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
