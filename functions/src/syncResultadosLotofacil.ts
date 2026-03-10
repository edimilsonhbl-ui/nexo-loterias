/**
 * syncResultadosLotofacil
 *
 * Roda via Cloud Scheduler: segunda a sábado às 21h (horário de Brasília).
 * Lógica idêntica ao syncResultadosMegaSena — apenas o endpoint muda.
 */

import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";
import { buscarUltimoResultado } from "./caixaApi";

if (admin.apps.length === 0) admin.initializeApp();

const db = admin.firestore();

export const syncResultadosLotofacil = functions.scheduler.onSchedule(
  {
    schedule: "0 21 * * 1-6", // segunda (1) a sábado (6) às 21h
    timeZone: "America/Sao_Paulo",
    retryCount: 2,
    timeoutSeconds: 60,
  },
  async () => {
    functions.logger.info("[syncResultadosLotofacil] Iniciando sincronização...");

    let resultado;
    try {
      resultado = await buscarUltimoResultado("lotofacil");
    } catch (err) {
      functions.logger.error("[syncResultadosLotofacil] Erro ao consultar API da Caixa:", err);
      return;
    }

    if (!resultado.numeroConcurso) {
      functions.logger.error("[syncResultadosLotofacil] API retornou concurso inválido (numero=0).");
      return;
    }

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
      `[syncResultadosLotofacil] Concurso ${resultado.numeroConcurso} salvo — dezenas: ${resultado.dezenasSorteadas.join(", ")}`
    );
  }
);
