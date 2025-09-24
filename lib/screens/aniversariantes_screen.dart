import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../models/produto.dart';
import '../models/servico.dart';
import '../services/firebase_service.dart';

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
  void _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
                      return Column(
                        children: [
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: clientes.length,
                              separatorBuilder: (_, __) => const Divider(),
                              itemBuilder: (context, index) {
                                final cliente = clientes[index];
                                return ListTile(
                                  leading: const Icon(
                                    Icons.cake,
                                    color: Colors.pink,
                                  ),
                                  title: Text(cliente.nome),
                                  subtitle: Text(
                                    'Nascimento: ${_formatarData(cliente.dataNascimento)}',
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () =>
                                            _editarCliente(cliente),
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
}
