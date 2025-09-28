import 'package:flutter/material.dart';
import '../models/servico.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class ServicosScreen extends StatelessWidget {
  const ServicosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Serviços'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Adicionar Serviço',
            onPressed: () => _showServicoDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Servico>>(
        stream: FirebaseService.streamServicos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final servicos = snapshot.data ?? [];
          if (servicos.isEmpty) {
            return const Center(child: Text('Nenhum serviço cadastrado.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: servicos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final servico = servicos[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.secondaryColor.withAlpha(
                      (0.1 * 255).round(),
                    ),
                    child: const Icon(
                      Icons.design_services,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                  title: Text(
                    servico.nome,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${servico.descricao}\n${servico.duracaoFormatada}',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        servico.precoFormatado,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: AppTheme.secondaryColor,
                        ),
                        tooltip: 'Editar',
                        onPressed: () =>
                            _showServicoDialog(context, servico: servico),
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
                              title: const Text('Remover serviço'),
                              content: Text(
                                'Deseja remover o serviço "${servico.nome}"?',
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
                            await FirebaseService.removerServico(servico.id);
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

  void _showServicoDialog(BuildContext context, {Servico? servico}) {
    showDialog(
      context: context,
      builder: (ctx) => _ServicoDialog(servico: servico),
    );
  }
}

class _ServicoDialog extends StatefulWidget {
  final Servico? servico;
  const _ServicoDialog({this.servico});

  @override
  State<_ServicoDialog> createState() => _ServicoDialogState();
}

class _ServicoDialogState extends State<_ServicoDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _descricaoController;
  late TextEditingController _precoController;
  late TextEditingController _duracaoController;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.servico?.nome ?? '');
    _descricaoController = TextEditingController(
      text: widget.servico?.descricao ?? '',
    );
    _precoController = TextEditingController(
      text: widget.servico?.preco.toString() ?? '',
    );
    _duracaoController = TextEditingController(
      text: widget.servico?.duracao.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _precoController.dispose();
    _duracaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.servico == null ? 'Adicionar Serviço' : 'Editar Serviço',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                controller: _duracaoController,
                decoration: const InputDecoration(labelText: 'Duração (min)'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe a duração' : null,
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
        ElevatedButton(onPressed: _salvarServico, child: const Text('Salvar')),
      ],
    );
  }

  void _salvarServico() async {
    if (_formKey.currentState?.validate() != true) return;
    final nome = _nomeController.text.trim();
    final descricao = _descricaoController.text.trim();
    final preco =
        double.tryParse(_precoController.text.replaceAll(',', '.')) ?? 0.0;
    final duracao = int.tryParse(_duracaoController.text) ?? 0;

    if (widget.servico == null) {
      // Adicionar novo serviço
      final novo = Servico(
        id: '',
        nome: nome,
        descricao: descricao,
        preco: preco,
        duracao: duracao,
        icone: '',
      );
      await FirebaseService.adicionarServico(novo);
    } else {
      // Editar serviço existente
      final editado = Servico(
        id: widget.servico!.id,
        nome: nome,
        descricao: descricao,
        preco: preco,
        duracao: duracao,
        icone: widget.servico!.icone,
      );
      await FirebaseService.atualizarServico(editado);
    }
    Navigator.pop(context);
  }
}
