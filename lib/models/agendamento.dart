class Agendamento {
  final String id;
  final String clienteId;
  final String barbeiroId;
  final String servicoId;
  final DateTime dataHora;
  final StatusAgendamento status;
  final String observacoes;
  final double valor;
  final String? clienteNome;
  final String? servicoNome;
  final String? clienteTelefone;
  final String? clienteEmail;

  const Agendamento({
    required this.id,
    required this.clienteId,
    required this.barbeiroId,
    required this.servicoId,
    required this.dataHora,
    required this.status,
    this.observacoes = '',
    required this.valor,
    this.clienteNome,
    this.servicoNome,
    this.clienteTelefone,
    this.clienteEmail,
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
      'clienteNome': clienteNome,
      'servicoNome': servicoNome,
      if (clienteTelefone != null) 'clienteTelefone': clienteTelefone,
      if (clienteEmail != null) 'clienteEmail': clienteEmail,
    };
  }

  factory Agendamento.fromJson(Map<String, dynamic> json) {
    DateTime parsedDataHora;
    try {
      final raw = json['dataHora'];
      if (raw is String) {
        final tryParse = DateTime.tryParse(raw);
        if (tryParse != null) {
          parsedDataHora = tryParse;
        } else {
          // Não está em ISO; tentar log e fallback
          print(
            'Aviso: dataHora em formato inesperado, usando DateTime.now() - valor: $raw',
          );
          parsedDataHora = DateTime.now();
        }
      } else {
        parsedDataHora = (raw as dynamic).toDate(); // Timestamp
      }
    } catch (e) {
      print('Erro ao parsear dataHora do agendamento: $e');
      parsedDataHora = DateTime.now();
    }

    // Ler campos com tolerância a valores nulos (alguns documentos podem ter apenas nomes)
    final id = json['id'] as String? ?? '';
    final clienteId = json['clienteId'] as String? ?? '';
    final barbeiroId = json['barbeiroId'] as String? ?? '';
    final servicoId = json['servicoId'] as String? ?? '';
    final statusStr = json['status'] as String?;
    final status = StatusAgendamento.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => StatusAgendamento.agendado,
    );
    final observacoes = json['observacoes'] as String? ?? '';
    final valor = (json['valor'] as num?)?.toDouble() ?? 0.0;
    final clienteNome = json['clienteNome'] as String?;
    final servicoNome = json['servicoNome'] as String?;
  final clienteTelefone = json['clienteTelefone'] as String?;
  final clienteEmail = json['clienteEmail'] as String?;

    return Agendamento(
      id: id,
      clienteId: clienteId,
      barbeiroId: barbeiroId,
      servicoId: servicoId,
      dataHora: parsedDataHora,
      status: status,
      observacoes: observacoes,
      valor: valor,
      clienteNome: clienteNome,
      servicoNome: servicoNome,
      clienteTelefone: clienteTelefone,
      clienteEmail: clienteEmail,
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
