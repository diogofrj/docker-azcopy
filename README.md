# 🚀 AzCopy Docker - Versão Customizada 

[![Build Status](https://github.com/SQ-Green/iac-ban-saas-prd/actions/workflows/azcopy-docker.yml/badge.svg)](https://github.com/SQ-Green/iac-ban-saas-prd/actions/workflows/azcopy-docker.yml)
[![Docker Hub](https://img.shields.io/docker/pulls/dfsrj/docker-azcopy.svg)](https://hub.docker.com/r/dfsrj/docker-azcopy)
[![Docker Image Size](https://img.shields.io/docker/image-size/dfsrj/docker-azcopy/latest)](https://hub.docker.com/r/dfsrj/docker-azcopy)

Imagem Docker otimizada e customizada do Azure AzCopy, baseada em Alpine Linux com as últimas versões estáveis do AzCopy. Projetada especificamente para automação de sincronização de arquivos entre Azure Storage.

## 🎯 Características

- ✅ **Sempre atualizada**: Build automático com a última versão estável do AzCopy
- ✅ **Multi-arquitetura**: Suporte para AMD64 e ARM64
- ✅ **Imagem mínima**: Baseada em Alpine Linux (~50MB)
- ✅ **Segurança**: Execução com usuário não-root
- ✅ **CI/CD Ready**: Otimizada para pipelines de automação
- ✅ **Verificação diária**: Workflow automatizado para detectar novas versões

## 📦 Repositórios da Imagem

- **Docker Hub**: `dfsrj/docker-azcopy`
- **GitHub**: `ghcr.io/diogofrj/docker-azcopy`

## 🏷️ Tags Disponíveis

- `latest` - Última versão estável
- `10.x.x` - Versão específica do AzCopy
- `10.x` - Última versão minor
- `10` - Última versão major

## 🚀 Uso Básico

### Comando simples
```bash
docker run --rm dfsrj/docker-azcopy:latest --version
```

### Sincronização de arquivos
```bash
docker run --rm -v $PWD:/workspace \
  dfsrj/docker-azcopy:latest \
  sync "/workspace/local-folder" "https://account.blob.core.windows.net/container?SAS_TOKEN" \
  --recursive --delete-destination
```

### Sincronização FileShare para Blob (caso de uso principal)
```bash
docker run --rm \
  -e SAS_ORIGEM="se=2025-07-16T14:59:59Z&sp=r..." \
  -e SAS_DESTINO="se=2025-07-16T14:59:59Z&sp=rwcl..." \
  dfsrj/docker-azcopy:latest \
  sync "https://source.file.core.windows.net/share?$SAS_ORIGEM" \
       "https://dest.blob.core.windows.net/container?$SAS_DESTINO" \
  --from-to=FileBlob --recursive --delete-destination
```

## 🔧 Uso Avançado

### Script personalizado
```bash
#!/bin/bash
# script-sync.sh

SOURCE_URL="https://source.file.core.windows.net/share?$SAS_ORIGEM"
DEST_URL="https://dest.blob.core.windows.net/container?$SAS_DESTINO"

docker run --rm \
  -v $PWD:/workspace \
  -e SAS_ORIGEM="$SAS_ORIGEM" \
  -e SAS_DESTINO="$SAS_DESTINO" \
  dfsrj/docker-azcopy:latest \
  sync "$SOURCE_URL" "$DEST_URL" \
  --from-to=FileBlob \
  --recursive \
  --delete-destination \
  --log-level=INFO
```

### Docker Compose
```yaml
version: '3.8'
services:
  azcopy-sync:
    image: dfsrj/docker-azcopy:latest
    environment:
      - SAS_ORIGEM=${SAS_ORIGEM}
      - SAS_DESTINO=${SAS_DESTINO}
    volumes:
      - ./scripts:/scripts:ro
    command: |
      sync "https://source.file.core.windows.net/share?$$SAS_ORIGEM" 
           "https://dest.blob.core.windows.net/container?$$SAS_DESTINO"
           --from-to=FileBlob --recursive --delete-destination
```

## 🎛️ Kubernetes Integration

### CronJob para sincronização automática
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: azcopy-sync
spec:
  schedule: "0 */6 * * *"  # A cada 6 horas
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: azcopy-sync
            image: dfsrj/docker-azcopy:latest
            command: ["azcopy", "sync"]
            args:
              - "https://source.file.core.windows.net/share?$(SAS_ORIGEM)"
              - "https://dest.blob.core.windows.net/container?$(SAS_DESTINO)"
              - "--from-to=FileBlob"
              - "--recursive"
              - "--delete-destination"
            env:
            - name: SAS_ORIGEM
              valueFrom:
                secretKeyRef:
                  name: azcopy-tokens
                  key: sas-origem
            - name: SAS_DESTINO
              valueFrom:
                secretKeyRef:
                  name: azcopy-tokens
                  key: sas-destino
          restartPolicy: OnFailure
```

## 🔍 Verificação de Versão

```bash
# Verificar versão atual
docker run --rm dfsrj/docker-azcopy:latest --version

# Saída esperada:
# azcopy version 10.x.x
```

## 🛠️ Build Local

```bash
# Build da imagem
docker build -t meu-azcopy .

# Test local
docker run --rm meu-azcopy --version
```

## 📋 Comandos Úteis

### Listar conteúdo
```bash
docker run --rm dfsrj/docker-azcopy:latest \
  list "https://account.blob.core.windows.net/container?SAS_TOKEN"
```

### Copy com progresso
```bash
docker run --rm -v $PWD:/workspace dfsrj/docker-azcopy:latest \
  copy "/workspace/file.txt" "https://account.blob.core.windows.net/container/file.txt?SAS_TOKEN" \
  --log-level=INFO
```

### Sync com filtros
```bash
docker run --rm dfsrj/docker-azcopy:latest \
  sync "source" "destination" \
  --include-pattern="*.pdf;*.doc*" \
  --exclude-pattern="temp/*"
```

## 🔒 Segurança

- Execução com usuário não-root (UID/GID 1000)
- Scan de vulnerabilidades automatizado com Trivy
- Imagem baseada em Alpine Linux (minimal attack surface)
- Certificados CA atualizados

## 📊 Monitoramento

### Logs estruturados
```bash
docker run --rm dfsrj/docker-azcopy:latest \
  sync "source" "destination" \
  --log-level=INFO \
  --output-type=json
```

### Métricas de performance
```bash
docker run --rm dfsrj/docker-azcopy:latest \
  sync "source" "destination" \
  --cap-mbps=100 \
  --log-level=INFO
```

## 🤝 Contribuição

1. Fork do repositório
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

## 📄 Licença

MIT License - veja o arquivo LICENSE para detalhes.

## 🆘 Suporte

- **GitHub Issues**: [Reportar problemas](https://github.com/diogofrj/docker-azcopy/issues)
- **Documentação AzCopy**: [Documentação oficial](https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azcopy)

## 📈 Changelog

### Latest AzCopy: 10.x.x
- ✅ Build automático com última versão estável
- ✅ Multi-arquitetura (AMD64/ARM64)
- ✅ Otimizações de performance
- ✅ Segurança aprimorada

---

**Mantido por:** [Diogo Fernandes](mailto:dfs@outlook.com.br) - iachero  
**Baseado em:** [Azure AzCopy](https://github.com/Azure/azure-storage-azcopy)
