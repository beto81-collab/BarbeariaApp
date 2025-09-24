import 'package:flutter/services.dart';

/// Formatador de telefone que aplica máscara automaticamente
class TelefoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove todos os caracteres não numéricos
    final numeros = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Se não há números, retorna vazio
    if (numeros.isEmpty) {
      return const TextEditingValue();
    }

    // Limita a 11 dígitos
    final numeroLimitado = numeros.length > 11
        ? numeros.substring(0, 11)
        : numeros;

    String textoFormatado;

    if (numeroLimitado.length <= 2) {
      // Apenas código de área: (11
      textoFormatado = '($numeroLimitado';
    } else if (numeroLimitado.length <= 7) {
      // Código de área + início do número: (11) 9999
      textoFormatado =
          '(${numeroLimitado.substring(0, 2)}) ${numeroLimitado.substring(2)}';
    } else if (numeroLimitado.length <= 10) {
      // Telefone fixo: (11) 9999-9999
      textoFormatado =
          '(${numeroLimitado.substring(0, 2)}) ${numeroLimitado.substring(2, 6)}-${numeroLimitado.substring(6)}';
    } else {
      // Celular: (11) 99999-9999
      textoFormatado =
          '(${numeroLimitado.substring(0, 2)}) ${numeroLimitado.substring(2, 7)}-${numeroLimitado.substring(7)}';
    }

    return TextEditingValue(
      text: textoFormatado,
      selection: TextSelection.collapsed(offset: textoFormatado.length),
    );
  }
}

/// Utilitários para trabalhar com telefones
class TelefoneUtils {
  /// Remove formatação e retorna apenas os números
  static String apenasNumeros(String telefone) {
    return telefone.replaceAll(RegExp(r'[^\d]'), '');
  }

  /// Formata um telefone com máscara
  static String formatarTelefone(String telefone) {
    final numeros = apenasNumeros(telefone);

    if (numeros.length <= 2) {
      return '($numeros';
    } else if (numeros.length <= 7) {
      return '(${numeros.substring(0, 2)}) ${numeros.substring(2)}';
    } else if (numeros.length <= 10) {
      return '(${numeros.substring(0, 2)}) ${numeros.substring(2, 6)}-${numeros.substring(6)}';
    } else if (numeros.length == 11) {
      return '(${numeros.substring(0, 2)}) ${numeros.substring(2, 7)}-${numeros.substring(7)}';
    } else {
      return telefone; // Retorna original se inválido
    }
  }

  /// Valida se um telefone brasileiro é válido
  static bool isValido(String telefone) {
    final numeros = apenasNumeros(telefone);

    // Deve ter 10 ou 11 dígitos
    if (numeros.length < 10 || numeros.length > 11) {
      return false;
    }

    // Código de área deve ser entre 11 e 99
    final codigoArea = int.tryParse(numeros.substring(0, 2));
    if (codigoArea == null || codigoArea < 11 || codigoArea > 99) {
      return false;
    }

    return true;
  }

  /// Retorna o tipo do telefone (fixo ou celular)
  static String tipoTelefone(String telefone) {
    final numeros = apenasNumeros(telefone);

    if (numeros.length == 11) {
      return 'Celular';
    } else if (numeros.length == 10) {
      return 'Fixo';
    } else {
      return 'Inválido';
    }
  }
}
