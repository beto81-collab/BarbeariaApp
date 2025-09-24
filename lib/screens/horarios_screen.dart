import 'package:flutter/material.dart';
import '../models/horario.dart';
import '../services/firebase_service.dart';

class HorariosScreen extends StatefulWidget {
  const HorariosScreen({super.key});

  @override
  State<HorariosScreen> createState() => _HorariosScreenState();
}

class _HorariosScreenState extends State<HorariosScreen> {
  List<HorarioFuncionamento> horarios = [];
  bool carregando = true;
  bool salvando = false;

  @override
  void initState() {
    super.initState();
    _carregarHorarios();
  }

  Future<void> _carregarHorarios() async {
    setState(() => carregando = true);
    try {
      horarios = await FirebaseService.buscarHorariosFuncionamento();
    } catch (e) {
      horarios = diasSemana
          .map(
            (dia) => HorarioFuncionamento(
              dia: dia,
              aberto: dia != 'Domingo',
              horaAbertura1: '08:00',
              horaFechamento1: '12:00',
              horaAbertura2: '13:00',
              horaFechamento2: '19:00',
            ),
          )
          .toList();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar horários: $e')));
    }
    setState(() => carregando = false);
  }

  Future<void> _salvarHorarios() async {
    setState(() => salvando = true);
    try {
      await FirebaseService.salvarHorariosFuncionamento(horarios);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Horários salvos com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao salvar horários: $e')));
      }
    }
    setState(() => salvando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Horários'),
        actions: [
          IconButton(
            icon: salvando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            tooltip: 'Salvar',
            onPressed: salvando ? null : _salvarHorarios,
          ),
        ],
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: horarios.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final h = horarios[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              h.dia,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Switch(
                              value: h.aberto,
                              onChanged: (v) => setState(
                                () => horarios[index] = HorarioFuncionamento(
                                  dia: h.dia,
                                  aberto: v,
                                  horaAbertura1: h.horaAbertura1,
                                  horaFechamento1: h.horaFechamento1,
                                  horaAbertura2: h.horaAbertura2,
                                  horaFechamento2: h.horaFechamento2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (h.aberto)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text('1º Período: '),
                                  _HoraField(
                                    valor: h.horaAbertura1,
                                    onChanged: (v) => setState(
                                      () => horarios[index] =
                                          HorarioFuncionamento(
                                            dia: h.dia,
                                            aberto: h.aberto,
                                            horaAbertura1: v,
                                            horaFechamento1: h.horaFechamento1,
                                            horaAbertura2: h.horaAbertura2,
                                            horaFechamento2: h.horaFechamento2,
                                          ),
                                    ),
                                  ),
                                  const Text(' às '),
                                  _HoraField(
                                    valor: h.horaFechamento1,
                                    onChanged: (v) => setState(
                                      () => horarios[index] =
                                          HorarioFuncionamento(
                                            dia: h.dia,
                                            aberto: h.aberto,
                                            horaAbertura1: h.horaAbertura1,
                                            horaFechamento1: v,
                                            horaAbertura2: h.horaAbertura2,
                                            horaFechamento2: h.horaFechamento2,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Text('2º Período: '),
                                  _HoraField(
                                    valor: h.horaAbertura2,
                                    onChanged: (v) => setState(
                                      () => horarios[index] =
                                          HorarioFuncionamento(
                                            dia: h.dia,
                                            aberto: h.aberto,
                                            horaAbertura1: h.horaAbertura1,
                                            horaFechamento1: h.horaFechamento1,
                                            horaAbertura2: v,
                                            horaFechamento2: h.horaFechamento2,
                                          ),
                                    ),
                                  ),
                                  const Text(' às '),
                                  _HoraField(
                                    valor: h.horaFechamento2,
                                    onChanged: (v) => setState(
                                      () => horarios[index] =
                                          HorarioFuncionamento(
                                            dia: h.dia,
                                            aberto: h.aberto,
                                            horaAbertura1: h.horaAbertura1,
                                            horaFechamento1: h.horaFechamento1,
                                            horaAbertura2: h.horaAbertura2,
                                            horaFechamento2: v,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        else
                          const Text('Fechado'),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _HoraField extends StatelessWidget {
  final String valor;
  final ValueChanged<String> onChanged;
  const _HoraField({required this.valor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      child: TextFormField(
        initialValue: valor,
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
        ),
        keyboardType: TextInputType.datetime,
        onChanged: onChanged,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
