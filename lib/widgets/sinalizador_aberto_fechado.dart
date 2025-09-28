import 'package:flutter/material.dart';
import '../models/horario.dart';
import '../services/firebase_service.dart';

class SinalizadorAbertoFechado extends StatefulWidget {
  const SinalizadorAbertoFechado({super.key});

  @override
  State<SinalizadorAbertoFechado> createState() =>
      _SinalizadorAbertoFechadoState();
}

class _SinalizadorAbertoFechadoState extends State<SinalizadorAbertoFechado> {
  Color cor = Colors.grey;
  String mensagem = 'Carregando...';

  @override
  void initState() {
    super.initState();
    _verificarStatus();
  }

  Future<void> _verificarStatus() async {
    final horarios = await FirebaseService.buscarHorariosFuncionamento();
    final agora = DateTime.now();
    final dias = [
      'Segunda',
      'Terça',
      'Quarta',
      'Quinta',
      'Sexta',
      'Sábado',
      'Domingo',
    ];
    final diaSemana = dias[agora.weekday - 1];

    final horarioHoje = horarios.firstWhere(
      (h) => h.dia == diaSemana,
      orElse: () => HorarioFuncionamento(
        dia: diaSemana,
        aberto: false,
        horaAbertura1: '00:00',
        horaFechamento1: '00:00',
        horaAbertura2: '00:00',
        horaFechamento2: '00:00',
      ),
    );

    if (!horarioHoje.aberto) {
      setState(() {
        cor = Colors.red;
        mensagem = 'Fechado';
      });
      return;
    }

    final agoraMin = agora.hour * 60 + agora.minute;
    bool aberto = false;
    int minutosParaFechar = 9999;

    // 1º intervalo
    final partesAbertura1 = horarioHoje.horaAbertura1.split(':');
    final partesFechamento1 = horarioHoje.horaFechamento1.split(':');
    final abertura1 =
        int.parse(partesAbertura1[0]) * 60 + int.parse(partesAbertura1[1]);
    final fechamento1 =
        int.parse(partesFechamento1[0]) * 60 + int.parse(partesFechamento1[1]);
    if (agoraMin >= abertura1 && agoraMin < fechamento1) {
      aberto = true;
      minutosParaFechar = fechamento1 - agoraMin;
    }

    // 2º intervalo
    final partesAbertura2 = horarioHoje.horaAbertura2.split(':');
    final partesFechamento2 = horarioHoje.horaFechamento2.split(':');
    final abertura2 =
        int.parse(partesAbertura2[0]) * 60 + int.parse(partesAbertura2[1]);
    final fechamento2 =
        int.parse(partesFechamento2[0]) * 60 + int.parse(partesFechamento2[1]);
    if (agoraMin >= abertura2 && agoraMin < fechamento2) {
      aberto = true;
      minutosParaFechar = fechamento2 - agoraMin;
    }

    if (aberto) {
      if (minutosParaFechar <= 30) {
        setState(() {
          cor = Colors.amber;
          mensagem = 'Fechando em breve';
        });
      } else {
        setState(() {
          cor = Colors.green;
          mensagem = 'Aberto agora';
        });
      }
    } else {
      setState(() {
        cor = Colors.red;
        mensagem = 'Fechado';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: cor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: cor.withAlpha((0.5 * 255).round()),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(mensagem, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
