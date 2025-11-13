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

  int _playingReminderDays = 7;
  int _interestedReminderDays = 14;
  final List<int> _optionsDays = [7, 14, 21, 30];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadSettings();
  }

  Future<void> _initializeNotifications() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Santiago'));

    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel gamesChannel = AndroidNotificationChannel(
      'games_channel',
      'Recordatorios de juegos',
      description: 'Canal para recordatorios de juegos',
      importance: Importance.max,
    );

    const AndroidNotificationChannel testChannel = AndroidNotificationChannel(
      'test_channel',
      'Pruebas',
      description: 'Canal para pruebas',
      importance: Importance.max,
    );

    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(gamesChannel);
    await androidPlugin?.createNotificationChannel(testChannel);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _listStyle = prefs.getString('listStyle') ?? 'Grid';
      _coverSize = prefs.getString('coverSize') ?? 'Medianas';
      _sortCriteria = prefs.getString('sortCriteria') ?? 'Nombre';
      _playingReminderDays = prefs.getInt('playingReminderDays') ?? 7;
      _interestedReminderDays = prefs.getInt('interestedReminderDays') ?? 14;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('listStyle', _listStyle);
    await prefs.setString('coverSize', _coverSize);
    await prefs.setString('sortCriteria', _sortCriteria);
    await prefs.setInt('playingReminderDays', _playingReminderDays);
    await prefs.setInt('interestedReminderDays', _interestedReminderDays);
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

  Future<void> _scheduleGameNotifications({bool testMode = false}) async {
    if (testMode) {
      debugPrint("--- INICIANDO PRUEBA DE RECORDATORIOS ---");
    } else {
      debugPrint("--- Programando recordatorios normales... ---");
    }

    await flutterLocalNotificationsPlugin.cancelAll();
    debugPrint("Notificaciones anteriores canceladas.");

    final box = Hive.box('juegosBox');
    final dynamic juegosList = box.get('juegos');

    if (juegosList == null || juegosList is! List || juegosList.isEmpty) {
      debugPrint("!!! ERROR: No se encontraron juegos en Hive ('juegos' vacío o nulo).");
      return;
    }

    final juegos = (juegosList as List)
        .map((item) => Game.fromMap(Map<String, dynamic>.from(item)))
        .toList();

    int id = 0;
    int programados = 0;

    for (var juego in juegos) {
      if (juego.estado == 'Playing' || juego.estado == 'Interested') {
        programados++;
        final isPlaying = juego.estado == 'Playing';
        final days = isPlaying ? _playingReminderDays : _interestedReminderDays;
        final message = isPlaying
            ? 'Sigue jugando ${juego.nombre}!'
            : 'Revisa ${juego.nombre}, estás interesado!';

        final scheduledTime = testMode
            ? tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10))
            : tz.TZDateTime.now(tz.local).add(Duration(days: days));

        if (scheduledTime.isAfter(tz.TZDateTime.now(tz.local))) {
          await flutterLocalNotificationsPlugin.zonedSchedule(
            id++,
            'Recordatorio de juego',
            message,
            scheduledTime,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'games_channel',
                'Recordatorios de juegos',
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
        }
      }
    }

    debugPrint("--- TOTAL PROGRAMADAS: $programados ---");
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Ajustes de visualización
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Ajustes de visualización",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text("Forma de la lista:"),
                    DropdownButton<String>(
                      value: _listStyle,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'Grid', child: Text('Cuadrícula')),
                        DropdownMenuItem(value: 'Lista', child: Text('Lista')),
                        DropdownMenuItem(value: 'Compacta', child: Text('Compacta')),
                      ],
                      onChanged: _onListStyleChanged,
                    ),
                    const SizedBox(height: 12),
                    const Text("Tamaño de las carátulas:"),
                    DropdownButton<String>(
                      value: _coverSize,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'Grandes', child: Text('Grandes')),
                        DropdownMenuItem(value: 'Medianas', child: Text('Medianas')),
                        DropdownMenuItem(value: 'Pequeñas', child: Text('Pequeñas')),
                      ],
                      onChanged: _onCoverSizeChanged,
                    ),
                    const SizedBox(height: 12),
                    const Text("Criterio de ordenamiento:"),
                    DropdownButton<String>(
                      value: _sortCriteria,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'Nombre', child: Text('Por nombre')),
                        DropdownMenuItem(
                            value: 'Fecha', child: Text('Por fecha de agregado')),
                        DropdownMenuItem(
                            value: 'Puntuación', child: Text('Por puntuación')),
                      ],
                      onChanged: _onSortCriteriaChanged,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Recordatorios
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Recordatorios de juegos",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text("Para juegos en 'Playing':"),
                    DropdownButton<int>(
                      value: _playingReminderDays,
                      isExpanded: true,
                      items: _optionsDays
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text('$e días'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _playingReminderDays = value);
                          _saveSettings();
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text("Para juegos en 'Interested':"),
                    DropdownButton<int>(
                      value: _interestedReminderDays,
                      isExpanded: true,
                      items: _optionsDays
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text('$e días'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _interestedReminderDays = value);
                          _saveSettings();
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () async {
                        if (await Permission.notification.isGranted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Programando recordatorios de prueba... ¡llegarán en 10 segundos!'),
                              duration: Duration(seconds: 3),
                            ),
                          );
                          await _scheduleGameNotifications(testMode: true);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Permiso de notificación no otorgado'),
                            ),
                          );
                        }
                      },
                      child: const Text("Probar recordatorios (10 seg)"),
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
}
