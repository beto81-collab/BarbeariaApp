import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/horario.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _horariosDoc = 'horarios_funcionamento';

  /// Busca os horários de funcionamento
  static Future<List<HorarioFuncionamento>>
  buscarHorariosFuncionamento() async {
    try {
      final doc = await _firestore.collection('config').doc(_horariosDoc).get();
      if (!doc.exists || doc.data() == null || doc.data()!['dias'] == null) {
        // Retorna padrão se não existir
        return diasSemana
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
      }
      final Map<String, dynamic> dias = Map<String, dynamic>.from(
        doc.data()!['dias'],
      );
      return dias.values
          .map(
            (v) => HorarioFuncionamento.fromJson(Map<String, dynamic>.from(v)),
          )
          .toList();
    } catch (e) {
      print('Erro ao buscar horários: $e');
      rethrow;
    }
  }
}
