import 'package:flutter/material.dart';
import '../models/promocao.dart';
import '../models/produto.dart';
import '../models/servico.dart';
import '../services/firebase_service.dart';

class PromocoesScreen extends StatefulWidget {
  const PromocoesScreen({super.key});

  // Nota: fluxo de criação de promoção
  // - Ao clicar no FAB (+) o admin escolhe primeiro se a promoção é para
  //   um Produto ou para um Serviço.
  // - Em seguida é exibida uma lista (bottom sheet) para selecionar o item
  //   alvo da promoção.
  // - Depois da seleção, abre-se o diálogo de criação/edição da promoção
  //   com o campo produtoId/servicoId já preenchido.

  @override
  State<PromocoesScreen> createState() => _PromocoesScreenState();
}

class _PromocoesScreenState extends State<PromocoesScreen> {
  final Map<String, String> _produtosById = {};
  final Map<String, String> _servicosById = {};

  @override
  void initState() {
    super.initState();
    // Carregar nomes de produtos e serviços para exibir na lista de promoções
    FirebaseService.obterProdutos().then((lista) {
      setState(() {
        for (var p in lista) {
          _produtosById[p.id] = p.nome;
        }
      });
    });
    FirebaseService.obterServicos().then((lista) {
      setState(() {
        for (var s in lista) {
          _servicosById[s.id] = s.nome;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Promoções')),
      body: StreamBuilder<List<Promocao>>(
        stream: FirebaseService.streamPromocoes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final promocoes = snapshot.data ?? [];
          if (promocoes.isEmpty) {
            return const Center(child: Text('Nenhuma promoção cadastrada.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: promocoes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final p = promocoes[index];
              return Card(
                child: ListTile(
                  title: Text(
                    p.titulo,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.descricao),
                      if (p.produtoId != null && p.produtoId!.isNotEmpty)
                        Text(
                          'Aplicada em produto: ${_produtosById[p.produtoId] ?? p.produtoId}',
                        ),
                      if (p.servicoId != null && p.servicoId!.isNotEmpty)
                        Text(
                          'Aplicada em serviço: ${_servicosById[p.servicoId] ?? p.servicoId}',
                        ),
                      Text('Desconto: ${p.desconto.toStringAsFixed(2)}%'),
                      if (p.validade != null)
                        Text(
                          'Válida até: ${p.validade!.day.toString().padLeft(2, '0')}/${p.validade!.month.toString().padLeft(2, '0')}/${p.validade!.year}',
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () =>
                            _abrirDialogPromocao(context, promocao: p),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removerPromocao(p.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _criarPromocaoComSelecao(context),
        tooltip: 'Nova promoção',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _removerPromocao(String id) async {
    await FirebaseService.removerPromocao(id);
  }

  Future<void> _abrirDialogPromocao(
    BuildContext context, {
    Promocao? promocao,
    Produto? produto,
    Servico? servico,
  }) async {
    final result = await showDialog<Promocao>(
      context: context,
      builder: (context) => _DialogPromocao(
        promocao: promocao,
        produto: produto,
        servico: servico,
      ),
    );
    if (result != null) {
      if (promocao == null) {
        await FirebaseService.criarPromocao(result);
      } else {
        await FirebaseService.atualizarPromocao(result);
      }
    }
  }

  Future<void> _criarPromocaoComSelecao(BuildContext context) async {
    // Primeiro pergunta se é para Produto ou Serviço
    final escolha = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.shopping_bag),
            title: const Text('Produto'),
            onTap: () => Navigator.of(ctx).pop('produto'),
          ),
          ListTile(
            leading: const Icon(Icons.design_services),
            title: const Text('Serviço'),
            onTap: () => Navigator.of(ctx).pop('servico'),
          ),
          ListTile(
            leading: const Icon(Icons.close),
            title: const Text('Cancelar'),
            onTap: () => Navigator.of(ctx).pop(null),
          ),
        ],
      ),
    );

    if (escolha == null) return; // cancelado

    if (escolha == 'produto') {
      // Mostrar lista de produtos para selecionar
      final produto = await showModalBottomSheet<Produto>(
        context: context,
        builder: (ctx) => SizedBox(
          height: 400,
          child: StreamBuilder<List<Produto>>(
            stream: FirebaseService.streamProdutos(),
            builder: (context, snapshot) {
              final lista = snapshot.data ?? [];
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (lista.isEmpty)
                return const Center(child: Text('Nenhum produto disponível'));
              return ListView.separated(
                itemCount: lista.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final p = lista[index];
                  return ListTile(
                    leading:
                        null, // Foto removida intencionalmente da listagem de seleção para
                    // evitar problemas de carregamento. Mostrar apenas texto.
                    title: Text(p.nome),
                    subtitle: Text(p.precoFormatado),
                    onTap: () => Navigator.of(ctx).pop(p),
                  );
                },
              );
            },
          ),
        ),
      );

      if (produto != null) {
        await _abrirDialogPromocao(context, produto: produto);
      }
    } else if (escolha == 'servico') {
      final servico = await showModalBottomSheet<Servico>(
        context: context,
        builder: (ctx) => SizedBox(
          height: 400,
          child: StreamBuilder<List<Servico>>(
            stream: FirebaseService.streamServicos(),
            builder: (context, snapshot) {
              final lista = snapshot.data ?? [];
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (lista.isEmpty)
                return const Center(child: Text('Nenhum serviço disponível'));
              return ListView.separated(
                itemCount: lista.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final s = lista[index];
                  return ListTile(
                    leading: s.icone.isNotEmpty ? Icon(Icons.circle) : null,
                    title: Text(s.nome),
                    subtitle: Text(s.precoFormatado),
                    onTap: () => Navigator.of(ctx).pop(s),
                  );
                },
              );
            },
          ),
        ),
      );

      if (servico != null) {
        await _abrirDialogPromocao(context, servico: servico);
      }
    }
  }
}

class _DialogPromocao extends StatefulWidget {
  final Promocao? promocao;
  final Produto? produto;
  final Servico? servico;

  const _DialogPromocao({this.promocao, this.produto, this.servico});

  @override
  State<_DialogPromocao> createState() => _DialogPromocaoState();
}

class _DialogPromocaoState extends State<_DialogPromocao> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tituloController;
  late TextEditingController _descricaoController;
  late TextEditingController _descontoController;
  DateTime? _validade;
  String? _produtoId;
  String? _servicoId;
  Produto? _produto;
  Servico? _servico;
  double? _valorOriginal;
  double? _valorComDesconto;

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController(
      text: widget.promocao?.titulo ?? '',
    );
    _descricaoController = TextEditingController(
      text: widget.promocao?.descricao ?? '',
    );
    _descontoController = TextEditingController(
      text: widget.promocao?.desconto.toString() ?? '',
    );
    _validade = widget.promocao?.validade;
    _produto = widget.produto;
    _servico = widget.servico;
    _produtoId = widget.produto?.id ?? widget.promocao?.produtoId;
    _servicoId = widget.servico?.id ?? widget.promocao?.servicoId;

    // preencher título/descrição/valor quando tiver produto/servico
    if (_produto != null) {
      _tituloController.text = _produto!.nome;
      _descricaoController.text = _produto!.descricao;
      _valorOriginal = _produto!.preco;
    } else if (_servico != null) {
      _tituloController.text = _servico!.nome;
      _descricaoController.text = _servico!.descricao;
      _valorOriginal = _servico!.preco;
    }

    // inicializa valor com desconto
    _computeValorComDesconto();

    // atualizar em tempo real quando admin digitar o desconto
    _descontoController.addListener(_computeValorComDesconto);
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _descontoController.removeListener(_computeValorComDesconto);
    _descontoController.dispose();
    super.dispose();
  }

  void _computeValorComDesconto() {
    final d = double.tryParse(_descontoController.text.trim());
    if (_valorOriginal == null || d == null) {
      setState(() {
        _valorComDesconto = null;
      });
      return;
    }
    final calculado = _valorOriginal! * (1 - (d / 100));
    setState(() => _valorComDesconto = calculado);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.promocao == null ? 'Nova Promoção' : 'Editar Promoção',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe o título' : null,
              ),
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(labelText: 'Descrição'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe a descrição' : null,
              ),
              TextFormField(
                controller: _descontoController,
                decoration: const InputDecoration(labelText: 'Desconto (%)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final d = double.tryParse(v ?? '');
                  if (d == null || d < 0) return 'Informe um valor válido';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              // Se o item selecionado tem preço, mostrar valor original e valor com desconto
              const SizedBox(height: 8),
              if (_valorOriginal != null) ...[
                Row(
                  children: [
                    const Text('Valor original:'),
                    const SizedBox(width: 8),
                    Text(
                      'R\$ ${_valorOriginal!.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Valor com desconto:'),
                    const SizedBox(width: 8),
                    Text(
                      _valorComDesconto == null
                          ? '-'
                          : 'R\$ ${_valorComDesconto!.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Validade:'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _validade == null
                          ? ''
                          : '${_validade!.day.toString().padLeft(2, '0')}/${_validade!.month.toString().padLeft(2, '0')}/${_validade!.year}',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                        confirmText: 'OK', // ou '' / ' ' conforme preferir
                        builder: (ctx, child) {
                          final base = Theme.of(ctx);
                          return Theme(
                            data: base.copyWith(
                              textButtonTheme: TextButtonThemeData(
                                style: ButtonStyle(
                                  foregroundColor: MaterialStateProperty.all(
                                    Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) setState(() => _validade = picked);
                    },
                  ),
                  if (_validade != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _validade = null),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) return;

            // Garantir que exista um alvo (produto ou serviço)
            if ((_produtoId == null || _produtoId!.isEmpty) &&
                (_servicoId == null || _servicoId!.isEmpty)) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Selecione um alvo'),
                  content: const Text(
                    'Selecione um produto ou um serviço para aplicar a promoção.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
              return;
            }

            final promocao = Promocao(
              id: widget.promocao?.id ?? '',
              titulo: _tituloController.text.trim(),
              descricao: _descricaoController.text.trim(),
              desconto: double.parse(_descontoController.text.trim()),
              validade: _validade,
              produtoId: _produtoId,
              servicoId: _servicoId,
            );
            Navigator.of(context).pop(promocao);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
