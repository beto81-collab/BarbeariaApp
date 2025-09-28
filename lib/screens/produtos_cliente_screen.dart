import 'package:flutter/material.dart';
import '../models/produto.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class ProdutosClienteScreen extends StatefulWidget {
  const ProdutosClienteScreen({super.key});

  @override
  State<ProdutosClienteScreen> createState() => _ProdutosClienteScreenState();
}

class _ProdutosClienteScreenState extends State<ProdutosClienteScreen> {
  String _categoriaSelecionada = 'Todos';
  final List<String> _categorias = [
    'Todos',
    'Shampoo',
    'Condicionador',
    'Creme',
    'Gel',
    'Pomada',
    'Óleo',
    'Cera',
    'Spray',
    'After Shave',
    'Perfume',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produtos'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Column(
        children: [
          // Filtro por categoria
          Container(
            height: 60,
            color: AppTheme.primaryColor.withAlpha((0.1 * 255).round()),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _categorias.length,
              itemBuilder: (context, index) {
                final categoria = _categorias[index];
                final isSelected = categoria == _categoriaSelecionada;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(categoria),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _categoriaSelecionada = categoria;
                      });
                    },
                    selectedColor: AppTheme.secondaryColor,
                    backgroundColor: Colors.grey[200],
                  ),
                );
              },
            ),
          ),
          // Lista/Grid de produtos
          Expanded(
            child: StreamBuilder<List<Produto>>(
              stream: FirebaseService.streamProdutos(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<Produto> produtos = snapshot.data ?? [];

                // Filtrar por categoria se não for "Todos"
                if (_categoriaSelecionada != 'Todos') {
                  produtos = produtos
                      .where(
                        (produto) => produto.categoria == _categoriaSelecionada,
                      )
                      .toList();
                }

                // Filtrar apenas produtos disponíveis
                produtos = produtos
                    .where((produto) => produto.disponivel)
                    .toList();

                if (produtos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _categoriaSelecionada == 'Todos'
                              ? 'Nenhum produto disponível'
                              : 'Nenhum produto na categoria $_categoriaSelecionada',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: produtos.length,
                  itemBuilder: (context, index) {
                    final produto = produtos[index];
                    return _buildProdutoCard(produto);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProdutoCard(Produto produto) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _mostrarDetalheProduto(produto),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem do produto
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: produto.foto.isNotEmpty
                      ? Image.network(
                          produto.foto,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPlaceholderImage(),
                        )
                      : _buildPlaceholderImage(),
                ),
              ),
            ),
            // Informações do produto
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      produto.nome,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      produto.marca,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            produto.precoFormatado,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.secondaryColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: produto.estoque > 0
                                ? Colors.green.withAlpha((0.2 * 255).round())
                                : Colors.red.withAlpha((0.2 * 255).round()),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            produto.estoque > 0
                                ? 'Disponível'
                                : 'Fora de estoque',
                            style: TextStyle(
                              fontSize: 10,
                              color: produto.estoque > 0
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      color: AppTheme.secondaryColor.withAlpha((0.1 * 255).round()),
      child: const Icon(
        Icons.shopping_bag,
        size: 48,
        color: AppTheme.secondaryColor,
      ),
    );
  }

  void _mostrarDetalheProduto(Produto produto) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Imagem do produto
              Container(
                height: 250,
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: produto.foto.isNotEmpty
                      ? Image.network(
                          produto.foto,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPlaceholderImage(),
                        )
                      : _buildPlaceholderImage(),
                ),
              ),
              // Detalhes do produto
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      produto.nome,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      produto.marca,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Categoria: ${produto.categoria}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      produto.descricao,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            produto.precoFormatado,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.secondaryColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: produto.estoque > 0
                                ? Colors.green.withAlpha((0.2 * 255).round())
                                : Colors.red.withAlpha((0.2 * 255).round()),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            produto.statusEstoque,
                            style: TextStyle(
                              color: produto.estoque > 0
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (produto.avaliacao > 0) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            produto.avaliacao.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Botões
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Fechar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: produto.estoque > 0
                            ? () {
                                Navigator.pop(context);
                                _mostrarMensagemInteresse(produto);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Tenho interesse'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarMensagemInteresse(Produto produto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Interesse registrado em "${produto.nome}". Entre em contato conosco para mais informações!',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
