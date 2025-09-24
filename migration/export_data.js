const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Inicializar Firebase Admin (certifique-se de ter as credenciais corretas)
admin.initializeApp({
  projectId: 'corte-real-4d73b', // Substitua pelo ID do seu projeto atual
});

const db = admin.firestore();

async function exportCollection(collectionName) {
  console.log(`Exportando coleção: ${collectionName}`);
  
  try {
    const snapshot = await db.collection(collectionName).get();
    const data = {};
    
    snapshot.forEach(doc => {
      data[doc.id] = doc.data();
    });
    
    const fileName = `${collectionName}_backup.json`;
    const filePath = path.join(__dirname, 'backups', fileName);
    
    // Criar pasta backups se não existir
    const backupsDir = path.join(__dirname, 'backups');
    if (!fs.existsSync(backupsDir)) {
      fs.mkdirSync(backupsDir);
    }
    
    fs.writeFileSync(filePath, JSON.stringify(data, null, 2));
    console.log(`✅ Coleção ${collectionName} exportada para: ${filePath}`);
    console.log(`   Documentos encontrados: ${snapshot.size}`);
    
    return { collection: collectionName, documents: snapshot.size, file: fileName };
  } catch (error) {
    console.error(`❌ Erro ao exportar ${collectionName}:`, error);
    return { collection: collectionName, error: error.message };
  }
}

async function exportAllData() {
  console.log('🔄 Iniciando backup completo do Firestore...\n');
  
  const collections = [
    'usuarios',
    'produtos', 
    'servicos',
    'agendamentos',
    'barbeiros',
    'horarios',
    'promocoes',
    'vitrine',
    // Adicione outras coleções conforme necessário
  ];
  
  const results = [];
  
  for (const collection of collections) {
    const result = await exportCollection(collection);
    results.push(result);
  }
  
  // Salvar resumo do backup
  const summary = {
    timestamp: new Date().toISOString(),
    project: 'corte-real-4d73b',
    results: results
  };
  
  fs.writeFileSync(
    path.join(__dirname, 'backups', 'backup_summary.json'), 
    JSON.stringify(summary, null, 2)
  );
  
  console.log('\n📊 Resumo do Backup:');
  results.forEach(result => {
    if (result.error) {
      console.log(`❌ ${result.collection}: ${result.error}`);
    } else {
      console.log(`✅ ${result.collection}: ${result.documents} documentos`);
    }
  });
  
  console.log('\n🎉 Backup concluído! Arquivos salvos em ./backups/');
  process.exit(0);
}

// Executar backup
exportAllData().catch(console.error);