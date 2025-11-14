import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'package:gpoint/models/game.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:gpoint/main.dart';
import 'package:permission_handler/permission_handler.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  String _listStyle = 'Grid';
  String _coverSize = 'Medianas';
  String _sortCriteria = 'Nombre';
  String _selectedYear = 'Todas';
  List<String> _availableYears = ['Todas'];

  bool _enableNotifications = true;
  int _playingReminderDays = 7;
  int _interestedReminderDays = 14;
  final List<int> _optionsDays = [7, 14, 21, 30];

  int _countdownSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadSettings();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('America/Santiago'));
    } catch (e) {
      tz.setLocalLocation(tz.UTC);
    }

    await Permission.notification.request();
    await Permission.scheduleExactAlarm.request();

    const AndroidNotificationChannel gamesChannel = AndroidNotificationChannel(
      'games_channel_v3',
      'Recordatorios de juegos',
      description: 'Notificaciones importantes de tus juegos',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(gamesChannel);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await _loadAvailableYears();

    setState(() {
      _listStyle = prefs.getString('listStyle') ?? 'Grid';
      _coverSize = prefs.getString('coverSize') ?? 'Medianas';
      _sortCriteria = prefs.getString('sortCriteria') ?? 'Nombre';
      _enableNotifications = prefs.getBool('enableNotifications') ?? true;
      _playingReminderDays = prefs.getInt('playingReminderDays') ?? 7;
      _interestedReminderDays = prefs.getInt('interestedReminderDays') ?? 14;
      _selectedYear = prefs.getString('selectedYear') ?? 'Todas';
    });
  }

  String? _extractYear(String? date) {
    if (date != null && date.length >= 10) {
      try {
        String year = date.substring(date.length - 4);
        if (int.tryParse(year) != null) {
          return year;
        }
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> _loadAvailableYears() async {
    final box = Hive.box('juegosBox');
    final dynamic juegosList = box.get('juegos');
    if (juegosList == null || juegosList is! List || juegosList.isEmpty) {
      return;
    }

    final juegos = (juegosList)
        .map((item) => Game.fromMap(Map<String, dynamic>.from(item)))
        .toList();

    final Set<String> years = {};
    for (var juego in juegos) {
      String? yearInicio = _extractYear(juego.fechaInicio);
      if (yearInicio != null) {
        years.add(yearInicio);
      }

      String? yearTermino = _extractYear(juego.fechaTermino);
      if (yearTermino != null) {
        years.add(yearTermino);
      }
    }

    setState(() {
      _availableYears = [
        'Todas',
        ...years.toList()..sort((a, b) => b.compareTo(a))
      ];
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('listStyle', _listStyle);
    await prefs.setString('coverSize', _coverSize);
    await prefs.setString('sortCriteria', _sortCriteria);
    await prefs.setBool('enableNotifications', _enableNotifications);
    await prefs.setInt('playingReminderDays', _playingReminderDays);
    await prefs.setInt('interestedReminderDays', _interestedReminderDays);
    await prefs.setString('selectedYear', _selectedYear);

    _scheduleGameNotifications();
  }

  void _onListStyleChanged(String? value) {
    if (value != null) {
      setState(() => _listStyle = value);
      _saveSettings();
    }
  }

  void _onCoverSizeChanged(String? value) {
    if (value != null) {
      setState(() => _coverSize = value);
      _saveSettings();
    }
  }

  void _onSortCriteriaChanged(String? value) {
    if (value != null) {
      setState(() => _sortCriteria = value);
      _saveSettings();
    }
  }

  void _onYearChanged(String? value) {
    if (value != null) {
      setState(() => _selectedYear = value);
      _saveSettings();
    }
  }

  void _startCountdown() {
    setState(() => _countdownSeconds = 10);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 0) {
        setState(() => _countdownSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _scheduleGameNotifications({bool testMode = false}) async {
    if (!_enableNotifications && !testMode) {
      await flutterLocalNotificationsPlugin.cancelAll();
      return;
    }

    bool canExact = await Permission.scheduleExactAlarm.isGranted;

    if (testMode) {
      if (!canExact) {
        await Permission.scheduleExactAlarm.request();
        canExact = await Permission.scheduleExactAlarm.isGranted;
        if (!canExact && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Habilita 'Alarmas y recordatorios' en Ajustes")));
          openAppSettings();
          return;
        }
      }
      _startCountdown();
    }

    await flutterLocalNotificationsPlugin.cancelAll();

    if (!_enableNotifications && !testMode) return;

    final box = Hive.box('juegosBox');
    final dynamic juegosList = box.get('juegos');
    if (juegosList == null || juegosList is! List || juegosList.isEmpty) {
      return;
    }

    final juegos = (juegosList)
        .map((item) => Game.fromMap(Map<String, dynamic>.from(item)))
        .toList();

    int id = 0;
    int count = 0;

    for (var juego in juegos) {
      if (juego.estado == 'Playing' || juego.estado == 'Interested') {
        count++;
        final isPlaying = juego.estado == 'Playing';
        final days = isPlaying ? _playingReminderDays : _interestedReminderDays;
        final msg =
            isPlaying ? 'Sigue jugando ${juego.nombre}' : 'Revisa ${juego.nombre}';

        final scheduledTime = testMode
            ? tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10))
            : tz.TZDateTime.now(tz.local).add(Duration(days: days));

        try {
          await flutterLocalNotificationsPlugin.zonedSchedule(
            id++,
            'Gamer Point',
            msg,
            scheduledTime,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'games_channel_v3',
                'Recordatorios de juegos',
                importance: Importance.max,
                priority: Priority.high,
                fullScreenIntent: true,
              ),
            ),
            androidScheduleMode: testMode
                ? AndroidScheduleMode.alarmClock
                : AndroidScheduleMode.exactAllowWhileIdle,
          );
        } catch (e) {
          debugPrint("Error programando: $e");
        }
      }
    }

    if (mounted && testMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Programadas $count notificaciones')),
      );
    }
  }

  Future<void> _testImmediateNotification() async {
    await flutterLocalNotificationsPlugin.show(
      9999,
      'Prueba Inmediata',
      'Si ves esto, las notificaciones funcionan.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'games_channel_v3',
          'Pruebas',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Configuración"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Ajustes de visualización",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildDropdown(
                        "Forma de la lista:",
                        _listStyle,
                        ['Grid', 'Lista', 'Compacta'],
                        ['Cuadrícula', 'Lista', 'Compacta'],
                        _onListStyleChanged),
                    const SizedBox(height: 12),
                    _buildDropdown(
                        "Tamaño de las carátulas:",
                        _coverSize,
                        ['Grandes', 'Medianas', 'Pequeñas'],
                        ['Grandes', 'Medianas', 'Pequeñas'],
                        _onCoverSizeChanged),
                    const SizedBox(height: 12),
                    _buildDropdown(
                        "Criterio de ordenamiento:",
                        _sortCriteria,
                        ['Nombre', 'Fecha', 'Puntuación'],
                        ['Nombre', 'Fecha de Inicio', 'Puntuación'],
                        _onSortCriteriaChanged),
                    const SizedBox(height: 12),
                    Text("Filtrar por año (Inicio/Término):"),
                    DropdownButton<String>(
                      value: _availableYears.contains(_selectedYear)
                          ? _selectedYear
                          : 'Todas',
                      isExpanded: true,
                      items: _availableYears
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: _onYearChanged,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Recordatorios de juegos",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Switch(
                          value: _enableNotifications,
                          onChanged: (value) {
                            setState(() {
                              _enableNotifications = value;
                            });
                            _saveSettings();
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    Opacity(
                      opacity: _enableNotifications ? 1.0 : 0.5,
                      child: IgnorePointer(
                        ignoring: !_enableNotifications,
                        child: Column(
                          children: [
                            _buildIntDropdown(
                                "Para juegos en 'Playing':",
                                _playingReminderDays,
                                _optionsDays, (val) {
                              if (val != null) {
                                setState(() => _playingReminderDays = val);
                                _saveSettings();
                              }
                            }),
                            const SizedBox(height: 12),
                            _buildIntDropdown(
                                "Para juegos en 'Interested':",
                                _interestedReminderDays,
                                _optionsDays, (val) {
                              if (val != null) {
                                setState(() => _interestedReminderDays = val);
                                _saveSettings();
                              }
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _testImmediateNotification,
                        child: const Text("Prueba Inmediata (Check)"),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _countdownSeconds > 0
                            ? null
                            : () async {
                                if (await Permission.notification
                                    .request()
                                    .isGranted) {
                                  await _scheduleGameNotifications(
                                      testMode: true);
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              "Falta permiso de notificación")),
                                    );
                                  }
                                }
                              },
                        child: Text(_countdownSeconds > 0
                            ? "Esperando... ($_countdownSeconds)"
                            : "Probar recordatorios (10 seg)"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items,
      List<String> labels, Function(String?) onChanged) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          DropdownButton<String>(
            value: value,
            isExpanded: true,
            items: List.generate(items.length, (index) {
              return DropdownMenuItem(
                value: items[index],
                child: Text(labels[index]),
              );
            }),
            onChanged: onChanged,
          )
        ]);
  }

  Widget _buildIntDropdown(
      String label, int value, List<int> items, Function(int?)? onChanged) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          DropdownButton<int>(
              value: value,
              isExpanded: true,
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text('$e días')))
                  .toList(),
              onChanged: onChanged)
        ]);
  }
}