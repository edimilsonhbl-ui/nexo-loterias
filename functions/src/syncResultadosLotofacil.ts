/**
 * syncResultadosLotofacil
 *
 * Roda automaticamente via Cloud Scheduler (segunda a sábado às 21h,
 * horário de Brasília).
 *
 * Fluxo idêntico ao syncResultadosMegaSena, mas para a Lotofácil.
 *
 * TODO: implementar fetch à API real antes de ir para produção.
 */

import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) admin.initializeApp();

const db = admin.firestore();

export const syncResultadosLotofacil = functions.scheduler.onSchedule(
  {
    schedule: "every 60 minutes",
    timeZone: "America/Sao_Paulo",
  },
  async () => {
    functions.logger.info("[syncResultadosLotofacil] Iniciando sincronização...");

    // ------------------------------------------------------------------
    // STUB — substitua este bloco pela chamada real à API da Caixa.
    // ------------------------------------------------------------------
    const resultado = {
      numeroConcurso: 0,
      dataSorteio: new Date().toISOString(),
      dezenasSorteadas: [] as string[],
      premioEstimado: 0,
      acumulou: false,
    };

    const concursoId = `lotofacil_${resultado.numeroConcurso}`;
    const ref = db.collection("concursos").doc(concursoId);
    const snap = await ref.get();

    if (snap.exists) {
      functions.logger.info(
        `[syncResultadosLotofacil] Concurso ${resultado.numeroConcurso} já existe. Nada a fazer.`
      );
      return;
    }

    await ref.set({
      modalidadeId: "lotofacil",
      numeroConcurso: resultado.numeroConcurso,
      dataSorteio: resultado.dataSorteio,
      dezenasSorteadas: resultado.dezenasSorteadas,
      premioEstimado: resultado.premioEstimado,
      acumulou: resultado.acumulou,
      criadoEm: admin.firestore.FieldValue.serverTimestamp(),
    });

    functions.logger.info(
      `[syncResultadosLotofacil] Concurso ${resultado.numeroConcurso} salvo com sucesso.`
    );
  }
);
