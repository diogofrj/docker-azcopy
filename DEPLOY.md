# 🚀 Instruções de Deploy - AzCopy Docker Image

## 📋 Resumo das Melhorias

### ✅ **Dockerfile Otimizado**
- Multi-stage build para imagem menor
- Build do AzCopy sempre com última versão estável
- Usuário não-root para segurança
- Labels OCI compliance
- Dependências mínimas

### ✅ **Script de Build Inteligente**
- Detecção automática da última versão do AzCopy
- Suporte a buildx (multi-platform) quando disponível
- Fallback para build padrão
- Testes automáticos
- Logs coloridos

### ✅ **Makefile Completo**
- Targets para todas as operações
- Testes de segurança
- Desenvolvimento e produção
- Documentação automática

### ✅ **GitHub Actions**
- Build automático diário
- Multi-platform (AMD64/ARM64)
- Testes de segurança
- Atualização automática do README

## 🔧 Como Usar

### 1. Build Local
```bash
# Versão atual do AzCopy
./build.sh version

# Build completo (build + test)
./build.sh build

# Apenas build
./build.sh build-only

# Teste de versão específica
./build.sh test 10.29.1
```

### 2. Usando Makefile
```bash
# Ver todas as opções
make help

# Build completo
make build

# Teste rápido
make quick-test

# Build multi-platform
make buildx-build

# Scan de segurança
make security-scan
```

### 3. Uso da Imagem

#### Básico
```bash
# Verificar versão
docker run --rm dfsrj/azcopy-sync:latest --version

# Ajuda
docker run --rm dfsrj/azcopy-sync:latest --help
```

#### Sincronização FileShare → Blob
```bash
docker run --rm \
  -e SAS_ORIGEM="se=2025-07-16..." \
  -e SAS_DESTINO="se=2025-07-16..." \
  dfsrj/azcopy-sync:latest \
  sync "https://source.file.core.windows.net/share?\$SAS_ORIGEM" \
       "https://dest.blob.core.windows.net/container?\$SAS_DESTINO" \
  --from-to=FileBlob --recursive --delete-destination
```

#### Kubernetes (usar com all-in-one.yaml)
```yaml
containers:
- name: azcopy-sync
  image: dfsrj/azcopy-sync:latest
  command: ["azcopy", "sync"]
  # ... resto da configuração
```

## 🔐 Deploy no Docker Hub

### 1. Login
```bash
./build.sh login
# ou
docker login
```

### 2. Build e Push
```bash
./build.sh build
```

### 3. Verificação
```bash
# Verificar no Docker Hub
docker run --rm dfsrj/azcopy-sync:latest --version

# Verificar tags
docker search dfsrj/azcopy-sync
```

## 🤖 Automação GitHub Actions

### 1. Configurar Secrets
No GitHub Repository Settings → Secrets:
- `DOCKERHUB_USERNAME`: seu usuário do Docker Hub
- `DOCKERHUB_TOKEN`: token de acesso do Docker Hub

### 2. Workflow Automático
- **Trigger**: Push, PR, Schedule (diário às 2h UTC)
- **Build**: Multi-platform (AMD64/ARM64)
- **Test**: Testes automáticos
- **Security**: Scan com Trivy
- **Update**: README automático

### 3. Estrutura dos Workflows
```
.github/workflows/
├── azcopy-docker.yml       # Build principal
```

## 📊 Comparação: Antes vs Depois

### Antes (Original)
```bash
# Dockerfile simples
FROM golang:alpine as build
RUN wget ... # comando complexo
FROM alpine:latest
COPY --from=build /azcopy/azcopy /usr/local/bin
```

### Depois (Otimizado)
```bash
# Multi-stage otimizado
FROM golang:1.23-alpine3.19 as builder
RUN apk add --no-cache build-base ca-certificates git curl
# Build com flags de otimização
RUN go build -a -installsuffix cgo -ldflags="-w -s" -o azcopy

FROM alpine:3.19 as release
# Usuário não-root, timezone, dependências mínimas
RUN adduser -u 1000 -S azcopy -G azcopy
USER azcopy
```

## 📈 Benefícios da Versão Melhorada

### 🔒 **Segurança**
- Usuário não-root
- Scan automático de vulnerabilidades
- Imagem Alpine minimal
- Certificados atualizados

### ⚡ **Performance**
- Multi-stage build
- Cache otimizado
- Binário otimizado com flags
- Imagem ~50MB vs ~100MB+

### 🛠️ **Manutenibilidade**
- Build automático
- Testes integrados
- Documentação clara
- Versionamento automático

### 🚀 **CI/CD Ready**
- GitHub Actions
- Multi-platform
- Testes automáticos
- Deploy automático

## 🎯 Próximos Passos

1. **Fazer login no Docker Hub**:
   ```bash
   ./build.sh login
   ```

2. **Build da primeira versão**:
   ```bash
   ./build.sh build
   ```

3. **Configurar GitHub Actions**:
   - Adicionar secrets do Docker Hub
   - Commit e push do código

4. **Testar integração com Kubernetes**:
   ```bash
   cd ../k8s
   # Atualizar all-in-one.yaml para usar dfsrj/azcopy-sync:latest
   ./simple-deploy.sh deploy
   ```

5. **Monitorar builds automáticos**:
   - Verificar GitHub Actions
   - Confirmar builds diários
   - Acompanhar atualizações de versão

## 📝 Notas Importantes

- A imagem é atualizada automaticamente quando há nova versão do AzCopy
- Suporta AMD64 e ARM64
- Compatível com o script original do Kubernetes
- Mantém compatibilidade com todos os comandos do AzCopy

**Versão atual**: AzCopy 10.29.1  
**Imagem**: `dfsrj/azcopy-sync:latest`  
**Autor**: Diogo Fernandes (dfs@outlook.com.br)
