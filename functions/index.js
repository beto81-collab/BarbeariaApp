const {onSchedule} = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
admin.initializeApp();

// Função agendada para rodar diariamente às 00:10 (horário de São Paulo)
exports.enviarPresenteAniversario = onSchedule({
  schedule: "10 3 * * *", // 03:10 UTC = 00:10 BRT
  timeZone: "America/Sao_Paulo",
  memory: "256MiB",
}, async (event) => {
  const db = admin.firestore();
  const hoje = new Date();
  hoje.setHours(0, 0, 0, 0);
  const dia = hoje.getDate().toString().padStart(2, "0");
  const mes = (hoje.getMonth() + 1).toString().padStart(2, "0");

  console.log(`Verificando aniversariantes do dia ${dia}/${mes}...`);

  // Busca todos os usuários aniversariantes do dia
  const usuariosSnap = await db.collection("usuarios")
      .where("dataNascimentoDia", "==", dia)
      .where("dataNascimentoMes", "==", mes)
      .get();

  console.log(`Encontrados ${usuariosSnap.size} aniversariantes.`);

  // Busca a oferta de aniversário ativa
  const ofertaSnap = await db.collection("ofertas_aniversario")
      .where("ativa", "==", true)
      .limit(1)
      .get();

  if (ofertaSnap.empty) {
    console.log("Nenhuma oferta de aniversário ativa encontrada.");
    return null;
  }

  const oferta = ofertaSnap.docs[0].data();
  console.log("Oferta ativa encontrada:", oferta);

  // Para cada aniversariante, atualiza o campo presenteAniversario
  const batch = db.batch();
  let contadorEnviados = 0;

  usuariosSnap.forEach((doc) => {
    const userRef = doc.ref;
    const userData = doc.data();
    // Só envia se não tiver presente ou se já foi resgatado
    if (!userData.presenteAniversario ||
        userData.presenteAniversario.resgatado) {
      // calcular data de expiração em 7 dias
      const expira = new Date();
      expira.setDate(expira.getDate() + 7);
      batch.update(userRef, {
        presenteAniversario: {
          ...oferta,
          enviadoEm: admin.firestore.FieldValue.serverTimestamp(),
          expiraEm: admin.firestore.Timestamp.fromDate(expira),
          resgatado: false,
        },
      });
      contadorEnviados++;
    }
  });

  await batch.commit();
  console.log(`Presente de aniversário enviado para ` +
      `${contadorEnviados} usuários.`);
  return null;
});

// Limpar presentes expirados diariamente às 04:00 BRT
exports.limparPresentesExpirados = onSchedule({
  schedule: "0 7 * * *",
  timeZone: "America/Sao_Paulo",
  memory: "128MiB",
}, async (event) => {
  const db = admin.firestore();
  const agora = admin.firestore.Timestamp.now();

  console.log("Procurando presentes expirados...");

  // Buscar usuários cujo presente existe e tem expiraEm <= agora
  const usuariosSnap = await db
      .collection("usuarios")
      .where("presenteAniversario.expiraEm", "<=", agora)
      .get();

  if (usuariosSnap.empty) {
    console.log("Nenhum presente expirado encontrado.");
    return null;
  }

  const batch = db.batch();
  let removidos = 0;

  usuariosSnap.forEach((doc) => {
    const data = doc.data();
    const presente = data.presenteAniversario || null;
    // Só remover se não resgatado e não marcado como entregue
    if (presente && !presente.resgatado && !presente.entregue) {
      const ref = doc.ref;
      batch.update(ref, {
        presenteAniversario: admin.firestore.FieldValue.delete(),
      });
      removidos++;
    }
  });

  if (removidos > 0) {
    await batch.commit();
    console.log(`Removidos ${removidos} presentes expirados.`);
  } else {
    console.log("Nenhum presente elegível para remoção encontrado.");
  }

  return null;
});
