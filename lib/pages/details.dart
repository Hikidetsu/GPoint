import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gpoint/main.dart';
import 'package:gpoint/pages/my_home_page_state.dart';
import 'package:gpoint/models/game.dart';


class Details extends StatelessWidget {

  final Game juego;
  final int index;
  const Details({Key? key, required this.juego, required this.index}): super(key: key);

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(juego.nombre),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              String nuevoNombre = juego.nombre;
              String nuevoScore = juego.score;
              String nuevoEstado = juego.estado;
              String nuevoComentario=juego.comentario ?? "";
              

              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Editar Juego"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          decoration: const InputDecoration(
                            labelText: "Nombre del juego",
                            border: OutlineInputBorder(),
                          ),
                          controller: TextEditingController(text: nuevoNombre),
                          onChanged: (value) => nuevoNombre = value,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: "Score (1-10)",
                            border: OutlineInputBorder(),
                          ),
                          controller: TextEditingController(text: nuevoScore),
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
                              nuevoEstado = value;
                            }
                          },
                        ),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: "Comentario(opcional)",
                            border:OutlineInputBorder(),
                          ),
                          controller: TextEditingController(text:nuevoComentario),
                          maxLines: 2,
                          onChanged: (value) => nuevoComentario=value,
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
                          Navigator.pop(context); 
                          Navigator.pop(
                            context,
                            Game(
                              nombre: nuevoNombre,
                              score: nuevoScore,
                              estado: nuevoEstado,
                              imagen: juego.imagen,
                              comentario: nuevoComentario.isNotEmpty ? nuevoComentario: null,
                            ),
                          ); 
                        },
                        child: const Text("Guardar"),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              Navigator.pop(context, "delete"); 
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (juego.imagen != null)
                    Image.asset(
                      juego.imagen!,
                      width: 150,
                      height: 150,
                    ),
                  const SizedBox(height: 16),
                  Text("Estado: ${juego.estado}"),
                  Text("Score: ${juego.score}"),
                  Text("Género: ${juego.genero}"),
                  Text("Plataforma: ${juego.plataforma}"),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Text(
              "Sinopsis:",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if(juego.sinopsis !=null && juego.sinopsis!.isNotEmpty)
            Text(
              juego.sinopsis!,
              style: const TextStyle(fontSize: 16),
            )
            else
            const SizedBox.shrink(),

            const SizedBox(height: 30),
            Text(
              "Comentario:",
              style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if(juego.comentario!=null && juego.comentario!.isNotEmpty)
            Text(
              juego.comentario!,
              style: const TextStyle(fontSize: 16),
            )
            else
            const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}