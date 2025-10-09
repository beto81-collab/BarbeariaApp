import 'dart:async';
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/usuario.dart';
import '../models/servico.dart';

class ProgramaPontosScreen extends StatefulWidget {
  const ProgramaPontosScreen({Key? key}) : super(key: key);

  @override
  State<ProgramaPontosScreen> createState() => _ProgramaPontosScreenState();
}

class _ProgramaPontosScreenState extends State<ProgramaPontosScreen> {
  List<Usuario> _clientes = [];
  bool _carregando = true;
  List<Servico> _servicos = [];
  Servico? _selectedServicoParaPresente;
  String? _selectedServicoId;
  StreamSubscription<Map<String, dynamic>?>? _adminSub;

  // ID do administrador que salva a configuração de prêmio padrão
  static const String _adminIdForDefaultPrize = 'HgI2Y3EGc2X7F5nk7wZMFoR1QDs2';

  @override
  void initState() {
    super.initState();
    _loadClientes();
    _loadServicos();

    // Inscrever no documento do admin para atualizações em tempo real
    _adminSub = FirebaseService.streamUsuarioMapPorId(_adminIdForDefaultPrize)
        .listen((adminMap) {
          if (adminMap == null) return;
          final premio = adminMap['premioProgramaPontos'];
          if (premio == null) return;
          try {
            final Map<String, dynamic> premioMap = Map<String, dynamic>.from(
              premio,
            );
            if (premioMap['id'] != null) {
              final String possibleId = premioMap['id'].toString();
              final found = _servicos.where((s) => s.id == possibleId).toList();
              if (found.isNotEmpty) {
                setState(() {
                  _selectedServicoParaPresente = found.first;
                  _selectedServicoId = found.first.id;
                });
                return;
              }
            }
          } catch (e) {
            // ignore parsing errors
          }
        });
  }

  @override
  void dispose() {
    _adminSub?.cancel();
    super.dispose();
  }

  Future<void> _loadServicos() async {
    try {
      final servs = await FirebaseService.obterServicos();
      setState(() => _servicos = servs);
      // Após carregar serviços, tentar carregar prêmio pré-selecionado do admin
      await _loadAdminSelectedPrize();
    } catch (e) {
      setState(() => _servicos = []);
    }
  }

  Future<void> _loadAdminSelectedPrize() async {
    try {
      final adminMap = await FirebaseService.obterUsuarioMapPorId(
        _adminIdForDefaultPrize,
      );
      if (adminMap == null) return;
      var premio = adminMap['premioProgramaPontos'];
      if (premio == null) {
        // retry rápido
        await Future.delayed(const Duration(milliseconds: 300));
        final adminMap2 = await FirebaseService.obterUsuarioMapPorId(
          _adminIdForDefaultPrize,
        );
        premio = adminMap2?['premioProgramaPontos'];
      }
      if (premio == null) return;

      final Map<String, dynamic> premioMap = Map<String, dynamic>.from(premio);

      // tentar casar por id
      if (premioMap['id'] != null) {
        final String possibleId = premioMap['id'].toString();
        final foundList = _servicos.where((s) => s.id == possibleId).toList();
        if (foundList.isNotEmpty) {
          setState(() {
            _selectedServicoParaPresente = foundList.first;
            _selectedServicoId = foundList.first.id;
          });
          return;
        }

        final serv = await FirebaseService.obterServicoPorId(possibleId);
        if (serv != null) {
          setState(() {
            _servicos.insert(0, serv);
            _selectedServicoParaPresente = serv;
            _selectedServicoId = serv.id;
          });
          return;
        }
      }

      // tentar casar por nome
      if (premioMap['nome'] != null) {
        final String nome = premioMap['nome'].toString();
        final foundByNameList = _servicos
            .where((s) => s.nome.toLowerCase() == nome.toLowerCase())
            .toList();
        if (foundByNameList.isNotEmpty) {
          setState(() {
            _selectedServicoParaPresente = foundByNameList.first;
            _selectedServicoId = foundByNameList.first.id;
          });
          return;
        }
      }

      // criar temporário
      try {
        final servObj = Servico.fromJson({
          ...Map<String, dynamic>.from(premioMap),
        });
        setState(() {
          _servicos.insert(0, servObj);
          _selectedServicoParaPresente = servObj;
          _selectedServicoId = servObj.id;
        });
      } catch (_) {
        // ignore
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _loadClientes() async {
    setState(() => _carregando = true);
    final clientes = await FirebaseService.buscarClientes();
    setState(() {
      _clientes = clientes;
      _carregando = false;
    });
  }

  Future<void> _toggleParticipacao(Usuario u, bool value) async {
    try {
      await FirebaseService.atualizarUsuarioField(u.id, {
        'participaProgramaPontos': value,
      });
      await _loadClientes();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${u.nome} atualizado.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao atualizar: $e')));
    }
  }

  Future<void> _marcarTodos() async {
    try {
      for (final u in _clientes) {
        await FirebaseService.atualizarUsuarioField(u.id, {
          'participaProgramaPontos': true,
        });
      }
      await _loadClientes();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todos os clientes marcados como participantes'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao marcar todos: $e')));
    }
  }

