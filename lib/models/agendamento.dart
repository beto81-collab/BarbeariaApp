class Agendamento {
  final String id;
  final String clienteId;
  final String barbeiroId;
  final String servicoId;
  final DateTime dataHora;
  final StatusAgendamento status;
  final String observacoes;
  final double valor;

  const Agendamento({
    required this.id,
    required this.clienteId,
    required this.barbeiroId,
    required this.servicoId,
    required this.dataHora,
    required this.status,
    this.observacoes = '',
    required this.valor,
  });

  Map<String, dynamic> toJson() {
    return {
      // Não incluir 'id' no toJson para criação no Firebase
      'clienteId': clienteId,
      'barbeiroId': barbeiroId,
      'servicoId': servicoId,
      'dataHora':
          dataHora, // Firebase aceita DateTime diretamente como Timestamp
      'status': status.name,
      'observacoes': observacoes,
      'valor': valor,
    };
  }

  factory Agendamento.fromJson(Map<String, dynamic> json) {
    return Agendamento(
      id: json['id'] as String,
      clienteId: json['clienteId'] as String,
      barbeiroId: json['barbeiroId'] as String,
      servicoId: json['servicoId'] as String,
      dataHora: json['dataHora'] is String
          ? DateTime.parse(json['dataHora'] as String)
          : (json['dataHora'] as dynamic)
                .toDate(), // Para Timestamp do Firebase
      status: StatusAgendamento.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => StatusAgendamento.agendado,
      ),
      observacoes: json['observacoes'] as String? ?? '',
      valor: (json['valor'] as num).toDouble(),
    );
  }

  bool get podeSerCancelado {
    final agora = DateTime.now();
    final diferencaHoras = dataHora.difference(agora).inHours;

    return status == StatusAgendamento.agendado && diferencaHoras > 2;
  }
}

enum StatusAgendamento {
  agendado,
  confirmado,
  emAndamento,
  concluido,
  cancelado,
  naoCompareceu;

  String get label {
    switch (this) {
      case StatusAgendamento.agendado:
        return 'Agendado';
      case StatusAgendamento.confirmado:
        return 'Confirmado';
      case StatusAgendamento.emAndamento:
        return 'Em Andamento';
      case StatusAgendamento.concluido:
        return 'Concluído';
      case StatusAgendamento.cancelado:
        return 'Cancelado';
      case StatusAgendamento.naoCompareceu:
        return 'Não Compareceu';
    }
  }
}
