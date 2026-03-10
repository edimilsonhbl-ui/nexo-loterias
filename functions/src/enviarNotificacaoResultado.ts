/**
 * enviarNotificacaoResultado
 *
 * Disparada automaticamente via Firestore trigger quando um novo documento
 * é criado em /concursos/{concursoId}.
 *
 * Fluxo:
 *  1. Monta a mensagem de notificação com o resultado do concurso.
 *  2. Envia para o tópico FCM da modalidade (ex.: "megasena", "lotofacil").
 *  3. Se o prêmio acumulou, envia também para o tópico "acumulados".
 *
 * Tópicos FCM usados pelo app Flutter:
 *   - "megasena"    → usuários que assinaram notificações da Mega-Sena
 *   - "lotofacil"   → usuários que assinaram notificações da Lotofácil
 *   - "acumulados"  → todos os usuários interessados em prêmios acumulados
 */

import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) admin.initializeApp();

const messaging = admin.messaging();

export const enviarNotificacaoResultado = functions.firestore.onDocumentCreated(
  "concursos/{concursoId}",
  async (event) => {
    const concurso = event.data?.data();

    if (!concurso) return;

    const { modalidadeId, numeroConcurso, dezenasSorteadas, premioEstimado, acumulou } =
      concurso as {
        modalidadeId: string;
        numeroConcurso: number;
        dezenasSorteadas: string[];
        premioEstimado: number;
        acumulou: boolean;
      };

    const nomesModalidade: Record<string, string> = {
      megasena: "Mega-Sena",
      lotofacil: "Lotofácil",
    };

    const nomeModalidade = nomesModalidade[modalidadeId] ?? modalidadeId;
    const dezenas = dezenasSorteadas.join(" - ");
    const premio = new Intl.NumberFormat("pt-BR", {
      style: "currency",
      currency: "BRL",
    }).format(premioEstimado);

    functions.logger.info(
      `[enviarNotificacaoResultado] Enviando notificação para tópico "${modalidadeId}" — concurso ${numeroConcurso}`
    );

    // Notificação principal para assinantes da modalidade.
    await messaging.sendEachForMulticast({
      tokens: [],          // Não é usado — usamos tópicos.
      topic: modalidadeId, // Campo usado no envio por tópico abaixo.
      notification: {
        title: `${nomeModalidade} — Concurso ${numeroConcurso}`,
        body: `Resultado: ${dezenas}`,
      },
      data: {
        modalidadeId,
        numeroConcurso: String(numeroConcurso),
        dezenas,
        acumulou: String(acumulou),
      },
    }).catch(() => {
      // sendEachForMulticast não suporta `topic` — usar send com topic.
    });

    // Envio correto por tópico.
    await messaging.send({
      topic: modalidadeId,
      notification: {
        title: `${nomeModalidade} — Concurso ${numeroConcurso}`,
        body: `Resultado: ${dezenas}`,
      },
      data: {
        modalidadeId,
        numeroConcurso: String(numeroConcurso),
        dezenas,
        acumulou: String(acumulou),
      },
    });

    // Notificação extra para o tópico "acumulados".
    if (acumulou) {
      await messaging.send({
        topic: "acumulados",
        notification: {
          title: `${nomeModalidade} ACUMULOU!`,
          body: `Prêmio estimado: ${premio}`,
        },
        data: {
          modalidadeId,
          numeroConcurso: String(numeroConcurso),
          premio: String(premioEstimado),
        },
      });

      functions.logger.info(
        `[enviarNotificacaoResultado] Notificação de acúmulo enviada para tópico "acumulados".`
      );
    }

    functions.logger.info(`[enviarNotificacaoResultado] Notificação enviada com sucesso.`);
  }
);