  // Abre um dialog com 10 quadrados para adicionar pontos manualmente
  Future<void> _openPontosDialog(Usuario cliente) async {
    int pontosSelecionados = cliente.pontosFidelidade % 10;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cliente.nome,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Telefone: ${cliente.telefone}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(10, (i) {
                        final selected = i < pontosSelecionados;
                        return GestureDetector(
                          onTap: () => setStateDialog(() {
                            if (i < pontosSelecionados) return; // não desmarca
                            pontosSelecionados = i + 1;
                          }),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.amber.shade50
                                  : Colors.transparent,
                              border: Border.all(
                                color: selected
                                    ? Colors.amber.shade700
                                    : Colors.grey.shade600,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: selected
                                  ? Icon(
                                      Icons.emoji_events,
                                      color: Colors.amber.shade700,
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: pontosSelecionados == 0
                              ? null
                              : () async {
                                  try {
                                    final currentPoints =
                                        cliente.pontosFidelidade;
                                    final currentProgress = currentPoints % 10;
                                    final delta =
                                        pontosSelecionados - currentProgress;
                                    if (delta <= 0) {
                                      Navigator.of(context).pop();
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Nenhum ponto novo selecionado',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    await FirebaseService.incrementarPontosFidelidade(
                                      cliente.id,
                                      delta,
                                    );
                                    await _loadClientes();

                                    final refreshed = _clientes.firstWhere(
                                      (c) => c.id == cliente.id,
                                    );
                                    if (refreshed.pontosFidelidade >= 10) {
                                      // criar resgate e persistir premio no usuario
                                      final usuarioMap =
                                          await FirebaseService.obterUsuarioMapPorId(
                                            cliente.id,
                                          );
                                      Map<String, dynamic>? premioUser =
                                          usuarioMap?['premioProgramaPontos']
                                              as Map<String, dynamic>?;
                                      Map<String, dynamic> premioData;
                                      if (premioUser != null) {
                                        premioData = Map<String, dynamic>.from(
                                          premioUser,
                                        );
                                      } else if (_selectedServicoParaPresente !=
                                          null) {
                                        premioData =
                                            _selectedServicoParaPresente!
                                                .toJson();
                                      } else {
                                        premioData = {
                                          'descricao':
                                              'Serviço gratuito (resgate automático por 10 pontos)',
                                          'valor': 0,
                                        };
                                      }

                                      await FirebaseService.resgatarPremioParaUsuario(
                                        cliente.id,
                                        premioData,
                                      );
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Prêmio gerado para ${cliente.nome} e pontos consumidos',
                                          ),
                                        ),
                                      );
                                    } else {
                                      final added = delta;
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '$added ponto(s) adicionados para ${cliente.nome}',
                                          ),
                                        ),
                                      );
                                    }

                                    Navigator.of(context).pop();
                                  } catch (e) {
                                    Navigator.of(context).pop();
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Erro ao adicionar pontos: $e',
                                        ),
                                      ),
                                    );
                                  }
                                },
                          child: const Text('Confirmar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _aplicarPremioAosParticipantes(Servico? premio) async {
    if (premio == null) return;
    try {
      int updated = 0;
      for (final u in _clientes) {
        // Ler o documento cru para garantir que pegamos o campo real salvo no Firestore
        final userMap = await FirebaseService.obterUsuarioMapPorId(u.id);
        final participa =
            (userMap?['participaProgramaPontos'] ?? false) as bool;
        if (!participa) continue;
        final payload = premio.toJson();
        // debug prints removed
        await FirebaseService.atualizarUsuarioField(u.id, {
          'premioProgramaPontos': payload,
        });
        // confirmation logs removed
        updated++;
      }
      await _loadClientes();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Prêmio aplicado a $updated participante(s)')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao aplicar prêmio: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // build debug removed
    return Scaffold(
      appBar: AppBar(
        title: const Text('Programa de Pontos'),
        actions: [
          TextButton(
            onPressed: _marcarTodos,
            child: const Text(
              'Marcar todos',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadClientes,
              child: Column(
                children: [
                  Card(
                    margin: const EdgeInsets.all(8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String?>(
                              value: _selectedServicoId,
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('Nenhum prêmio selecionado'),
                                ),
                                ..._servicos.map(
                                  (s) => DropdownMenuItem<String?>(
                                    value: s.id,
                                    child: Text(
                                      '${s.nome} - ${s.precoFormatado}',
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (id) async {
                                final servList = _servicos
                                    .where((s) => s.id == id)
                                    .toList();
                                final serv = servList.isNotEmpty
                                    ? servList.first
                                    : null;
                                setState(() {
                                  _selectedServicoId = id;
                                  _selectedServicoParaPresente = serv;
                                });

                                try {
                                  await FirebaseService.atualizarUsuarioField(
                                    _adminIdForDefaultPrize,
                                    {'premioProgramaPontos': serv?.toJson()},
                                  );
                                  // admin update confirmed (no debug print)

                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Prêmio salvo como padrão do admin',
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  // error logged below
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Erro ao salvar prêmio: $e',
                                      ),
                                    ),
                                  );
                                }
                              },
                              decoration: const InputDecoration(
                                labelText: 'Prêmio por 10 atendimentos',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _selectedServicoParaPresente == null
                                ? null
                                : () => _aplicarPremioAosParticipantes(
                                    _selectedServicoParaPresente,
                                  ),
                            child: const Text('Aplicar prêmio'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: _clientes.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final cliente = _clientes[index];
                        final participa =
                            (cliente.toJson()['participaProgramaPontos'] ??
                                    false)
                                as bool;
                        final pontos = cliente.pontosFidelidade;
                        final progresso = pontos % 10;
                        return ListTile(
                          title: Text(cliente.nome),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Telefone: ${cliente.telefone}'),
                              if (cliente.toJson()['premioProgramaPontos'] !=
                                  null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    'Prêmio: ${(cliente.toJson()['premioProgramaPontos']['nome'] ?? cliente.toJson()['premioProgramaPontos']['descricao'])}',
                                    style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text('Pontos: $pontos'),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$progresso/10',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          leading: Checkbox(
                            value: participa,
                            onChanged: (v) async {
                              if (v == null) return;
                              await _toggleParticipacao(cliente, v);
                            },
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (pontos >= 10)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                    onPressed: () async {
                                      try {
                                        final existe =
                                            await FirebaseService.resgateExisteParaUsuario(
                                              cliente.id,
                                            );
                                        if (!existe) {
                                          final usuarioMap =
                                              await FirebaseService.obterUsuarioMapPorId(
                                                cliente.id,
                                              );
                                          Map<String, dynamic>? premioUser =
                                              usuarioMap?['premioProgramaPontos']
                                                  as Map<String, dynamic>?;
                                          Map<String, dynamic> premioData;
                                          if (premioUser != null) {
                                            premioData =
                                                Map<String, dynamic>.from(
                                                  premioUser,
                                                );
                                          } else if (_selectedServicoParaPresente !=
                                              null) {
                                            premioData =
                                                _selectedServicoParaPresente!
                                                    .toJson();
                                          } else {
                                            premioData = {
                                              'descricao':
                                                  'Serviço gratuito (resgate automático por 10 pontos)',
                                              'valor': 0,
                                            };
                                          }

                                          await FirebaseService.resgatarPremioParaUsuario(
                                            cliente.id,
                                            premioData,
                                          );
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Resgate criado para ${cliente.nome}',
                                              ),
                                            ),
                                          );
                                        } else {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text(
                                                'Confirmar resgate',
                                              ),
                                              content: Text(
                                                'Já existe um resgate pendente para ${cliente.nome}. Deseja confirmar o uso do cupom e remover o registro?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(
                                                    ctx,
                                                  ).pop(false),
                                                  child: const Text('Cancelar'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () => Navigator.of(
                                                    ctx,
                                                  ).pop(true),
                                                  child: const Text(
                                                    'Confirmar',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            try {
                                              await FirebaseService.finalizarResgateParaUsuario(
                                                cliente.id,
                                              );
                                              if (!mounted) return;
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Resgate finalizado para ${cliente.nome}',
                                                  ),
                                                ),
                                              );
                                            } catch (e) {
                                              if (!mounted) return;
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Erro ao finalizar resgate: $e',
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        }
                                        await _loadClientes();
                                      } catch (e) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Erro ao criar/resgatar: $e',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    child: const Text('Resgatar'),
                                  ),
                                ),
                              ElevatedButton(
                                onPressed: () => _openPontosDialog(cliente),
                                child: const Text('Ok'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
