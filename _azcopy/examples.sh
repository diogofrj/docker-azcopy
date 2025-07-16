#!/bin/bash

# Exemplos de comandos Azure CLI para gerar SAS tokens
# Este arquivo contém comandos de exemplo - não execute diretamente

# ===== CONFIGURAÇÕES =====
SA_ORIGEM="stbanprdbrstest"
SA_DESTINO="stbanprdbrs"
FILESHARE_NAME="client1"
BLOB_CONTAINER="client1"
EXPIRY_DATE=$(date -u -d "+1 hour" '+%Y-%m-%dT%H:%M:%SZ')

echo "Data de expiração: $EXPIRY_DATE"

# ===== GERAR SAS PARA FILESHARE (ORIGEM) =====
echo ""
echo "=== Gerando SAS para FileShare (Origem) ==="
echo "Comando:"
echo "az storage share generate-sas \\"
echo "  --account-name $SA_ORIGEM \\"
echo "  --name $FILESHARE_NAME \\"
echo "  --permissions rl \\"
echo "  --expiry $EXPIRY_DATE \\"
echo "  --https-only \\"
echo "  --output tsv"

# Descomente para executar:
# SAS_ORIGEM=$(az storage share generate-sas \
#   --account-name $SA_ORIGEM \
#   --name $FILESHARE_NAME \
#   --permissions rl \
#   --expiry $EXPIRY_DATE \
#   --https-only \
#   --output tsv)

echo ""
echo "URL completa seria:"
echo "https://${SA_ORIGEM}.file.core.windows.net/${FILESHARE_NAME}?{SAS_TOKEN}"

# ===== GERAR SAS PARA BLOB CONTAINER (DESTINO) =====
echo ""
echo "=== Gerando SAS para Blob Container (Destino) ==="
echo "Comando:"
echo "az storage container generate-sas \\"
echo "  --account-name $SA_DESTINO \\"
echo "  --name $BLOB_CONTAINER \\"
echo "  --permissions rwcl \\"
echo "  --expiry $EXPIRY_DATE \\"
echo "  --https-only \\"
echo "  --output tsv"

# Descomente para executar:
# SAS_DESTINO=$(az storage container generate-sas \
#   --account-name $SA_DESTINO \
#   --name $BLOB_CONTAINER \
#   --permissions rwcl \
#   --expiry $EXPIRY_DATE \
#   --https-only \
#   --output tsv)

echo ""
echo "URL completa seria:"
echo "https://${SA_DESTINO}.blob.core.windows.net/${BLOB_CONTAINER}?{SAS_TOKEN}"

# ===== COMANDO AZCOPY COMPLETO =====
echo ""
echo "=== Comando AzCopy Completo ==="
echo "azcopy sync \\"
echo "  \"https://${SA_ORIGEM}.file.core.windows.net/${FILESHARE_NAME}?{SAS_ORIGEM}\" \\"
echo "  \"https://${SA_DESTINO}.blob.core.windows.net/${BLOB_CONTAINER}?{SAS_DESTINO}\" \\"
echo "  --from-to=FileBlob \\"
echo "  --recursive \\"
echo "  --delete-destination=true \\"
echo "  --log-level=INFO \\"
echo "  --output-type=text"

# ===== VERIFICAÇÕES ÚTEIS =====
echo ""
echo "=== Comandos de Verificação ==="
echo ""
echo "# Verificar se Storage Accounts existem:"
echo "az storage account show --name $SA_ORIGEM"
echo "az storage account show --name $SA_DESTINO"
echo ""
echo "# Verificar se FileShare existe:"
echo "az storage share show --account-name $SA_ORIGEM --name $FILESHARE_NAME"
echo ""
echo "# Verificar se Blob Container existe:"
echo "az storage container show --account-name $SA_DESTINO --name $BLOB_CONTAINER"
echo ""
echo "# Criar Blob Container se não existir:"
echo "az storage container create --account-name $SA_DESTINO --name $BLOB_CONTAINER --public-access off"
echo ""
echo "# Listar arquivos no FileShare:"
echo "az storage file list --account-name $SA_ORIGEM --share-name $FILESHARE_NAME --output table"
echo ""
echo "# Listar arquivos no Blob Container:"
echo "az storage blob list --account-name $SA_DESTINO --container-name $BLOB_CONTAINER --output table"

# ===== PERMISSÕES DETALHADAS =====
echo ""
echo "=== Permissões dos SAS Tokens ==="
echo ""
echo "FileShare (Origem) - Permissões: rl"
echo "  r = read   (leitura dos arquivos)"
echo "  l = list   (listagem do conteúdo)"
echo ""
echo "Blob Container (Destino) - Permissões: rwcl"
echo "  r = read   (leitura dos blobs)"
echo "  w = write  (escrita de blobs)"
echo "  c = create (criação de novos blobs)"
echo "  l = list   (listagem do conteúdo)"
echo ""
echo "Outras permissões disponíveis:"
echo "  d = delete (exclusão de arquivos/blobs)"
echo "  a = add    (apenas para tabelas)"
echo "  u = update (apenas para tabelas)"
echo "  p = process (apenas para tabelas)"

# ===== EXEMPLO DE TESTE =====
echo ""
echo "=== Exemplo de Teste Manual ==="
echo ""
echo "# 1. Criar arquivo de teste no FileShare:"
echo "echo 'Teste de sincronização' > test.txt"
echo "az storage file upload --account-name $SA_ORIGEM --share-name $FILESHARE_NAME --source test.txt --path test.txt"
echo ""
echo "# 2. Executar sincronização (usando os scripts criados):"
echo "./azcopy.sh"
echo ""
echo "# 3. Verificar se arquivo foi sincronizado:"
echo "az storage blob show --account-name $SA_DESTINO --container-name $BLOB_CONTAINER --name test.txt"
echo ""
echo "# 4. Limpar arquivo de teste:"
echo "az storage file delete --account-name $SA_ORIGEM --share-name $FILESHARE_NAME --path test.txt"
echo "az storage blob delete --account-name $SA_DESTINO --container-name $BLOB_CONTAINER --name test.txt"
echo "rm test.txt"
