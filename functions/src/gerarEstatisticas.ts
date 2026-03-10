/**
 * gerarEstatisticas
 *
 * Disparada automaticamente via Firestore trigger quando um novo documento
 * é criado em /concursos/{concursoId}.
 *
 * Fluxo:
 *  1. Busca todos os concursos da mesma modalidade.
 *  2. Calcula:
 *     - frequência de cada número (maisSorteados / menosSorteados)
 *     - números atrasados (não saíram nos últimos N concursos)
 *     - proporção pares × ímpares
 *     - soma média das dezenas
 *  3. Grava / atualiza o documento em /estatisticas/{modalidadeId}.
 */

import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";

if (admin.apps.length === 0) admin.initializeApp();

const db = admin.firestore();

/** Número de concursos recentes usado para calcular "atrasados". */
const JANELA_ATRASO = 10;

export const gerarEstatisticas = functions.firestore.onDocumentCreated(
  "concursos/{concursoId}",
  async (event) => {
    const concurso = event.data?.data();

    if (!concurso) return;

    const modalidadeId: string = concurso.modalidadeId;

    functions.logger.info(`[gerarEstatisticas] Gerando estatísticas para ${modalidadeId}...`);

    // 1. Busca todos os concursos da modalidade, ordenados por número.
    const snap = await db
      .collection("concursos")
      .where("modalidadeId", "==", modalidadeId)
      .orderBy("numeroConcurso", "desc")
      .get();

    if (snap.empty) return;

    const todosOsConcursos = snap.docs.map((d) => d.data());

    // 2. Frequência acumulada de cada dezena.
    const frequencia: Record<string, number> = {};

    for (const c of todosOsConcursos) {
      const dezenas: string[] = c.dezenasSorteadas ?? [];
      for (const d of dezenas) {
        frequencia[d] = (frequencia[d] ?? 0) + 1;
      }
    }

    // 3. Ordenações derivadas.
    const dezenasOrdenadas = Object.entries(frequencia).sort((a, b) => b[1] - a[1]);
    const maisSorteados = dezenasOrdenadas.slice(0, 10).map(([d]) => d);
    const menosSorteados = dezenasOrdenadas.slice(-10).map(([d]) => d);

    // 4. Números atrasados: não apareceram nos últimos JANELA_ATRASO concursos.
    const recentes = todosOsConcursos.slice(0, JANELA_ATRASO);
    const dezenasRecentes = new Set(
      recentes.flatMap((c) => (c.dezenasSorteadas ?? []) as string[])
    );
    const atrasados = Object.keys(frequencia).filter((d) => !dezenasRecentes.has(d));

    // 5. Pares × ímpares e soma média (sobre todos os concursos).
    let totalPares = 0;
    let totalImpares = 0;
    let somaTotal = 0;
    let totalDezenas = 0;

    for (const c of todosOsConcursos) {
      const dezenas: string[] = c.dezenasSorteadas ?? [];
      for (const d of dezenas) {
        const n = parseInt(d, 10);
        if (isNaN(n)) continue;
        totalDezenas++;
        somaTotal += n;
        n % 2 === 0 ? totalPares++ : totalImpares++;
      }
    }

    const somaMedia = totalDezenas > 0 ? somaTotal / todosOsConcursos.length : 0;

    // 6. Persiste o resultado.
    await db.collection("estatisticas").doc(modalidadeId).set(
      {
        modalidadeId,
        maisSorteados,
        menosSorteados,
        atrasados,
        paresImpares: { pares: totalPares, impares: totalImpares },
        somaMedia: Math.round(somaMedia),
        totalConcursos: todosOsConcursos.length,
        atualizadoEm: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    functions.logger.info(
      `[gerarEstatisticas] Estatísticas de ${modalidadeId} salvas (${todosOsConcursos.length} concursos).`
    );
  }
);
