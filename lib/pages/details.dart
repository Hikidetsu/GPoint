import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gpoint/models/game.dart';

class Details extends StatefulWidget {
  final Game juego;
  final int index;

  const Details({Key? key, required this.juego, required this.index}) : super(key: key);

  @override
  State<Details> createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  late Game juegoActual;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    juegoActual = widget.juego;
  }

  Future<void> _seleccionarImagen() async {
    final cameraStatus = await Permission.camera.request();
    final storageStatus = await Permission.photos.request();

    if (cameraStatus.isDenied || storageStatus.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes conceder permisos para continuar.')),
      );
      return;
    }

    try {
      final ImageSource source = await _mostrarOpcionesImagen();
      final XFile? imagenSeleccionada = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (imagenSeleccionada != null) {
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String newPath =
            '${appDir.path}/${DateTime.now().millisecondsSinceEpoch}.png';
        final File nuevaImagen = await File(imagenSeleccionada.path).copy(newPath);

        setState(() {
          juegoActual = Game(
            nombre: juegoActual.nombre,
            score: juegoActual.score,
            estado: juegoActual.estado,
            imagen: nuevaImagen.path,
            comentario: juegoActual.comentario,
            genero: juegoActual.genero,
            plataforma: juegoActual.plataforma,
            sinopsis: juegoActual.sinopsis,
          );
        });

        await _guardarJuegoLocal(); // 🔹 Guarda persistencia
        Navigator.pop(context, juegoActual); // 🔹 Devuelve el juego actualizado
      }
    } catch (e) {
      debugPrint("Error al seleccionar imagen: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ocurrió un error al abrir la cámara o galería.')),
      );
    }
  }

  Future<void> _guardarJuegoLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final String? juegosGuardados = prefs.getString('juegos');
    List<dynamic> listaJuegos = [];

    if (juegosGuardados != null) {
      listaJuegos = jsonDecode(juegosGuardados);
    }

    if (widget.index < listaJuegos.length) {
      listaJuegos[widget.index] = juegoActual.toJson();
    } else {
      listaJuegos.add(juegoActual.toJson());
    }

    await prefs.setString('juegos', jsonEncode(listaJuegos));
  }

  Future<ImageSource> _mostrarOpcionesImagen() async {
    return await showDialog<ImageSource>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Seleccionar imagen"),
            content: const Text("¿Deseas tomar una foto o elegir una de la galería?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, ImageSource.camera),
                child: const Text("Cámara"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, ImageSource.gallery),
                child: const Text("Galería"),
              ),
            ],
          ),
        ) ??
        ImageSource.gallery;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(juegoActual.nombre),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              String nuevoNombre = juegoActual.nombre;
              String nuevoScore = juegoActual.score;
              String nuevoEstado = juegoActual.estado;
              String nuevoComentario = juegoActual.comentario ?? "";

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
                            if (value != null) nuevoEstado = value;
                          },
                        ),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: "Comentario (opcional)",
                            border: OutlineInputBorder(),
                          ),
                          controller: TextEditingController(text: nuevoComentario),
                          maxLines: 2,
                          onChanged: (value) => nuevoComentario = value,
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancelar"),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          final nuevoJuego = Game(
                            nombre: nuevoNombre,
                            score: nuevoScore,
                            estado: nuevoEstado,
                            imagen: juegoActual.imagen,
                            comentario:
                                nuevoComentario.isNotEmpty ? nuevoComentario : null,
                            genero: juegoActual.genero,
                            plataforma: juegoActual.plataforma,
                            sinopsis: juegoActual.sinopsis,
                          );

                          setState(() => juegoActual = nuevoJuego);
                          await _guardarJuegoLocal();
                          Navigator.pop(context, nuevoJuego);
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
            onPressed: () => Navigator.pop(context, "delete"),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: juegoActual.imagen != null
                        ? (juegoActual.imagen!.startsWith('/'))
                            ? Image.file(
                                File(juegoActual.imagen!),
                                width: 150,
                                height: 150,
                                fit: BoxFit.cover,
                              )
                            : Image.asset(
                                juegoActual.imagen!,
                                width: 150,
                                height: 150,
                                fit: BoxFit.cover,
                              )
                        : Image.asset(
                            'assets/placeholder.png',
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                  ),
                  Positioned(
                    bottom: 5,
                    right: 5,
                    child: InkWell(
                      onTap: _seleccionarImagen,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(Icons.edit, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text("Estado: ${juegoActual.estado}"),
            Text("Score: ${juegoActual.score}"),
            Text("Género: ${juegoActual.genero}"),
            Text("Plataforma: ${juegoActual.plataforma}"),
            const SizedBox(height: 30),
            const Text(
              "Sinopsis:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (juegoActual.sinopsis != null && juegoActual.sinopsis!.isNotEmpty)
              Text(
                juegoActual.sinopsis!,
                style: const TextStyle(fontSize: 16),
              ),
            const SizedBox(height: 30),
            const Text(
              "Comentario:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (juegoActual.comentario != null && juegoActual.comentario!.isNotEmpty)
              Text(
                juegoActual.comentario!,
                style: const TextStyle(fontSize: 16),
              ),
          ],
        ),
      ),
    );
  }
}
