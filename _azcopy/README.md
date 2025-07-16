# Sincronização de Storage Accounts usando AzCopy

Este diretório contém scripts para sincronizar arquivos entre um Storage Account com FileShare e um Storage Account com Blob Container usando AzCopy.

## Cenário

- **Origem**: Storage Account `stbanprdbrstest` com FileShare `client1`
- **Destino**: Storage Account `stbanprdbrs` com Blob Container `client1`
- **Ferramenta**: AzCopy com SAS tokens de privilégio mínimo

## Scripts Disponíveis

### 1. `azcopy.sh` - Script Principal
Script principal que executa a sincronização usando SAS tokens pré-definidos.

```bash
./azcopy.sh
```

**Funcionalidades:**
- Usa SAS tokens pré-configurados no script
- Verifica validade dos tokens automaticamente
- Instala AzCopy automaticamente se necessário
- Executa sincronização FileShare → Blob
- Logs coloridos e informativos
- Tratamento de erros robusto
- Timeout de segurança (sem travamento)

### 2. `update-tokens.sh` - Gerador e Atualizador de Tokens
Script para gerar novos SAS tokens e atualizar o script principal.

```bash
# Gerar tokens com validade padrão (24 horas)
./update-tokens.sh

# Gerar tokens com validade personalizada
./update-tokens.sh "2 hours"
./update-tokens.sh "1 week"
```

**Funcionalidades:**
- Gera novos SAS tokens automaticamente
- Mostra instruções para atualização manual
- Opção de atualização automática do azcopy.sh
- Cria backup antes de alterar arquivos

### 3. `generate-sas-tokens.sh` - Gerador Manual de SAS Tokens
Script para gerar SAS tokens manualmente quando necessário.

```bash
# Gerar SAS para FileShare (origem)
./generate-sas-tokens.sh -s stbanprdbrstest -t fileshare -n client1

# Gerar SAS para Blob Container (destino)
./generate-sas-tokens.sh -s stbanprdbrs -t blob -n client1

# Gerar SAS com tempo customizado (2 horas)
./generate-sas-tokens.sh -s stbanprdbrs -t blob -n client1 -e "2 hours"

# Gerar SAS com permissões específicas
./generate-sas-tokens.sh -s stbanprdbrs -t blob -n client1 -p "r"
```

### 4. `test-sync.sh` - Script de Teste
Script para validar a sincronização com arquivos de teste.

```bash
# Teste completo com cleanup
./test-sync.sh --cleanup

# Teste sem alterações reais
./test-sync.sh --dry-run

# Teste com saída detalhada
./test-sync.sh --verbose --cleanup
```

## Pré-requisitos

### 1. Azure CLI
```bash
# Instalar Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Fazer login
az login

# Verificar conta ativa
az account show
```

### 2. AzCopy
O script principal instala o AzCopy automaticamente se não estiver disponível.

### 3. Permissões Azure
Certifique-se de que sua conta tem as seguintes permissões:
- **Storage Account Contributor** ou **Storage Blob Data Contributor** nos Storage Accounts
- Permissão para gerar SAS tokens

## Permissões de SAS Token

### FileShare (Origem)
- **r** (read) - Leitura dos arquivos
- **l** (list) - Listagem do conteúdo

### Blob Container (Destino)
- **r** (read) - Leitura dos blobs
- **w** (write) - Escrita de novos blobs
- **c** (create) - Criação de novos blobs
- **l** (list) - Listagem do conteúdo

## Configuração

### Configuração de SAS Tokens
O script principal (`azcopy.sh`) usa SAS tokens pré-definidos nas variáveis:

```bash
# Configurações básicas
SA_ORIGEM="stbanprdbrstest"        # Storage Account origem
SA_DESTINO="stbanprdbrs"           # Storage Account destino
FILESHARE_NAME="client1"           # Nome do FileShare
BLOB_CONTAINER="client1"           # Nome do Blob Container

# SAS Tokens (atualize conforme necessário)
SAS_ORIGEM="se=2025-07-16T14%3A59%3A59Z&sp=rl&spr=https&sv=2025-05-05&sr=s&sig=..."
SAS_DESTINO="se=2025-07-16T15%3A01%3A05Z&sp=rcwl&spr=https&sv=2022-11-02&sr=c&sig=..."
```

### Como Atualizar os Tokens

#### Método 1: Usando o script automático
```bash
# Gerar e atualizar automaticamente
./update-tokens.sh

# Com validade personalizada
./update-tokens.sh "2 hours"
```

#### Método 2: Geração manual
```bash
# Para FileShare (origem)
az storage share generate-sas \
    --account-name stbanprdbrstest \
    --name client1 \
    --permissions rl \
    --expiry 2025-07-16T15:00:00Z \
    --https-only \
    --output tsv

# Para Blob Container (destino)
az storage container generate-sas \
    --account-name stbanprdbrs \
    --name client1 \
    --permissions rwcl \
    --expiry 2025-07-16T15:00:00Z \
    --https-only \
    --output tsv
```

### Verificação de Validade
O script verifica automaticamente a validade dos tokens baseado na data de expiração. Se um token estiver próximo do vencimento, será exibido um aviso.

### Opções do AzCopy
```bash
azcopy sync "$source_url" "$dest_url" \
    --from-to=FileBlob \                   # Especifica origem FileShare e destino Blob
    --recursive \                          # Sincroniza recursivamente
    --delete-destination=true \            # Remove arquivos não existentes na origem
    --log-level=INFO \                     # Nível de log
    --output-type=text                     # Formato de saída
```

