class Promocao {
  final String id;
  final String titulo;
  final String descricao;
  final double desconto;
  final DateTime? validade;

  Promocao({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.desconto,
    this.validade,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'titulo': titulo,
    'descricao': descricao,
    'desconto': desconto,
    'validade': validade?.toIso8601String(),
  };

  factory Promocao.fromJson(Map<String, dynamic> json) => Promocao(
    id: json['id'] as String,
    titulo: json['titulo'] as String,
    descricao: json['descricao'] as String,
    desconto: (json['desconto'] as num).toDouble(),
    validade: json['validade'] != null && json['validade'] != ''
        ? DateTime.parse(json['validade'])
        : null,
  );
}
