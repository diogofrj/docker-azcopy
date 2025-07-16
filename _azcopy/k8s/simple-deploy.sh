#!/bin/bash

# Script simples para deploy do AzCopy Sync CronJob
set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

show_usage() {
    echo "Uso: $0 [deploy|undeploy|status|logs|run-now|update-tokens]"
    echo ""
    echo "Comandos:"
    echo "  deploy              - Aplica todos os manifestos"
    echo "  undeploy            - Remove todos os recursos"
    echo "  status              - Mostra status do CronJob"
    echo "  logs                - Exibe logs do último job"
    echo "  run-now             - Executa job manualmente"
    echo "  update-tokens <o> <d> - Atualiza SAS tokens"
    echo ""
    echo "Exemplos:"
    echo "  $0 deploy"
    echo "  $0 update-tokens 'se=2025...' 'se=2025...'"
    echo "  $0 status"
}

case "${1:-help}" in
    deploy)
        echo -e "${BLUE}[INFO]${NC} Fazendo deploy dos recursos..."
        kubectl apply -f all-in-one.yaml
        echo -e "${GREEN}[SUCCESS]${NC} Deploy concluído!"
        ;;
    undeploy)
        echo -e "${BLUE}[INFO]${NC} Removendo recursos..."
        kubectl delete -f all-in-one.yaml --ignore-not-found=true
        echo -e "${GREEN}[SUCCESS]${NC} Recursos removidos!"
        ;;
    status)
        echo -e "${BLUE}[INFO]${NC} Status do CronJob:"
        kubectl get cronjob azcopy-sync-cronjob -o wide
        echo ""
        echo -e "${BLUE}[INFO]${NC} Jobs recentes:"
        kubectl get jobs -l app=azcopy-sync --sort-by=.metadata.creationTimestamp
        ;;
    logs)
        echo -e "${BLUE}[INFO]${NC} Logs do último job:"
        LAST_JOB=$(kubectl get jobs -l app=azcopy-sync --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1].metadata.name}' 2>/dev/null || echo "")
        if [ -n "$LAST_JOB" ]; then
            kubectl logs job/$LAST_JOB
        else
            echo "Nenhum job encontrado"
        fi
        ;;
    run-now)
        echo -e "${BLUE}[INFO]${NC} Executando job manualmente..."
        kubectl create job azcopy-sync-manual-$(date +%s) --from=cronjob/azcopy-sync-cronjob
        echo -e "${GREEN}[SUCCESS]${NC} Job manual criado!"
        ;;
    update-tokens)
        if [ $# -ne 3 ]; then
            echo -e "${RED}[ERROR]${NC} Uso: $0 update-tokens <sas_origem> <sas_destino>"
            exit 1
        fi
        echo -e "${BLUE}[INFO]${NC} Atualizando SAS tokens..."
        SAS_ORIGEM_B64=$(echo -n "$2" | base64 -w 0)
        SAS_DESTINO_B64=$(echo -n "$3" | base64 -w 0)
        
        kubectl patch secret azcopy-sas-tokens -p="{\"data\":{\"sas-origem\":\"$SAS_ORIGEM_B64\",\"sas-destino\":\"$SAS_DESTINO_B64\"}}"
        echo -e "${GREEN}[SUCCESS]${NC} SAS tokens atualizados!"
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        echo -e "${RED}[ERROR]${NC} Comando desconhecido: $1"
        show_usage
        exit 1
        ;;
esac
