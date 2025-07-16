#!/bin/bash

# Script de teste para validar sincronização AzCopy
# Autor: DevOps Team
# Data: $(date +%Y-%m-%d)

set -euo pipefail

# Configurações
SA_ORIGEM="stbanprdbrstest"
SA_DESTINO="stbanprdbrs"
FILESHARE_NAME="client1"
BLOB_CONTAINER="client1"
TEST_FILE="test-sync-$(date +%Y%m%d_%H%M%S).txt"

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

Script de teste para validar a sincronização entre FileShare e Blob Storage.

OPÇÕES:
    --dry-run               Executa teste sem fazer alterações reais
    --cleanup               Remove arquivos de teste após validação
    --verbose               Saída detalhada
    -h, --help              Exibe esta ajuda

EXEMPLOS:
    # Teste completo com cleanup
    $0 --cleanup

    # Teste sem alterações reais
    $0 --dry-run

    # Teste com saída detalhada
    $0 --verbose --cleanup

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

# Verifica se os Storage Accounts existem
check_storage_accounts() {
    log_info "Verificando Storage Accounts..."
    
    if ! az storage account show --name "$SA_ORIGEM" &> /dev/null; then
        log_error "Storage Account de origem '$SA_ORIGEM' não encontrado"
        exit 1
    fi
    log_success "Storage Account de origem '$SA_ORIGEM' encontrado"
    
    if ! az storage account show --name "$SA_DESTINO" &> /dev/null; then
        log_error "Storage Account de destino '$SA_DESTINO' não encontrado"
        exit 1
    fi
    log_success "Storage Account de destino '$SA_DESTINO' encontrado"
}

# Verifica se o FileShare existe
check_fileshare() {
    log_info "Verificando FileShare '$FILESHARE_NAME'..."
    
    if ! az storage share show --account-name "$SA_ORIGEM" --name "$FILESHARE_NAME" &> /dev/null; then
        log_error "FileShare '$FILESHARE_NAME' não encontrado em '$SA_ORIGEM'"
        exit 1
    fi
    log_success "FileShare '$FILESHARE_NAME' encontrado"
}

# Verifica se o Blob Container existe
check_blob_container() {
    log_info "Verificando Blob Container '$BLOB_CONTAINER'..."
    
    if ! az storage container show --account-name "$SA_DESTINO" --name "$BLOB_CONTAINER" &> /dev/null; then
        log_warning "Blob Container '$BLOB_CONTAINER' não encontrado. Criando..."
        az storage container create --account-name "$SA_DESTINO" --name "$BLOB_CONTAINER" --public-access off
        log_success "Blob Container '$BLOB_CONTAINER' criado"
    else
        log_success "Blob Container '$BLOB_CONTAINER' encontrado"
    fi
}

# Cria arquivo de teste no FileShare
create_test_file() {
    local dry_run=$1
    
    log_info "Criando arquivo de teste '$TEST_FILE'..."
    
    if [ "$dry_run" == "true" ]; then
        log_info "[DRY-RUN] Arquivo de teste seria criado: $TEST_FILE"
        return 0
    fi
    
    # Cria conteúdo de teste
    local test_content="Teste de sincronização AzCopy
Data: $(date)
Origem: $SA_ORIGEM/$FILESHARE_NAME
Destino: $SA_DESTINO/$BLOB_CONTAINER
Arquivo: $TEST_FILE"
    
    # Cria arquivo local temporário
    echo "$test_content" > "/tmp/$TEST_FILE"
    
    # Faz upload para FileShare
    az storage file upload \
        --account-name "$SA_ORIGEM" \
        --share-name "$FILESHARE_NAME" \
        --source "/tmp/$TEST_FILE" \
        --path "$TEST_FILE"
    
    # Remove arquivo local
    rm -f "/tmp/$TEST_FILE"
    
    log_success "Arquivo de teste criado no FileShare"
}

# Lista arquivos no FileShare
list_fileshare_files() {
    log_info "Listando arquivos no FileShare '$FILESHARE_NAME'..."
    
    az storage file list \
        --account-name "$SA_ORIGEM" \
        --share-name "$FILESHARE_NAME" \
        --query "[].name" \
        --output table
}

