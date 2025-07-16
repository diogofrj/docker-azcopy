#!/bin/bash

# Script para interromper processos AzCopy em execução
# Útil quando o script principal trava

echo "=== Interrompendo processos AzCopy ==="

# Encontra e mata processos AzCopy
AZCOPY_PIDS=$(pgrep -f "azcopy" 2>/dev/null)

if [ -n "$AZCOPY_PIDS" ]; then
    echo "Processos AzCopy encontrados: $AZCOPY_PIDS"
    
    # Tenta interromper graciosamente primeiro
    echo "Tentando interromper graciosamente..."
    kill -TERM $AZCOPY_PIDS 2>/dev/null
    
    # Aguarda 5 segundos
    sleep 5
    
    # Verifica se ainda existem processos
    REMAINING_PIDS=$(pgrep -f "azcopy" 2>/dev/null)
    
    if [ -n "$REMAINING_PIDS" ]; then
        echo "Forçando terminação dos processos restantes..."
        kill -KILL $REMAINING_PIDS 2>/dev/null
    fi
    
    echo "✅ Processos AzCopy interrompidos"
else
    echo "ℹ️ Nenhum processo AzCopy encontrado"
fi

# Limpa jobs/logs temporários do AzCopy
echo "Limpando jobs temporários do AzCopy..."
rm -rf ~/.azcopy/jobs/* 2>/dev/null || true

echo "=== Limpeza concluída ==="
