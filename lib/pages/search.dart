import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  List<dynamic> _games = [];
  bool _isLoading = false;
  final TextEditingController _controller = TextEditingController();

  Future<void> _searchGames(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _games = [];
    });

    final url = Uri.parse(
        'https://api.rawg.io/api/games?key=b07bda41b1374abb95cbe687ff0698ce&search=$query&page_size=20');

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
          _showErrorDialog('Error en el servidor: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Error de conexión');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Aviso"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Aceptar"),
          ),
        ],
      ),
    );
  }

  void _onSelectGame(Map<String, dynamic> game) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(game['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Rating: ${game['rating'] ?? 'N/A'}"),
            const SizedBox(height: 8),
            Text("Lanzamiento: ${game['released'] ?? 'N/A'}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar en RAWG'),
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
                            child: Text(
                                "Ingresa un nombre y busca para ver resultados."))
                        : ListView.builder(
                            itemCount: _games.length,
                            itemBuilder: (context, index) {
                              final game = _games[index];
                              final String? imageUrl = game['background_image'];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  leading: imageUrl != null
                                      ? Image.network(
                                          imageUrl,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(Icons.videogame_asset),
                                        )
                                      : const Icon(Icons.videogame_asset,
                                          size: 60),
                                  title: Text(game['name']),
                                  subtitle: Text(
                                      "Rating: ${game['rating'] ?? '0.0'}"),
                                  onTap: () => _onSelectGame(game),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}