class Servico {
  final String id;
  final String nome;
  final String descricao;
  final double preco;
  final int duracao; // em minutos
  final String icone;

  const Servico({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.preco,
    required this.duracao,
    required this.icone,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'preco': preco,
      'duracao': duracao,
      'icone': icone,
    };
  }

  factory Servico.fromJson(Map<String, dynamic> json) {
    return Servico(
      id: json['id'] as String,
      nome: json['nome'] as String,
      descricao: json['descricao'] as String,
      preco: (json['preco'] as num).toDouble(),
      duracao: json['duracao'] as int,
      icone: json['icone'] as String,
    );
  }

  String get duracaoFormatada {
    final horas = duracao ~/ 60;
    final minutos = duracao % 60;

    if (horas > 0) {
      return minutos > 0 ? '${horas}h ${minutos}min' : '${horas}h';
    } else {
      return '${minutos}min';
    }
  }

  String get precoFormatado {
    return 'R\$ ${preco.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}
