   #!/bin/bash
    # set -euo pipefail

    # Configurações
    SA_ORIGEM="saorigemhr"
    SA_DESTINO="sadestinohr"
    FILESHARE_NAME_HOT="file-share-origem/pasta_hot"
    FILESHARE_NAME_COLD="file-share-origem/pasta_cold"    
    BLOB_CONTAINER="blob-recebidos"

    # SAS Tokens pré-definidos
    SAS_ORIGEM="se=2025-07-20T21%3A03%3A18Z&sp=rl&spr=https&sv=2025-05-05&sr=s&sig=knwMEFyCDlDwJkAUhjiqhtiMLW0Duou%2BmmxpX67vUaU%3D"
    SAS_DESTINO="se=2025-07-20T21%3A04%3A50Z&sp=rcwl&spr=https&sv=2022-11-02&sr=c&sig=822HWSvZkjumJnbY95oX0Bd5TF42SHiZlHWADBQEkR8%3D"

    # Cores para output
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    YELLOW='\033[1;33m'
    NC='\033[0m'

    echo -e "${BLUE}[INFO]${NC} === Iniciando sincronização contínua FileShare -> Blob ==="
    echo -e "${BLUE}[INFO]${NC} Executando a cada 10 segundos..."

    # Loop infinito para execução contínua
    while true; do
        echo -e "${YELLOW}[SYNC]${NC} Iniciando sincronização às $(date)"
        
        # Constrói URLs completas
        SOURCE_URL="https://${SA_ORIGEM}.file.core.windows.net/${FILESHARE_NAME_HOT}?${SAS_ORIGEM}"
        DEST_URL="https://${SA_DESTINO}.blob.core.windows.net/${BLOB_CONTAINER}?${SAS_DESTINO}"

        echo -e "${BLUE}[INFO]${NC} Executando comando AzCopy sync..."

        # Executa AzCopy
    azcopy sync "$SOURCE_URL" "$DEST_URL" \
        --from-to=FileBlob \
        --recursive \
        --put-md5 \
        --skip-version-check

        EXIT_CODE=$?

        if [ $EXIT_CODE -eq 0 ]; then
            echo -e "${GREEN}[SUCCESS]${NC} Sincronização concluída com sucesso!"
        else
            echo -e "${RED}[ERROR]${NC} Falha na sincronização (código: $EXIT_CODE)"
        fi

        echo -e "${BLUE}[INFO]${NC} Aguardando 10 segundos para próxima sincronização..."
        sleep 10
    done
 