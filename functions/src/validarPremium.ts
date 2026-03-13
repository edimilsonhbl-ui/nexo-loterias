import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const planoMap: Record<string, string> = {
  premium_mensal: "mensal",
  premium_anual: "anual",
  premium_vitalicio: "vitalicio",
};

export const validarPremium = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Usuário não autenticado."
      );
    }

    const { purchaseToken, productId, platform } = data as {
      purchaseToken?: string;
      productId?: string;
      platform?: string;
    };

    if (!purchaseToken || !productId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "purchaseToken e productId são obrigatórios."
      );
    }

    const plano = planoMap[productId];
    if (!plano) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        `Produto desconhecido: ${productId}`
      );
    }

    const userId = context.auth.uid;
    const agora = admin.firestore.Timestamp.now();

    // Calcula data de expiração para planos recorrentes
    let dataExpiracao: admin.firestore.Timestamp | null = null;
    if (plano === "mensal") {
      const d = new Date();
      d.setMonth(d.getMonth() + 1);
      dataExpiracao = admin.firestore.Timestamp.fromDate(d);
    } else if (plano === "anual") {
      const d = new Date();
      d.setFullYear(d.getFullYear() + 1);
      dataExpiracao = admin.firestore.Timestamp.fromDate(d);
    }

    // Salva status Premium no Firestore (campos premium/* são bloqueados pelo cliente)
    const dadosPremium: Record<string, unknown> = {
      premium: true,
      plano,
      premiumSince: agora,
      premiumPlatform: platform ?? "android",
      purchaseToken,
    };

    if (dataExpiracao) {
      dadosPremium.dataExpiracaoPremium = dataExpiracao;
    } else {
      // Vitalício: garante que não há data de expiração
      dadosPremium.dataExpiracaoPremium = admin.firestore.FieldValue.delete();
    }

    await admin.firestore()
      .collection("usuarios")
      .doc(userId)
      .set(dadosPremium, { merge: true });

    functions.logger.info(`Premium ativado: userId=${userId} plano=${plano}`);

    return { success: true, plano };
  });
