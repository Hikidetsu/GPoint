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
    this.imagen,
    this.genero,
    this.plataforma,
    this.sinopsis,
    this.comentario,
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
}
