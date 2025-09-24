import 'package:flutter/material.dart';
import '../models/produto.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProdutosScreen extends StatelessWidget {
  const ProdutosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Produtos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Adicionar Produto',
            onPressed: () => _showProdutoDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Produto>>(
        stream: FirebaseService.streamProdutos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final produtos = snapshot.data ?? [];
          if (produtos.isEmpty) {
            return const Center(child: Text('Nenhum produto cadastrado.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: produtos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final produto = produtos[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.secondaryColor.withOpacity(0.1),
                    child: const Icon(
                      Icons.shopping_bag,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                  title: Text(
                    produto.nome,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(produto.descricao),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        produto.precoFormatado,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: AppTheme.secondaryColor,
                        ),
                        tooltip: 'Editar',
                        onPressed: () =>
                            _showProdutoDialog(context, produto: produto),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: AppTheme.errorColor,
                        ),
                        tooltip: 'Remover',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Remover produto'),
                              content: Text(
                                'Deseja remover o produto "${produto.nome}"?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancelar'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Remover'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await FirebaseService.removerProduto(produto.id);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showProdutoDialog(BuildContext context, {Produto? produto}) {
    showDialog(
      context: context,
      builder: (ctx) => _ProdutoDialog(produto: produto),
    );
  }
}

class _ProdutoDialog extends StatefulWidget {
  final Produto? produto;
  const _ProdutoDialog({this.produto});

  @override
  State<_ProdutoDialog> createState() => _ProdutoDialogState();
}

class _ProdutoDialogState extends State<_ProdutoDialog> {
  void _removerImagem() {
    setState(() {
      _imagemFile = null;
      _fotoUrl = null;
    });
  }

  File? _imagemFile;
  String? _fotoUrl;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _descricaoController;
  late TextEditingController _precoController;
  late TextEditingController _estoqueController;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.produto?.nome ?? '');
    _descricaoController = TextEditingController(
      text: widget.produto?.descricao ?? '',
    );
    _precoController = TextEditingController(
      text: widget.produto?.preco.toString() ?? '',
    );
    _estoqueController = TextEditingController(
      text: widget.produto?.estoque.toString() ?? '',
    );
    _fotoUrl = widget.produto?.foto;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _precoController.dispose();
    _estoqueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.produto == null ? 'Adicionar Produto' : 'Editar Produto',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Campo de imagem
              Stack(
                alignment: Alignment.topRight,
                children: [
                  if (_imagemFile != null)
                    Image.file(
                      _imagemFile!,
                      height: 120,
                      width: 120,
                      fit: BoxFit.cover,
                    )
                  else if (_fotoUrl != null && _fotoUrl!.isNotEmpty)
                    Image.network(
                      _fotoUrl!,
                      height: 120,
                      width: 120,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      height: 120,
                      width: 120,
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.image,
                        size: 60,
                        color: Colors.grey,
                      ),
                    ),
                  if (_imagemFile != null ||
                      (_fotoUrl != null && _fotoUrl!.isNotEmpty))
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      tooltip: 'Remover imagem',
                      onPressed: _removerImagem,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Tirar foto'),
                    onPressed: _pickImageFromCamera,
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galeria'),
                    onPressed: _pickImageFromGallery,
                  ),
                ],
              ),
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe o nome' : null,
              ),
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(labelText: 'Descrição'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe a descrição' : null,
              ),
              TextFormField(
                controller: _precoController,
                decoration: const InputDecoration(labelText: 'Preço'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe o preço' : null,
              ),
              TextFormField(
                controller: _estoqueController,
                decoration: const InputDecoration(labelText: 'Estoque'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe o estoque' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _salvarProduto, child: const Text('Salvar')),
      ],
    );
  }

  void _salvarProduto() async {
    if (_formKey.currentState?.validate() != true) return;
    final nome = _nomeController.text.trim();
    final descricao = _descricaoController.text.trim();
    final preco =
        double.tryParse(_precoController.text.replaceAll(',', '.')) ?? 0.0;
    final estoque = int.tryParse(_estoqueController.text) ?? 0;

    String fotoUrl = _fotoUrl ?? '';
    if (_imagemFile != null) {
      // Upload da imagem para o Firebase Storage
      fotoUrl = await FirebaseService.uploadImagemProduto(_imagemFile!);
    }

    if (widget.produto == null) {
      // Adicionar novo produto
      final novo = Produto(
        id: '',
        nome: nome,
        descricao: descricao,
        preco: preco,
        categoria: '',
        marca: '',
        foto: fotoUrl,
        avaliacao: 0,
        estoque: estoque,
      );
      await FirebaseService.adicionarProduto(novo);
    } else {
      // Editar produto existente
      final editado = Produto(
        id: widget.produto!.id,
        nome: nome,
        descricao: descricao,
        preco: preco,
        categoria: widget.produto!.categoria,
        marca: widget.produto!.marca,
        foto: fotoUrl,
        avaliacao: widget.produto!.avaliacao,
        estoque: estoque,
        disponivel: widget.produto!.disponivel,
      );
      await FirebaseService.atualizarProduto(editado);
    }
    Navigator.pop(context);
  }

  Future<void> _pickImageFromCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _imagemFile = File(pickedFile.path);
        _fotoUrl = null;
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _imagemFile = File(pickedFile.path);
        _fotoUrl = null;
      });
    }
  }
}
