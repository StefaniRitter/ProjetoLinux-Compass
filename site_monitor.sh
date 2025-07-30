#!/bin/bash

# =======================================
# Script de Monitoramento
# =======================================

# URL do site a ser monitorado
SITE_URL="http://<IP_PUBLICO_DA_EC2>/"
TIMEOUT_SECONDS=10  # tempo máximo de espera da resposta

# Caminho para o log
LOG_DIR="/var/log/monitoramento"
LOG_FILE="${LOG_DIR}/site_monitor.log"

# Webhook do Discord para envio de alertas
WEBHOOK_DISCORD="https://discordapp.com/api/webhooks/<Substitua_por_um_link_válido>"

# Função responsável por enviar notificações pro Discord
enviar_alerta() {
    local mensagem="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Tentando enviar alerta: ${mensagem}" >> "${LOG_FILE}"

    if [[ -n "$WEBHOOK_DISCORD" ]]; then
        curl -H "Content-Type: application/json" \
             -X POST \
             -d "{\"content\": \"${mensagem}\"}" \
             "${WEBHOOK_DISCORD}" &>/dev/null

        if [ $? -eq 0 ]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Alerta enviado com sucesso para o Discord." >> "${LOG_FILE}"
        else
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Falha ao enviar alerta para o Discord." >> "${LOG_FILE}"
        fi
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Webhook do Discord não configurado. Alerta não enviado." >> "${LOG_FILE}"
    fi
}

# Função para verificar se o site está no ar
verificar_site() {
    HTTP_STATUS=$(curl -o /dev/null -s -w "%{http_code}" --connect-timeout "${TIMEOUT_SECONDS}" "${SITE_URL}")
    CURL_EXIT_CODE=$?
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    if [ "$CURL_EXIT_CODE" -eq 0 ]; then
        if [ "$HTTP_STATUS" -eq 200 ]; then
            MENSAGEM="Site online. Código HTTP: ${HTTP_STATUS}"
            echo "${TIMESTAMP} - OK - ${MENSAGEM}" | tee -a "${LOG_FILE}"
        else
            MENSAGEM="Site respondeu com status inesperado: ${HTTP_STATUS}"
            echo "${TIMESTAMP} - ERRO - ${MENSAGEM}" | tee -a "${LOG_FILE}"
            enviar_alerta "🚨 Atenção! ${MENSAGEM} em ${SITE_URL}"
        fi
    else
        MENSAGEM="Site fora do ar. Falha na conexão ou timeout (curl: ${CURL_EXIT_CODE})"
        echo "${TIMESTAMP} - ERRO - ${MENSAGEM}" | tee -a "${LOG_FILE}"
        enviar_alerta "🚨 Atenção! ${MENSAGEM} em ${SITE_URL}"
    fi
}

# Executa a verificação
verificar_site

