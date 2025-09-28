import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Para kIsWeb
import '../models/produto.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
// 'dart:typed_data' não é necessário porque usamos 'foundation.dart' para Uint8List

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
                elevation: 4,
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: produto.foto.isNotEmpty
                        ? Image.network(
                            produto.foto,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 60,
                                  height: 60,
                                  color: AppTheme.secondaryColor.withAlpha(
                                    (0.1 * 255).round(),
                                  ),
                                  child: const Icon(
                                    Icons.shopping_bag,
                                    color: AppTheme.secondaryColor,
                                  ),
                                ),
                          )
                        : Container(
                            width: 60,
                            height: 60,
                            color: AppTheme.secondaryColor.withAlpha(
                              (0.1 * 255).round(),
                            ),
                            child: const Icon(
                              Icons.shopping_bag,
                              color: AppTheme.secondaryColor,
                            ),
                          ),
                  ),
                  title: Text(
                    produto.nome,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(produto.descricao),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.inventory,
                            size: 16,
                            color: produto.estoque > 0
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Estoque: ${produto.estoque}',
                            style: TextStyle(
                              fontSize: 12,
                              color: produto.estoque > 0
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
  bool _carregandoImagem = false;
  void _removerImagem() {
    setState(() {
      _imagemFile = null;
      _imagemBytes = null;
      _fotoUrl = null;
    });
  }

  File? _imagemFile;
  Uint8List? _imagemBytes; // Para armazenar bytes da imagem na web
  String? _fotoUrl;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _descricaoController;
  late TextEditingController _precoController;
  late TextEditingController _estoqueController;
  late TextEditingController _categoriaController;
  late TextEditingController _marcaController;
  CategoriaProduto? _categoriaSelecionada;

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
    _categoriaController = TextEditingController(
      text: widget.produto?.categoria ?? '',
    );
    _marcaController = TextEditingController(text: widget.produto?.marca ?? '');
    _fotoUrl = widget.produto?.foto;

    // Definir categoria selecionada se for edição
    if (widget.produto != null && widget.produto!.categoria.isNotEmpty) {
      try {
        _categoriaSelecionada = CategoriaProduto.values.firstWhere(
          (cat) => cat.label == widget.produto!.categoria,
        );
      } catch (e) {
        _categoriaSelecionada = null;
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _precoController.dispose();
    _estoqueController.dispose();
    _categoriaController.dispose();
    _marcaController.dispose();
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
                  if (kIsWeb && _imagemBytes != null)
                    Image.memory(
                      _imagemBytes!,
                      height: 120,
                      width: 120,
                      fit: BoxFit.cover,
                    )
                  else if (!kIsWeb && _imagemFile != null)
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
                  if ((kIsWeb && _imagemBytes != null) ||
                      (!kIsWeb && _imagemFile != null) ||
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
              // Dropdown para categoria
              DropdownButtonFormField<CategoriaProduto>(
                value: _categoriaSelecionada,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: CategoriaProduto.values.map((categoria) {
                  return DropdownMenuItem<CategoriaProduto>(
                    value: categoria,
                    child: Text(categoria.label),
                  );
                }).toList(),
                onChanged: (CategoriaProduto? newValue) {
                  setState(() {
                    _categoriaSelecionada = newValue;
                    _categoriaController.text = newValue?.label ?? '';
                  });
                },
                validator: (v) => v == null ? 'Selecione uma categoria' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _marcaController,
                decoration: const InputDecoration(labelText: 'Marca'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe a marca' : null,
              ),
              const SizedBox(height: 12),
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
    debugPrint("Iniciando processo de salvar produto");
    if (_formKey.currentState?.validate() != true) return;

    final nome = _nomeController.text.trim();
    final descricao = _descricaoController.text.trim();
    final preco =
        double.tryParse(_precoController.text.replaceAll(',', '.')) ?? 0.0;
    final estoque = int.tryParse(_estoqueController.text) ?? 0;
    final categoria = _categoriaSelecionada?.label ?? '';
    final marca = _marcaController.text.trim();

    String fotoUrl = _fotoUrl ?? '';
    // Faz upload da imagem apenas se houver uma nova selecionada
    if (kIsWeb && _imagemBytes != null) {
      fotoUrl = await FirebaseService.uploadImagemProdutoBytes(_imagemBytes!);
      debugPrint("Imagem salva com URL: $fotoUrl");
      // Registrar a imagem também na vitrine
      try {
        if (fotoUrl.isNotEmpty) {
          await FirebaseService.adicionarImagemVitrinePorUrl(fotoUrl);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Imagem adicionada à vitrine')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar imagem à vitrine: $e')),
        );
      }
    } else if (!kIsWeb && _imagemFile != null) {
      fotoUrl = await FirebaseService.uploadImagemProduto(_imagemFile!);
      debugPrint("Imagem salva com URL: $fotoUrl");
      // Registrar a imagem também na vitrine
      try {
        if (fotoUrl.isNotEmpty) {
          await FirebaseService.adicionarImagemVitrinePorUrl(fotoUrl);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Imagem adicionada à vitrine')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar imagem à vitrine: $e')),
        );
      }
    }

    if (widget.produto == null) {
      // Adicionar novo produto
      final novo = Produto(
        id: '',
        nome: nome,
        descricao: descricao,
        preco: preco,
        categoria: categoria,
        marca: marca,
        foto: fotoUrl,
        avaliacao: 0,
        estoque: estoque,
      );
      await FirebaseService.adicionarProduto(novo);
      if (!mounted) return;
    } else {
      // Editar produto existente
      final editado = Produto(
        id: widget.produto!.id,
        nome: nome,
        descricao: descricao,
        preco: preco,
        categoria: categoria,
        marca: marca,
        foto: fotoUrl,
        avaliacao: widget.produto!.avaliacao,
        estoque: estoque,
        disponivel: widget.produto!.disponivel,
      );
      await FirebaseService.atualizarProduto(editado);
      if (!mounted) return;
    }
    Navigator.pop(context);
  }

  Future<void> _pickImageFromCamera() async {
    if (_carregandoImagem) return;
    setState(() => _carregandoImagem = true);
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        if (kIsWeb) {
          // Para web, ler os bytes da imagem
          final bytes = await pickedFile.readAsBytes();
          if (!mounted) return;
          setState(() {
            _imagemBytes = bytes;
            _imagemFile = null;
            _fotoUrl = null;
          });
        } else {
          if (!mounted) return;
          // Para mobile/desktop, usar File
          setState(() {
            _imagemFile = File(pickedFile.path);
            _imagemBytes = null;
            _fotoUrl = null;
          });
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagem selecionada com sucesso')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao acessar câmera: $e')));
    } finally {
      if (mounted) setState(() => _carregandoImagem = false);
    }
  }

  Future<void> _pickImageFromGallery() async {
    if (_carregandoImagem) return;
    setState(() => _carregandoImagem = true);
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        if (kIsWeb) {
          // Para web, ler os bytes da imagem
          final bytes = await pickedFile.readAsBytes();
          if (!mounted) return;
          setState(() {
            _imagemBytes = bytes;
            _imagemFile = null;
            _fotoUrl = null;
          });
        } else {
          if (!mounted) return;
          // Para mobile/desktop, usar File
          setState(() {
            _imagemFile = File(pickedFile.path);
            _imagemBytes = null;
            _fotoUrl = null;
          });
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagem selecionada da galeria')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao abrir galeria: $e')));
    } finally {
      if (mounted) setState(() => _carregandoImagem = false);
    }
  }
}
