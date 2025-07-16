#!/bin/bash

# Script para validar SAS tokens limpos
# Testa se os tokens estão sendo gerados sem caracteres de controle

set -euo pipefail

# Configurações
SA_ORIGEM="stbanprdbrstest"
SA_DESTINO="stbanprdbrs"
FILESHARE_NAME="client1"
BLOB_CONTAINER="client1"

echo "=== Validação de SAS Tokens ==="
echo

# Função para validar SAS token
validate_sas_token() {
    local token=$1
    local type=$2
    
    echo "Validando token $type:"
    echo "Comprimento: ${#token}"
    
    # Verifica se contém caracteres de controle
    if [[ "$token" =~ [[:cntrl:]] ]]; then
        echo "❌ ERRO: Token contém caracteres de controle!"
        return 1
    else
        echo "✅ OK: Token não contém caracteres de controle"
    fi
    
    # Verifica se contém códigos de cor ANSI
    if [[ "$token" =~ \\\[0\;3[0-9]m ]]; then
        echo "❌ ERRO: Token contém códigos de cor ANSI!"
        return 1
    else
        echo "✅ OK: Token não contém códigos de cor ANSI"
    fi
    
    # Verifica se contém logs
    if [[ "$token" =~ \[INFO\]|\[SUCCESS\]|\[ERROR\] ]]; then
        echo "❌ ERRO: Token contém logs!"
        return 1
    else
        echo "✅ OK: Token não contém logs"
    fi
    
    echo "✅ Token $type é válido!"
    echo
    return 0
}

# Gera tokens
echo "Gerando SAS tokens..."
EXPIRY_DATE=$(date -u -d "+1 hour" '+%Y-%m-%dT%H:%M:%SZ')

# FileShare token
SAS_ORIGEM=$(az storage share generate-sas \
    --account-name "$SA_ORIGEM" \
    --name "$FILESHARE_NAME" \
    --permissions rl \
    --expiry "$EXPIRY_DATE" \
    --https-only \
    --output tsv 2>/dev/null)

# Blob Container token
SAS_DESTINO=$(az storage container generate-sas \
    --account-name "$SA_DESTINO" \
    --name "$BLOB_CONTAINER" \
    --permissions rwcl \
    --expiry "$EXPIRY_DATE" \
    --https-only \
    --output tsv 2>/dev/null)

# Valida tokens
validate_sas_token "$SAS_ORIGEM" "FileShare"
validate_sas_token "$SAS_DESTINO" "Blob Container"

echo "=== URLs Completas ==="
echo "FileShare: https://${SA_ORIGEM}.file.core.windows.net/${FILESHARE_NAME}?${SAS_ORIGEM}"
echo "Blob Container: https://${SA_DESTINO}.blob.core.windows.net/${BLOB_CONTAINER}?${SAS_DESTINO}"

echo
echo "=== Comando AzCopy ==="
echo "azcopy sync \\"
echo "  \"https://${SA_ORIGEM}.file.core.windows.net/${FILESHARE_NAME}?${SAS_ORIGEM}\" \\"
echo "  \"https://${SA_DESTINO}.blob.core.windows.net/${BLOB_CONTAINER}?${SAS_DESTINO}\" \\"
echo "  --from-to=FileBlob \\"
echo "  --recursive \\"
echo "  --delete-destination=true \\"
echo "  --log-level=INFO \\"
echo "  --output-type=text"

echo
echo "✅ Validação concluída com sucesso!"
