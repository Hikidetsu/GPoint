import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  Map<String, dynamic>? encuesta;
  final Map<int, dynamic> respuestas = {};

  @override
  void initState() {
    super.initState();
    _cargarEncuesta();
  }

  Future<void> _cargarEncuesta() async {
    final data = await rootBundle.loadString('assets/encuesta.json');
    final jsonData = json.decode(data);
    setState(() {
      encuesta = jsonData;
    });
  }

  Future<void> _enviarRespuestas() async {
    if (encuesta == null) return;

    final buffer = StringBuffer();
    buffer.writeln('📋 ${encuesta!["titulo"]}\n');

    for (var seccion in encuesta!["secciones"]) {
      buffer.writeln('🟩 ${seccion["titulo"]}\n');
      for (var p in seccion["preguntas"]) {
        final id = p["id"];
        final pregunta = p["pregunta"];
        final respuesta = respuestas[id]?.toString() ?? 'Sin respuesta';
        buffer.writeln('$pregunta\n→ $respuesta\n');
      }
      buffer.writeln('');
    }

    final subject = Uri.encodeComponent('Respuestas de encuesta');
    final body = Uri.encodeComponent(buffer.toString());
    const email = 'nosi111mobo@gmail.com';

    final uri = Uri.parse('mailto:$email?subject=$subject&body=$body');

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir el correo: $e')),
      );
    }
  }

  Widget _buildPregunta(Map pregunta) {
    final id = pregunta['id'];
    final tipo = pregunta['tipo'];

    switch (tipo) {
      case 'texto':
        return TextField(
          decoration: InputDecoration(
            labelText: pregunta['pregunta'],
            prefixIcon: pregunta['icono'] != null
                ? Icon(_getIconFromName(pregunta['icono']))
                : null,
          ),
          onChanged: (v) => respuestas[id] = v,
        );

      case 'texto_largo':
        return TextField(
          decoration: InputDecoration(
            labelText: pregunta['pregunta'],
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
          onChanged: (v) => respuestas[id] = v,
        );

      case 'slider':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pregunta['pregunta']),
            Slider(
              value: (respuestas[id] ?? 3).toDouble(),
              min: (pregunta['min'] ?? 1).toDouble(),
              max: (pregunta['max'] ?? 5).toDouble(),
              divisions: ((pregunta['max'] ?? 5) - (pregunta['min'] ?? 1)),
              label: '${respuestas[id] ?? 3}',
              onChanged: (v) => setState(() => respuestas[id] = v.round()),
            ),
          ],
        );

      case 'booleano':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pregunta['pregunta']),
            Row(
              children: (pregunta['opciones'] as List<dynamic>)
                  .map(
                    (op) => Expanded(
                      child: RadioListTile<String>(
                        title: Text(op),
                        value: op,
                        groupValue: respuestas[id],
                        onChanged: (v) =>
                            setState(() => respuestas[id] = v ?? ''),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        );

      case 'estrellas':
        final int rating = respuestas[id] ?? 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pregunta['pregunta']),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pregunta['max'] ?? 5,
                (index) => IconButton(
                  icon: Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () => setState(() => respuestas[id] = index + 1),
                ),
              ),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  IconData _getIconFromName(String name) {
    switch (name) {
      case 'email':
        return Icons.email;
      case 'person':
        return Icons.person;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final encuestaData = encuesta;

    return Scaffold(
      appBar: AppBar(title: const Text('Encuesta de satisfacción y feedback')),
      body: encuestaData == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Text(
                      encuestaData['titulo'],
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ...List.generate(
                      encuestaData['secciones'].length,
                      (i) {
                        final seccion = encuestaData['secciones'][i];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              seccion['titulo'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (seccion['descripcion'] != null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(
                                  seccion['descripcion'],
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.grey),
                                ),
                              ),
                            const Divider(),
                            ...seccion['preguntas']
                                .map<Widget>((p) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      child: _buildPregunta(p),
                                    ))
                                .toList(),
                            const SizedBox(height: 20),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _enviarRespuestas,
                      icon: const Icon(Icons.send),
                      label: const Text('Enviar por correo'),
                    ),
                    const SizedBox(height: 40),

                    Image.asset(
                      "assets/Gsinfondo.png",
                      width: 120,
                      height: 120,
                    ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              "Creador: Hikidetsu",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Objetivo: Esta aplicación fue creada con la intención de que el usuario pueda listar de forma rápida y cómoda los videojuegos que esté jugando, dándoles una puntuación y un estado.",
                              style: TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 20),
                            Text(
                              "Versión: 1.0\n\nMuchas gracias por utilizar esta aplicación.",
                              style: TextStyle(
                                  fontSize: 14, color: Colors.black54),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
