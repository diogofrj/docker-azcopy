#!/bin/bash

# Script para gerar novos SAS tokens para o azcopy.sh
# Este script gera os tokens e mostra como atualizar o script principal

set -euo pipefail

# Configurações (mesmas do script principal)
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

echo -e "${BLUE}[INFO]${NC} === Gerando novos SAS tokens ==="

# Verifica se o Azure CLI está instalado e logado
if ! command -v az &> /dev/null; then
    echo -e "${RED}[ERROR]${NC} Azure CLI não encontrado. Instale o Azure CLI primeiro."
    exit 1
fi

if ! az account show &> /dev/null; then
    echo -e "${RED}[ERROR]${NC} Você não está logado no Azure. Execute 'az login' primeiro."
    exit 1
fi

# Define tempo de expiração (padrão: 24 horas)
EXPIRY_TIME=${1:-"24 hours"}
EXPIRY_DATE=$(date -u -d "+$EXPIRY_TIME" '+%Y-%m-%dT%H:%M:%SZ')

echo -e "${BLUE}[INFO]${NC} Gerando tokens com expiração: $EXPIRY_DATE"

# Gera SAS token para FileShare (origem)
echo -e "${BLUE}[INFO]${NC} Gerando SAS token para FileShare '$FILESHARE_NAME' em '$SA_ORIGEM'..."
SAS_ORIGEM=$(az storage share generate-sas \
    --account-name "$SA_ORIGEM" \
    --name "$FILESHARE_NAME" \
    --permissions rl \
    --expiry "$EXPIRY_DATE" \
    --https-only \
    --output tsv 2>/dev/null)

if [ -z "$SAS_ORIGEM" ]; then
    echo -e "${RED}[ERROR]${NC} Falha ao gerar SAS token para FileShare"
    exit 1
fi

echo -e "${GREEN}[SUCCESS]${NC} SAS token gerado para FileShare"

# Gera SAS token para Blob Container (destino)
echo -e "${BLUE}[INFO]${NC} Gerando SAS token para Blob Container '$BLOB_CONTAINER' em '$SA_DESTINO'..."
SAS_DESTINO=$(az storage container generate-sas \
    --account-name "$SA_DESTINO" \
    --name "$BLOB_CONTAINER" \
    --permissions rwcl \
    --expiry "$EXPIRY_DATE" \
    --https-only \
    --output tsv 2>/dev/null)

if [ -z "$SAS_DESTINO" ]; then
    echo -e "${RED}[ERROR]${NC} Falha ao gerar SAS token para Blob Container"
    exit 1
fi

echo -e "${GREEN}[SUCCESS]${NC} SAS token gerado para Blob Container"

# Mostra os tokens gerados
echo
echo -e "${BLUE}[INFO]${NC} === Tokens gerados ==="
echo
echo -e "${YELLOW}[ORIGEM]${NC} FileShare SAS Token:"
echo "SAS_ORIGEM=\"$SAS_ORIGEM\""
echo
echo -e "${YELLOW}[DESTINO]${NC} Blob Container SAS Token:"
echo "SAS_DESTINO=\"$SAS_DESTINO\""
echo

# Instruções para atualizar o script principal
echo -e "${BLUE}[INFO]${NC} === Instruções para atualizar o azcopy.sh ==="
echo
echo "1. Edite o arquivo azcopy.sh"
echo "2. Substitua as linhas dos tokens SAS pelas linhas abaixo:"
echo
echo -e "${GREEN}# Tokens gerados em $(date)${NC}"
echo -e "${GREEN}SAS_ORIGEM=\"$SAS_ORIGEM\"${NC}"
echo -e "${GREEN}SAS_DESTINO=\"$SAS_DESTINO\"${NC}"
echo

# Opção para atualizar automaticamente
echo -e "${YELLOW}[OPCIONAL]${NC} Deseja atualizar automaticamente o arquivo azcopy.sh? (y/n)"
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    # Backup do arquivo original
    cp azcopy.sh azcopy.sh.backup.$(date +%Y%m%d_%H%M%S)
    echo -e "${GREEN}[SUCCESS]${NC} Backup criado: azcopy.sh.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Atualiza os tokens no arquivo
    sed -i "s|^SAS_ORIGEM=.*|SAS_ORIGEM=\"$SAS_ORIGEM\"|" azcopy.sh
    sed -i "s|^SAS_DESTINO=.*|SAS_DESTINO=\"$SAS_DESTINO\"|" azcopy.sh
    
    echo -e "${GREEN}[SUCCESS]${NC} Arquivo azcopy.sh atualizado com novos tokens!"
    echo -e "${BLUE}[INFO]${NC} Tokens válidos até: $EXPIRY_DATE"
else
    echo -e "${BLUE}[INFO]${NC} Atualize manualmente o arquivo azcopy.sh com os tokens mostrados acima"
fi

echo
echo -e "${GREEN}[SUCCESS]${NC} === Processo concluído! ==="
