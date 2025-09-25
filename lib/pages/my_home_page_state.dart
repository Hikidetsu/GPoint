import 'package:flutter/material.dart';
import 'package:gpoint/pages/about.dart';
import 'package:gpoint/pages/news.dart';
import 'package:gpoint/pages/search.dart';
import 'package:gpoint/pages/details.dart';
import 'package:gpoint/models/game.dart';



//hacer que se pueda abrir la los juegos añadidos a otra pantalla (listo)
//agregar una pantalla de about 


 

class MyHomePage extends StatefulWidget {
  final String title;
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0; 
  String _Option = "All";


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }



   void _goToNews() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => News()),
    );
  }

    void _goToSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Search()),
    );
    }
    void _goToAbout(){
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context)=> About()),
      );
    }

    
  
     List<Game> juegos = [
      
      Game(nombre: "Larry", estado: "Played", score: "7", imagen: "assets/Larry.png",genero:"Contenido sexual/Desnudos/Aventuras",
      plataforma: "Playstation 2/PC/Xbox",
      sinopsis: "Con estudiantes universitarias guapísimas por todas partes, el nerd universitario Larry Lovage va tras algo más que su diploma. Intenta estar a la altura de la leyenda de su tío, Larry Laffer, el playboy de poliéster favorito de todos.",
      comentario: "Riquisimo. mi juego favorito 10/10"),
      Game(nombre: "LeapGalaxy", estado: "Interested", score: " ", imagen: "assets/LeapGalaxy.png",genero: "Carreras/Plataforma2D",
      plataforma: "PC",
      sinopsis: "Leap Galaxy es un videojuego de plataformas 2D con estética minimalista y jugabilidad que enfatiza velocidad y fluidez. ¡Aprovecha el momentum y perfecciona el impulso entregado por tus disparos para superar cada nivel en el menor tiempo posible!.",
      comentario: "El mejor indie chileno jamas creado, el creador debio farmear bastante aura"),

      Game(nombre: "SilkSong", estado: "Playing", score: "10", imagen: "assets/Silksong.png",genero: "Metroidvania/Indie/Dificiles",
      plataforma: "PC/MacOS/Linux/Nintendo Switch/Playstation 4/Playstation 5/Xbox One/ Xbox Series X/S",
      sinopsis: "¡Descubre un vasto reino embrujado en Hollow Knight: Silksong! Explora, lucha y sobrevive mientras asciendes a la cima de una tierra gobernada por la seda y la canción.",
      comentario: "Hollow Knigth parece una demo al lado de silkSong 10/10 goty"),


    ];



  @override
  Widget build(BuildContext context) {
    final juegosFiltados = _Option == "All"
    ? juegos : juegos.where((j) => j.estado == _Option).toList();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        title: Image.asset('assets/Gsinfondo.png',height: 40,fit:BoxFit.contain),
      

      leading:IconButton(
        icon: const Icon(Icons.info),
        onPressed: (){
          _goToAbout();
        },
      )
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
            child: ListView.builder(
              itemCount: juegosFiltados.length,
              itemBuilder: (context, index) {
                final juego = juegosFiltados[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: ListTile(
                    leading: SizedBox(
                      
                      width: 50,
                      height: 50,
                      child: juego.imagen != null ? Image.asset(
                        juego.imagen!,
                        fit:BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.videogame_asset),
                       )
                    : Icon(Icons.videogame_asset),
                  ),
                    title: Text(juego.nombre),
                    subtitle: Text("Score: ${juego.score}"),
                    trailing: Text(juego.estado),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:(context) => Details(juego:juego, index: index),
                        ),
                      );
                      if(result == "delete"){
                        setState(() {
                          juegos.removeAt(index);
                        });
                      }
                      else if (result is Game){
                        setState(() {
                          juegos[index]=result;
                        });
                      }
                    }
                  ),
                );
              },
            ),
          ),
        ],
      ),



//funciones de la lista y añadir
          floatingActionButton: FloatingActionButton(
      onPressed: () {
        String nuevoJuego = "";
        int nuevoScore = 0;
        String nuevoEstado = "Playing"; 
        String nuevoComentario= "";
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
                      labelText: "Comentario(opcional)",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    onChanged: (value)=>nuevoComentario=value,
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
                          comentario:  nuevoComentario,
                        ));
                      });
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
    ),








      //botones de abajo
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Buscar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.newspaper),
            label: 'Noticias',
          ),
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
      ),
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
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
      ),
    ),
  );
}
}