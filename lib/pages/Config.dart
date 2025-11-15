import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:gpoint/models/game.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:gpoint/main.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
  bool _autoSyncEnabled = false;
  int _playingReminderDays = 7;
  int _interestedReminderDays = 14;
  final List<int> _optionsDays = [7, 14, 21, 30];

  int _countdownSeconds = 0;
  Timer? _timer;

  User? _user;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadSettings();
    _checkCurrentUser();
  }

  void _checkCurrentUser() {
    setState(() {
      _user = FirebaseAuth.instance.currentUser;
    });
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
      _autoSyncEnabled = prefs.getBool('autoSyncEnabled') ?? false;
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
    await prefs.setBool('autoSyncEnabled', _autoSyncEnabled);
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

  Future<void> _signInWithGoogle() async {
    setState(() => _isSyncing = true);

    try {
      // Usa el constructor simple para compatibilidad con la versión V5 o V6 antigua que instaló pub get
      final GoogleSignIn googleSignIn = GoogleSignIn(); 

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _isSyncing = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      setState(() {
        _user = userCredential.user;
        _isSyncing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Sesión iniciada como ${_user?.displayName ?? "Usuario"}')),
        );
      }
    } catch (e) {
      setState(() => _isSyncing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al iniciar sesión: $e')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();

    await FirebaseAuth.instance.signOut();
    await googleSignIn.signOut();

    setState(() => _user = null);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión cerrada')),
      );
    }
  }

  Future<void> _backupToCloud() async {
    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión primero')),
      );
      return;
    }
    setState(() => _isSyncing = true);

    try {
      final box = Hive.box('juegosBox');
      final dynamic juegosList = box.get('juegos');

      if (juegosList == null || juegosList is! List) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No hay datos locales para guardar.')));
        setState(() => _isSyncing = false);
        return;
      }

      final docRef = FirebaseFirestore.instance
          .collection('user_data')
          .doc(_user!.uid);

      await docRef.set({
        'games_backup': juegosList,
        'lastBackup': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Copia de seguridad guardada en la nube!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  Future<void> _restoreFromCloud() async {
    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión primero')),
      );
      return;
    }
    setState(() => _isSyncing = true);

    try {
      final docRef = FirebaseFirestore.instance
          .collection('user_data')
          .doc(_user!.uid);
      final docSnap = await docRef.get();

      if (!docSnap.exists || docSnap.data()?['games_backup'] == null) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No se encontró copia de seguridad.')));
        setState(() => _isSyncing = false);
        return;
      }

      final dynamic juegosList = docSnap.data()!['games_backup'];

      if (juegosList is! List) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Datos corruptos en la nube.')));
        setState(() => _isSyncing = false);
        return;
      }

      final box = Hive.box('juegosBox');
      await box.put('juegos', juegosList);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Datos restaurados desde la nube!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al restaurar: $e')),
        );
      }
    } finally {
      setState(() => _isSyncing = false);
    }
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Ajustes de visualización", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildDropdown("Forma de la lista:", _listStyle, ['Grid', 'Lista', 'Compacta'], ['Cuadrícula', 'Lista', 'Compacta'], _onListStyleChanged),
                    const SizedBox(height: 12),
                    _buildDropdown("Tamaño de las carátulas:", _coverSize, ['Grandes', 'Medianas', 'Pequeñas'], ['Grandes', 'Medianas', 'Pequeñas'], _onCoverSizeChanged),
                    const SizedBox(height: 12),
                    _buildDropdown("Criterio de ordenamiento:", _sortCriteria, ['Nombre', 'Fecha', 'Puntuación'], ['Nombre', 'Fecha agregado', 'Puntuación'], _onSortCriteriaChanged),
                    const SizedBox(height: 12),
                    Text("Filtrar por año de agregado:"),
                    DropdownButton<String>(
                      value: _availableYears.contains(_selectedYear) ? _selectedYear : 'Todas',
                      isExpanded: true,
                      items: _availableYears.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: _onYearChanged,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Sincronización en la Nube", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),
                    const SizedBox(height: 8),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Sincronización Automática", style: TextStyle(fontWeight: FontWeight.w500)),
                        Switch(
                          value: _autoSyncEnabled,
                          onChanged: (value) {
                            setState(() {
                              _autoSyncEnabled = value;
                            });
                            _saveSettings(); 
                          },
                        ),
                      ],
                    ),
                    const Divider(),

                    _isSyncing
                    ? const Center(child: CircularProgressIndicator())
                    : _user == null 
                    ? Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.login),
                          label: const Text("Iniciar sesión con Google"),
                          onPressed: _signInWithGoogle,
                        ),
                      )
                    : Column(
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundImage: _user!.photoURL != null ? NetworkImage(_user!.photoURL!) : null,
                            child: _user!.photoURL == null ? const Icon(Icons.person) : null,
                          ),
                          title: Text(_user!.displayName ?? "Usuario"),
                          subtitle: Text(_user!.email ?? "Sin email"),
                          trailing: IconButton(
                            icon: const Icon(Icons.logout, color: Colors.red),
                            onPressed: _signOut,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isSyncing ? null : _backupToCloud,
                                child: _isSyncing ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("Guardar en Nube"),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isSyncing ? null : _restoreFromCloud,
                                child: _isSyncing ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("Restaurar"),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Recordatorios", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                              _optionsDays, 
                              (val) {
                                 if(val != null) { setState(() => _playingReminderDays = val); _saveSettings(); }
                              }
                            ),
                            const SizedBox(height: 12),
                            _buildIntDropdown(
                              "Para juegos en 'Interested':", 
                              _interestedReminderDays, 
                              _optionsDays, 
                              (val) {
                                 if(val != null) { setState(() => _interestedReminderDays = val); _saveSettings(); }
                              }
                            ),
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
                                if (await Permission.notification.request().isGranted) {
                                  await _scheduleGameNotifications(testMode: true);
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Falta permiso de notificación")),
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

  Widget _buildDropdown(String label, String value, List<String> items, List<String> labels, Function(String?) onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label), DropdownButton<String>(
      value: value, 
      isExpanded: true, 
      items: List.generate(items.length, (index) => DropdownMenuItem(value: items[index], child: Text(labels[index]))), 
      onChanged: onChanged
    )]);
  }

  Widget _buildIntDropdown(String label, int value, List<int> items, Function(int?)? onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        Text(label), 
        DropdownButton<int>(
          value: value, 
          isExpanded: true, 
          items: items.map((e) => DropdownMenuItem(value: e, child: Text('$e días'))).toList(), 
          onChanged: onChanged
        )
      ]
    );
  }
}