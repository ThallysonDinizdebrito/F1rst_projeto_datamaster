import logging
import json
import azure.functions as func
from azure.storage.blob import BlobServiceClient
from pydantic import BaseModel, EmailStr, conint, ValidationError
import os

# Modelo de validação baseado no JSON real
class Pessoa(BaseModel):
    id: str
    nome: str
    email: EmailStr
    telefone: str
    endereco: str
    idade: conint(ge=18, le=100)  # idade entre 18 e 100
    criado_em: str

def main(event: func.EventGridEvent):
    logging.info('Evento recebido do Event Grid: %s', event.get_json())

    # Conexão com o Storage
    storage_connection = os.getenv("AzureWebJobsStorage")
    blob_service_client = BlobServiceClient.from_connection_string(storage_connection)

    # Detalhes do evento
    event_data = event.get_json()
    blob_url = event_data['data']['url']
    parts = blob_url.split('/')
    container_name = parts[-2]
    blob_name = parts[-1]

    # Lê blob
    blob_client = blob_service_client.get_blob_client(container=container_name, blob=blob_name)
    blob_data = blob_client.download_blob().readall()
    registros = json.loads(blob_data)

    # Containers de destino
    valid_container = os.getenv("VALIDATED_CONTAINER_NAME", "validado")
    reject_container = os.getenv("REJECTED_CONTAINER_NAME", "rejeitado")

    validos = []
    rejeitados = []

    for registro in registros:
        try:
            Pessoa(**registro)
            validos.append(registro)
        except ValidationError as e:
            logging.warning(f"Registro inválido: {e}")
            rejeitados.append(registro)

    # Salva registros válidos
    if validos:
        blob_client_valid = blob_service_client.get_blob_client(
            container=valid_container,
            blob=blob_name
        )
        blob_client_valid.upload_blob(json.dumps(validos, ensure_ascii=False, indent=2), overwrite=True)

    # Salva registros inválidos
    if rejeitados:
        blob_client_reject = blob_service_client.get_blob_client(
            container=reject_container,
            blob=blob_name
        )
        blob_client_reject.upload_blob(json.dumps(rejeitados, ensure_ascii=False, indent=2), overwrite=True)

    logging.info(f"Arquivo {blob_name} processado: {len(validos)} válidos, {len(rejeitados)} rejeitados")
