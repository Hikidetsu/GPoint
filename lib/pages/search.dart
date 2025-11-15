import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:gpoint/models/game.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  List<dynamic> _games = [];
  bool _isLoading = false;
  bool _hasChanges = false;
  final TextEditingController _controller = TextEditingController();
  final String _apiKey = 'b07bda41b1374abb95cbe687ff0698ce';

  Future<void> _searchGames(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _games = [];
    });

    final url = Uri.parse(
        'https://api.rawg.io/api/games?key=$_apiKey&search=$query&page_size=20');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _games = data['results'];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openDetailScreen(Map<String, dynamic> gameData) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameDetailScreen(
          gameId: gameData['id'],
          name: gameData['name'],
          initialImage: gameData['background_image'],
          apiKey: _apiKey,
        ),
      ),
    );

    if (result == true) {
      _hasChanges = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.pop(context, _hasChanges);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Buscar en RAWG'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _hasChanges),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    labelText: "Escribe un juego...",
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        setState(() {
                          _games = [];
                        });
                      },
                    ),
                  ),
                  onSubmitted: _searchGames,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _games.isEmpty
                          ? const Center(
                              child: Text("Ingresa un nombre para buscar."))
                          : ListView.builder(
                              itemCount: _games.length,
                              itemBuilder: (context, index) {
                                final game = _games[index];
                                final String? imageUrl =
                                    game['background_image'];
                                final List genresList = game['genres'] ?? [];
                                final String genreText = genresList.isNotEmpty
                                    ? genresList
                                        .map((g) => g['name'])
                                        .join(', ')
                                    : 'Sin género';

                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    leading: imageUrl != null
                                        ? Image.network(
                                            imageUrl,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(
                                                    Icons.videogame_asset),
                                          )
                                        : const Icon(Icons.videogame_asset,
                                            size: 60),
                                    title: Text(game['name']),
                                    subtitle: Text(
                                      genreText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onTap: () => _openDetailScreen(game),
                                  ),
                                );
                              },
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

class GameDetailScreen extends StatefulWidget {
  final int gameId;
  final String name;
  final String? initialImage;
  final String apiKey;

  const GameDetailScreen({
    super.key,
    required this.gameId,
    required this.name,
    this.initialImage,
    required this.apiKey,
  });

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  Map<String, dynamic>? _gameDetails;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final url = Uri.parse(
        'https://api.rawg.io/api/games/${widget.gameId}?key=${widget.apiKey}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _gameDetails = json.decode(response.body);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _triggerAutoSync() async {
    final prefs = await SharedPreferences.getInstance();
    final bool autoSyncEnabled = prefs.getBool('autoSyncEnabled') ?? false;
    final user = FirebaseAuth.instance.currentUser;

    if (!autoSyncEnabled || user == null) {
      return;
    }

    final box = Hive.box('juegosBox');
    final dynamic juegosList = box.get('juegos');

    if (juegosList == null || juegosList is! List) {
      return;
    }

    try {
      final docRef = FirebaseFirestore.instance
          .collection('user_data')
          .doc(user.uid);

      await docRef.set({
        'games_backup': juegosList,
        'lastBackup': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error de Auto-Sync desde Search: $e");
    }
  }

  void _showAddDialog() {
    if (_gameDetails == null) return;

    String nuevoScore = "";
    String nuevoEstado = "Playing";
    String nuevoComentario = "";
    final String finalImage =
        _gameDetails!['background_image'] ?? widget.initialImage ?? "";

    final TextEditingController inicioDateController = TextEditingController();
    final TextEditingController finDateController = TextEditingController();
    final String today = DateFormat('dd/MM/yyyy').format(DateTime.now());

    showDialog(
      context: context,
      builder: (context) {
        String estadoLocal = nuevoEstado;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Agregar Juego"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    if (finalImage.isNotEmpty)
                      Image.network(finalImage, height: 100, fit: BoxFit.cover),
                    const SizedBox(height: 12),
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
                      value: estadoLocal,
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
                            estadoLocal = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: inicioDateController,
                      decoration: InputDecoration(
                        labelText: "Fecha de Inicio (dd/mm/aaaa)",
                        border: const OutlineInputBorder(),
                        suffixIcon: TextButton(
                          child: const Text("Hoy"),
                          onPressed: () {
                            inicioDateController.text = today;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: finDateController,
                      decoration: InputDecoration(
                        labelText: "Fecha de Término (dd/mm/aaaa)",
                        border: const OutlineInputBorder(),
                        suffixIcon: TextButton(
                          child: const Text("Hoy"),
                          onPressed: () {
                            finDateController.text = today;
                          },
                        ),
                      ),
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
                    _saveGameToHive(
                        finalImage,
                        nuevoScore,
                        estadoLocal,
                        nuevoComentario,
                        inicioDateController.text,
                        finDateController.text);
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

  void _saveGameToHive(String image, String score, String status, String comment,
      String fechaInicio, String fechaTermino) async {
    final box = Hive.box('juegosBox');
    final List dynamicList = box.get('juegos', defaultValue: []);

    List<Game> currentGames = dynamicList
        .map((item) => Game.fromMap(Map<String, dynamic>.from(item)))
        .toList();

    String platforms = (_gameDetails!['platforms'] as List<dynamic>?)
            ?.map((p) => p['platform']['name'])
            .join(', ') ??
        "PC";

    String genre = (_gameDetails!['genres'] as List<dynamic>?)
            ?.map((g) => g['name'])
            .join('/') ??
        "Varios";

    String synopsis = _gameDetails!['description_raw'] ??
        _gameDetails!['description'] ??
        "";

    final newGame = Game(
      nombre: widget.name,
      estado: status,
      score: score,
      genero: genre,
      plataforma: platforms,
      sinopsis: synopsis,
      comentario: comment,
      imagen: image,
      fechaInicio: fechaInicio,
      fechaTermino: fechaTermino,
      dateAddedTimestamp: DateTime.now().millisecondsSinceEpoch,
    );

    currentGames.add(newGame);
    await box.put('juegos', currentGames.map((g) => g.toMap()).toList());

    // --- ¡AQUÍ ESTÁ LA CORRECCIÓN! ---
    // Dispara la sincronización automática después de guardar localmente
    _triggerAutoSync(); 
    // ---------------------------------

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${newGame.nombre} agregado a Inicio")),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
      ),
      floatingActionButton: _isLoading || _hasError
          ? null
          : FloatingActionButton(
              onPressed: _showAddDialog,
              child: const Icon(Icons.add),
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? const Center(child: Text("Error al cargar detalles"))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_gameDetails!['background_image'] != null ||
                          widget.initialImage != null)
                        Image.network(
                          _gameDetails!['background_image'] ??
                              widget.initialImage,
                          width: double.infinity,
                          height: 250,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 250,
                            color: Colors.grey,
                            child: const Icon(Icons.broken_image, size: 50),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _gameDetails!['name'],
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  "Lanzamiento: ${_gameDetails!['released'] ?? 'N/A'}",
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Plataformas:",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (_gameDetails!['platforms'] as List<dynamic>?)
                                      ?.map((p) => p['platform']['name'])
                                      .join(', ') ??
                                  "No especificadas",
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Sinopsis:",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _gameDetails!['description_raw'] ??
                                  _gameDetails!['description'] ??
                                  "Sin descripción disponible.",
                              style: const TextStyle(fontSize: 15, height: 1.4),
                            ),
                            const SizedBox(height: 60),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}