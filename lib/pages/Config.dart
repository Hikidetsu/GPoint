import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  String _listStyle = 'Grid';
  String _coverSize = 'Medianas';
  String _sortCriteria = 'Nombre';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _listStyle = prefs.getString('listStyle') ?? 'Grid';
      _coverSize = prefs.getString('coverSize') ?? 'Medianas';
      _sortCriteria = prefs.getString('sortCriteria') ?? 'Nombre'; 
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('listStyle', _listStyle);
    await prefs.setString('coverSize', _coverSize);
    await prefs.setString('sortCriteria', _sortCriteria); 
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
            Image.asset(
              "assets/Gsinfondo.png",
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 20),
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
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                        DropdownMenuItem(value: 'Fecha', child: Text('Por fecha de agregado')),
                        DropdownMenuItem(value: 'Puntuación', child: Text('Por puntuación')),
                      ],
                      onChanged: _onSortCriteriaChanged,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: const [
                    Text(
                      "Creador: Hikidetsu",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Objetivo: Esta aplicación fue creada con la intención de que el usuario pueda listar de forma rápida y cómoda los videojuegos que esté jugando, dándoles una puntuación y un estado.",
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Versión: 1.0\n\nMuchas gracias por utilizar esta aplicación.",
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                      textAlign: TextAlign.center,
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
