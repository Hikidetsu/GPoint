import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gpoint/pages/Config.dart';
import 'package:gpoint/pages/news.dart';
import 'package:gpoint/pages/search.dart';
import 'package:gpoint/pages/details.dart';
import 'package:gpoint/models/game.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
          genero: "Contenido sexual/Desnudos/Aventuras",
          plataforma: "Playstation 2/PC/Xbox",
          sinopsis:
              "Con estudiantes universitarias guapísimas por todas partes, el nerd universitario Larry Lovage va tras algo más que su diploma.",
          comentario: "Riquisimo. mi juego favorito 10/10",
        ),
        Game(
          nombre: "LeapGalaxy",
          estado: "Interested",
          score: " ",
          imagen: "assets/LeapGalaxy.png",
          genero: "Carreras/Plataforma2D",
          plataforma: "PC",
          sinopsis:
              "Leap Galaxy es un videojuego de plataformas 2D con estética minimalista.",
          comentario:
              "El mejor indie chileno jamás creado, el creador debió farmear bastante aura.",
        ),
        Game(
          nombre: "SilkSong",
          estado: "Playing",
          score: "10",
          imagen: "assets/Silksong.png",
          genero: "Metroidvania/Indie/Dificiles",
          plataforma:
              "PC/MacOS/Linux/Nintendo Switch/Playstation 4/Playstation 5/Xbox One/ Xbox Series X/S",
          sinopsis:
              "¡Descubre un vasto reino embrujado en Hollow Knight: Silksong!",
          comentario: "Hollow Knigth parece una demo al lado de Silksong 10/10 goty",
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
  void _goToNews() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => News()));
  }
  void _goToSearch() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => Search()));
  }
  Future<void> _goToAbout() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Settings()),
    );
    _loadSettings();
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
        title:
            Image.asset('assets/Gsinfondo.png', height: 40, fit: BoxFit.contain),
        leading: IconButton(
          icon: const Icon(Icons.settings),
          onPressed: _goToAbout,
        ),
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
      floatingActionButton: _buildAddButton(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }
  Widget _buildGridView(List<Game> juegosOrdenados) {
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
                _buildGameImage(juego),
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
    return ListView.builder(
      itemCount: juegosOrdenados.length,
      itemBuilder: (context, index) {
        final juego = juegosOrdenados[index];
        final origIndex = juegos.indexOf(juego);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: ListTile(
            leading: SizedBox(
              width: 60,
              height: 60,
              child: _buildGameImage(juego),
            ),
            title: Text(juego.nombre),
            subtitle: Text("Score: ${juego.score}"),
            trailing: Text(juego.estado),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Details(juego: juego, index: origIndex)),
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
    if (juego.imagen == null) {
      return const Icon(Icons.videogame_asset);
    } else if (juego.imagen!.startsWith('/')) {
      final file = File(juego.imagen!);
      return Image.file(file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.videogame_asset));
    } else {
      return Image.asset(juego.imagen!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.videogame_asset));
    }
  }
  Widget _buildAddButton() {
    return FloatingActionButton(
      onPressed: () {
        String nuevoJuego = "";
        int nuevoScore = 0;
        String nuevoEstado = "Playing"; 
        String nuevoComentario = "";

        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Agregar Juego"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: "Nombre del juego",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => nuevoJuego = value,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: "Score(1-10)",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      nuevoScore = int.tryParse(value) ?? 0;
                    },
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
                        nuevoEstado = value;
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nuevoJuego.isNotEmpty) {
                      setState(() {
                        juegos.add(Game(
                          nombre: nuevoJuego,
                          score: nuevoScore.toString(),
                          estado: nuevoEstado,
                          comentario: nuevoComentario,
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
      tooltip: 'Agregar',
      child: const Icon(Icons.add),
    );
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