# Lista arquivos no Blob Container
list_blob_files() {
    log_info "Listando arquivos no Blob Container '$BLOB_CONTAINER'..."
    
    az storage blob list \
        --account-name "$SA_DESTINO" \
        --container-name "$BLOB_CONTAINER" \
        --query "[].name" \
        --output table
}

# Executa sincronização usando o script principal
run_sync() {
    local dry_run=$1
    
    log_info "Executando sincronização..."
    
    if [ "$dry_run" == "true" ]; then
        log_info "[DRY-RUN] Sincronização seria executada usando ./azcopy.sh"
        return 0
    fi
    
    # Executa script de sincronização
    if [ -f "./azcopy.sh" ]; then
        ./azcopy.sh
    else
        log_error "Script azcopy.sh não encontrado no diretório atual"
        exit 1
    fi
}

# Valida se arquivo foi sincronizado
validate_sync() {
    local dry_run=$1
    
    log_info "Validando sincronização..."
    
    if [ "$dry_run" == "true" ]; then
        log_info "[DRY-RUN] Validação seria executada"
        return 0
    fi
    
    # Verifica se arquivo existe no destino
    if az storage blob show \
        --account-name "$SA_DESTINO" \
        --container-name "$BLOB_CONTAINER" \
        --name "$TEST_FILE" &> /dev/null; then
        log_success "Arquivo '$TEST_FILE' encontrado no destino - Sincronização OK!"
        return 0
    else
        log_error "Arquivo '$TEST_FILE' não encontrado no destino - Sincronização FALHOU!"
        return 1
    fi
}

# Remove arquivos de teste
cleanup_test_files() {
    local dry_run=$1
    
    log_info "Removendo arquivos de teste..."
    
    if [ "$dry_run" == "true" ]; then
        log_info "[DRY-RUN] Arquivos de teste seriam removidos"
        return 0
    fi
    
    # Remove do FileShare
    if az storage file show \
        --account-name "$SA_ORIGEM" \
        --share-name "$FILESHARE_NAME" \
        --path "$TEST_FILE" &> /dev/null; then
        az storage file delete \
            --account-name "$SA_ORIGEM" \
            --share-name "$FILESHARE_NAME" \
            --path "$TEST_FILE"
        log_success "Arquivo removido do FileShare"
    fi
    
    # Remove do Blob Container
    if az storage blob show \
        --account-name "$SA_DESTINO" \
        --container-name "$BLOB_CONTAINER" \
        --name "$TEST_FILE" &> /dev/null; then
        az storage blob delete \
            --account-name "$SA_DESTINO" \
            --container-name "$BLOB_CONTAINER" \
            --name "$TEST_FILE"
        log_success "Arquivo removido do Blob Container"
    fi
}

# Função principal
main() {
    local dry_run="false"
    local cleanup="false"
    local verbose="false"
    
    # Parse dos argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                dry_run="true"
                shift
                ;;
            --cleanup)
                cleanup="true"
                shift
                ;;
            --verbose)
                verbose="true"
                shift
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
    
    log_info "=== Iniciando teste de sincronização ==="
    
    if [ "$dry_run" == "true" ]; then
        log_warning "Executando em modo DRY-RUN - nenhuma alteração será feita"
    fi
    
    # Verificações iniciais
    check_azure_cli
    check_storage_accounts
    check_fileshare
    check_blob_container
    
    # Lista arquivos antes da sincronização
    if [ "$verbose" == "true" ]; then
        log_info "Estado antes da sincronização:"
        list_fileshare_files
        list_blob_files
    fi
    
    # Cria arquivo de teste
    create_test_file "$dry_run"
    
    # Executa sincronização
    run_sync "$dry_run"
    
    # Valida sincronização
    if validate_sync "$dry_run"; then
        log_success "Teste de sincronização PASSOU!"
    else
        log_error "Teste de sincronização FALHOU!"
        exit 1
    fi
    
    # Lista arquivos após sincronização
    if [ "$verbose" == "true" ]; then
        log_info "Estado após sincronização:"
        list_fileshare_files
        list_blob_files
    fi
    
    # Cleanup se solicitado
    if [ "$cleanup" == "true" ]; then
        cleanup_test_files "$dry_run"
    fi
    
    log_success "=== Teste concluído com sucesso! ==="
}

# Executa função principal se script for executado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
