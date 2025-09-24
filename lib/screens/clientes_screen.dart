import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/firebase_service.dart';

class ClientesScreen extends StatelessWidget {
  const ClientesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clientes Cadastrados')),
      body: FutureBuilder<List<Usuario>>(
        future: FirebaseService.buscarClientes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final clientes = snapshot.data ?? [];
          if (clientes.isEmpty) {
            return const Center(child: Text('Nenhum cliente cadastrado.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: clientes.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final cliente = clientes[index];
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(cliente.nome),
                subtitle: Text(cliente.email),
                trailing: Text(cliente.telefone),
                onTap: () => _showClienteDetalhe(context, cliente),
              );
            },
          );
        },
      ),
    );
  }

  void _showClienteDetalhe(BuildContext context, Usuario cliente) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(cliente.nome),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('E-mail: ${cliente.email}'),
            const SizedBox(height: 8),
            Text('Telefone: ${cliente.telefone}'),
            const SizedBox(height: 8),
            Text(
              'Data de nascimento: '
              '${cliente.dataNascimento != null ? _formatarData(cliente.dataNascimento!) : 'Não informado'}',
            ),
            const SizedBox(height: 8),
            Text('ID: ${cliente.id}'),
            const SizedBox(height: 8),
            Text('Tipo: ${cliente.tipo.name}'),
            const SizedBox(height: 8),
            Text('Cadastro: ${cliente.dataCadastro.toString()}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }
}
