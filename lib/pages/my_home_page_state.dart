import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:gpoint/pages/Config.dart';
import 'package:gpoint/pages/news.dart';
import 'package:gpoint/pages/search.dart';
import 'package:gpoint/pages/details.dart';
import 'package:gpoint/models/game.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gpoint/pages/about.dart';

class MyHomePage extends StatefulWidget {
  final String title;
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  String _Option = "All";
  String _listStyle = 'Grid';
  String _coverSize = 'Medianas';
  String _sortCriteria = 'Nombre';

  List<Game> juegos = [];

  @override
  void initState() {
    super.initState();
    _loadJuegos();
    _loadSettings();
  }

  void _loadJuegos() async {
    final box = Hive.box('juegosBox');
    final data = box.get('juegos');

    if (data == null || (data as List).isEmpty) {
      juegos = [
        Game(
          nombre: "Larry",
          estado: "Played",
          score: "7",
          imagen: "assets/Larry.png",
          genero: "Aventuras",
          plataforma: "PC",
          sinopsis: "Juego clásico.",
          comentario: "Divertido.",
        ),
      ];
      await box.put('juegos', juegos.map((g) => g.toMap()).toList());
    } else {
      setState(() {
        juegos = (data as List)
            .map((item) => Game.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      });
    }
  }

  void _saveJuegos() async {
    final box = Hive.box('juegosBox');
    await box.put('juegos', juegos.map((g) => g.toMap()).toList());
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _listStyle = prefs.getString('listStyle') ?? 'Grid';
      _coverSize = prefs.getString('coverSize') ?? 'Medianas';
      _sortCriteria = prefs.getString('sortCriteria') ?? 'Nombre';
    });
  }

  void _gotoAbout() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AboutPage()),
    );
  }

  void _goToNews() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => News()));
  }

  Future<void> _goToSearch() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Search()),
    );
    if (result == true) {
      _loadJuegos();
    }
  }

  Future<void> _gotoConfig() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Settings()),
    );
    _loadSettings();
  }

  Future<List<Map<String, dynamic>>> _searchAPI(String query) async {
    if (query.length < 3) return [];
    const apiKey = 'b07bda41b1374abb95cbe687ff0698ce';
    final url = Uri.parse(
        'https://api.rawg.io/api/games?key=$apiKey&search=$query&page_size=5');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['results']);
      }
    } catch (e) {
      debugPrint("Error API: $e");
    }
    return [];
  }

  Future<String> _fetchFullDescription(int id) async {
    const apiKey = 'b07bda41b1374abb95cbe687ff0698ce';
    final url = Uri.parse('https://api.rawg.io/api/games/$id?key=$apiKey');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['description_raw'] ?? data['description'] ?? "";
      }
    } catch (e) {
      debugPrint("Error Details: $e");
    }
    return "";
  }

  void _mostrarDialogoAgregar() {
    String nombreJuego = "";
    String nuevoScore = "";
    String nuevoEstado = "Playing";
    String nuevoComentario = "";
    String? imagenUrl;
    String genero = "Varios";
    String plataforma = "Varios";
    String sinopsis = "";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Agregar Juego"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Autocomplete<Map<String, dynamic>>(
                      optionsBuilder: (TextEditingValue textEditingValue) async {
                        if (textEditingValue.text == '') {
                          return const Iterable<Map<String, dynamic>>.empty();
                        }
                        return await _searchAPI(textEditingValue.text);
                      },
                      displayStringForOption: (option) => option['name'],
                      fieldViewBuilder:
                          (context, controller, focusNode, onFieldSubmitted) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: "Nombre del juego (Buscar)",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (value) {
                            nombreJuego = value;
                          },
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0,
                            child: SizedBox(
                              width: 250,
                              height: 200,
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final option = options.elementAt(index);
                                  return ListTile(
                                    leading: option['background_image'] != null
                                        ? Image.network(
                                            option['background_image'],
                                            width: 30,
                                            height: 30,
                                            fit: BoxFit.cover)
                                        : const Icon(Icons.videogame_asset),
                                    title: Text(option['name']),
                                    onTap: () {
                                      onSelected(option);
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                      onSelected: (Map<String, dynamic> selection) async {
                        setStateDialog(() {
                          nombreJuego = selection['name'];
                          imagenUrl = selection['background_image'];
                          
                          final genresList = selection['genres'] as List?;
                          genero = (genresList != null && genresList.isNotEmpty)
                              ? genresList.map((g) => g['name']).join('/')
                              : "Varios";

                          final platList = selection['platforms'] as List?;
                          plataforma = (platList != null && platList.isNotEmpty)
                              ? platList.map((p) => p['platform']['name']).join(', ')
                              : "PC";
                          
                          sinopsis = "Cargando sinopsis...";
                        });

                        String desc = await _fetchFullDescription(selection['id']);
                        if (context.mounted) {
                           setStateDialog(() {
                             sinopsis = desc.isNotEmpty ? desc : "Sin sinopsis disponible.";
                           });
                        }
                      },
                    ),
                    
                    const SizedBox(height: 12),
                    
                    if (imagenUrl != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        height: 100,
                        width: double.infinity,
                        child: Image.network(imagenUrl!, fit: BoxFit.cover),
                      ),

                    if (sinopsis.isNotEmpty)
                       Padding(
                         padding: const EdgeInsets.only(bottom: 12.0),
                         child: Text(
                           sinopsis, 
                           maxLines: 3, 
                           overflow: TextOverflow.ellipsis,
                           style: TextStyle(color: Colors.grey[600], fontSize: 12),
                         ),
                       ),

                    TextField(
                      decoration: const InputDecoration(
                        labelText: "Score (1-10)",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => nuevoScore = value,
                    ),
                    const SizedBox(height: 12),
                    DropdownButton<String>(
                      value: nuevoEstado,
                      isExpanded: true,
                      items: ["Playing", "Played", "Interested", "Dropped"]
                          .map((estado) => DropdownMenuItem(
                                value: estado,
                                child: Text(estado),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setStateDialog(() {
                            nuevoEstado = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: "Comentario (opcional)",
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      onChanged: (value) => nuevoComentario = value,
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nombreJuego.isNotEmpty) {
                      setState(() {
                        juegos.add(Game(
                          nombre: nombreJuego,
                          score: nuevoScore,
                          estado: nuevoEstado,
                          comentario: nuevoComentario.isNotEmpty ? nuevoComentario : null,
                          imagen: imagenUrl,
                          genero: genero,
                          plataforma: plataforma,
                          sinopsis: sinopsis,
                        ));
                      });
                      _saveJuegos();
                    }
                    Navigator.pop(context);
                  },
                  child: const Text("Guardar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final juegosFiltados = _Option == "All"
        ? juegos
        : juegos.where((j) => j.estado == _Option).toList();

    List<Game> juegosOrdenados = List.from(juegosFiltados);
    if (_sortCriteria == 'Nombre') {
      juegosOrdenados.sort(
          (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    } else if (_sortCriteria == 'Puntuación') {
      juegosOrdenados.sort((b, a) {
        final aScore = int.tryParse(a.score.trim()) ?? 0;
        final bScore = int.tryParse(b.score.trim()) ?? 0;
        return aScore.compareTo(bScore);
      });
    } else if (_sortCriteria == 'Fecha') {
      juegosOrdenados = juegosOrdenados.reversed.toList();
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        title: Image.asset('assets/Gsinfondo.png', height: 40, fit: BoxFit.contain),
        leading: IconButton(
          icon: const Icon(Icons.settings),
          onPressed: _gotoConfig,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Acerca de',
            onPressed: _gotoAbout,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 40,
            color: Colors.grey[200],
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  _buildOption("All"),
                  _buildOption("Playing"),
                  _buildOption("Played"),
                  _buildOption("Interested"),
                  _buildOption("Dropped"),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
          Expanded(
            child: _listStyle == 'Grid'
                ? _buildGridView(juegosOrdenados)
                : _buildListView(juegosOrdenados),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoAgregar,
        tooltip: 'Agregar Juego',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildGridView(List<Game> juegosOrdenados) {
    double imageSize;
    if (_coverSize == 'Grandes') {
      imageSize = 180;
    } else if (_coverSize == 'Pequeñas') {
      imageSize = 100;
    } else {
      imageSize = 140;
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.9,
      ),
      itemCount: juegosOrdenados.length,
      itemBuilder: (context, index) {
        final juego = juegosOrdenados[index];
        final origIndex = juegos.indexOf(juego);

        return GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      Details(juego: juego, index: origIndex)),
            );
            if (result == "delete") {
              setState(() {
                juegos.removeAt(origIndex);
              });
              _saveJuegos();
            } else if (result is Game) {
              setState(() {
                juegos[origIndex] = result;
              });
              _saveJuegos();
            }
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: imageSize,
                  width: imageSize,
                  child: _buildGameImage(juego),
                ),
                const SizedBox(height: 8),
                Text(juego.nombre,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                Text("Score: ${juego.score}"),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListView(List<Game> juegosOrdenados) {
    double imageSize;
    if (_coverSize == 'Grandes') {
      imageSize = 80;
    } else if (_coverSize == 'Pequeñas') {
      imageSize = 40;
    } else {
      imageSize = 60;
    }

    return ListView.builder(
      itemCount: juegosOrdenados.length,
      itemBuilder: (context, index) {
        final juego = juegosOrdenados[index];
        final origIndex = juegos.indexOf(juego);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: ListTile(
            leading: SizedBox(
              width: imageSize,
              height: imageSize,
              child: _buildGameImage(juego),
            ),
            title: Text(juego.nombre),
            subtitle: Text("Score: ${juego.score}"),
            trailing: Text(juego.estado),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        Details(juego: juego, index: origIndex)),
              );
              if (result == "delete") {
                setState(() {
                  juegos.removeAt(origIndex);
                });
                _saveJuegos();
              } else if (result is Game) {
                setState(() {
                  juegos[origIndex] = result;
                });
                _saveJuegos();
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildGameImage(Game juego) {
    if (juego.imagen == null || juego.imagen!.isEmpty) {
      return const Icon(Icons.videogame_asset);
    } else if (juego.imagen!.startsWith('http')) {
      return Image.network(
        juego.imagen!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image),
      );
    } else if (juego.imagen!.startsWith('/')) {
      final file = File(juego.imagen!);
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.videogame_asset),
      );
    } else {
      return Image.asset(
        juego.imagen!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.videogame_asset),
      );
    }
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Buscar'),
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.newspaper), label: 'Noticias'),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.deepPurple,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
        if (index == 0) {
          _goToSearch();
        } else if (index == 2) {
          _goToNews();
        }
      },
    );
  }

  Widget _buildOption(String label) {
    final bool isSelected = _Option == label;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          setState(() {
            _Option = selected ? label : _Option;
          });
        },
        selectedColor: Colors.deepPurple,
        backgroundColor: Colors.grey[300],
        labelStyle:
            TextStyle(color: isSelected ? Colors.white : Colors.black),
      ),
    );
  }
}