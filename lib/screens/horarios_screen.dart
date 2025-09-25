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

  Future<void> _selecionarHora(BuildContext context) async {
    final partes = valor.split(":");
    final hora = int.tryParse(partes[0]) ?? 8;
    final minuto = int.tryParse(partes.length > 1 ? partes[1] : "0") ?? 0;
    final TimeOfDay? selecionada = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hora, minute: minuto),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          timePickerTheme: TimePickerThemeData(
            backgroundColor: Colors.white,
            hourMinuteTextColor: Colors.white, // número selecionado em branco
            hourMinuteColor: WidgetStateColor.resolveWith(
              (states) => Colors.amber[700]!,
            ), // círculo amarelo
            hourMinuteShape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            dayPeriodTextColor: Colors.black,
            dialHandColor: Colors.amber[700],
            dialBackgroundColor: Colors.amber[50],
            dialTextColor: WidgetStateColor.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.white; // número selecionado em branco
              }
              return Colors.black; // números do dial em preto
            }),
            entryModeIconColor: Colors.amber[700],
          ),
        ),
        child: child!,
      ),
    );
    if (selecionada != null) {
      final h = selecionada.hour.toString().padLeft(2, '0');
      final m = selecionada.minute.toString().padLeft(2, '0');
      onChanged("$h:$m");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110, // largura aumentada para melhor visualização
      child: GestureDetector(
        onTap: () => _selecionarHora(context),
        child: AbsorbPointer(
          child: TextFormField(
            readOnly: true,
            initialValue: valor,
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              suffixIcon: Icon(Icons.access_time, size: 16),
            ),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
