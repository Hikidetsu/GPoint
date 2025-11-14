import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:gpoint/models/game.dart';
import 'package:intl/intl.dart';

class Details extends StatefulWidget {
  final Game juego;
  final int index;

  const Details({super.key, required this.juego, required this.index});

  @override
  State<Details> createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  late Game juegoActual;
  final ImagePicker _picker = ImagePicker();
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    juegoActual = widget.juego;
  }

  Future<void> _seleccionarImagen() async {
    final cameraStatus = await Permission.camera.request();
    final storageStatus = await Permission.photos.request();

    if (cameraStatus.isDenied || storageStatus.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Se requieren permisos de cámara/galería.')),
        );
      }
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
        final File nuevaImagen =
            await File(imagenSeleccionada.path).copy(newPath);

        setState(() {
          juegoActual = juegoActual.copyWith(imagen: nuevaImagen.path);
          _hasChanged = true;
        });

        await _guardarJuegoLocal();
      }
    } catch (e) {
      debugPrint("Error al seleccionar imagen: $e");
    }
  }

  Future<void> _guardarJuegoLocal() async {
    final box = Hive.box('juegosBox');
    final List dynamicList = box.get('juegos', defaultValue: []);

    List<Map<String, dynamic>> listaJuegos = dynamicList
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    if (widget.index >= 0 && widget.index < listaJuegos.length) {
      listaJuegos[widget.index] = juegoActual.toMap();
      await box.put('juegos', listaJuegos);
    }
  }

  Future<ImageSource> _mostrarOpcionesImagen() async {
    return await showDialog<ImageSource>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Seleccionar imagen"),
            content:
                const Text("¿Deseas tomar una foto o elegir una de la galería?"),
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

  void _confirmarEliminacion() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Eliminar Juego"),
          content: Text(
              "¿Estás seguro de que deseas eliminar '${juegoActual.nombre}' de tu lista?"),
          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop("delete");
              },
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogoEditar() {
    final nameController = TextEditingController(text: juegoActual.nombre);
    final scoreController = TextEditingController(text: juegoActual.score);
    final commentController =
        TextEditingController(text: juegoActual.comentario ?? "");
    final inicioDateController =
        TextEditingController(text: juegoActual.fechaInicio ?? "");
    final finDateController =
        TextEditingController(text: juegoActual.fechaTermino ?? "");
    final String today = DateFormat('dd/MM/yyyy').format(DateTime.now());
    
    String nuevoEstado = juegoActual.estado;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Editar Juego"),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Nombre del juego",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: scoreController,
                      decoration: const InputDecoration(
                        labelText: "Score (1-10)",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
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
                      controller: inicioDateController,
                      decoration: InputDecoration(
                        labelText: "Fecha de Inicio (dd/mm/aaaa)",
                        border: const OutlineInputBorder(),
                        suffixIcon: TextButton(
                          child: const Text("Hoy"),
                          onPressed: () => inicioDateController.text = today,
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
                          onPressed: () => finDateController.text = today,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: commentController,
                      decoration: const InputDecoration(
                        labelText: "Comentario (opcional)",
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                final nuevoJuego = juegoActual.copyWith(
                  nombre: nameController.text,
                  score: scoreController.text,
                  estado: nuevoEstado,
                  comentario: commentController.text.isNotEmpty
                      ? commentController.text
                      : null,
                  fechaInicio: inicioDateController.text.isNotEmpty 
                      ? inicioDateController.text 
                      : null,
                  fechaTermino: finDateController.text.isNotEmpty 
                      ? finDateController.text 
                      : null,
                );

                setState(() {
                  juegoActual = nuevoJuego;
                  _hasChanged = true;
                });

                await _guardarJuegoLocal();
                if (mounted) Navigator.pop(context);
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.pop(context, juegoActual);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(juegoActual.nombre),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, juegoActual),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _mostrarDialogoEditar,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmarEliminacion,
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                height: 250,
                child: Stack(
                  children: [
                    Positioned.fill(child: _buildImage(juegoActual.imagen)),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: InkWell(
                        onTap: _seleccionarImagen,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                        Icons.star, "Score", "${juegoActual.score}/10"),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.flag, "Estado", juegoActual.estado),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.calendar_today, "Inicio",
                        juegoActual.fechaInicio ?? "N/A"),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.calendar_today_outlined, "Término",
                        juegoActual.fechaTermino ?? "N/A"),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.category, "Género",
                        juegoActual.genero ?? "N/A"),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.gamepad, "Plataformas",
                        juegoActual.plataforma ?? "N/A"),
                    
                    const Divider(height: 30),
                    const Text(
                      "Sinopsis",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (juegoActual.sinopsis != null &&
                              juegoActual.sinopsis!.isNotEmpty)
                          ? juegoActual.sinopsis!
                          : "Sin descripción disponible.",
                      style: const TextStyle(fontSize: 16, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    if (juegoActual.comentario != null &&
                        juegoActual.comentario!.isNotEmpty) ...[
                      const Text(
                        "Mi Comentario",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          juegoActual.comentario!,
                          style: const TextStyle(
                              fontStyle: FontStyle.italic, fontSize: 16),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.deepPurple),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildImage(String? path) {
    if (path == null || path.isEmpty) {
      return Image.asset(
        'assets/placeholder.png',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey,
          child: const Icon(Icons.videogame_asset,
              size: 50, color: Colors.white),
        ),
      );
    }

    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image),
        ),
      );
    } else if (path.startsWith('/')) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image),
        ),
      );
    } else {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey[300],
          child: const Icon(Icons.image_not_supported),
        ),
      );
    }
  }
}