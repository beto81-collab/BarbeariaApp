import '../screens/backup_auto_config.dart';
import '../models/app_version.dart';
import '../models/promocao.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/usuario.dart';
import '../models/agendamento.dart';
import '../models/produto.dart';
import '../models/servico.dart';
import '../models/horario.dart';

class FirebaseService {
  /// Stream que retorna o número de agendamentos pendentes de confirmação (para badge no dashboard)
  static Stream<int> streamContadorAgendamentosPendentes() {
    return _firestore.collection(_appointmentsCollection).snapshots().map((
      snapshot,
    ) {
      int count = 0;
      for (final doc in snapshot.docs) {
        final raw = doc.data();
        final dynamic statusField = raw['status'];
        final statusRaw = statusField is String
            ? statusField
            : (statusField?.toString() ?? '');
        if (statusRaw == 'pendente' ||
            statusRaw == StatusAgendamento.agendado.name) {
          count++;
        }
      }
      return count;
    });
  }

  /// Faz upload de uma imagem da vitrine usando bytes (para Flutter Web) e salva a URL no Firestore
  static Future<void> uploadImagemVitrineBytes(Uint8List imageBytes) async {
    try {
      final fileName =
          'vitrine/${DateTime.now().millisecondsSinceEpoch}_vitrine.jpg';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = await ref.putData(imageBytes);
      final url = await uploadTask.ref.getDownloadURL();
      // Salva a URL no Firestore (coleção 'vitrine')
      await FirebaseFirestore.instance.collection('vitrine').add({
        'url': url,
        'data': DateTime.now(),
      });
    } catch (e) {
      print('Erro ao fazer upload da imagem da vitrine (bytes): $e');
      rethrow;
    }
  }

