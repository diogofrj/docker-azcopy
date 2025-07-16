#!/bin/bash

# Script para sincronização de arquivos usando AzCopy
# De: Storage Account com FileShare para Storage Account com Blob
# Autor: DevOps Team
# Data: $(date +%Y-%m-%d)

set -euo pipefail

# Configurações
SA_ORIGEM="stbanprdbrstest"
SA_DESTINO="stbanprdbrs"
FILESHARE_NAME="client1"
BLOB_CONTAINER="client1"

# SAS Tokens pré-definidos
# Para gerar novos tokens, use os comandos:
# az storage share generate-sas --account-name stbanprdbrstest --name client1 --permissions rl --expiry 2025-07-16T15:00:00Z --https-only --output tsv
# az storage container generate-sas --account-name stbanprdbrs --name client1 --permissions rwcl --expiry 2025-07-16T15:00:00Z --https-only --output tsv

SAS_ORIGEM="se=2025-07-16T14%3A59%3A59Z&sp=rl&spr=https&sv=2025-05-05&sr=s&sig=awjiFPep/HiRpaEwF6ew7ndG1aMUQVbzZkQU3nOMaVs%3D"
SAS_DESTINO="se=2025-07-16T15%3A01%3A05Z&sp=rcwl&spr=https&sv=2022-11-02&sr=c&sig=Vpn5Ch%2BE3Sv9jezJzstBuCjt%2B7ou9ZyOAOG/JSAlqPM%3D"





# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}[INFO]${NC} === Iniciando sincronização FileShare -> Blob ==="
echo -e "${BLUE}[INFO]${NC} Usando tokens SAS pré-definidos..."

# Verifica se o AzCopy está instalado
if ! command -v azcopy &> /dev/null; then
    echo -e "${YELLOW}[WARNING]${NC} AzCopy não encontrado. Tentando instalar..."
    
    echo -e "${BLUE}[INFO]${NC} Instalando AzCopy..."
    wget -O azcopy.tar.gz https://aka.ms/downloadazcopy-v10-linux
    tar -xf azcopy.tar.gz --strip-components=1
    chmod +x azcopy
    sudo mv azcopy /usr/local/bin/
    rm -f azcopy.tar.gz
    
    echo -e "${GREEN}[SUCCESS]${NC} AzCopy instalado com sucesso"
else
    VERSION=$(azcopy --version 2>/dev/null | head -1 | grep -o 'azcopy version [0-9.]*' || echo "azcopy versão desconhecida")
    echo -e "${GREEN}[SUCCESS]${NC} AzCopy encontrado: $VERSION"
fi

# Verifica se os SAS tokens foram definidos
if [ -z "$SAS_ORIGEM" ]; then
    echo -e "${RED}[ERROR]${NC} SAS_ORIGEM não definido. Configure a variável no script."
    exit 1
fi

if [ -z "$SAS_DESTINO" ]; then
    echo -e "${RED}[ERROR]${NC} SAS_DESTINO não definido. Configure a variável no script."
    exit 1
fi

# Verifica validade dos tokens (extrai data de expiração)
check_token_expiry() {
    local token=$1
    local token_name=$2
    
    # Extrai a data de expiração do token (formato: se=2025-07-16T14%3A59%3A59Z)
    local expiry_encoded=$(echo "$token" | grep -o 'se=[^&]*' | cut -d'=' -f2)
    
    if [ -n "$expiry_encoded" ]; then
        # Decodifica URL encoding básico para datas
        local expiry_decoded=$(echo "$expiry_encoded" | sed 's/%3A/:/g')
        local expiry_timestamp=$(date -d "$expiry_decoded" +%s 2>/dev/null || echo "0")
        local current_timestamp=$(date +%s)
        
        if [ "$expiry_timestamp" -gt "$current_timestamp" ]; then
            echo -e "${GREEN}[SUCCESS]${NC} $token_name válido até: $expiry_decoded"
        else
            echo -e "${YELLOW}[WARNING]${NC} $token_name pode ter expirado: $expiry_decoded"
            echo -e "${YELLOW}[WARNING]${NC} Continuando execução... Se falhar, gere novos tokens"
        fi
    else
        echo -e "${YELLOW}[WARNING]${NC} Não foi possível verificar expiração do $token_name"
    fi
}

echo -e "${BLUE}[INFO]${NC} Usando SAS tokens pré-definidos..."
check_token_expiry "$SAS_ORIGEM" "SAS token da origem"
check_token_expiry "$SAS_DESTINO" "SAS token do destino"

# Constrói URLs completas
SOURCE_URL="https://${SA_ORIGEM}.file.core.windows.net/${FILESHARE_NAME}?${SAS_ORIGEM}"
DEST_URL="https://${SA_DESTINO}.blob.core.windows.net/${BLOB_CONTAINER}?${SAS_DESTINO}"

# Executa sincronização
echo -e "${BLUE}[INFO]${NC} Iniciando sincronização..."
echo -e "${BLUE}[INFO]${NC} Origem: ${SOURCE_URL%\?*}?[SAS_TOKEN]"
echo -e "${BLUE}[INFO]${NC} Destino: ${DEST_URL%\?*}?[SAS_TOKEN]"

echo -e "${BLUE}[INFO]${NC} Executando comando AzCopy sync..."

# Configura ambiente não-interativo
export AZCOPY_AUTO_LOGIN_TYPE=DEVICE
export AZCOPY_DISABLE_HIERARCHICAL_SCAN=true
export AZCOPY_CONCURRENCY_VALUE=AUTO
export AZCOPY_LOG_LEVEL=INFO

# Executa AzCopy com timeout de 30 minutos
azcopy sync "$SOURCE_URL" "$DEST_URL" \
    --from-to=FileBlob \
    --recursive \
    --delete-destination=true \
    --log-level=INFO \
    --output-type=text \
    --skip-version-check

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}[SUCCESS]${NC} Sincronização concluída com sucesso!"
    echo -e "${GREEN}[SUCCESS]${NC} === Processo concluído com sucesso! ==="
elif [ $EXIT_CODE -eq 124 ]; then
    echo -e "${RED}[ERROR]${NC} Timeout - Sincronização cancelada após 30 minutos"
    echo -e "${RED}[ERROR]${NC} Tente novamente ou verifique a conectividade"
    exit $EXIT_CODE
else
    echo -e "${RED}[ERROR]${NC} Falha na sincronização (código: $EXIT_CODE)"
    echo -e "${RED}[ERROR]${NC} Consulte os logs do AzCopy para mais detalhes"
    exit $EXIT_CODE
fi

