class Produto {
  final String id;
  final String nome;
  final String descricao;
  final double preco;
  final String categoria;
  final String marca;
  final String foto;
  final bool disponivel;
  final double avaliacao;
  final int estoque;

  const Produto({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.preco,
    required this.categoria,
    required this.marca,
    required this.foto,
    this.disponivel = true,
    required this.avaliacao,
    required this.estoque,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'preco': preco,
      'categoria': categoria,
      'marca': marca,
      'foto': foto,
      'disponivel': disponivel,
      'avaliacao': avaliacao,
      'estoque': estoque,
    };
  }

  factory Produto.fromJson(Map<String, dynamic> json) {
    return Produto(
      id: json['id'] as String,
      nome: json['nome'] as String,
      descricao: json['descricao'] as String,
      preco: (json['preco'] as num).toDouble(),
      categoria: json['categoria'] as String,
      marca: json['marca'] as String,
      foto: json['foto'] as String,
      disponivel: json['disponivel'] as bool? ?? true,
      avaliacao: (json['avaliacao'] as num).toDouble(),
      estoque: json['estoque'] as int,
    );
  }

  String get precoFormatado {
    return 'R\$ ${preco.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  bool get emEstoque => estoque > 0;

  String get statusEstoque {
    if (estoque == 0) return 'Fora de estoque';
    if (estoque < 5) return 'Últimas unidades';
    return 'Em estoque';
  }
}

enum CategoriaProduto {
  shampoo('Shampoo'),
  condicionador('Condicionador'),
  creme('Creme'),
  gel('Gel'),
  pomada('Pomada'),
  oleo('Óleo'),
  cera('Cera'),
  spray('Spray'),
  afterShave('After Shave'),
  perfume('Perfume');

  const CategoriaProduto(this.label);
  final String label;
}
