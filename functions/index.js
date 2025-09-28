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
      batch.update(userRef, {
        presenteAniversario: {
          ...oferta,
          enviadoEm: admin.firestore.FieldValue.serverTimestamp(),
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
