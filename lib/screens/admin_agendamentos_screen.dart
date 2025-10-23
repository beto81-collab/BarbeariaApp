import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/agendamento.dart';
import '../models/servico.dart';
import '../models/usuario.dart';
import '../models/horario.dart';
import '../services/firebase_service.dart';
import 'clientes_screen.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AdminAgendamentosScreen extends StatefulWidget {
  const AdminAgendamentosScreen({super.key});
  @override
  State<AdminAgendamentosScreen> createState() => _AdminAgendamentosScreenState();
}

class _AdminAgendamentosScreenState extends State<AdminAgendamentosScreen> {
  bool _switchBusy = false;

  Color _statusColor(StatusAgendamento status) {
    switch (status) {
      case StatusAgendamento.confirmado:
        return const Color.fromARGB(255, 30, 177, 1);
      case StatusAgendamento.concluido:
        return const Color.fromARGB(255, 0, 119, 255);
      case StatusAgendamento.cancelado:
        return Colors.red;
      case StatusAgendamento.agendado:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  final Map<String, String> _clienteNomes = {};
  final Map<String, String> _servicoNomes = {};

  Future<void> _ensureClienteNome(String clienteId) async {
    if (_clienteNomes.containsKey(clienteId)) return;
    final u = await FirebaseService.obterUsuarioPorId(clienteId);
    if (u != null) setState(() => _clienteNomes[clienteId] = u.nome);
  }

  Future<void> _ensureServicoNome(String servicoId) async {
    if (_servicoNomes.containsKey(servicoId)) return;
    final s = await FirebaseService.obterServicoPorId(servicoId);
    if (s != null) setState(() => _servicoNomes[servicoId] = s.nome);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendamentos (pendentes)'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Column(
        children: [
          _buildAgendamentosToggle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _abrirPreAgendamentoDialog,
                icon: const Icon(Icons.event_available),
                label: const Text('Pré-Agendamentos'),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Agendamento>>(
              stream: FirebaseService.streamAgendamentosPendentes(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print(
                    'Erro no stream de agendamentos pendentes: ${snapshot.error}',
                  );
                  return Center(
                    child: Text(
                      'Erro ao carregar agendamentos: ${snapshot.error}',
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final agendamentos = snapshot.data ?? [];
                print(
                  'Stream agendamentos pendentes - documentos recebidos: ${agendamentos.length}',
                );

                if (agendamentos.isEmpty) {
                  return FutureBuilder<List<Agendamento>>(
                    future: FirebaseService.obterTodosAgendamentos().then(
                      (list) => list
                          .where(
                            (a) =>
                                (a.status.name == 'pendente' ||
                                a.status == StatusAgendamento.agendado),
                          )
                          .toList(),
                    ),
                    builder: (context, snap2) {
                      if (snap2.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final fallback = snap2.data ?? [];
                      print(
                        'Fallback obteve agendamentos pendentes: ${fallback.length}',
                      );
                      if (fallback.isEmpty) {
                        return const Center(
                          child: Text('Nenhum agendamento pendente'),
                        );
                      }
                      return _buildListView(fallback);
                    },
                  );
                }

                return _buildListView(agendamentos);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgendamentosToggle() {
    return StreamBuilder<bool>(
      stream: FirebaseService.streamAgendamentosHabilitados(),
      builder: (context, snapshot) {
        final enabled = snapshot.data ?? true;
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              const Expanded(
                child: Text('Habilitar agendamentos no app do cliente'),
              ),
              Switch(
                value: enabled,
                onChanged: _switchBusy
                    ? null
                    : (v) async {
                        setState(() => _switchBusy = true);
                        try {
                          await FirebaseService.setAgendamentosHabilitados(v);
                        } finally {
                          if (mounted) setState(() => _switchBusy = false);
                        }
                      },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildListView(List<Agendamento> agendamentos) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: agendamentos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final a = agendamentos[index];

        final clienteNomeDoc = a.clienteNome;
        final servicoNomeDoc = a.servicoNome;

        if (clienteNomeDoc == null) _ensureClienteNome(a.clienteId);
        if (servicoNomeDoc == null) _ensureServicoNome(a.servicoId);

        final clienteNome =
            clienteNomeDoc ?? _clienteNomes[a.clienteId] ?? a.clienteId;
        final servicoNome =
            servicoNomeDoc ?? _servicoNomes[a.servicoId] ?? a.servicoId;

        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, color: Colors.indigo, size: 28),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        clienteNome,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      a.toJson()['clienteTelefone']?.toString() ?? '',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.design_services,
                      color: Colors.deepPurple,
                      size: 22,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      servicoNome,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Colors.teal,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${a.dataHora.day.toString().padLeft(2, '0')}/'
                      '${a.dataHora.month.toString().padLeft(2, '0')}/'
                      '${a.dataHora.year} • ${a.dataHora.hour.toString().padLeft(2, '0')}:${a.dataHora.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.timer, color: Colors.deepPurple, size: 20),
                    const SizedBox(width: 4),
                    FutureBuilder<Servico?>(
                      future: FirebaseService.obterServicoPorId(a.servicoId),
                      builder: (ctx, snap) {
                        final s = snap.data;
                        final dur = s?.duracao ?? null;
                        return Text(
                          dur != null ? '${dur} min' : '',
                          style: const TextStyle(fontSize: 15),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.info, color: Colors.blueGrey, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      'Status: ',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(a.status).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        a.status.name,
                        style: TextStyle(
                          color: _statusColor(a.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final bool xs = w < 420;
                    final bool sm = w < 520;
                    final double iconSize = xs ? 14 : (sm ? 16 : 18);
                    final double fontSize = xs ? 10 : (sm ? 12 : 13);
                    final double padH = xs ? 6 : (sm ? 8 : 10);
                    final double padV = xs ? 5 : (sm ? 6 : 8);
                    final double gap = xs ? 6 : 8;
                    final double minH = xs ? 28 : (sm ? 32 : 36);

                    ButtonStyle baseStyle(Color bg, Color fg) => ElevatedButton.styleFrom(
                          backgroundColor: bg,
                          foregroundColor: fg,
                          padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
                          minimumSize: Size(0, minH),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                        );

                    final widgets = <Widget>[
                      ElevatedButton.icon(
                        style: baseStyle(Colors.cyan, Colors.white),
                        icon: Icon(Icons.chat_bubble_outline, size: iconSize),
                        label: Text('Contato', style: TextStyle(fontSize: fontSize)),
                        onPressed: () async {
                          if (!mounted) return;
                          _showContatoActions(
                            context,
                            nome: clienteNome,
                            telefone: a.clienteTelefone,
                            email: a.clienteEmail,
                            clienteId: a.clienteId,
                          );
                        },
                      ),
                      SizedBox(width: gap),
                      ElevatedButton.icon(
                        style: baseStyle(Colors.blue, Colors.white),
                        icon: Icon(Icons.check_circle, size: iconSize),
                        label: Text('Confirmar', style: TextStyle(fontSize: fontSize)),
                        onPressed: () async {
                          await FirebaseService.alterarStatusAgendamento(
                            a.id,
                            StatusAgendamento.confirmado,
                          );
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Agendamento confirmado'),
                            ),
                          );
                        },
                      ),
                      SizedBox(width: gap),
                      ElevatedButton.icon(
                        style: baseStyle(Colors.green, Colors.white),
                        icon: Icon(Icons.check, size: iconSize),
                        label: Text('Concluir', style: TextStyle(fontSize: fontSize)),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Concluir agendamento'),
                              content: const Text(
                                'Deseja marcar este agendamento como concluído? Isso irá removê-lo do sistema.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                                  child: const Text('Concluir'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            try {
                              await FirebaseService.removerAgendamento(a.id);

                              final clienteId = a.clienteId;
                              if (clienteId.isNotEmpty && clienteId != 'loja') {
                                try {
                                  final userMap = await FirebaseService.obterUsuarioMapPorId(clienteId);
                                  final participa = (userMap?['participaProgramaPontos'] ?? false) as bool;
                                  if (!mounted) return;
                                  if (participa) {
                                    await FirebaseService.incrementarPontosFidelidade(clienteId, 1);
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Agendamento concluído e ponto adicionado ao cliente')),
                                    );
                                  } else {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Agendamento concluído')),
                                    );
                                  }
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Agendamento concluído (erro ao adicionar ponto)')),
                                  );
                                }
                              } else {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Agendamento concluído')),
                                );
                              }
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Erro ao concluir agendamento')),
                              );
                            }
                          }
                        },
                      ),
                      SizedBox(width: gap),
                      ElevatedButton.icon(
                        style: baseStyle(Colors.red, Colors.white),
                        icon: Icon(Icons.close, size: iconSize),
                        label: Text('Cancelar', style: TextStyle(fontSize: fontSize)),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Confirmar exclusão'),
                              content: const Text('Deseja remover este agendamento permanentemente do sistema?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                                  child: const Text('Remover'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            try {
                              await FirebaseService.removerAgendamento(a.id);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Agendamento removido')),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Erro ao remover agendamento')),
                              );
                            }
                          }
                        },
                      ),
                      SizedBox(width: gap),
                      ElevatedButton.icon(
                        style: baseStyle(Colors.amber, Colors.black),
                        icon: Icon(Icons.edit, size: iconSize),
                        label: Text('Editar', style: TextStyle(fontSize: fontSize)),
                        onPressed: () async {
                          final novo = await _abrirDialogEditarAgendamento(a);
                          if (novo != null) {
                            try {
                              final disponivel = await _verificarConflitoAgendamento(novo);
                              if (!disponivel) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Horário em conflito com outro agendamento. Escolha outro horário.')),
                                );
                                return;
                              }
                              await FirebaseService.atualizarAgendamento(novo);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Agendamento atualizado')),
                                );
                              }
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Erro ao atualizar agendamento')),
                              );
                            }
                          }
                        },
                      ),
                    ];

                    return Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: widgets,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showContatoActions(
    BuildContext context, {
    required String nome,
    required String clienteId,
    String? telefone,
    String? email,
  }) async {
    // Buscar dados do usuário se faltar telefone/email
    String? fone = telefone;
    String? mail = email;
    if ((fone == null || fone.isEmpty) || (mail == null || mail.isEmpty)) {
      // Apenas tentar buscar quando clienteId válido
      if (clienteId.isNotEmpty && clienteId != 'loja') {
        try {
          final u = await FirebaseService.obterUsuarioPorId(clienteId);
          fone = fone?.isNotEmpty == true ? fone : u?.telefone;
          mail = mail?.isNotEmpty == true ? mail : u?.email;
        } catch (_) {}
      }
    }

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.chat),
              title: Text('WhatsApp de $nome'),
              enabled: (fone != null && fone.isNotEmpty),
              onTap: (fone != null && fone.isNotEmpty)
                  ? () {
                      final cleaned = fone!.replaceAll(RegExp(r'[^0-9+]'), '');
                      final uri = 'https://wa.me/$cleaned';
                      try {
                        launchUrlString(uri);
                      } catch (_) {}
                      Navigator.pop(ctx);
                    }
                  : null,
            ),
            ListTile(
              leading: const Icon(Icons.call),
              title: const Text('Ligar'),
              enabled: (fone != null && fone.isNotEmpty),
              onTap: (fone != null && fone.isNotEmpty)
                  ? () {
                      final cleaned = fone!.replaceAll(RegExp(r'[^0-9+]'), '');
                      final uri = 'tel:$cleaned';
                      try {
                        launchUrlString(uri);
                      } catch (_) {}
                      Navigator.pop(ctx);
                    }
                  : null,
            ),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Enviar e-mail'),
              enabled: (mail != null && mail.isNotEmpty),
              onTap: (mail != null && mail.isNotEmpty)
                  ? () {
                      final uri = 'mailto:$mail';
                      try {
                        launchUrlString(uri);
                      } catch (_) {}
                      Navigator.pop(ctx);
                    }
                  : null,
            ),
            const Divider(height: 0),
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Abrir guia Clientes'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ClientesScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<Agendamento?> _abrirDialogEditarAgendamento(Agendamento original) async {
    try {
      final services = await FirebaseService.obterServicos();
      final horarios = await FirebaseService.buscarHorariosFuncionamento();
      final servicoDoAg = await FirebaseService.obterServicoPorId(original.servicoId);

      DateTime dataSel = DateTime(original.dataHora.year, original.dataHora.month, original.dataHora.day);
      TimeOfDay? selecionado = TimeOfDay(hour: original.dataHora.hour, minute: original.dataHora.minute);

      List<TimeOfDay> slots = _filtrarPassados(dataSel, _slotsParaData(horarios, dataSel));
      try {
        slots = await _filtrarSlotsConsiderandoOcupados(
          dataSel,
          slots,
          services,
          servicoDoAg,
          excludeAgendamentoId: original.id,
        );
      } catch (_) {}

      final result = await showDialog<Agendamento?>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Editar data e horário'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: dataSel,
                              firstDate: DateTime.now().subtract(const Duration(days: 0)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                              locale: const Locale('pt', 'BR'),
                              builder: (context, child) {
                                final base = Theme.of(context);
                                return Theme(
                                  data: base.copyWith(
                                    useMaterial3: false,
                                    textButtonTheme: TextButtonThemeData(
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  child: child ?? const SizedBox.shrink(),
                                );
                              },
                            );
                            if (picked != null) {
                              dataSel = DateTime(picked.year, picked.month, picked.day);
                              selecionado = null;
                              setState(() {});
                              try {
                                final novos = _filtrarPassados(dataSel, _slotsParaData(horarios, dataSel));
                                slots = await _filtrarSlotsConsiderandoOcupados(
                                  dataSel,
                                  novos,
                                  services,
                                  servicoDoAg,
                                  excludeAgendamentoId: original.id,
                                );
                              } catch (_) {
                                slots = _filtrarPassados(dataSel, _slotsParaData(horarios, dataSel));
                              }
                              setState(() {});
                            }
                          },
                          child: Text(
                            '${dataSel.day.toString().padLeft(2, '0')}/${dataSel.month.toString().padLeft(2, '0')}/${dataSel.year}',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Horários disponíveis:', style: Theme.of(context).textTheme.labelLarge),
                  ),
                  const SizedBox(height: 8),
                  if (slots.isEmpty)
                    const SizedBox.shrink()
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final t in slots)
                          ChoiceChip(
                            label: Text(_formatTOD(t)),
                            selected: selecionado == t,
                            onSelected: (_) {
                              selecionado = t;
                              setState(() {});
                            },
                          ),
                      ],
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: selecionado != null
                    ? () {
                        final dt = DateTime(
                          dataSel.year,
                          dataSel.month,
                          dataSel.day,
                          selecionado!.hour,
                          selecionado!.minute,
                        );
                        final novo = Agendamento(
                          id: original.id,
                          clienteId: original.clienteId,
                          barbeiroId: original.barbeiroId,
                          servicoId: original.servicoId,
                          dataHora: dt,
                          status: original.status,
                          observacoes: original.observacoes,
                          valor: original.valor,
                          clienteNome: original.clienteNome,
                          servicoNome: original.servicoNome,
                          clienteTelefone: original.clienteTelefone,
                          clienteEmail: original.clienteEmail,
                        );
                        Navigator.pop(ctx, novo);
                      }
                    : null,
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      );

      return result;
    } catch (_) {
      return null;
    }
  }

  Future<void> _abrirPreAgendamentoDialog() async {
    final services = await FirebaseService.obterServicos();
    final horarios = await FirebaseService.buscarHorariosFuncionamento();

    DateTime dataSel = DateTime.now();
    String? nomeCliente;
    Servico? servicoSel; // opcional

    // Inicialmente gerar slots e remover passados/ocupados
    List<TimeOfDay> slots = _filtrarPassados(dataSel, _slotsParaData(horarios, dataSel));
    try {
      slots = await _filtrarSlotsConsiderandoOcupados(dataSel, slots, services, null);
    } catch (_) {}
    final Set<TimeOfDay> selecionados = {};

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Pré-agendamento (loja)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Seleção de data
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: dataSel,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 0),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                            locale: const Locale('pt', 'BR'),
                            builder: (context, child) {
                              // Força os botões OK/Cancelar em branco apenas neste diálogo
                              final base = Theme.of(context);
                              return Theme(
                                data: base.copyWith(
                                  // Aparência mais enfática para seleção/hoje no DatePicker
                                  useMaterial3: false,
                                  textButtonTheme: TextButtonThemeData(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                                child: child ?? const SizedBox.shrink(),
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() {
                              dataSel = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                              );
                              selecionados.clear();
                            });
                            // atualizar slots (fora do setState para não bloquear)
                            try {
                              final newSlots = _filtrarPassados(dataSel, _slotsParaData(horarios, dataSel));
                              final startOfDay = DateTime(dataSel.year, dataSel.month, dataSel.day, 0, 0);
                              final endOfDay = DateTime(dataSel.year, dataSel.month, dataSel.day, 23, 59, 59);
                              final ocupados = await FirebaseService.buscarAgendamentosEntre(startOfDay, endOfDay);
                              final ocupadosTOD = ocupados.map((a) => TimeOfDay(hour: a.dataHora.hour, minute: a.dataHora.minute)).toSet();
                              final filtered = newSlots.where((s) => !ocupadosTOD.contains(s)).toList();
                              setState(() {
                                slots = filtered;
                              });
                            } catch (e) {
                              setState(() {
                                slots = _filtrarPassados(dataSel, _slotsParaData(horarios, dataSel));
                              });
                            }
                          }
                        },
                        child: Text(
                          '${dataSel.day.toString().padLeft(2, '0')}/${dataSel.month.toString().padLeft(2, '0')}/${dataSel.year}',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Grade de horários (multi-seleção)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Horários disponíveis:',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                const SizedBox(height: 8),
                if (slots.isEmpty)
                  const SizedBox.shrink()
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final t in slots)
                        ChoiceChip(
                          label: Text(_formatTOD(t)),
                          selected: selecionados.contains(t),
                          onSelected: (_) {
                            setState(() {
                              if (selecionados.contains(t)) {
                                selecionados.remove(t);
                              } else {
                                selecionados.add(t);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                const SizedBox(height: 12),
                // Nome do cliente (opcional)
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Nome do cliente (opcional)',
                  ),
                  onChanged: (v) => nomeCliente = v.trim(),
                ),
                const SizedBox(height: 8),
                // Serviço (opcional)
                DropdownButtonFormField<Servico?>(
                  isExpanded: true,
                  initialValue: null,
                  items: [
                    const DropdownMenuItem<Servico?>(
                      value: null,
                      child: Text('Sem serviço'),
                    ),
                    ...services.map(
                      (s) => DropdownMenuItem<Servico?>(
                        value: s,
                        child: Text(s.nome),
                      ),
                    ),
                  ],
                  onChanged: (v) async {
                    // Atualiza seleção e re-filtra os slots considerando a duração do serviço escolhido
                    setState(() => servicoSel = v);
                    try {
                      final newSlotsBase = _filtrarPassados(dataSel, _slotsParaData(horarios, dataSel));
                      final filtered = await _filtrarSlotsConsiderandoOcupados(dataSel, newSlotsBase, services, servicoSel);
                      setState(() => slots = filtered);
                    } catch (_) {
                      // keep current slots
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Serviço (opcional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: selecionados.isNotEmpty
                  ? () async {
                      try {
                        for (final t in selecionados) {
                          final dt = DateTime(
                            dataSel.year,
                            dataSel.month,
                            dataSel.day,
                            t.hour,
                            t.minute,
                          );
                          final ag = Agendamento(
                            id: '',
                            clienteId: 'loja',
                            barbeiroId: 'loja',
                            servicoId: servicoSel?.id ?? 'sem-servico',
                            dataHora: dt,
                            status: StatusAgendamento.confirmado,
                            observacoes: 'Pré-agendamento (loja)',
                            valor: servicoSel?.preco ?? 0.0,
                            clienteNome:
                                (nomeCliente != null && nomeCliente!.isNotEmpty)
                                ? nomeCliente
                                : 'Pré-agendamento (loja)',
                            servicoNome: servicoSel?.nome,
                          );
                          await FirebaseService.criarAgendamento(ag);
                        }
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Pré-agendamento(s) criado(s): ${selecionados.length} horário(s)',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Erro ao criar pré-agendamento'),
                            ),
                          );
                        }
                      }
                    }
                  : null,
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }

  List<TimeOfDay> _slotsParaData(
    List<HorarioFuncionamento> horarios,
    DateTime data,
  ) {
    final String diaSemana = _diaSemanaLabel(data.weekday);
    final HorarioFuncionamento? h = horarios.firstWhere(
      (e) => e.dia == diaSemana,
      orElse: () => HorarioFuncionamento(
        dia: diaSemana,
        aberto: false,
        horaAbertura1: '00:00',
        horaFechamento1: '00:00',
        horaAbertura2: '00:00',
        horaFechamento2: '00:00',
      ),
    );
    return _gerarSlots(h);
  }

  List<TimeOfDay> _gerarSlots(HorarioFuncionamento? h) {
    final out = <TimeOfDay>[];
    if (h == null || !h.aberto) return out;
    void addRange(String ini, String fim) {
      final startOpt = _parseTOD(ini);
      final endOpt = _parseTOD(fim);
      if (startOpt == null || endOpt == null) return;
      var t = startOpt; // non-null
      final end = endOpt; // non-null
      while (_todBeforeOrEqual(t, end)) {
        out.add(t);
        final m = t.minute + 30;
        t = TimeOfDay(hour: t.hour + (m ~/ 60), minute: m % 60);
      }
    }

    addRange(h.horaAbertura1, h.horaFechamento1);
    addRange(h.horaAbertura2, h.horaFechamento2);
    return out;
  }

  // Remove horários já passados quando a data selecionada é hoje
  List<TimeOfDay> _filtrarPassados(DateTime data, List<TimeOfDay> slots) {
    final agora = DateTime.now();
    if (data.year != agora.year || data.month != agora.month || data.day != agora.day) {
      return slots;
    }
    final nowTod = TimeOfDay(hour: agora.hour, minute: agora.minute);
    return slots.where((t) {
      if (t.hour > nowTod.hour) return true;
      if (t.hour == nowTod.hour && t.minute >= nowTod.minute) return true;
      return false;
    }).toList();
  }

  TimeOfDay? _parseTOD(String s) {
    final parts = s.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  bool _todBeforeOrEqual(TimeOfDay a, TimeOfDay b) {
    if (a.hour < b.hour) return true;
    if (a.hour == b.hour && a.minute <= b.minute) return true;
    return false;
  }

  // Filtra slots removendo os que entram em conflito com agendamentos existentes
  // Se servicoSel fornecido, considera sua duração ao bloquear intervalos.
  Future<List<TimeOfDay>> _filtrarSlotsConsiderandoOcupados(
    DateTime data,
    List<TimeOfDay> baseSlots,
    List<Servico> services,
    Servico? servicoSel, {
    String? excludeAgendamentoId,
  }) async {
    final startOfDay = DateTime(data.year, data.month, data.day, 0, 0);
    final endOfDay = DateTime(data.year, data.month, data.day, 23, 59, 59);
    final ocupadosAll = await FirebaseService.buscarAgendamentosEntre(startOfDay, endOfDay);
    // Considerar apenas agendamentos que realmente ocupam o horário
    final ocupados = ocupadosAll.where((a) =>
      (a.status == StatusAgendamento.agendado || a.status == StatusAgendamento.confirmado) &&
      (excludeAgendamentoId == null || a.id != excludeAgendamentoId)
    ).toList();

    // Mapear ocupados para intervalos (start..end) considerando duração do serviço associado se disponível
    final List<Map<String, DateTime>> intervalos = [];
    for (final a in ocupados) {
      // achar duração do serviço salvo no agendamento (servicoId) nas services
      int duracao = 30; // fallback
      try {
        final s = services.firstWhere((s) => s.id == a.servicoId, orElse: () => Servico(id: '', nome: '', descricao: '', preco: 0.0, duracao: 30, icone: ''));
        duracao = s.duracao;
      } catch (_) {}
      final inicio = a.dataHora;
      final fim = inicio.add(Duration(minutes: duracao));
      intervalos.add({'start': inicio, 'end': fim});
    }

    // Se o admin escolheu um serviço para novos pré-agendamentos, usar sua duração para evitar sobreposição
    final newDur = servicoSel?.duracao ?? 30;

    bool conflita(TimeOfDay slot) {
      final slotInicio = DateTime(data.year, data.month, data.day, slot.hour, slot.minute);
      final slotFim = slotInicio.add(Duration(minutes: newDur));
      for (final iv in intervalos) {
        final s = iv['start']!;
        final e = iv['end']!;
        if (!(slotFim.isBefore(s) || slotInicio.isAfter(e))) {
          return true;
        }
      }
      return false;
    }

    return baseSlots.where((s) => !conflita(s)).toList();
  }

  String _formatTOD(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _diaSemanaLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Segunda';
      case DateTime.tuesday:
        return 'Terça';
      case DateTime.wednesday:
        return 'Quarta';
      case DateTime.thursday:
        return 'Quinta';
      case DateTime.friday:
        return 'Sexta';
      case DateTime.saturday:
        return 'Sábado';
      case DateTime.sunday:
        return 'Domingo';
      default:
        return 'Segunda';
    }
  }

  // Verifica se um agendamento proposto conflita com outros agendamentos
  // Retorna true se não houver conflito (disponível)
  Future<bool> _verificarConflitoAgendamento(Agendamento proposto) async {
    final data = proposto.dataHora;
    final startOfDay = DateTime(data.year, data.month, data.day, 0, 0);
    final endOfDay = DateTime(data.year, data.month, data.day, 23, 59, 59);
    try {
      final ocupados = await FirebaseService.buscarAgendamentosEntre(startOfDay, endOfDay);
      // Filtrar apenas status que ocupam horário e excluir o próprio agendamento
      final relevantes = ocupados.where((a) => (a.status == StatusAgendamento.agendado || a.status == StatusAgendamento.confirmado) && a.id != proposto.id).toList();

      // obter duração do proposto
      int durProposto = 30;
      try {
        final s = await FirebaseService.obterServicoPorId(proposto.servicoId);
        if (s != null) durProposto = s.duracao;
      } catch (_) {}

      final inicioProposto = proposto.dataHora;
      final fimProposto = inicioProposto.add(Duration(minutes: durProposto));

      for (final a in relevantes) {
        int dur = 30;
        try {
          final s2 = await FirebaseService.obterServicoPorId(a.servicoId);
          if (s2 != null) dur = s2.duracao;
        } catch (_) {}
        final inicio = a.dataHora;
        final fim = inicio.add(Duration(minutes: dur));
        if (!(fimProposto.isBefore(inicio) || inicioProposto.isAfter(fim))) {
          return false; // conflito
        }
      }
      return true;
    } catch (e) {
      // Em caso de erro conservador, retornar false para prevenir sobreposição
      return false;
    }
  }
}
