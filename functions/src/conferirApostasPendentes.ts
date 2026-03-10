/**
 * conferirApostasPendentes
 *
 * Disparada automaticamente via Firestore trigger quando um novo documento
 * é criado em /concursos/{concursoId}.
 *
 * Fluxo:
 *  1. Lê as dezenasSorteadas do concurso recém-criado.
 *  2. Consulta apostas_usuario onde:
 *     - modalidadeId == concurso.modalidadeId
 *     - statusConferencia == "pendente"
 *  3. Para cada aposta, calcula a quantidade de acertos.
 *  4. Atualiza o documento da aposta com { acertos, statusConferencia: "conferida" }.
 */

import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) admin.initializeApp();

const db = admin.firestore();

export const conferirApostasPendentes = functions.firestore.onDocumentCreated(
  "concursos/{concursoId}",
  async (event) => {
    const concursoId = event.params.concursoId;
    const concurso = event.data?.data();

    if (!concurso) {
      functions.logger.warn(`[conferirApostasPendentes] Documento vazio: ${concursoId}`);
      return;
    }

    const { modalidadeId, dezenasSorteadas } = concurso as {
      modalidadeId: string;
      dezenasSorteadas: string[];
    };

    functions.logger.info(
      `[conferirApostasPendentes] Conferindo apostas para ${modalidadeId} — concurso ${concursoId}`
    );

    const apostasSnap = await db
      .collection("apostas_usuario")
      .where("modalidadeId", "==", modalidadeId)
      .where("statusConferencia", "==", "pendente")
      .get();

    if (apostasSnap.empty) {
      functions.logger.info("[conferirApostasPendentes] Nenhuma aposta pendente encontrada.");
      return;
    }

    const batch = db.batch();

    apostasSnap.forEach((doc) => {
      const aposta = doc.data();
      const numerosEscolhidos: string[] = aposta.numerosEscolhidos ?? [];

      const acertos = numerosEscolhidos.filter((n) =>
        dezenasSorteadas.includes(n)
      ).length;

      batch.update(doc.ref, {
        acertos,
        concursoConferido: concursoId,
        statusConferencia: "conferida",
        conferidoEm: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    await batch.commit();

    functions.logger.info(
      `[conferirApostasPendentes] ${apostasSnap.size} apostas conferidas para ${concursoId}.`
    );
  }
);
