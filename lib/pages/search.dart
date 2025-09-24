import 'package:flutter/material.dart';



class Search extends StatefulWidget {
  const Search({Key? key}) : super(key: key);

@override
State<Search> createState() => _SearchState();
}

class _SearchState extends State <Search> {

  final List<String> allGames = ["Silksong","Larry", "LeapGalaxy"];
  List<String>filteredGames = [];

  @override
  void initState(){
    super.initState();
    filteredGames = allGames;
  }

  void _filteredGames(String query){
    setState(() {
      filteredGames=allGames.where((game)=> game.toLowerCase().contains(query.toLowerCase()))
      .toList();
    });
  }

  void _onSelectGame(String game){
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text("No existe informacion de $game por el momento"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Aceptar"),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar'),
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
              onChanged: _filteredGames,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount:filteredGames.length,
                itemBuilder: (context, index) {
                  final game = filteredGames[index];
                  return ListTile(
                  title: Text(game),
                  onTap:()=>_onSelectGame(game),
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