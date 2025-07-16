# Manifestos Kubernetes para AzCopy Sync

Este diretório contém todos os manifestos Kubernetes necessários para executar o script de sincronização AzCopy como um CronJob.

## Estrutura dos Arquivos

```
k8s/
├── configmap.yaml      # Script de sincronização
├── secret.yaml         # SAS tokens (Base64)
├── config.yaml         # Configurações gerais
├── rbac.yaml           # ServiceAccount e permissões
├── cronjob.yaml        # CronJob principal
├── deploy.sh           # Script de deploy e gerenciamento
└── README.md           # Este arquivo
```

## Arquivos de Manifesto

### 1. `configmap.yaml`
Contém o script de sincronização AzCopy adaptado para Kubernetes.

### 2. `secret.yaml`
Armazena os SAS tokens em formato Base64 de forma segura.

### 3. `config.yaml`
Configurações gerais como timezone, schedules predefinidos, etc.

### 4. `rbac.yaml`
ServiceAccount e permissões RBAC necessárias.

### 5. `cronjob.yaml`
CronJob principal que executa a sincronização.

### 6. `deploy.sh`
Script auxiliar para gerenciar os recursos Kubernetes.

## Como Usar

### 1. Deploy Inicial

```bash
# Torna o script executável
chmod +x deploy.sh

# Faz deploy de todos os manifestos
./deploy.sh deploy
```

### 2. Atualizar SAS Tokens

```bash
# Método 1: Usando o script deploy.sh
./deploy.sh update-tokens "seu_sas_token_origem" "seu_sas_token_destino"

# Método 2: Manualmente
# Edite o arquivo secret.yaml com tokens em Base64
echo "seu_token_aqui" | base64 -w 0
```

### 3. Configurar Schedule

```bash
# Atualizar schedule para executar a cada hora
./deploy.sh update-schedule "0 * * * *"

# Atualizar schedule para executar às 2h da manhã
./deploy.sh update-schedule "0 2 * * *"

# Atualizar schedule para executar a cada 30 minutos
./deploy.sh update-schedule "*/30 * * * *"
```

### 4. Monitoramento

```bash
# Verificar status dos recursos
./deploy.sh status

# Ver logs do último job
./deploy.sh logs

# Executar job manualmente
./deploy.sh run-now
```

## Schedules Cron Comuns

| Schedule | Descrição |
|----------|-----------|
| `"0 * * * *"` | A cada hora |
| `"0 */6 * * *"` | A cada 6 horas |
| `"0 2 * * *"` | Diariamente às 2h |
| `"0 0 * * 0"` | Semanalmente no domingo |
| `"0 0 1 * *"` | Mensalmente no dia 1 |
| `"*/30 * * * *"` | A cada 30 minutos |
| `"0 */4 * * *"` | A cada 4 horas |

## Configurações do CronJob

### Recursos
- **Memory**: 256Mi (request) / 1Gi (limit)
- **CPU**: 100m (request) / 500m (limit)

### Timeout
- **Job Timeout**: 2 horas (activeDeadlineSeconds)
- **AzCopy Timeout**: 30 minutos (timeout no script)

### Políticas
- **Concurrency**: Forbid (não permite execução simultânea)
- **Restart**: Never (não reinicia em caso de falha)
- **History**: 3 jobs bem-sucedidos, 5 jobs falhados

## Comandos Úteis

### Verificar Status
```bash
# Ver CronJob
kubectl get cronjob azcopy-sync-cronjob

# Ver Jobs
kubectl get jobs -l app=azcopy-sync

# Ver Pods
kubectl get pods -l app=azcopy-sync

# Ver logs detalhados
kubectl logs -l app=azcopy-sync --tail=100
```

### Executar Manualmente
```bash
# Criar job manual
kubectl create job azcopy-sync-manual --from=cronjob/azcopy-sync-cronjob

# Acompanhar execução
kubectl get jobs -w
```

### Atualizar Recursos
```bash
# Atualizar CronJob
kubectl apply -f cronjob.yaml

# Atualizar Secret
kubectl apply -f secret.yaml

# Reiniciar CronJob
kubectl rollout restart cronjob azcopy-sync-cronjob
```

## Solução de Problemas

### 1. Job Falhando
```bash
# Ver logs do job
kubectl logs job/azcopy-sync-cronjob-xxxxx

# Verificar eventos
kubectl describe cronjob azcopy-sync-cronjob
```

### 2. Tokens Expirados
```bash
# Gerar novos tokens
az storage share generate-sas --account-name stbanprdbrstest --name client1 --permissions rl --expiry 2025-12-31T23:59:59Z --https-only --output tsv

# Atualizar no cluster
./deploy.sh update-tokens "novo_token_origem" "novo_token_destino"
kubectl apply -f secret.yaml
```

### 3. Schedule Incorreto
```bash
# Verificar próxima execução
kubectl get cronjob azcopy-sync-cronjob -o jsonpath='{.status.lastScheduleTime}'

# Atualizar schedule
./deploy.sh update-schedule "0 */2 * * *"
```

## Segurança

### Secrets
- SAS tokens armazenados em Kubernetes Secrets
- Codificados em Base64
- Não expostos em logs

### RBAC
- ServiceAccount dedicado
- Permissões mínimas necessárias
- Acesso limitado ao namespace

### Container Security
- Execução como usuário não-root (UID 1000)
- Filesystem read-only para scripts
- Recursos limitados

## Monitoramento e Alertas

### Prometheus Metrics (Opcional)
```yaml
# Adicionar ao cronjob.yaml se usando Prometheus
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
```

### Logs Centralizados
Os logs são enviados automaticamente para o stdout e podem ser coletados por soluções como ELK Stack, Fluentd, etc.

## Backup e Restore

### Backup da Configuração
```bash
# Exportar recursos
kubectl get cronjob,configmap,secret,serviceaccount,role,rolebinding -l app=azcopy-sync -o yaml > backup.yaml
```

### Restore
```bash
# Restaurar recursos
kubectl apply -f backup.yaml
```

## Customização

### Modificar Container Image
Edite o arquivo `cronjob.yaml` para usar uma imagem personalizada:

```yaml
containers:
- name: azcopy-sync
  image: minha-registry/azcopy-custom:latest
```

### Adicionar Notificações
Modifique o script no `configmap.yaml` para incluir notificações:

```bash
# Exemplo: Slack notification
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"Sincronização AzCopy concluída"}' \
  YOUR_SLACK_WEBHOOK_URL
```
