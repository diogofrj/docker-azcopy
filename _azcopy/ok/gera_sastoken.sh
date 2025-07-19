#!/bin/bash

# Script para geração manual de SAS tokens com privilégios mínimos
# Autor: DevOps Team
# Data: $(date +%Y-%m-%d)

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções auxiliares
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Função para exibir ajuda
show_help() {
    cat << EOF
Uso: $0 [OPÇÕES]

Gera SAS tokens para Storage Accounts com privilégios mínimos.

OPÇÕES:
    -s, --storage-account    Nome do Storage Account
    -t, --type              Tipo de storage (fileshare|blob)
    -n, --name              Nome do container/fileshare
    -p, --permissions       Permissões (opcional, usa padrões mínimos)
    -e, --expiry            Tempo de expiração (opcional, padrão: 1h)
    -h, --help              Exibe esta ajuda

EXEMPLOS:
    # Gerar SAS para FileShare (read + list)
    $0 -s saorigemhr -t fileshare -n file-share-origem

    # Gerar SAS para Blob Container (read + write + create + list)
    $0 -s sadestinohr -t blob -n blob-recebidos

    # Gerar SAS com tempo customizado (2 horas)
    $0 -s sadestinohr -t blob -n blob-recebidos -e "24 hours"

    # Gerar SAS com permissões customizadas
    $0 -s sadestinohr -t blob -n blob-recebidos -p "r"

PERMISSÕES DISPONÍVEIS:
    FileShare: r (read), w (write), d (delete), l (list)
    Blob: r (read), w (write), d (delete), l (list), c (create)

EOF
}

# Verifica se o Azure CLI está instalado e logado
check_azure_cli() {
    if ! command -v az &> /dev/null; then
        log_error "Azure CLI não encontrado. Instale o Azure CLI primeiro."
        exit 1
    fi
    
    if ! az account show &> /dev/null; then
        log_error "Você não está logado no Azure. Execute 'az login' primeiro."
        exit 1
    fi
    
    local subscription_id=$(az account show --query id -o tsv)
    log_info "Usando subscription: $subscription_id"
}

# Gera SAS token para FileShare
generate_fileshare_sas() {
    local storage_account=$1
    local fileshare_name=$2
    local permissions=${3:-"rl"}  # Padrão: read + list
    local expiry_time=${4:-"1 hour"}
    
    local expiry_date=$(date -u -d "+$expiry_time" '+%Y-%m-%dT%H:%M:%SZ')
    
    log_info "Gerando SAS token para FileShare..."
    log_info "Storage Account: $storage_account"
    log_info "FileShare: $fileshare_name"
    log_info "Permissões: $permissions"
    log_info "Expiração: $expiry_date"
    
    local sas_token=$(az storage share generate-sas \
        --account-name "$storage_account" \
        --name "$fileshare_name" \
        --permissions "$permissions" \
        --expiry "$expiry_date" \
        --https-only \
        --output tsv)
    
    if [ -z "$sas_token" ]; then
        log_error "Falha ao gerar SAS token para FileShare"
        exit 1
    fi
    
    log_success "SAS token gerado com sucesso!"
    echo
    echo "=== SAS TOKEN ==="
    echo "$sas_token"
    echo
    echo "=== URL COMPLETA ==="
    echo "https://${storage_account}.file.core.windows.net/${fileshare_name}?${sas_token}"
    echo
    echo "=== SAS TOKEN em Base64 ==="
    echo -n "$sas_token" | base64 -w 0
    echo
}

# Gera SAS token para Blob Container
generate_blob_sas() {
    local storage_account=$1
    local container_name=$2
    local permissions=${3:-"rwcl"}  # Padrão: read + write + create + list
    local expiry_time=${4:-"1 hour"}
    
    local expiry_date=$(date -u -d "+$expiry_time" '+%Y-%m-%dT%H:%M:%SZ')
    
    log_info "Gerando SAS token para Blob Container..."
    log_info "Storage Account: $storage_account"
    log_info "Container: $container_name"
    log_info "Permissões: $permissions"
    log_info "Expiração: $expiry_date"
    
    local sas_token=$(az storage container generate-sas \
        --account-name "$storage_account" \
        --name "$container_name" \
        --permissions "$permissions" \
        --expiry "$expiry_date" \
        --https-only \
        --output tsv)
    
    if [ -z "$sas_token" ]; then
        log_error "Falha ao gerar SAS token para Blob Container"
        exit 1
    fi
    
    log_success "SAS token gerado com sucesso!"
    echo
    echo "=== SAS TOKEN ==="
    echo "$sas_token"
    echo
    echo "=== URL COMPLETA ==="
    echo "https://${storage_account}.blob.core.windows.net/${container_name}?${sas_token}"
    echo
    echo "=== SAS TOKEN em Base64 ==="
    echo -n "$sas_token" | base64 -w 0
    echo
}

# Função principal
main() {
    local storage_account=""
    local type=""
    local name=""
    local permissions=""
    local expiry_time="1 hour"
    
    # Parse dos argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            -s|--storage-account)
                storage_account="$2"
                shift 2
                ;;
            -t|--type)
                type="$2"
                shift 2
                ;;
            -n|--name)
                name="$2"
                shift 2
                ;;
            -p|--permissions)
                permissions="$2"
                shift 2
                ;;
            -e|--expiry)
                expiry_time="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Opção desconhecida: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Validações
    if [ -z "$storage_account" ]; then
        log_error "Storage Account é obrigatório (-s)"
        show_help
        exit 1
    fi
    
    if [ -z "$type" ]; then
        log_error "Tipo é obrigatório (-t)"
        show_help
        exit 1
    fi
    
    if [ -z "$name" ]; then
        log_error "Nome do container/fileshare é obrigatório (-n)"
        show_help
        exit 1
    fi
    
    if [[ "$type" != "fileshare" && "$type" != "blob" ]]; then
        log_error "Tipo deve ser 'fileshare' ou 'blob'"
        exit 1
    fi
    
    # Verifica Azure CLI
    check_azure_cli
    
    # Gera SAS token baseado no tipo
    if [ "$type" == "fileshare" ]; then
        generate_fileshare_sas "$storage_account" "$name" "$permissions" "$expiry_time"
    else
        generate_blob_sas "$storage_account" "$name" "$permissions" "$expiry_time"
    fi
}

# Executa função principal se script for executado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi