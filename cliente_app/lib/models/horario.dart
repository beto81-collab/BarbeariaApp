class HorarioFuncionamento {
  final String dia;
  final bool aberto;
  final String horaAbertura1;
  final String horaFechamento1;
  final String horaAbertura2;
  final String horaFechamento2;

  HorarioFuncionamento({
    required this.dia,
    required this.aberto,
    required this.horaAbertura1,
    required this.horaFechamento1,
    required this.horaAbertura2,
    required this.horaFechamento2,
  });

  Map<String, dynamic> toJson() => {
    'dia': dia,
    'aberto': aberto,
    'horaAbertura1': horaAbertura1,
    'horaFechamento1': horaFechamento1,
    'horaAbertura2': horaAbertura2,
    'horaFechamento2': horaFechamento2,
  };

  factory HorarioFuncionamento.fromJson(Map<String, dynamic> json) =>
      HorarioFuncionamento(
        dia: json['dia'] as String,
        aberto: json['aberto'] is bool
            ? json['aberto'] as bool
            : (json['aberto'].toString().toLowerCase() == 'true'),
        horaAbertura1: json['horaAbertura1'] as String? ?? '08:00',
        horaFechamento1: json['horaFechamento1'] as String? ?? '12:00',
        horaAbertura2: json['horaAbertura2'] as String? ?? '13:00',
        horaFechamento2: json['horaFechamento2'] as String? ?? '19:00',
      );
}

const List<String> diasSemana = [
  'Segunda',
  'Terça',
  'Quarta',
  'Quinta',
  'Sexta',
  'Sábado',
  'Domingo',
];
