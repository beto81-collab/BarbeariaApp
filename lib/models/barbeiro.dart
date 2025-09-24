class Barbeiro {
  final String id;
  final String nome;
  final String especialidade;
  final String foto;
  final double avaliacao;
  final String telefone;
  final String email;
  final bool disponivel;

  const Barbeiro({
    required this.id,
    required this.nome,
    required this.especialidade,
    required this.foto,
    required this.avaliacao,
    required this.telefone,
    required this.email,
    this.disponivel = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'especialidade': especialidade,
      'foto': foto,
      'avaliacao': avaliacao,
      'telefone': telefone,
      'email': email,
      'disponivel': disponivel,
    };
  }

  factory Barbeiro.fromJson(Map<String, dynamic> json) {
    return Barbeiro(
      id: json['id'] as String,
      nome: json['nome'] as String,
      especialidade: json['especialidade'] as String,
      foto: json['foto'] as String,
      avaliacao: (json['avaliacao'] as num).toDouble(),
      telefone: json['telefone'] as String,
      email: json['email'] as String,
      disponivel: json['disponivel'] as bool? ?? true,
    );
  }
}