### Flags Adicionais Disponíveis
```bash
# Outras opções úteis do AzCopy sync:
--dry-run                                  # Simula a operação sem fazer alterações
--exclude-pattern="*.tmp;*.log"           # Exclui arquivos por padrão
--include-pattern="*.txt;*.pdf"           # Inclui apenas arquivos específicos
--cap-mbps=100                             # Limita largura de banda
--block-size-mb=8                          # Tamanho do bloco em MB
--log-level=DEBUG                          # Nível de log mais detalhado
```

### Tipos de Origem e Destino (--from-to)
Para sincronização entre diferentes tipos de storage, use:
- `FileBlob` - FileShare para Blob Container (nosso caso)
- `BlobBlob` - Blob para Blob
- `FileFile` - FileShare para FileShare
- `BlobLocal` - Blob para sistema local
- `LocalBlob` - Sistema local para Blob

**Nota**: As flags `--preserve-permissions` e `--preserve-last-modified-time` foram removidas nas versões mais recentes do AzCopy. Os metadados e timestamps são preservados automaticamente quando possível.

## Uso Típico

### 1. Execução Simples
```bash
# Torna o script executável
chmod +x azcopy.sh

# Executa sincronização
./azcopy.sh
```

### 2. Teste antes da Produção
```bash
# Torna o script de teste executável
chmod +x test-sync.sh

# Executa teste sem alterações
./test-sync.sh --dry-run

# Executa teste completo
./test-sync.sh --cleanup --verbose
```

### 3. Geração Manual de SAS
```bash
# Torna o script executável
chmod +x generate-sas-tokens.sh

# Gera SAS para origem
./generate-sas-tokens.sh -s stbanprdbrstest -t fileshare -n client1

# Gera SAS para destino
./generate-sas-tokens.sh -s stbanprdbrs -t blob -n client1
```

## Monitoramento e Logs

### Logs do AzCopy
Os logs são exibidos em tempo real durante a execução. Para logs mais detalhados:

```bash
# Verificar logs do AzCopy
azcopy jobs list
azcopy jobs show <job-id>
```

### Verificação Manual
```bash
# Listar arquivos no FileShare
az storage file list --account-name stbanprdbrstest --share-name client1

# Listar arquivos no Blob Container
az storage blob list --account-name stbanprdbrs --container-name client1
```

## Solução de Problemas

### 1. Erro de Autenticação
```bash
# Verificar login
az account show

# Renovar login se necessário
az login
```

### 2. Permissões Insuficientes
```bash
# Verificar permissões no Storage Account
az role assignment list --scope /subscriptions/<subscription-id>/resourceGroups/<rg>/providers/Microsoft.Storage/storageAccounts/<storage-account>
```

### 3. SAS Token Expirado
```bash
# Gerar novo SAS token
./generate-sas-tokens.sh -s <storage-account> -t <type> -n <name>
```

### 4. AzCopy Falha
```bash
# Verificar versão do AzCopy
azcopy --version

# Verificar conectividade
azcopy list "https://<storage-account>.blob.core.windows.net/<container>?<sas-token>"
```

## Boas Práticas

1. **Sempre teste primeiro** usando `--dry-run`
2. **Use privilégios mínimos** - os scripts já implementam isso
3. **Monitore os logs** durante a execução
4. **Valide a sincronização** após execução
5. **Mantenha SAS tokens seguros** e com tempo de vida curto
6. **Execute em horários de baixo uso** para minimizar impacto

## Segurança

- SAS tokens são gerados com tempo de vida de 1 hora por padrão
- Permissões mínimas necessárias são aplicadas automaticamente
- Tokens são utilizados apenas via HTTPS
- Não são armazenados em arquivos ou logs

## Exemplo de Execução

```bash
$ ./azcopy.sh
[INFO] === Iniciando sincronização FileShare -> Blob ===
[INFO] Usando subscription: 12345678-1234-1234-1234-123456789012
[SUCCESS] AzCopy encontrado: azcopy version 10.16.2
[INFO] Gerando SAS tokens...
[INFO] Gerando SAS token para FileShare 'client1' em 'stbanprdbrstest'...
[SUCCESS] SAS token gerado para FileShare (válido até: 2025-07-15T15:30:00Z)
[INFO] Gerando SAS token para Blob Container 'client1' em 'stbanprdbrs'...
[SUCCESS] SAS token gerado para Blob Container (válido até: 2025-07-15T15:30:00Z)
[INFO] Iniciando sincronização...
[INFO] Origem: https://stbanprdbrstest.file.core.windows.net/client1?sp=rl&st=...
[INFO] Destino: https://stbanprdbrs.blob.core.windows.net/client1?sp=rwcl&st=...
[SUCCESS] Sincronização concluída com sucesso!
[SUCCESS] === Processo concluído com sucesso! ===
```

## Suporte

Para problemas ou dúvidas:
1. Verifique os logs de execução
2. Execute o script de teste
3. Consulte a documentação do AzCopy
4. Contate a equipe de DevOps




<!-- 
# # Comando AzCopy para copiar de Storage File para Storage Blob
# # Usando as configurações definidas acima

# # Construir URLs completas
# SOURCE_URL="https://${SA_ORIGEM}.file.core.windows.net/${FILESHARE_NAME}?${SAS_ORIGEM}"
# DEST_URL="https://${SA_DESTINO}.blob.core.windows.net/${BLOB_CONTAINER}?${SAS_DESTINO}"

# # Comando AzCopy
# azcopy copy "${SOURCE_URL}" "${DEST_URL}" \
#     --from-to=FileBlob \
#     --recursive \
#     --overwrite=true \
#     --log-level=INFO -->
