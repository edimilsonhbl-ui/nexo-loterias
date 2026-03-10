/**
 * syncResultadosMegaSena
 *
 * Roda via Cloud Scheduler: quarta e sábado às 21h (horário de Brasília).
 * Consulta a API pública da Caixa, verifica se o concurso já existe no
 * Firestore e salva se for novo.
 *
 * Os triggers onDocumentCreated de conferirApostasPendentes,
 * gerarEstatisticas e enviarNotificacaoResultado disparam automaticamente
 * após o set.
 */

import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";
import { buscarUltimoResultado } from "./caixaApi";

if (admin.apps.length === 0) admin.initializeApp();

const db = admin.firestore();

export const syncResultadosMegaSena = functions.scheduler.onSchedule(
  {
    schedule: "0 21 * * 3,6", // quarta (3) e sábado (6) às 21h
    timeZone: "America/Sao_Paulo",
    retryCount: 2,
    timeoutSeconds: 60,
  },
  async () => {
    functions.logger.info("[syncResultadosMegaSena] Iniciando sincronização...");

    let resultado;
    try {
      resultado = await buscarUltimoResultado("megasena");
    } catch (err) {
      functions.logger.error("[syncResultadosMegaSena] Erro ao consultar API da Caixa:", err);
      return;
    }

    if (!resultado.numeroConcurso) {
      functions.logger.error("[syncResultadosMegaSena] API retornou concurso inválido (numero=0).");
      return;
    }

    const concursoId = `megasena_${resultado.numeroConcurso}`;
    const ref = db.collection("concursos").doc(concursoId);
    const snap = await ref.get();

    if (snap.exists) {
      functions.logger.info(
        `[syncResultadosMegaSena] Concurso ${resultado.numeroConcurso} já existe. Nada a fazer.`
      );
      return;
    }

    await ref.set({
      modalidadeId: "megasena",
      numeroConcurso: resultado.numeroConcurso,
      dataSorteio: resultado.dataSorteio,
      dezenasSorteadas: resultado.dezenasSorteadas,
      premioEstimado: resultado.premioEstimado,
      acumulou: resultado.acumulou,
      criadoEm: admin.firestore.FieldValue.serverTimestamp(),
    });

    functions.logger.info(
      `[syncResultadosMegaSena] Concurso ${resultado.numeroConcurso} salvo — dezenas: ${resultado.dezenasSorteadas.join(", ")}`
    );
  }
);
