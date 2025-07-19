#!/bin/bash

# Script para criar um Storage Account no Azure usando Azure CLI

# Parâmetros
RESOURCE_GROUP="RG-AZCOPY-DESTINO"
STORAGE_ACCOUNT_NAME="sadestinohr"
LOCATION="eastus2"
SKU="Standard_LRS"
KIND="StorageV2"
CONTAINER_NAME="blob-recebidos"

# Criar o resource group se não existir
echo "Criando resource group: $RESOURCE_GROUP"
az group create --name "$RESOURCE_GROUP" --location "$LOCATION"


echo "Criando Storage Account: $STORAGE_ACCOUNT_NAME no resource group: $RESOURCE_GROUP"

az storage account create \
  --name "$STORAGE_ACCOUNT_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --sku "$SKU" \
  --kind "$KIND"

if [ $? -eq 0 ]; then
  echo "Storage Account criado com sucesso: $STORAGE_ACCOUNT_NAME"
else
  echo "Falha ao criar o Storage Account"
  exit 1
fi

echo "Criando container: $CONTAINER_NAME no Storage Account: $STORAGE_ACCOUNT_NAME"

az storage container create \
  --name "$CONTAINER_NAME" \
  --account-name "$STORAGE_ACCOUNT_NAME"

