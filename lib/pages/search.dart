import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Search extends StatefulWidget {
  const Search({Key? key}) : super(key: key);

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final List<String> allGames = ["Silksong", "Larry", "LeapGalaxy"];
  List<String> filteredGames = [];

  @override
  void initState() {
    super.initState();
    filteredGames = allGames;
  }

  Future<List<dynamic>> fetchGames() async {
    final url = Uri.parse('https://www.freetogame.com/api/games');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al cargar los juegos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  void _filterGames(String query) {
    setState(() {
      filteredGames = allGames
          .where((game) => game.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _onSelectGame(String game) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text("No existe información de $game por el momento."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Aceptar"),
          ),
        ],
      ),
    );
  }

  void _goToApiGames() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GameListScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_download),
            tooltip: "Ver juegos desde API",
            onPressed: _goToApiGames,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: "Buscar",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterGames,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: filteredGames.length,
                itemBuilder: (context, index) {
                  final game = filteredGames[index];
                  return ListTile(
                    title: Text(game),
                    onTap: () => _onSelectGame(game),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class GameListScreen extends StatelessWidget {
  const GameListScreen({super.key});

  Future<List<dynamic>> fetchGames() async {
    final url = Uri.parse('https://www.freetogame.com/api/games');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al cargar los juegos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Juegos FreeToGame')),
      body: FutureBuilder<List<dynamic>>(
        future: fetchGames(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final games = snapshot.data!;
            return ListView.builder(
              itemCount: games.length,
              itemBuilder: (context, index) {
                final game = games[index];
                return ListTile(
                  leading: Image.network(
                    game['thumbnail'],
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.image),
                  ),
                  title: Text(game['title']),
                  subtitle: Text(game['genre']),
                );
              },
            );
          } else {
            return const Center(child: Text('No hay juegos disponibles.'));
          }
        },
      ),
    );
  }
}
