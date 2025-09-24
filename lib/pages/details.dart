import 'package:flutter/material.dart';
import 'package:gpoint/main.dart';
import 'package:gpoint/pages/my_home_page_state.dart';


class Details extends StatelessWidget {

  final Juego juego;
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
                            Juego(
                              nombre: nuevoNombre,
                              score: nuevoScore,
                              estado: nuevoEstado,
                              imagen: juego.imagen,
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
      body: Center(
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
            const Text(
              "Aqui iran futuros detalles",
              style: TextStyle(
                fontSize: 20,
                fontStyle: FontStyle.italic,
                color:Colors.black,
              ),
            )
          ],
        ),
      ),
    );
  }
}