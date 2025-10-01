import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../models/produto.dart';
import '../models/servico.dart';
import '../services/firebase_service.dart';

enum FilterOpcao { todos, pendentes, expirados, entregues }

class AniversariantesScreen extends StatefulWidget {
  const AniversariantesScreen({super.key});

  @override
  State<AniversariantesScreen> createState() => _AniversariantesScreenState();
}

class _AniversariantesScreenState extends State<AniversariantesScreen> {
  double? _precoEspecialProduto;
  double? _precoEspecialServico;
  bool _carregandoProdutos = false;
  bool _carregandoServicos = false;
  FilterOpcao _filtro = FilterOpcao.todos;
  void _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          ),
          child: child!,
        );
      },
    );
    if (data != null) {
      setState(() => _dataSelecionada = data);
    }
  }

  Future<void> _enviarOfertas() async {
    if (_selecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos um cliente!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Monta o objeto da oferta (pode ser vazia se "Nenhum" foi selecionado)
      final Map<String, dynamic> oferta = {
        'enviadoEm': DateTime.now(),
        'resgatado': false,
      };

      // Adiciona produto se selecionado
      if (_produtoEspecial != null) {
        oferta['produto'] = {
          'id': _produtoEspecial!.id,
          'nome': _produtoEspecial!.nome,
          'precoOriginal': _produtoEspecial!.preco,
          'precoEspecial': _precoEspecialProduto ?? _produtoEspecial!.preco,
        };
      }

      // Adiciona serviço se selecionado
      if (_servicoEspecial != null) {
        oferta['servico'] = {
          'id': _servicoEspecial!.id,
          'nome': _servicoEspecial!.nome,
          'precoOriginal': _servicoEspecial!.preco,
          'precoEspecial': _precoEspecialServico ?? _servicoEspecial!.preco,
        };
      }

      // Envia a oferta para cada cliente selecionado
      int enviados = 0;
      for (final clienteId in _selecionados) {
        await FirebaseService.atualizarPresenteAniversario(clienteId, oferta);
        enviados++;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Presente enviado para $enviados aniversariante(s)!'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _selecionados.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao enviar ofertas: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _enviarOfertasAniversariantesHoje() async {
    try {
      // Busca aniversariantes de hoje
      final hoje = DateTime.now();
      final aniversariantesHoje = await FirebaseService.buscarAniversariantes(
        hoje,
      );

      if (aniversariantesHoje.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nenhum aniversariante hoje!'),
            backgroundColor: Colors.blue,
          ),
        );
        return;
      }

      // Monta o objeto da oferta
      final Map<String, dynamic> oferta = {
        'enviadoEm': DateTime.now(),
        'resgatado': false,
      };

      // Adiciona produto se selecionado
      if (_produtoEspecial != null) {
        oferta['produto'] = {
          'id': _produtoEspecial!.id,
          'nome': _produtoEspecial!.nome,
          'precoOriginal': _produtoEspecial!.preco,
          'precoEspecial': _precoEspecialProduto ?? _produtoEspecial!.preco,
        };
      }

      // Adiciona serviço se selecionado
      if (_servicoEspecial != null) {
        oferta['servico'] = {
          'id': _servicoEspecial!.id,
          'nome': _servicoEspecial!.nome,
          'precoOriginal': _servicoEspecial!.preco,
          'precoEspecialServico':
              _precoEspecialServico ?? _servicoEspecial!.preco,
        };
      }

      // Envia para todos os aniversariantes de hoje que não têm presente ou já resgataram
      int enviados = 0;
      for (final cliente in aniversariantesHoje) {
        await FirebaseService.atualizarPresenteAniversario(cliente.id, oferta);
        enviados++;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Presente enviado para $enviados aniversariante(s) de hoje!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao enviar ofertas: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editarCliente(Usuario cliente) {
    // Aqui você pode abrir uma tela ou diálogo para editar os dados do cliente
    // Exemplo: Navigator.push(...)
  }

  String _formatarData(DateTime? data) {
    if (data == null) return 'Não informado';
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

  DateTime _dataSelecionada = DateTime.now();
  Produto? _produtoEspecial;
  Servico? _servicoEspecial;
  bool _envioAutomatico = false;
  List<String> _selecionados = [];
  List<Produto> _produtos = [];
  List<Servico> _servicos = [];
  bool _carregandoOfertas = true;

  @override
  void initState() {
    super.initState();
    _carregarOfertas();
  }

  Future<void> _carregarOfertas() async {
    _produtos = await FirebaseService.obterProdutos();
    _servicos = await FirebaseService.obterServicos();
    setState(() => _carregandoOfertas = false);
  }

  Future<void> _carregarProdutos() async {
    setState(() => _carregandoProdutos = true);
    _produtos = await FirebaseService.obterProdutos();
    setState(() => _carregandoProdutos = false);
  }

  Future<void> _carregarServicos() async {
    setState(() => _carregandoServicos = true);
    _servicos = await FirebaseService.obterServicos();
    setState(() => _carregandoServicos = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes Aniversariantes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('Filtrar:'),
                const SizedBox(width: 12),
                DropdownButton<FilterOpcao>(
                  value: _filtro,
                  items: [
                    DropdownMenuItem(
                      value: FilterOpcao.todos,
                      child: Text('Todos'),
                    ),
                    DropdownMenuItem(
                      value: FilterOpcao.pendentes,
                      child: Text('Pendentes'),
                    ),
                    DropdownMenuItem(
                      value: FilterOpcao.expirados,
                      child: Text('Expirados'),
                    ),
                    DropdownMenuItem(
                      value: FilterOpcao.entregues,
                      child: Text('Entregues'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _filtro = v);
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: _enviarOfertasAniversariantesHoje,
            tooltip: 'Enviar oferta para aniversariantes de hoje',
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selecionarData,
          ),
        ],
      ),
      body: _carregandoOfertas
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Focus(
                              onFocusChange: (hasFocus) {
                                if (hasFocus &&
                                    _produtos.isEmpty &&
                                    !_carregandoProdutos) {
                                  _carregarProdutos();
                                }
                              },
                              child: DropdownButtonFormField<Produto>(
                                initialValue: _produtoEspecial,
                                items: [
                                  const DropdownMenuItem<Produto>(
                                    value: null,
                                    child: Text('Nenhum'),
                                  ),
                                  ..._produtos.map(
                                    (p) => DropdownMenuItem(
                                      value: p,
                                      child: Text(p.nome),
                                    ),
                                  ),
                                ],
                                onChanged: (p) {
                                  setState(() {
                                    _produtoEspecial = p;
                                    _precoEspecialProduto = p?.preco;
                                  });
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Produto especial',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Focus(
                              onFocusChange: (hasFocus) {
                                if (hasFocus &&
                                    _servicos.isEmpty &&
                                    !_carregandoServicos) {
                                  _carregarServicos();
                                }
                              },
                              child: DropdownButtonFormField<Servico>(
                                initialValue: _servicoEspecial,
                                items: [
                                  const DropdownMenuItem<Servico>(
                                    value: null,
                                    child: Text('Nenhum'),
                                  ),
                                  ..._servicos.map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s.nome),
                                    ),
                                  ),
                                ],
                                onChanged: (s) {
                                  setState(() {
                                    _servicoEspecial = s;
                                    _precoEspecialServico = s?.preco;
                                  });
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Serviço especial',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_produtoEspecial != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: TextFormField(
                            initialValue: _precoEspecialProduto
                                ?.toStringAsFixed(2),
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Valor especial do produto (R\$)',
                              prefixIcon: const Icon(Icons.price_change),
                            ),
                            onChanged: (v) => setState(
                              () => _precoEspecialProduto = double.tryParse(
                                v.replaceAll(',', '.'),
                              ),
                            ),
                          ),
                        ),
                      if (_servicoEspecial != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: TextFormField(
                            initialValue: _precoEspecialServico
                                ?.toStringAsFixed(2),
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Valor especial do serviço (R\$)',
                              prefixIcon: const Icon(Icons.price_change),
                            ),
                            onChanged: (v) => setState(
                              () => _precoEspecialServico = double.tryParse(
                                v.replaceAll(',', '.'),
                              ),
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          Switch(
                            value: _envioAutomatico,
                            onChanged: (v) {
                              setState(() {
                                _envioAutomatico = v;
                              });
                            },
                            activeThumbColor: Colors.amber,
                          ),
                          const Text(
                            'Enviar oferta automaticamente para todos os aniversariantes',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<Usuario>>(
                    future: FirebaseService.buscarAniversariantes(
                      _dataSelecionada,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final clientes = snapshot.data ?? [];
                      if (clientes.isEmpty) {
                        return const Center(
                          child: Text('Nenhum aniversariante nesta data.'),
                        );
                      }
                      if (_envioAutomatico) {
                        _selecionados = clientes.map((c) => c.id).toList();
                      }
                      // Aplicar filtro baseado em presenteAniversario
                      final filtrados = clientes.where((cliente) {
                        final presente = cliente.presenteAniversario;
                        final resgatado =
                            presente != null && presente['resgatado'] == true;
                        final entregue =
                            presente != null && presente['entregue'] == true;
                        final expirado = _presenteExpirado(presente);

                        switch (_filtro) {
                          case FilterOpcao.todos:
                            return true;
                          case FilterOpcao.pendentes:
                            return presente != null &&
                                !resgatado &&
                                !entregue &&
                                !expirado;
                          case FilterOpcao.expirados:
                            return presente != null &&
                                expirado &&
                                !resgatado &&
                                !entregue;
                          case FilterOpcao.entregues:
                            return presente != null && entregue;
                        }
                        return false;
                      }).toList();

                      return Column(
                        children: [
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: filtrados.length,
                              separatorBuilder: (_, __) => const Divider(),
                              itemBuilder: (context, index) {
                                final cliente = filtrados[index];
                                return ListTile(
                                  leading: const Icon(
                                    Icons.cake,
                                    color: Colors.pink,
                                  ),
                                  title: Text(cliente.nome),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () =>
                                            _editarCliente(cliente),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.done_all,
                                          color: Colors.green,
                                        ),
                                        tooltip: 'Marcar entregue',
                                        onPressed: () async {
                                          try {
                                            await FirebaseService.marcarPresenteComoEntregue(
                                              cliente.id,
                                            );
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Presente marcado como entregue',
                                                ),
                                              ),
                                            );
                                          } catch (e) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Erro ao marcar entregue',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      if (!_envioAutomatico)
                                        Checkbox(
                                          value: _selecionados.contains(
                                            cliente.id,
                                          ),
                                          onChanged: (v) {
                                            setState(() {
                                              if (v == true) {
                                                _selecionados.add(cliente.id);
                                              } else {
                                                _selecionados.remove(
                                                  cliente.id,
                                                );
                                              }
                                            });
                                          },
                                        ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Nascimento: ${_formatarData(cliente.dataNascimento)}',
                                      ),
                                      const SizedBox(height: 4),
                                      _buildStatusBadge(
                                        cliente.presenteAniversario,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.card_giftcard),
                              label: const Text('Enviar oferta/presente'),
                              onPressed: _selecionados.isEmpty
                                  ? null
                                  : _enviarOfertas,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  bool _presenteExpirado(Map<String, dynamic>? presente) {
    if (presente == null) return false;
    final exp = presente['expiraEm'];
    if (exp == null) return false;
    try {
      DateTime expDate;
      if (exp is String) {
        expDate = DateTime.parse(exp);
      } else if (exp is Map &&
          (exp['_seconds'] != null || exp['seconds'] != null)) {
        final seconds = exp['_seconds'] ?? exp['seconds'];
        expDate = DateTime.fromMillisecondsSinceEpoch((seconds as int) * 1000);
      } else if (exp is num) {
        expDate = DateTime.fromMillisecondsSinceEpoch(exp.toInt());
      } else if (exp is DateTime) {
        expDate = exp;
      } else {
        expDate = DateTime.parse(exp.toString());
      }
      return DateTime.now().isAfter(expDate);
    } catch (e) {
      return false;
    }
  }

  Widget _buildStatusBadge(Map<String, dynamic>? presente) {
    if (presente == null) {
      return const SizedBox.shrink();
    }

    final resgatado = presente['resgatado'] == true;
    final entregue = presente['entregue'] == true;
    final expirado = _presenteExpirado(presente);

    String text = 'Pendente';
    Color color = Colors.orange;
    if (resgatado) {
      text = 'Resgatado';
      color = Colors.green;
    } else if (entregue) {
      text = 'Entregue';
      color = Colors.blue;
    } else if (expirado) {
      text = 'Expirado';
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
