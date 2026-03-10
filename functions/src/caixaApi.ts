/**
 * caixaApi.ts
 *
 * Utilitário compartilhado para consultar a API pública da Caixa Econômica
 * Federal. Implementa retry com backoff exponencial para lidar com
 * instabilidades ocasionais do serviço.
 */

import fetch from "node-fetch";
import * as functions from "firebase-functions/v2";

const BASE_URL = "https://servicebus2.caixa.gov.br/portaldeloterias/api";
const MAX_TENTATIVAS = 3;
const TIMEOUT_MS = 10_000;

export interface ResultadoCaixa {
  numeroConcurso: number;
  dataSorteio: string;
  dezenasSorteadas: string[];
  premioEstimado: number;
  acumulou: boolean;
}

/**
 * Busca o último resultado de uma modalidade na API da Caixa.
 * @param modalidade Identificador interno da API (ex.: "megasena", "lotofacil")
 */
export async function buscarUltimoResultado(
  modalidade: string
): Promise<ResultadoCaixa> {
  const url = `${BASE_URL}/${modalidade}`;
  let ultimoErro: Error | null = null;

  for (let tentativa = 1; tentativa <= MAX_TENTATIVAS; tentativa++) {
    try {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), TIMEOUT_MS);

      const response = await fetch(url, {
        signal: controller.signal as Parameters<typeof fetch>[1] extends { signal?: infer S } ? S : never,
        headers: { "Accept": "application/json" },
      });

      clearTimeout(timeout);

      if (!response.ok) {
        throw new Error(`HTTP ${response.status} ao consultar ${url}`);
      }

      const data = await response.json() as Record<string, unknown>;

      return mapearResultado(data);
    } catch (err) {
      ultimoErro = err as Error;
      functions.logger.warn(
        `[caixaApi] Tentativa ${tentativa}/${MAX_TENTATIVAS} falhou para ${modalidade}: ${ultimoErro.message}`
      );
      if (tentativa < MAX_TENTATIVAS) {
        await sleep(1_000 * tentativa); // backoff: 1s, 2s
      }
    }
  }

  throw new Error(
    `[caixaApi] Falha após ${MAX_TENTATIVAS} tentativas para ${modalidade}: ${ultimoErro?.message}`
  );
}

function mapearResultado(data: Record<string, unknown>): ResultadoCaixa {
  const dezenas = (data["listaDezenas"] as string[] | undefined) ?? [];

  return {
    numeroConcurso: Number(data["numero"] ?? 0),
    dataSorteio: String(data["dataApuracao"] ?? new Date().toISOString()),
    dezenasSorteadas: dezenas.map((d) => d.trim()),
    premioEstimado: Number(data["valorEstimadoProximoConcurso"] ?? 0),
    acumulou: Boolean(data["acumulado"] ?? false),
  };
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
