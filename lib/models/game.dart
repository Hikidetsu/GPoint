import 'dart:convert';

class Game {
  final String nombre;
  final String estado;
  final String score;
  final String? genero;
  final String? plataforma;
  final String? sinopsis;
  final String? comentario;
  final String? imagen; 

  Game({
    required this.nombre,
    required this.estado,
    required this.score,
    this.genero,
    this.plataforma,
    this.sinopsis,
    this.comentario,
    this.imagen,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'estado': estado,
      'score': score,
      'genero': genero,
      'plataforma': plataforma,
      'sinopsis': sinopsis,
      'comentario': comentario,
      'imagen': imagen,
    };
  }

  factory Game.fromMap(Map<String, dynamic> map) {
    return Game(
      nombre: map['nombre'] ?? '',
      estado: map['estado'] ?? '',
      score: map['score'] ?? '',
      genero: map['genero'],
      plataforma: map['plataforma'],
      sinopsis: map['sinopsis'],
      comentario: map['comentario'],
      imagen: map['imagen'], 
    );
  }
  String toJson() => json.encode(toMap());

  factory Game.fromJson(String source) => Game.fromMap(json.decode(source));

  Game copyWith({
    String? nombre,
    String? estado,
    String? score,
    String? genero,
    String? plataforma,
    String? sinopsis,
    String? comentario,
    String? imagen,
  }) {
    return Game(
      nombre: nombre ?? this.nombre,
      estado: estado ?? this.estado,
      score: score ?? this.score,
      genero: genero ?? this.genero,
      plataforma: plataforma ?? this.plataforma,
      sinopsis: sinopsis ?? this.sinopsis,
      comentario: comentario ?? this.comentario,
      imagen: imagen ?? this.imagen,
    );
  }
}
