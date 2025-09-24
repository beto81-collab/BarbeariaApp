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

  // ==================== ATUALIZAÇÕES ====================
  static const String _configCollection = 'config';
  static const String _appVersionDoc = 'app_version';

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
      final doc = await _firestore
          .collection(_promocoesCollection)
          .add(promocao.toJson());
      BackupAutoConfig.houveAlteracao = true;
      return doc.id;
    } catch (e) {
      print('Erro ao criar promoção: $e');
      rethrow;
    }
  }

  static Future<void> atualizarPromocao(Promocao promocao) async {
    try {
      await _firestore
          .collection(_promocoesCollection)
          .doc(promocao.id)
          .update(promocao.toJson());
      BackupAutoConfig.houveAlteracao = true;
    } catch (e) {
      print('Erro ao atualizar promoção: $e');
      rethrow;
    }
  }

  static Future<void> removerPromocao(String id) async {
    try {
      await _firestore.collection(_promocoesCollection).doc(id).delete();
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

      return querySnapshot.docs
          .map((doc) => Usuario.fromJson({...doc.data(), 'id': doc.id}))
          .where(
            (usuario) =>
                usuario.dataNascimento != null &&
                usuario.dataNascimento!.day == data.day &&
                usuario.dataNascimento!.month == data.month,
          )
          .toList();
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

        // Se não tem presente ou já foi resgatado ou não foi enviado hoje, conta
        if (presente == null) {
          count++; // Não recebeu presente ainda
        } else {
          final enviadoEm = presente['enviadoEm'] as Timestamp?;
          if (enviadoEm == null) {
            count++; // Não foi enviado ainda
          } else {
            final dataEnvio = enviadoEm.toDate();
            final hoje = DateTime.now();

            // Se não foi enviado hoje, conta como pendente
            if (dataEnvio.day != hoje.day ||
                dataEnvio.month != hoje.month ||
                dataEnvio.year != hoje.year) {
              count++;
            }
            // Se foi enviado hoje, não conta (já foi processado)
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

                // Se não tem presente, conta
                if (presente == null) {
                  count++;
                } else {
                  final enviadoEm = presente['enviadoEm'] as Timestamp?;
                  if (enviadoEm == null) {
                    count++; // Não foi enviado ainda
                  } else {
                    final dataEnvio = enviadoEm.toDate();

                    // Se não foi enviado hoje, conta como pendente
                    if (dataEnvio.day != hoje.day ||
                        dataEnvio.month != hoje.month ||
                        dataEnvio.year != hoje.year) {
                      count++;
                    }
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

  // ==================== UTILITÁRIOS ====================

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
