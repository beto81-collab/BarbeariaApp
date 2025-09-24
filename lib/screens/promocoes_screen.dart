import 'package:flutter/material.dart';
import '../models/promocao.dart';
import '../services/firebase_service.dart';

class PromocoesScreen extends StatefulWidget {
  const PromocoesScreen({super.key});

  @override
  State<PromocoesScreen> createState() => _PromocoesScreenState();
}

class _PromocoesScreenState extends State<PromocoesScreen> {
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
        onPressed: () => _abrirDialogPromocao(context),
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
  }) async {
    final result = await showDialog<Promocao>(
      context: context,
      builder: (context) => _DialogPromocao(promocao: promocao),
    );
    if (result != null) {
      if (promocao == null) {
        await FirebaseService.criarPromocao(result);
      } else {
        await FirebaseService.atualizarPromocao(result);
      }
    }
  }
}

class _DialogPromocao extends StatefulWidget {
  final Promocao? promocao;
  const _DialogPromocao({this.promocao});

  @override
  State<_DialogPromocao> createState() => _DialogPromocaoState();
}

class _DialogPromocaoState extends State<_DialogPromocao> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tituloController;
  late TextEditingController _descricaoController;
  late TextEditingController _descontoController;
  DateTime? _validade;

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
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _descontoController.dispose();
    super.dispose();
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
              Row(
                children: [
                  const Text('Validade:'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _validade == null
                          ? 'Sem validade'
                          : '${_validade!.day.toString().padLeft(2, '0')}/${_validade!.month.toString().padLeft(2, '0')}/${_validade!.year}',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _validade ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 1),
                        ),
                        lastDate: DateTime.now().add(
                          const Duration(days: 365 * 5),
                        ),
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
            if (_formKey.currentState?.validate() ?? false) {
              final promocao = Promocao(
                id: widget.promocao?.id ?? '',
                titulo: _tituloController.text.trim(),
                descricao: _descricaoController.text.trim(),
                desconto: double.parse(_descontoController.text.trim()),
                validade: _validade,
              );
              Navigator.of(context).pop(promocao);
            }
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
