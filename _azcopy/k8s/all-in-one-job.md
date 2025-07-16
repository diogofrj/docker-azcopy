# AzCopy Sync - Kubernetes CronJob Simplificado

Sincronização automática de arquivos do Azure FileShare para Blob Storage usando AzCopy.

## Estrutura Simplificada

```
k8s/
├── all-in-one.yaml       # Todos os recursos em um arquivo
├── simple-deploy.sh      # Script de gerenciamento simples
└── README.md            # Este arquivo
```

## Deploy Rápido

### 1. Atualizar SAS Tokens

Edite o arquivo `all-in-one.yaml` e substitua os tokens Base64:

```bash
# Gerar Base64 dos tokens
echo -n "seu_sas_token_origem" | base64 -w 0
echo -n "seu_sas_token_destino" | base64 -w 0
```

### 2. Fazer Deploy

```bash
./simple-deploy.sh deploy
```

## Comandos Principais

```bash
# Deploy
./simple-deploy.sh deploy

# Verificar status
./simple-deploy.sh status

# Ver logs
./simple-deploy.sh logs

# Atualizar tokens
./simple-deploy.sh update-tokens "se=2025..." "se=2025..."

# Remover tudo
./simple-deploy.sh undeploy
```

## Configuração do Schedule (JOB)

Para alterar o agendamento, edite o campo `schedule` no arquivo `all-in-one.yaml`:

```yaml
spec:
  schedule: "0 */6 * * *"  # A cada 6 horas
```

### Schedules Comuns:
- `"0 * * * *"` - A cada hora
- `"0 */6 * * *"` - A cada 6 horas
- `"0 2 * * *"` - Diariamente às 2:00
- `"*/30 * * * *"` - A cada 30 minutos

## Recursos Utilizados

- **Imagem**: `mcr.microsoft.com/azure-cli:2.9.1` (já tem AzCopy)
- **Recursos**: 256Mi RAM, 100m CPU (request) | 512Mi RAM, 300m CPU (limit)
- **Timeout**: 2 horas por job
- **Concorrência**: Forbid (não executa simultâneo)

## Troubleshooting

### Ver logs detalhados:
```bash
kubectl logs -l app=azcopy-sync --tail=100
```

### Verificar tokens:
```bash
kubectl get secret azcopy-sas-tokens -o yaml
```

### Executar teste manual:
```bash
kubectl create job test-sync --from=cronjob/azcopy-sync-cronjob
kubectl logs job/test-sync -f
```

## Arquivos Originais

Os arquivos individuais ainda estão disponíveis:
- `secret.yaml` - SAS tokens
- `configmap.yaml` - Script de sincronização
- `cronjob.yaml` - CronJob principal
- `rbac.yaml` - ServiceAccount (simplificado)

Use `deploy.sh` para deploy com arquivos separados.
