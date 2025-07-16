#!/bin/bash

# Script para testar apenas a geração de SAS tokens
# Útil para debug e verificação

set -euo pipefail

# Configurações
SA_ORIGEM="stbanprdbrstest"
SA_DESTINO="stbanprdbrs"
FILESHARE_NAME="client1"
BLOB_CONTAINER="client1"

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

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "=== Teste de SAS Tokens ==="
echo

# Gera SAS para FileShare
log_info "Gerando SAS token para FileShare..."
EXPIRY_DATE=$(date -u -d "+1 hour" '+%Y-%m-%dT%H:%M:%SZ')

SAS_ORIGEM=$(az storage share generate-sas \
    --account-name "$SA_ORIGEM" \
    --name "$FILESHARE_NAME" \
    --permissions rl \
    --expiry "$EXPIRY_DATE" \
    --https-only \
    --output tsv 2>/dev/null)

if [ -n "$SAS_ORIGEM" ] && [[ "$SAS_ORIGEM" != *"[INFO]"* ]]; then
    log_success "SAS FileShare gerado com sucesso"
    echo "URL: https://${SA_ORIGEM}.file.core.windows.net/${FILESHARE_NAME}?${SAS_ORIGEM}"
else
    log_error "Falha ao gerar SAS FileShare"
    exit 1
fi

echo

# Gera SAS para Blob Container
log_info "Gerando SAS token para Blob Container..."
SAS_DESTINO=$(az storage container generate-sas \
    --account-name "$SA_DESTINO" \
    --name "$BLOB_CONTAINER" \
    --permissions rwcl \
    --expiry "$EXPIRY_DATE" \
    --https-only \
    --output tsv 2>/dev/null)

if [ -n "$SAS_DESTINO" ] && [[ "$SAS_DESTINO" != *"[INFO]"* ]]; then
    log_success "SAS Blob Container gerado com sucesso"
    echo "URL: https://${SA_DESTINO}.blob.core.windows.net/${BLOB_CONTAINER}?${SAS_DESTINO}"
else
    log_error "Falha ao gerar SAS Blob Container"
    exit 1
fi

echo

# Mostra comando AzCopy que seria executado
log_info "Comando AzCopy que seria executado:"
echo "azcopy sync \\"
echo "  \"https://${SA_ORIGEM}.file.core.windows.net/${FILESHARE_NAME}?${SAS_ORIGEM}\" \\"
echo "  \"https://${SA_DESTINO}.blob.core.windows.net/${BLOB_CONTAINER}?${SAS_DESTINO}\" \\"
echo "  --from-to=FileBlob \\"
echo "  --recursive \\"
echo "  --delete-destination=true \\"
echo "  --log-level=INFO \\"
echo "  --output-type=text"

echo
log_success "Teste concluído com sucesso!"
