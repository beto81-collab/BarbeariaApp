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
  final Map<String, dynamic>? premioProgramaPontos; // prêmio do programa de pontos (mapa bruto)
  final int atendimentos; // Novo campo
  final int pontosFidelidade; // Novo campo para fidelidade

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
    this.premioProgramaPontos,
    this.atendimentos = 0, // Valor padrão
    this.pontosFidelidade = 0, // Valor padrão
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
      'premioProgramaPontos': premioProgramaPontos,
      'atendimentos': atendimentos, // Adicionado aqui
      'pontosFidelidade': pontosFidelidade,
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
    premioProgramaPontos: json['premioProgramaPontos'] != null
      ? Map<String, dynamic>.from(json['premioProgramaPontos'] as Map)
      : null,
      atendimentos: json['atendimentos'] != null
          ? (json['atendimentos'] is int
                ? json['atendimentos'] as int
                : int.tryParse(json['atendimentos'].toString()) ?? 0)
          : 0, // Mapeado aqui
      pontosFidelidade: json['pontosFidelidade'] != null
          ? (json['pontosFidelidade'] is int
                ? json['pontosFidelidade'] as int
                : int.tryParse(json['pontosFidelidade'].toString()) ?? 0)
          : 0,
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
