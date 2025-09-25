



class Game {
      final String nombre;
      final String estado;
      final String score;
      final String ?genero;
      final String ?plataforma;
      final String ?sinopsis;
      final String ?comentario;
      final String ?imagen;

      Game({required this.nombre, required this.estado, required this.score, this.imagen, this.genero, this.plataforma, this.sinopsis,this.comentario});
    }
