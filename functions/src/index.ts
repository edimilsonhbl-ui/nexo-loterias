/**
 * NEXO LOTERIAS — Firebase Cloud Functions
 *
 * Entrypoint: exporta todas as funções do projeto.
 */

export { syncResultadosMegaSena } from "./syncResultadosMegaSena";
export { syncResultadosLotofacil } from "./syncResultadosLotofacil";
export { conferirApostasPendentes } from "./conferirApostasPendentes";
export { gerarEstatisticas } from "./gerarEstatisticas";
export { enviarNotificacaoResultado } from "./enviarNotificacaoResultado";
