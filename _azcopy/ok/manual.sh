#!/bin/bash
# set -euo pipefail

# Configurações
SA_ORIGEM="saorigemhr"
SA_DESTINO="sadestinohr"
FILESHARE_NAME_HOT="file-share-origem/pasta_hot"
FILESHARE_NAME_COLD="file-share-origem/pasta_cold"    
BLOB_CONTAINER="blob-recebidos/pasta_hot"

# SAS Tokens pré-definidos
SAS_ORIGEM="se=2025-07-20T22%3A33%3A49Z&sp=rwdl&spr=https&sv=2025-05-05&sr=s&sig=Rc1GwN4Ue6TebSlAghvd69g0wVc5rWR0bkXmUMsBOpU%3D"
SAS_DESTINO="se=2025-07-20T21%3A04%3A50Z&sp=rcwl&spr=https&sv=2022-11-02&sr=c&sig=822HWSvZkjumJnbY95oX0Bd5TF42SHiZlHWADBQEkR8%3D"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}[INFO]${NC} === Iniciando sincronização contínua FileShare -> Blob com Backup ==="
echo -e "${BLUE}[INFO]${NC} Executando a cada 10 segundos..."

# Loop infinito para execução contínua
while true; do
    echo -e "${YELLOW}[SYNC]${NC} Iniciando ciclo de sincronização às $(date)"
    
    # Constrói URLs completas (com / no final para garantir que são tratadas como diretórios)
    SOURCE_HOT_URL="https://${SA_ORIGEM}.file.core.windows.net/${FILESHARE_NAME_HOT}/?${SAS_ORIGEM}"
    SOURCE_COLD_URL="https://${SA_ORIGEM}.file.core.windows.net/${FILESHARE_NAME_COLD}/?${SAS_ORIGEM}"
    DEST_BLOB_URL="https://${SA_DESTINO}.blob.core.windows.net/${BLOB_CONTAINER}/?${SAS_DESTINO}"

    # ETAPA 1: Sincronizar pasta_hot -> blob destino
    echo -e "${BLUE}[ETAPA 1]${NC} Sincronizando pasta_hot -> blob destino..."
    azcopy sync "$SOURCE_HOT_URL" "$DEST_BLOB_URL" \
        --from-to=FileBlob \
        --recursive \
        --skip-version-check

    SYNC_EXIT_CODE=$?

    if [ $SYNC_EXIT_CODE -eq 0 ]; then
        echo -e "${GREEN}[ETAPA 1 - SUCCESS]${NC} Sincronização para blob concluída!"
        
        # ETAPA 2: Backup pasta_hot -> pasta_cold
        echo -e "${BLUE}[ETAPA 2]${NC} Fazendo backup pasta_hot -> pasta_cold..."
        azcopy sync "$SOURCE_HOT_URL" "$SOURCE_COLD_URL" \
            --from-to=FileFile \
            --recursive \
            --skip-version-check

        BACKUP_EXIT_CODE=$?

        if [ $BACKUP_EXIT_CODE -eq 0 ]; then
            echo -e "${GREEN}[ETAPA 2 - SUCCESS]${NC} Backup concluído!"
            
            # ETAPA 3: Remover APENAS os ARQUIVOS da pasta_hot (preservar a estrutura da pasta)
            echo -e "${BLUE}[ETAPA 3]${NC} Removendo arquivos processados da pasta_hot..."
            
            # Usar remove com padrão /* para remover apenas arquivos, não a pasta
            SOURCE_HOT_FILES_URL="https://${SA_ORIGEM}.file.core.windows.net/${FILESHARE_NAME_HOT}/*?${SAS_ORIGEM}"
            
            azcopy remove "$SOURCE_HOT_FILES_URL" \
                --recursive \
                --skip-version-check

            DELETE_EXIT_CODE=$?

            if [ $DELETE_EXIT_CODE -eq 0 ]; then
                echo -e "${GREEN}[ETAPA 3 - SUCCESS]${NC} Arquivos processados removidos da pasta_hot!"
                echo -e "${GREEN}[CICLO COMPLETO]${NC} Todas as etapas concluídas com sucesso!"
            else
                echo -e "${RED}[ETAPA 3 - ERROR]${NC} Falha ao remover arquivos da pasta_hot (código: $DELETE_EXIT_CODE)"
            fi
        else
            echo -e "${RED}[ETAPA 2 - ERROR]${NC} Falha no backup (código: $BACKUP_EXIT_CODE)"
            echo -e "${YELLOW}[WARNING]${NC} Arquivos NÃO foram removidos da pasta_hot devido à falha no backup"
        fi
    else
        echo -e "${RED}[ETAPA 1 - ERROR]${NC} Falha na sincronização para blob (código: $SYNC_EXIT_CODE)"
        echo -e "${YELLOW}[WARNING]${NC} Backup e remoção cancelados devido à falha na sincronização"
    fi

    echo -e "${BLUE}[INFO]${NC} Aguardando 10 segundos para próximo ciclo..."
    sleep 10
done
 