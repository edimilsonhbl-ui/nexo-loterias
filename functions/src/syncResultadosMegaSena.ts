/**
 * syncResultadosMegaSena
 *
 * Roda automaticamente via Cloud Scheduler (a cada 30 min nos dias de sorteio:
 * quarta e sábado).
 *
 * Fluxo:
 *  1. Consulta a API pública da Caixa (resultados.caixa.gov.br) para obter o
 *     último concurso da Mega-Sena.
 *  2. Verifica se o concurso já existe em /concursos/{id}.
 *  3. Se for novo, salva o documento e dispara conferirApostasPendentes e
 *     gerarEstatisticas via Pub/Sub.
 *
 * TODO: implementar fetch à API real antes de ir para produção.
 */

import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) admin.initializeApp();

const db = admin.firestore();

export const syncResultadosMegaSena = functions.scheduler.onSchedule(
  {
    schedule: "every 30 minutes",
    timeZone: "America/Sao_Paulo",
  },
  async () => {
    functions.logger.info("[syncResultadosMegaSena] Iniciando sincronização...");

    // ------------------------------------------------------------------
    // STUB — substitua este bloco pela chamada real à API da Caixa.
    // Estrutura esperada do objeto `resultado`:
    // {
    //   numeroConcurso: number,
    //   dataSorteio: string (ISO 8601),
    //   dezenasSorteadas: string[],
    //   premioEstimado: number,
    //   acumulou: boolean,
    // }
    // ------------------------------------------------------------------
    const resultado = {
      numeroConcurso: 0,
      dataSorteio: new Date().toISOString(),
      dezenasSorteadas: [] as string[],
      premioEstimado: 0,
      acumulou: false,
    };

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
      `[syncResultadosMegaSena] Concurso ${resultado.numeroConcurso} salvo com sucesso.`
    );
  }
);