  /// Faz upload de bytes (Flutter Web) com callback de progresso.
  /// onProgress recebe o TaskSnapshot a cada evento de snapshot.
  static Future<void> uploadImagemVitrineBytesWithProgress(
    Uint8List imageBytes, {
    void Function(TaskSnapshot snapshot)? onProgress,
  }) async {
    try {
      final fileName =
          'vitrine/${DateTime.now().millisecondsSinceEpoch}_vitrine.jpg';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = ref.putData(imageBytes);

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen(onProgress);
      }

      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();
      await FirebaseFirestore.instance.collection('vitrine').add({
        'url': url,
        'data': DateTime.now(),
      });
    } catch (e) {
      print(
        'Erro ao fazer upload da imagem da vitrine (bytes) com progresso: $e',
      );
      rethrow;
    }
  }

  /// Faz upload de uma imagem da vitrine para o Firebase Storage e salva a URL no Firestore
  static Future<void> uploadImagemVitrine(File imagemFile) async {
    try {
      final fileName =
          'vitrine/${DateTime.now().millisecondsSinceEpoch}_${imagemFile.path.split('/').last}';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = await ref.putFile(imagemFile);
      final url = await uploadTask.ref.getDownloadURL();
      // Salva a URL no Firestore (coleção 'vitrine')
      await FirebaseFirestore.instance.collection('vitrine').add({
        'url': url,
        'data': DateTime.now(),
      });
    } catch (e) {
      print('Erro ao fazer upload da imagem da vitrine: $e');
      rethrow;
    }
  }

  /// Faz upload de arquivo (mobile/desktop) com callback de progresso.
  static Future<void> uploadImagemVitrineFileWithProgress(
    File imagemFile, {
    void Function(TaskSnapshot snapshot)? onProgress,
  }) async {
    try {
      final fileName =
          'vitrine/${DateTime.now().millisecondsSinceEpoch}_${imagemFile.path.split('/').last}';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = ref.putFile(imagemFile);

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen(onProgress);
      }

      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();
      await FirebaseFirestore.instance.collection('vitrine').add({
        'url': url,
        'data': DateTime.now(),
      });
    } catch (e) {
      print(
        'Erro ao fazer upload da imagem da vitrine (arquivo) com progresso: $e',
      );
      rethrow;
    }
  }

  /// Lista as imagens da vitrine (URLs)
  static Future<List<String>> listarImagensVitrine() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('vitrine')
          .orderBy('data', descending: true)
          .get();
      return query.docs.map((doc) => doc['url'] as String).toList();
    } catch (e) {
      print('Erro ao listar imagens da vitrine: $e');
      return [];
    }
  }

  /// Remove uma imagem da vitrine (Firestore e Storage)
  static Future<void> removerImagemVitrine(String url) async {
    try {
      // Remove do Firestore
      final query = await FirebaseFirestore.instance
          .collection('vitrine')
          .where('url', isEqualTo: url)
          .get();
      for (var doc in query.docs) {
        await doc.reference.delete();
      }
      // Remove do Storage
      final ref = FirebaseStorage.instance.refFromURL(url);
      await ref.delete();
    } catch (e) {
      print('Erro ao remover imagem da vitrine: $e');
      rethrow;
    }
  }

  /// Adiciona uma entrada na coleção 'vitrine' usando uma URL já existente
  static Future<void> adicionarImagemVitrinePorUrl(String url) async {
    try {
      await FirebaseFirestore.instance.collection('vitrine').add({
        'url': url,
        'data': DateTime.now(),
      });
    } catch (e) {
      print('Erro ao adicionar imagem na vitrine por URL: $e');
      rethrow;
    }
  }

  /// Faz upload de um arquivo de backup JSON para o Firebase Storage e retorna a URL pública
  static Future<String> uploadBackupJson(String jsonStr) async {
    try {
      final fileName =
          'backups/backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = await ref.putData(
        Uint8List.fromList(utf8.encode(jsonStr)),
        SettableMetadata(contentType: 'application/json'),
      );
      final url = await uploadTask.ref.getDownloadURL();
      return url;
    } catch (e) {
      print('Erro ao fazer upload do backup: $e');
      rethrow;
    }
  }

  /// Faz upload de uma imagem para o Firebase Storage e retorna a URL pública
  static Future<String> uploadImagemProduto(File imagemFile) async {
    try {
      final fileName =
          'produtos/${DateTime.now().millisecondsSinceEpoch}_${imagemFile.path.split('/').last}';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = await ref.putFile(imagemFile);
      final url = await uploadTask.ref.getDownloadURL();
      return url;
    } catch (e) {
      print('Erro ao fazer upload da imagem: $e');
      rethrow;
    }
  }

  /// Faz upload de uma imagem usando bytes (para Flutter Web) e retorna a URL pública
  static Future<String> uploadImagemProdutoBytes(Uint8List imageBytes) async {
    try {
      final fileName =
          'produtos/${DateTime.now().millisecondsSinceEpoch}_produto.jpg';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = await ref.putData(imageBytes);
      final url = await uploadTask.ref.getDownloadURL();
      return url;
    } catch (e) {
      print('Erro ao fazer upload da imagem (bytes): $e');
      rethrow;
    }
  }

  /// Faz upload de uma imagem de promoção (arquivo) para o Firebase Storage e retorna a URL pública
  static Future<String> uploadImagemPromocao(File imagemFile) async {
    try {
      final fileName =
          'promocoes/images/${DateTime.now().millisecondsSinceEpoch}_${imagemFile.path.split(Platform.pathSeparator).last}';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = await ref.putFile(imagemFile);
      final url = await uploadTask.ref.getDownloadURL();
      return url;
    } catch (e) {
      print('Erro ao fazer upload da imagem da promoção: $e');
      rethrow;
    }
  }

  /// Faz upload de uma imagem de promoção usando bytes (para Flutter Web) e retorna a URL pública
  static Future<String> uploadImagemPromocaoBytes(Uint8List imageBytes) async {
    try {
      final fileName =
          'promocoes/images/${DateTime.now().millisecondsSinceEpoch}_promocao.jpg';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = await ref.putData(imageBytes);
      final url = await uploadTask.ref.getDownloadURL();
      return url;
    } catch (e) {
      print('Erro ao fazer upload da imagem da promoção (bytes): $e');
      rethrow;
    }
  }

  // ==================== ATUALIZAÇÕES ====================
  static const String _configCollection = 'config';
  static const String _appVersionDoc = 'app_version';

  // ==================== CONFIG: AGENDAMENTO (Switch app cliente) ====================
  static const String _agendamentoConfigDoc = 'agendamento';

  /// Stream do flag de habilitar/desabilitar agendamentos no app do cliente
  /// Fallback para true (habilitado) quando o doc/campo não existir
  static Stream<bool> streamAgendamentosHabilitados() {
    return _firestore
        .collection(_configCollection)
        .doc(_agendamentoConfigDoc)
        .snapshots()
        .map((d) => (d.data()?['agendamentosHabilitados'] as bool?) ?? true);
  }

  /// Leitura pontual do flag (default true)
  static Future<bool> getAgendamentosHabilitados() async {
    final d = await _firestore
        .collection(_configCollection)
        .doc(_agendamentoConfigDoc)
        .get();
    return (d.data()?['agendamentosHabilitados'] as bool?) ?? true;
  }

  /// Atualiza/cria o flag de agendamentos habilitados no config/agendamento
  static Future<void> setAgendamentosHabilitados(bool enabled) async {
    final ref = _firestore
        .collection(_configCollection)
        .doc(_agendamentoConfigDoc);
    await ref.set({'agendamentosHabilitados': enabled}, SetOptions(merge: true));
    BackupAutoConfig.houveAlteracao = true;
  }

  static Future<AppVersion?> buscarVersaoApp() async {
    try {
      final doc = await _firestore
          .collection(_configCollection)
          .doc(_appVersionDoc)
          .get();
      if (!doc.exists || doc.data() == null) return null;
      return AppVersion.fromJson(doc.data()!);
    } catch (e) {
      print('Erro ao buscar versão do app: $e');
      return null;
    }
  }

  static Future<void> atualizarVersaoApp(AppVersion versao) async {
    try {
      await _firestore
          .collection(_configCollection)
          .doc(_appVersionDoc)
          .set(versao.toJson());
    } catch (e) {
      print('Erro ao atualizar versão do app: $e');
      rethrow;
    }
  }

  // ==================== PROMOÇÕES ====================
  static const String _promocoesCollection = 'promocoes';

  static Future<String> criarPromocao(Promocao promocao) async {
    try {
      // Preparar dados para Firestore (inclui valor original do serviço/produto se referenciado)
      final Map<String, dynamic> docData = Map<String, dynamic>.from(
        promocao.toJson(),
      );

      // Se houver servicoId e não houver valorOriginal, buscar o valor do serviço
      if (docData['servicoId'] != null &&
          (docData['valorOriginal'] == null ||
              docData['valorOriginal'].toString().isEmpty)) {
        try {
          final servRef = _firestore
              .collection('servicos')
              .doc(docData['servicoId']);
          final servSnap = await servRef.get();
          if (servSnap.exists && servSnap.data() != null) {
            final serv = servSnap.data()!;
            // campos comuns esperados: 'valor', 'titulo', 'descricao', 'tempo'
            if (serv['valor'] != null) {
              final valor = (serv['valor'] is num)
                  ? (serv['valor'] as num).toDouble()
                  : double.tryParse(serv['valor'].toString());
              if (valor != null)
                docData['valorOriginal'] = double.parse(
                  valor.toStringAsFixed(2),
                );
            }
            docData['servicoTitulo'] =
                serv['titulo'] ?? serv['nome'] ?? docData['titulo'];
            docData['servicoDescricao'] = serv['descricao'] ?? '';
            docData['servicoTempo'] = serv['tempo'] ?? serv['duracao'] ?? '';
          }
        } catch (e) {
          print('Aviso: falha ao obter dados do serviço para promoção: $e');
        }
      }

      // Se houver produtoId e não houver valorOriginal, buscar o valor do produto
      if (docData['produtoId'] != null &&
          (docData['valorOriginal'] == null ||
              docData['valorOriginal'].toString().isEmpty)) {
        try {
          final prodRef = _firestore
              .collection('produtos')
              .doc(docData['produtoId']);
          final prodSnap = await prodRef.get();
          if (prodSnap.exists && prodSnap.data() != null) {
            final prod = prodSnap.data()!;
            if (prod['valor'] != null) {
              final valor = (prod['valor'] is num)
                  ? (prod['valor'] as num).toDouble()
                  : double.tryParse(prod['valor'].toString());
              if (valor != null)
                docData['valorOriginal'] = double.parse(
                  valor.toStringAsFixed(2),
                );
            }
            docData['produtoTitulo'] =
                prod['titulo'] ?? prod['nome'] ?? docData['titulo'];
            docData['produtoDescricao'] = prod['descricao'] ?? '';
          }
        } catch (e) {
          print('Aviso: falha ao obter dados do produto para promoção: $e');
        }
      }

      // Calcular valor com desconto se possível
      if (docData['valorOriginal'] != null && docData['desconto'] != null) {
        try {
          final double valor = (docData['valorOriginal'] is num)
              ? (docData['valorOriginal'] as num).toDouble()
              : double.parse(docData['valorOriginal'].toString());
          final double perc = (docData['desconto'] is num)
              ? (docData['desconto'] as num).toDouble()
              : double.parse(docData['desconto'].toString());
          final double valorCom = (valor * (1 - (perc / 100)));
          docData['valorComDesconto'] = double.parse(
            valorCom.toStringAsFixed(2),
          );
        } catch (e) {
          print('Aviso: falha ao calcular valor com desconto: $e');
        }
      }

      // Mantém comportamento anterior de envio de imagemLocalPath se existir
      if (docData['imagemLocalPath'] != null &&
          docData['imagemLocalPath'] is String) {
        try {
          final path = docData['imagemLocalPath'] as String;
          final file = File(path);
          if (await file.exists()) {
            final url = await uploadImagemPromocao(file);
            docData['imagem'] = url;
          }
        } catch (e) {
          print('Aviso: falha ao enviar imagem da promoção: $e');
        }
        docData.remove('imagemLocalPath');
      }

      final doc = await _firestore
          .collection(_promocoesCollection)
          .add(docData);

      // Também salvar uma cópia JSON no Firebase Storage em 'promocoes/{id}.json'
      try {
        final id = doc.id;
        final Map<String, dynamic> dataToSave = {
          ...docData,
          'id': id,
          'salvoEm': DateTime.now().toIso8601String(),
        };
        final jsonStr = jsonEncode(dataToSave);
        final fileName = 'promocoes/${id}.json';
        final ref = FirebaseStorage.instance.ref().child(fileName);
        await ref.putData(
          Uint8List.fromList(utf8.encode(jsonStr)),
          SettableMetadata(contentType: 'application/json'),
        );
      } catch (e) {
        print('Aviso: falha ao salvar promoção no Storage: $e');
      }

      BackupAutoConfig.houveAlteracao = true;
      return doc.id;
    } catch (e) {
      print('Erro ao criar promoção: $e');
      rethrow;
    }
  }

  static Future<void> atualizarPromocao(Promocao promocao) async {
    try {
      final Map<String, dynamic> updateData = Map<String, dynamic>.from(
        promocao.toJson(),
      );

      // Preencher valor original do serviço/produto se necessário (mesma lógica do criar)
      if (updateData['servicoId'] != null &&
          (updateData['valorOriginal'] == null ||
              updateData['valorOriginal'].toString().isEmpty)) {
        try {
          final servRef = _firestore
              .collection('servicos')
              .doc(updateData['servicoId']);
          final servSnap = await servRef.get();
          if (servSnap.exists && servSnap.data() != null) {
            final serv = servSnap.data()!;
            if (serv['valor'] != null) {
              final valor = (serv['valor'] is num)
                  ? (serv['valor'] as num).toDouble()
                  : double.tryParse(serv['valor'].toString());
              if (valor != null)
                updateData['valorOriginal'] = double.parse(
                  valor.toStringAsFixed(2),
                );
            }
            updateData['servicoTitulo'] =
                serv['titulo'] ?? serv['nome'] ?? updateData['titulo'];
            updateData['servicoDescricao'] = serv['descricao'] ?? '';
            updateData['servicoTempo'] = serv['tempo'] ?? serv['duracao'] ?? '';
          }
        } catch (e) {
          print('Aviso: falha ao obter dados do serviço (update): $e');
        }
      }

      if (updateData['produtoId'] != null &&
          (updateData['valorOriginal'] == null ||
              updateData['valorOriginal'].toString().isEmpty)) {
        try {
          final prodRef = _firestore
              .collection('produtos')
              .doc(updateData['produtoId']);
          final prodSnap = await prodRef.get();
          if (prodSnap.exists && prodSnap.data() != null) {
            final prod = prodSnap.data()!;
            if (prod['valor'] != null) {
              final valor = (prod['valor'] is num)
                  ? (prod['valor'] as num).toDouble()
                  : double.tryParse(prod['valor'].toString());
              if (valor != null)
                updateData['valorOriginal'] = double.parse(
                  valor.toStringAsFixed(2),
                );
            }
            updateData['produtoTitulo'] =
                prod['titulo'] ?? prod['nome'] ?? updateData['titulo'];
            updateData['produtoDescricao'] = prod['descricao'] ?? '';
          }
        } catch (e) {
          print('Aviso: falha ao obter dados do produto (update): $e');
        }
      }

      // recalcula valor com desconto se possível
      if (updateData['valorOriginal'] != null &&
          updateData['desconto'] != null) {
        try {
          final double valor = (updateData['valorOriginal'] is num)
              ? (updateData['valorOriginal'] as num).toDouble()
              : double.parse(updateData['valorOriginal'].toString());
          final double perc = (updateData['desconto'] is num)
              ? (updateData['desconto'] as num).toDouble()
              : double.parse(updateData['desconto'].toString());
          final double valorCom = (valor * (1 - (perc / 100)));
          updateData['valorComDesconto'] = double.parse(
            valorCom.toStringAsFixed(2),
          );
        } catch (e) {
          print('Aviso: falha ao recalcular valor com desconto (update): $e');
        }
      }

      if (updateData['imagemLocalPath'] != null &&
          updateData['imagemLocalPath'] is String) {
        try {
          final path = updateData['imagemLocalPath'] as String;
          final file = File(path);
          if (await file.exists()) {
            final url = await uploadImagemPromocao(file);
            updateData['imagem'] = url;
          }
        } catch (e) {
          print('Aviso: falha ao enviar imagem da promoção (update): $e');
        }
        updateData.remove('imagemLocalPath');
      }

      await _firestore
          .collection(_promocoesCollection)
          .doc(promocao.id)
          .update(updateData);

      // Atualizar a cópia JSON no Firebase Storage também
      try {
        final Map<String, dynamic> dataToSave = {
          ...updateData,
          'id': promocao.id,
          'salvoEm': DateTime.now().toIso8601String(),
        };
        final jsonStr = jsonEncode(dataToSave);
        final fileName = 'promocoes/${promocao.id}.json';
        final ref = FirebaseStorage.instance.ref().child(fileName);
        await ref.putData(
          Uint8List.fromList(utf8.encode(jsonStr)),
          SettableMetadata(contentType: 'application/json'),
        );
      } catch (e) {
        print('Aviso: falha ao atualizar promoção no Storage: $e');
      }

      BackupAutoConfig.houveAlteracao = true;
    } catch (e) {
      print('Erro ao atualizar promoção: $e');
      rethrow;
    }
  }

  static Future<void> removerPromocao(String id) async {
    try {
      await _firestore.collection(_promocoesCollection).doc(id).delete();
      // Remover também o arquivo JSON no Storage, se existir
      try {
        final fileName = 'promocoes/${id}.json';
        final ref = FirebaseStorage.instance.ref().child(fileName);
        await ref.delete();
      } catch (e) {
        // Se não existir ou falhar, apenas logar
        print('Aviso: falha ao remover arquivo de promoção no Storage: $e');
      }

      BackupAutoConfig.houveAlteracao = true;
    } catch (e) {
      print('Erro ao remover promoção: $e');
      rethrow;
    }
  }

  static Future<List<Promocao>> buscarPromocoes() async {
    try {
      final query = await _firestore
          .collection(_promocoesCollection)
          .orderBy('validade', descending: false)
          .get();
      return query.docs
          .map((doc) => Promocao.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Erro ao buscar promoções: $e');
      return [];
    }
  }

  static Stream<List<Promocao>> streamPromocoes() {
    return _firestore
        .collection(_promocoesCollection)
        .orderBy('validade', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Promocao.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  // Instâncias do Firebase
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Coleções do Firestore
  static const String _usersCollection = 'usuarios';
  static const String _appointmentsCollection = 'agendamentos';
  static const String _servicesCollection = 'servicos';
  static const String _productsCollection = 'produtos';

  // ==================== AUTENTICAÇÃO ====================

  /// Registra um novo usuário
  static Future<User?> registrarUsuario(
    String email,
    String senha,
    Usuario usuario,
  ) async {
    try {
      // Criar usuário no Firebase Auth
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );

      if (result.user != null) {
        // Salvar dados do usuário no Firestore
        await _firestore
            .collection(_usersCollection)
            .doc(result.user!.uid)
            .set(usuario.toJson());

        return result.user;
      }
    } catch (e) {
      print('Erro ao registrar usuário: $e');
      rethrow;
    }
    return null;
  }

  /// Faz login do usuário
  static Future<User?> fazerLogin(String email, String senha) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );
      return result.user;
    } catch (e) {
      print('Erro ao fazer login: $e');
      rethrow;
    }
  }

  /// Logout do usuário
  static Future<void> logout() async {
    await _auth.signOut();
  }

  /// Obtém o usuário atual
  static User? get usuarioAtual => _auth.currentUser;

  /// Stream do estado de autenticação
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ==================== USUÁRIOS ====================
  /// Busca clientes aniversariantes em uma data específica
  static Future<List<Usuario>> buscarAniversariantes(DateTime data) async {
    try {
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('tipo', isEqualTo: 'cliente')
          .get();

      final List<Usuario> resultados = [];

      for (final doc in querySnapshot.docs) {
        try {
          final raw = {...doc.data()};

          // verificar se a data de nascimento bate com a data solicitada
          DateTime? dataNascimento;
          if (raw['dataNascimento'] != null) {
            try {
              dataNascimento = raw['dataNascimento'] is String
                  ? DateTime.parse(raw['dataNascimento'] as String)
                  : (raw['dataNascimento'] is DateTime
                      ? raw['dataNascimento'] as DateTime
                      : null);
            } catch (_) {
              dataNascimento = null;
            }
          }

          if (dataNascimento == null) continue;
          if (dataNascimento.day != data.day || dataNascimento.month != data.month) continue;

          // se não tem presenteAniversario no documento do usuário, verificar se existe um resgate pendente (feito pelo app cliente)
          if (raw['presenteAniversario'] == null) {
            try {
              final resgQuery = await _firestore
                  .collection('resgates')
                  .where('usuarioId', isEqualTo: doc.id)
                  .where('resgatado', isEqualTo: false)
                  .limit(1)
                  .get();

              if (resgQuery.docs.isNotEmpty) {
                final r = resgQuery.docs.first.data();
                // construir um presente a partir do resgate encontrado (mantendo a semântica usada pela UI)
                final presenteFromResgate = <String, dynamic>{};
                if (r['premio'] != null) {
                  try {
                    presenteFromResgate.addAll(Map<String, dynamic>.from(r['premio']));
                  } catch (_) {
                    // ignore
                  }
                }
                presenteFromResgate['resgatado'] = r['resgatado'] ?? false;
                presenteFromResgate['enviadoEm'] = r['criadoEm'] ?? r['enviadoEm'];
                raw['presenteAniversario'] = presenteFromResgate;
              }
            } catch (e) {
              // se falhar ao verificar resgates, prosseguir sem bloquear
              print('Aviso: falha ao checar resgates para usuário ${doc.id}: $e');
            }
          }

          raw['id'] = doc.id;
          resultados.add(Usuario.fromJson(raw));
        } catch (e) {
          print('Erro ao processar documento de usuário ${doc.id}: $e');
        }
      }

      return resultados;
    } catch (e) {
      print('Erro ao buscar aniversariantes: $e');
      return [];
    }
  }

  /// Conta quantos aniversariantes há hoje que ainda não receberam presente (para sinalizador no dashboard)
  static Future<int> contarAniversariantesHoje() async {
    try {
      final hoje = DateTime.now();
      final aniversariantes = await buscarAniversariantes(hoje);

      // Filtra apenas aniversariantes que ainda não receberam presente hoje
      int count = 0;
      for (final cliente in aniversariantes) {
        final doc = await _firestore
            .collection(_usersCollection)
            .doc(cliente.id)
            .get();

        final data = doc.data();
        if (data == null) continue;

        final presente = data['presenteAniversario'] as Map<String, dynamic>?;

        // Contar como pendente quando NÃO há presente OU quando há presente e
        // ele não foi resgatado, não foi entregue e não expirou.
        if (presente == null) {
          count++; // Não recebeu presente ainda
        } else {
          final resgatado = presente['resgatado'] == true;
          final entregue = presente['entregue'] == true;
          final expirado = _presenteExpirado(presente);
          if (!resgatado && !entregue && !expirado) {
            count++;
          }
        }
      }

      return count;
    } catch (e) {
      print('Erro ao contar aniversariantes: $e');
      return 0;
    }
  }


  /// Stream que atualiza automaticamente o contador de aniversariantes pendentes
  static Stream<int> streamContadorAniversariantesHoje() {
    return _firestore
        .collection(_usersCollection)
        .where('tipo', isEqualTo: 'cliente')
        .snapshots()
        .asyncMap((snapshot) async {
          try {
            final hoje = DateTime.now();
            int count = 0;

            for (final doc in snapshot.docs) {
              final data = {...doc.data(), 'id': doc.id};
              final usuario = Usuario.fromJson(data);

              // Verifica se é aniversariante hoje
              if (usuario.dataNascimento != null &&
                  usuario.dataNascimento!.day == hoje.day &&
                  usuario.dataNascimento!.month == hoje.month) {
                final presente =
                    data['presenteAniversario'] as Map<String, dynamic>?;

                // debug removed

                // Contar como pendente quando NÃO há presente OU quando há presente e
                // ele não foi resgatado, não foi entregue e não expirou.
                if (presente == null) {
                  count++;
                } else {
                  final resgatado = presente['resgatado'] == true;
                  final entregue = presente['entregue'] == true;
                  final expirado = _presenteExpirado(presente);
                  if (!resgatado && !entregue && !expirado) {
                    count++;
                  }
                }
              }
            }

            return count;
          } catch (e) {
            print('Erro no stream de aniversariantes: $e');
            return 0;
          }
        });
  }

  /// Retorna true se o presente expirou. Aceita Timestamp, String, num ou Map.
  static bool _presenteExpirado(Map<String, dynamic>? presente) {
    if (presente == null) return false;
    final exp = presente['expiraEm'];
    if (exp == null) return false;
    final dt = _toDateTime(exp);
    if (dt == null) return false;
    return DateTime.now().isAfter(dt);
  }


  /// Obtém dados do usuário atual
  static Future<Usuario?> obterUsuarioAtual() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore
            .collection(_usersCollection)
            .doc(user.uid)
            .get();

        if (doc.exists) {
          return Usuario.fromJson({...doc.data()!, 'id': doc.id});
        }
      }
    } catch (e) {
      print('Erro ao obter usuário: $e');
    }
    return null;
  }

  /// Obtém um usuário por id
  static Future<Usuario?> obterUsuarioPorId(String usuarioId) async {
    if (usuarioId.isEmpty) {
      print('aviso: obterUsuarioPorId chamado com id vazio');
      return null;
    }
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(usuarioId)
          .get();
      if (!doc.exists || doc.data() == null) return null;
      return Usuario.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      print('Erro ao obter usuário por id: $e');
      return null;
    }
  }

  /// Obtém o map cru do documento de usuário por id (ou null se não existir)
  static Future<Map<String, dynamic>?> obterUsuarioMapPorId(
    String usuarioId,
  ) async {
    if (usuarioId.isEmpty) {
      print('aviso: obterUsuarioMapPorId chamado com id vazio');
      return null;
    }
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(usuarioId)
          .get();
      if (!doc.exists || doc.data() == null) return null;
      return Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
    } catch (e) {
      print('Erro ao obter map cru do usuário por id: $e');
      return null;
    }
  }

  /// Stream do map cru do documento do usuário por id (ou null se não existir)
  static Stream<Map<String, dynamic>?> streamUsuarioMapPorId(String usuarioId) {
    if (usuarioId.isEmpty) {
      print('aviso: streamUsuarioMapPorId chamado com id vazio');
      return Stream.value(null);
    }
    try {
      return _firestore
          .collection(_usersCollection)
          .doc(usuarioId)
          .snapshots()
          .map((snap) {
            if (!snap.exists || snap.data() == null) return null;
            return Map<String, dynamic>.from(
              snap.data() as Map<String, dynamic>,
            );
          });
    } catch (e) {
      print('Erro ao criar stream do usuário por id: $e');
      return Stream.value(null);
    }
  }

  /// Obtém um serviço por id
  static Future<Servico?> obterServicoPorId(String servicoId) async {
    if (servicoId.isEmpty) {
      print('aviso: obterServicoPorId chamado com id vazio');
      return null;
    }
    try {
      final doc = await _firestore
          .collection(_servicesCollection)
          .doc(servicoId)
          .get();
      if (!doc.exists || doc.data() == null) return null;
      return Servico.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      print('Erro ao obter serviço por id: $e');
      return null;
    }
  }

  /// Atualiza dados do usuário
  static Future<void> atualizarUsuario(Usuario usuario) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(usuario.id)
          .update(usuario.toJson());
      BackupAutoConfig.houveAlteracao = true;
    } catch (e) {
      print('Erro ao atualizar usuário: $e');
      rethrow;
    }
  }

  /// Atualiza campos específicos do documento do usuário (merge parcial)
  static Future<void> atualizarUsuarioField(
    String usuarioId,
    Map<String, dynamic> fields,
  ) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(usuarioId)
          .update(fields);
      BackupAutoConfig.houveAlteracao = true;
    } catch (e) {
      print('Erro ao atualizar campos do usuário: $e');
      rethrow;
    }
  }

  /// Atualiza o campo presenteAniversario para um usuário específico
  static Future<void> atualizarPresenteAniversario(
    String usuarioId,
    Map<String, dynamic> presente,
  ) async {
    try {
      await _firestore.collection(_usersCollection).doc(usuarioId).update({
        'presenteAniversario': presente,
      });
      BackupAutoConfig.houveAlteracao = true;
    } catch (e) {
      print('Erro ao atualizar presente de aniversário: $e');
      rethrow;
    }
  }

  /// Marca o presente de aniversário como entregue pelo admin (campo entregue=true)
  static Future<void> marcarPresenteComoEntregue(String usuarioId) async {
    try {
      final docRef = _firestore.collection(_usersCollection).doc(usuarioId);
      final doc = await docRef.get();
      if (!doc.exists || doc.data() == null) return;
      final data = {...doc.data()!};
      final presente = Map<String, dynamic>.from(
        data['presenteAniversario'] ?? {},
      );
      presente['entregue'] = true;
      presente['entregueEm'] = DateTime.now().toIso8601String();
      await docRef.update({'presenteAniversario': presente});
      BackupAutoConfig.houveAlteracao = true;
    } catch (e) {
      print('Erro ao marcar presente como entregue: $e');
      rethrow;
    }
  }

  /// Busca todos os clientes
  static Future<List<Usuario>> buscarClientes() async {
    try {
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('tipo', isEqualTo: 'cliente')
          .get();

      return querySnapshot.docs.map((doc) {
        return Usuario.fromJson({...doc.data(), 'id': doc.id});
      }).toList();
    } catch (e) {
      print('Erro ao buscar clientes: $e');
      return [];
    }
  }

  /// Busca todos os barbeiros
  static Future<List<Usuario>> buscarBarbeiros() async {
    try {
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('tipo', isEqualTo: 'barbeiro')
          .get();

      return querySnapshot.docs.map((doc) {
        return Usuario.fromJson({...doc.data(), 'id': doc.id});
      }).toList();
    } catch (e) {
      print('Erro ao buscar barbeiros: $e');
      return [];
    }
  }

  /// Retorna um stream de clientes cadastrados
  Stream<List<Usuario>> streamClientes() {
    return _firestore
        .collection(_usersCollection)
        .where('tipo', isEqualTo: 'cliente')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Usuario.fromJson({...doc.data(), 'id': doc.id}))
              .toList();
        });
  }

  /// Incrementa a contagem de atendimentos para um cliente em 1
  Future<void> incrementServiceCount(String clienteId) async {
    final docRef = _firestore.collection(_usersCollection).doc(clienteId);
    await docRef.update({'atendimentos': FieldValue.increment(1)});
    BackupAutoConfig.houveAlteracao = true;
  }

  /// Incrementa a contagem de atendimentos para um cliente em N
  static Future<void> incrementServiceCountBy(String clienteId, int n) async {
    if (n == 0) return;
    final docRef = _firestore.collection(_usersCollection).doc(clienteId);
    await docRef.update({'atendimentos': FieldValue.increment(n)});
    BackupAutoConfig.houveAlteracao = true;
  }

  /// Incrementa pontos de fidelidade (campo 'pontosFidelidade') em N
  static Future<void> incrementarPontosFidelidade(
    String usuarioId,
    int n,
  ) async {
    if (n == 0) return;
    final docRef = _firestore.collection(_usersCollection).doc(usuarioId);
    await docRef.update({'pontosFidelidade': FieldValue.increment(n)});
    BackupAutoConfig.houveAlteracao = true;
  }

  /// Cria um documento de resgate de prêmio e zera/subtrai pontosFidelidade por 10
  static Future<void> resgatarPremioParaUsuario(
    String usuarioId,
    Map<String, dynamic> premioData,
  ) async {
    try {
      // Criar documento de resgate (não altera pontos; o consumo ocorre quando admin confirmar resgate)
      await _firestore.collection('resgates').add({
        'usuarioId': usuarioId,
        'premio': premioData,
        // registrar a hora de criação pelo servidor
        'criadoEm': FieldValue.serverTimestamp(),
        'resgatado': false,
        'enviado': false,
      });

      // NOTE: não persistir mais 'premioProgramaPontos' automaticamente no documento
      // do usuário a partir da criação do resgate. A gravação de presentes
      // específica (campo 'presenteAniversario') deve ser feita pela
      // tela/fluxo de aniversariantes quando aplicável.

      BackupAutoConfig.houveAlteracao = true;
    } catch (e) {
      print('Erro ao criar resgate: $e');
      rethrow;
    }
  }

  /// Verifica se já existe um documento de resgate para o usuário
  static Future<bool> resgateExisteParaUsuario(String usuarioId) async {
    try {
      final query = await _firestore
          .collection('resgates')
          .where('usuarioId', isEqualTo: usuarioId)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      print('Erro ao checar resgate existente: $e');
      return false;
    }
  }

  /// Stream de resgates pendentes (resgatado == false)
  static Stream<List<Map<String, dynamic>>> streamResgatesPendentes() {
    try {
      return _firestore
          .collection('resgates')
          .where('resgatado', isEqualTo: false)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => <String, dynamic>{...d.data(), 'id': d.id})
              .toList());
    } catch (e) {
      print('Erro ao criar stream de resgates pendentes: $e');
      return Stream.value([]);
    }
  }

  /// Finaliza o resgate: zera pontosFidelidade do usuário e remove o documento de resgate
  static Future<void> finalizarResgateParaUsuario(String usuarioId) async {
    try {
      // Procurar documento de resgate para o usuário
      final query = await _firestore
          .collection('resgates')
          .where('usuarioId', isEqualTo: usuarioId)
          .limit(1)
          .get();
      if (query.docs.isEmpty) {
        throw Exception('Nenhum resgate encontrado para este usuário');
      }

      for (final doc in query.docs) {
        await doc.reference.delete();
      }

      // Zerar pontosFidelidade
      final userRef = _firestore.collection(_usersCollection).doc(usuarioId);
      await userRef.update({'pontosFidelidade': 0});
      // pontos zerados

      BackupAutoConfig.houveAlteracao = true;
    } catch (e) {
      print('Erro ao finalizar resgate: $e');
      rethrow;
    }
  }

  /// Compatibilidade: cria um presente/resgate a partir de um payload genérico.
  /// Se o payload contiver 'usuarioId', o documento será associado a este usuário.
  /// Retorna o id do documento criado.
  static Future<String> criarPresente(Map<String, dynamic> payload) async {
    try {
      final docRef = await _firestore.collection('resgates').add({
        'premio': payload,
        'usuarioId': payload['usuarioId'],
        'criadoEm': FieldValue.serverTimestamp(),
        'resgatado': payload['resgatado'] ?? false,
        'enviado': payload['enviado'] ?? false,
      });
      BackupAutoConfig.houveAlteracao = true;
      return docRef.id;
    } catch (e) {
      print('Erro ao criar presente/resgate: $e');
      rethrow;
    }
  }

  // ==================== AGENDAMENTOS ====================

  /// Cria um novo agendamento
  static Future<String> criarAgendamento(Agendamento agendamento) async {
    try {
      final docRef = await _firestore
          .collection(_appointmentsCollection)
          .add(agendamento.toJson());
      return docRef.id;
    } catch (e) {
      print('Erro ao criar agendamento: $e');
      rethrow;
    }
  }

  /// Obtém agendamentos do usuário atual
  static Future<List<Agendamento>> obterAgendamentosUsuario() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final query = await _firestore
          .collection(_appointmentsCollection)
          .where('clienteId', isEqualTo: user.uid)
          .orderBy('dataHora', descending: true)
          .get();

      return query.docs
          .map((doc) => Agendamento.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Erro ao obter agendamentos: $e');
      return [];
    }
  }

  /// Stream de agendamentos do usuário (tempo real)
  static Stream<List<Agendamento>> streamAgendamentosUsuario() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection(_appointmentsCollection)
        .where('clienteId', isEqualTo: user.uid)
        .orderBy('dataHora', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Agendamento.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  /// Cancela um agendamento
  static Future<void> cancelarAgendamento(String agendamentoId) async {
    try {
      await _firestore
          .collection(_appointmentsCollection)
          .doc(agendamentoId)
          .update({'status': StatusAgendamento.cancelado.name});
    } catch (e) {
      print('Erro ao cancelar agendamento: $e');
      rethrow;
    }
  }

  /// Remove um agendamento do Firestore (exclusão permanente)
  static Future<void> removerAgendamento(String agendamentoId) async {
    try {
      await _firestore
          .collection(_appointmentsCollection)
          .doc(agendamentoId)
          .delete();
      BackupAutoConfig.houveAlteracao = true;
    } catch (e) {
      print('Erro ao remover agendamento: $e');
      rethrow;
    }
  }

  /// Obtém todos os agendamentos (para administradores)
  static Future<List<Agendamento>> obterTodosAgendamentos() async {
    try {
      final query = await _firestore
          .collection(_appointmentsCollection)
          .orderBy('dataHora', descending: true)
          .get();

      return query.docs
          .map((doc) => Agendamento.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Erro ao obter todos os agendamentos: $e');
      return [];
    }
  }

  /// Busca agendamentos existentes entre duas datas (inclusive start/end)
  static Future<List<Agendamento>> buscarAgendamentosEntre(
    DateTime inicio,
    DateTime fim,
  ) async {
    try {
      final query = await _firestore
          .collection(_appointmentsCollection)
          .where('dataHora', isGreaterThanOrEqualTo: inicio)
          .where('dataHora', isLessThanOrEqualTo: fim)
          .get();

      return query.docs
          .map((doc) => Agendamento.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Erro ao buscar agendamentos entre: $e');
      return [];
    }
  }

  /// Stream de agendamentos pendentes (para administradores)
  static Stream<List<Agendamento>> streamAgendamentosPendentes() {
    return _firestore
        .collection(_appointmentsCollection)
        .orderBy('dataHora', descending: true)
        .snapshots()
        .map((snapshot) {
          final list = <Agendamento>[];
          for (final doc in snapshot.docs) {
            final raw = doc.data();
            try {
              // Tolerância ao tipo de 'status' vindo do Firestore (pode ser String ou null)
              final dynamic statusField = raw['status'];
              final statusRaw = statusField is String
                  ? statusField
                  : (statusField?.toString() ?? '');

              if (statusRaw == 'pendente' || statusRaw == 'confirmado') {
                try {
                  final ag = Agendamento.fromJson({...raw, 'id': doc.id});
                  list.add(ag);
                } catch (e) {
                  // Logar e continuar com os demais documentos
                  print('Erro ao desserializar agendamento id=${doc.id}: $e');
                  print('Dados do documento: ${raw}');
                }
              }
            } catch (e) {
              print(
                'Erro ao processar documento de agendamento id=${doc.id}: $e',
              );
              print('raw data: ${raw}');
            }
          }
          return list;
        });
  }

  /// Altera o status de um agendamento (para administradores)
  static Future<void> alterarStatusAgendamento(
    String agendamentoId,
    StatusAgendamento novoStatus,
  ) async {
    try {
      await _firestore
          .collection(_appointmentsCollection)
          .doc(agendamentoId)
          .update({'status': novoStatus.name});
    } catch (e) {
      print('Erro ao alterar status do agendamento: $e');
      rethrow;
    }
  }

  /// Atualiza campos principais de um agendamento existente
  static Future<void> atualizarAgendamento(Agendamento ag) async {
    try {
      final data = {
        'dataHora': ag.dataHora,
        'servicoId': ag.servicoId,
        'observacoes': ag.observacoes,
        'valor': ag.valor,
        'clienteNome': ag.clienteNome,
        'servicoNome': ag.servicoNome,
      };
      await _firestore.collection(_appointmentsCollection).doc(ag.id).update(data);
    } catch (e) {
      print('Erro ao atualizar agendamento: $e');
      rethrow;
    }
  }

  // ==================== SERVIÇOS ====================

  /// Obtém todos os serviços
  static Future<List<Servico>> obterServicos() async {
    try {
      final query = await _firestore.collection(_servicesCollection).get();
      return query.docs
          .map((doc) => Servico.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Erro ao obter serviços: $e');
      return [];
    }
  }

  /// Stream de serviços (tempo real)
  static Stream<List<Servico>> streamServicos() {
    return _firestore
        .collection(_servicesCollection)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Servico.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  /// Adiciona um novo serviço
  static Future<void> adicionarServico(Servico servico) async {
    try {
      await _firestore.collection(_servicesCollection).add(servico.toJson());
      BackupAutoConfig.houveAlteracao = true;
    } catch (e) {
      print('Erro ao adicionar serviço: $e');
      rethrow;
    }
  }

  /// Atualiza um serviço existente
  static Future<void> atualizarServico(Servico servico) async {
    try {
      await _firestore
          .collection(_servicesCollection)
          .doc(servico.id)
          .update(servico.toJson());
      BackupAutoConfig.houveAlteracao = true;
    } catch (e) {
      print('Erro ao atualizar serviço: $e');
      rethrow;
    }
  }

  /// Remove um serviço
  static Future<void> removerServico(String servicoId) async {
    try {
      await _firestore.collection(_servicesCollection).doc(servicoId).delete();
      BackupAutoConfig.houveAlteracao = true;
    } catch (e) {
      print('Erro ao remover serviço: $e');
      rethrow;
    }
  }

  // ==================== PRODUTOS ====================

  /// Obtém todos os produtos
  static Future<List<Produto>> obterProdutos() async {
    try {
      final query = await _firestore
          .collection(_productsCollection)
          .where('disponivel', isEqualTo: true)
          .get();

      return query.docs
          .map((doc) => Produto.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Erro ao obter produtos: $e');
      return [];
    }
  }

  /// Stream de produtos (tempo real)
  static Stream<List<Produto>> streamProdutos() {
    return _firestore
        .collection(_productsCollection)
        .where('disponivel', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Produto.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  /// Busca produtos por categoria
  static Future<List<Produto>> buscarProdutosPorCategoria(
    String categoria,
  ) async {
    try {
      final query = await _firestore
          .collection(_productsCollection)
          .where('categoria', isEqualTo: categoria)
          .where('disponivel', isEqualTo: true)
          .get();

      return query.docs
          .map((doc) => Produto.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Erro ao buscar produtos por categoria: $e');
      return [];
    }
  }

  /// Adiciona um novo produto
  static Future<void> adicionarProduto(Produto produto) async {
    try {
      await _firestore.collection(_productsCollection).add(produto.toJson());
      BackupAutoConfig.houveAlteracao = true;
    } catch (e) {
      print('Erro ao adicionar produto: $e');
      rethrow;
    }
  }

  /// Atualiza um produto existente
  static Future<void> atualizarProduto(Produto produto) async {
    try {
      await _firestore
          .collection(_productsCollection)
          .doc(produto.id)
          .update(produto.toJson());
      BackupAutoConfig.houveAlteracao = true;
    } catch (e) {
      print('Erro ao atualizar produto: $e');
      rethrow;
    }
  }

  /// Remove um produto
  static Future<void> removerProduto(String produtoId) async {
    try {
      await _firestore.collection(_productsCollection).doc(produtoId).delete();
      BackupAutoConfig.houveAlteracao = true;
    } catch (e) {
      print('Erro ao remover produto: $e');
      rethrow;
    }
  }

  // ==================== HORÁRIOS ====================

  static const String _horariosDoc = 'horarios_funcionamento';

  /// Salva os horários de funcionamento (substitui todos)
  static Future<void> salvarHorariosFuncionamento(
    List<HorarioFuncionamento> horarios,
  ) async {
    try {
      final data = {for (var h in horarios) h.dia: h.toJson()};
      await _firestore.collection('config').doc(_horariosDoc).set({
        'dias': data,
      });
      BackupAutoConfig.houveAlteracao = true;
    } catch (e) {
      print('Erro ao salvar horários: $e');
      rethrow;
    }
  }

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
      final lista = dias.values
          .map(
            (v) => HorarioFuncionamento.fromJson(Map<String, dynamic>.from(v)),
          )
          .toList();
      // Ordena pela sequência correta da semana
      lista.sort((a, b) =>
          diasSemana.indexOf(a.dia).compareTo(diasSemana.indexOf(b.dia)));
      return lista;
    } catch (e) {
      print('Erro ao buscar horários: $e');
      rethrow;
    }
  }

  // ==================== UTILITÁRIOS ====================

  /// Normaliza diferentes representações de data/hora (Timestamp, Map, String, num, DateTime)
  /// para um objeto DateTime. Retorna null se não for possível.
  static DateTime? _toDateTime(dynamic raw) {
    if (raw == null) return null;
    try {
      // Firestore Timestamp
      if (raw is Timestamp) return raw.toDate();

      // Map com _seconds / seconds
      if (raw is Map && (raw['_seconds'] != null || raw['seconds'] != null)) {
        final seconds = raw['_seconds'] ?? raw['seconds'];
        final intSec = (seconds is int) ? seconds : int.tryParse(seconds.toString());
        if (intSec != null) return DateTime.fromMillisecondsSinceEpoch(intSec * 1000);
      }

      // Numeric epoch (seconds or milliseconds)
      if (raw is num) {
        // Heurística: se maior que 10^12 assume ms
        final n = raw.toInt();
        if (n > 1000000000000) return DateTime.fromMillisecondsSinceEpoch(n);
        return DateTime.fromMillisecondsSinceEpoch(n * 1000);
      }

      // String ISO
      if (raw is String) return DateTime.parse(raw);

      // DateTime
      if (raw is DateTime) return raw;

      return null;
    } catch (e) {
      return null;
    }
  }


  /// Inicializa dados mock no Firebase (apenas para desenvolvimento)
  static Future<void> inicializarDadosMock() async {
    try {
      // Verificar se já existem dados
      final servicosExistentes = await _firestore
          .collection(_servicesCollection)
          .limit(1)
          .get();
      if (servicosExistentes.docs.isNotEmpty) return; // Já tem dados

      // Adicionar serviços mock
      final servicos = [
        {
          'nome': 'Corte Masculino',
          'descricao': 'Corte clássico ou moderno',
          'preco': 50.0,
          'duracao': 30,
          'icone': 'content_cut',
        },
        {
          'nome': 'Barba Completa',
          'descricao': 'Aparar e modelar barba',
          'preco': 45.0,
          'duracao': 25,
          'icone': 'face',
        },
        {
          'nome': 'Acabamentos',
          'descricao': 'Acabamento de corte e barba',
          'preco': 35.0,
          'duracao': 20,
          'icone': 'cut',
        },
        {
          'nome': 'Corte + Barba',
          'descricao': 'Pacote completo',
          'preco': 90.0,
          'duracao': 50,
          'icone': 'star',
        },
      ];

      for (var servico in servicos) {
        await _firestore.collection(_servicesCollection).add(servico);
      }

      // Adicionar produtos mock
      final produtos = [
        {
          'nome': 'Shampoo Anti-Caspa',
          'descricao': 'Shampoo profissional para cabelos oleosos',
          'preco': 35.90,
          'categoria': 'Shampoo',
          'marca': 'Barber Pro',
          'foto': 'assets/produtos/shampoo1.jpg',
          'disponivel': true,
          'avaliacao': 4.7,
          'estoque': 15,
        },
        {
          'nome': 'Gel Fixador Forte',
          'descricao': 'Gel de fixação extra forte, longa duração',
          'preco': 28.50,
          'categoria': 'Gel',
          'marca': 'Style Master',
          'foto': 'assets/produtos/gel1.jpg',
          'disponivel': true,
          'avaliacao': 4.5,
          'estoque': 8,
        },
        {
          'nome': 'Creme para Barbear',
          'descricao': 'Creme hidratante para barbear',
          'preco': 22.90,
          'categoria': 'Creme',
          'marca': 'Smooth Shave',
          'foto': 'assets/produtos/creme1.jpg',
          'disponivel': true,
          'avaliacao': 4.8,
          'estoque': 12,
        },
      ];

      for (var produto in produtos) {
        await _firestore.collection(_productsCollection).add(produto);
      }

      // Criar usuário administrador padrão (apenas se não existir)
      try {
        await debugAdminLogin(); // Usar método de debug
      } catch (e) {
        print('Erro no debug do admin: $e');
      }

      print('Dados mock inicializados no Firebase!');
    } catch (e) {
      print('Erro ao inicializar dados mock: $e');
    }
  }

  /// Método para debug e recriação do admin
  static Future<void> debugAdminLogin() async {
    try {
      // Primeiro, tentar fazer login com admin
      final result = await _auth.signInWithEmailAndPassword(
        email: 'admin@barbearia.com',
        password: 'admin123',
      );

      if (result.user != null) {
        // Verificar se o documento existe no Firestore
        final doc = await _firestore
            .collection(_usersCollection)
            .doc(result.user!.uid)
            .get();

        print('Login admin bem-sucedido! UID: ${result.user!.uid}');

        if (doc.exists) {
          final userData = doc.data()!;
          print('Documento admin encontrado: $userData');
          print('Tipo do usuário: ${userData['tipo']}');
        } else {
          print('Documento admin NÃO encontrado no Firestore. Criando...');
          // Criar documento do admin no Firestore
          final usuario = Usuario(
            id: result.user!.uid,
            nome: 'Gerente da Barbearia',
            email: 'admin@barbearia.com',
            telefone: '(51) 98061-7630',
            tipo: TipoUsuario.admin,
            dataCadastro: DateTime.now(),
          );

          await _firestore
              .collection(_usersCollection)
              .doc(usuario.id)
              .set(usuario.toJson());

          print('Documento admin criado no Firestore!');
        }

        await logout(); // Fazer logout após o debug
      }
    } catch (e) {
      print('Erro no login admin ou admin não existe: $e');
      print('Criando usuário admin...');

      // Se não conseguir fazer login, criar o admin
      try {
        await criarUsuarioAdmin(
          email: 'admin@barbearia.com',
          senha: 'admin123',
          nome: 'Gerente da Barbearia',
          telefone: '(51) 98061-7630',
        );
        print('Admin criado com sucesso!');
      } catch (createError) {
        print('Erro ao criar admin: $createError');
      }
    }
  }

  /// Método para criar usuário administrador (desenvolvimento apenas)
  static Future<void> criarUsuarioAdmin({
    required String email,
    required String senha,
    String nome = 'Administrador',
    String telefone = '(51) 99999-9999',
  }) async {
    try {
      // Criar usuário no Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );

      // Criar documento de usuário admin no Firestore
      final usuario = Usuario(
        id: userCredential.user!.uid,
        nome: nome,
        email: email,
        telefone: telefone,
        tipo: TipoUsuario.admin, // Define como admin
        dataCadastro: DateTime.now(),
      );

      await _firestore
          .collection(_usersCollection)
          .doc(usuario.id)
          .set(usuario.toJson());

      print('Usuário administrador criado: $email');
    } catch (e) {
      print('Erro ao criar usuário admin: $e');
      rethrow;
    }
  }

  /// Inicializa o usuário admin se não existir
  static Future<void> inicializarAdminSeNecessario() async {
    try {
      // Tentar fazer login com credenciais admin
      final user = await _auth.signInWithEmailAndPassword(
        email: 'admin@barbearia.com',
        password: 'admin123',
      );

      // Se login bem-sucedido, verificar se documento existe no Firestore
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(user.user!.uid)
          .get();

      if (!doc.exists) {
        // Criar documento do admin no Firestore
        final usuario = Usuario(
          id: user.user!.uid,
          nome: 'Administrador',
          email: 'admin@barbearia.com',
          telefone: '(11) 9999-0000',
          tipo: TipoUsuario.admin,
          dataCadastro: DateTime.now(),
        );

        await _firestore
            .collection(_usersCollection)
            .doc(user.user!.uid)
            .set(usuario.toJson());

        print('Documento admin criado no Firestore');
      }

      await _auth.signOut(); // Deslogar após verificação
    } catch (e) {
      // Se não conseguir fazer login, criar o usuário admin
      try {
        await criarUsuarioAdmin(
          email: 'admin@barbearia.com',
          senha: 'admin123',
        );
        print('Usuário admin criado com sucesso');
      } catch (createError) {
        print('Erro ao criar admin: $createError');
      }
    }
  }
}
