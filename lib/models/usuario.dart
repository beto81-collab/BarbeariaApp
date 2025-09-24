class Usuario {
  final String id;
  final String nome;
  final String email;
  final String telefone;
  final String? foto;
  final TipoUsuario tipo;
  final DateTime dataCadastro;
  final DateTime? dataNascimento; // Novo campo
  final Map<String, dynamic>?
  presenteAniversario; // Campo para presente de aniversário

  const Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.telefone,
    this.foto,
    required this.tipo,
    required this.dataCadastro,
    this.dataNascimento, // Novo campo opcional
    this.presenteAniversario, // Novo campo para presente
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'foto': foto,
      'tipo': tipo.name,
      'dataCadastro': dataCadastro.toIso8601String(),
      'dataNascimento': dataNascimento?.toIso8601String(),
      'presenteAniversario': presenteAniversario,
    };
  }

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as String,
      nome: json['nome'] as String,
      email: json['email'] as String,
      telefone: json['telefone'] as String,
      foto: json['foto'] as String?,
      tipo: TipoUsuario.values.firstWhere(
        (e) => e.name == json['tipo'],
        orElse: () => TipoUsuario.cliente,
      ),
      dataCadastro: DateTime.parse(json['dataCadastro'] as String),
      dataNascimento: json['dataNascimento'] != null
          ? DateTime.parse(json['dataNascimento'] as String)
          : null,
      presenteAniversario: json['presenteAniversario'] as Map<String, dynamic>?,
    );
  }

  bool get isAdmin => tipo == TipoUsuario.admin;
  bool get isBarbeiro => tipo == TipoUsuario.barbeiro;
  bool get isCliente => tipo == TipoUsuario.cliente;

  // Verificar se é aniversário hoje
  bool get isAniversarioHoje {
    if (dataNascimento == null) return false;
    final hoje = DateTime.now();
    return dataNascimento!.day == hoje.day &&
        dataNascimento!.month == hoje.month;
  }

  // Calcular idade
  int? get idade {
    if (dataNascimento == null) return null;
    final hoje = DateTime.now();
    int idade = hoje.year - dataNascimento!.year;
    if (hoje.month < dataNascimento!.month ||
        (hoje.month == dataNascimento!.month &&
            hoje.day < dataNascimento!.day)) {
      idade--;
    }
    return idade;
  }
}

enum TipoUsuario {
  cliente,
  barbeiro,
  admin;

  String get label {
    switch (this) {
      case TipoUsuario.cliente:
        return 'Cliente';
      case TipoUsuario.barbeiro:
        return 'Barbeiro';
      case TipoUsuario.admin:
        return 'Administrador';
    }
  }
}
