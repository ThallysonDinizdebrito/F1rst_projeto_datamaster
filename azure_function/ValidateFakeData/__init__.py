import logging
import json
import azure.functions as func
from azure.storage.blob import BlobServiceClient
from pydantic import BaseModel, EmailStr, constr, ValidationError

# Modelo de validação
class Pessoa(BaseModel):
    CPF: constr(regex=r'^\d{11}$')  # exatamente 11 dígitos
    email: EmailStr
    idade: int

def main(event: func.EventGridEvent):
    logging.info('Evento recebido do Event Grid: %s', event.get_json())

    # Conexão Storage
    storage_connection = "<AzureWebJobsStorage>"
    blob_service_client = BlobServiceClient.from_connection_string(storage_connection)

    # Detalhes do evento
    event_data = event.get_json()
    blob_url = event_data['url']
    parts = blob_url.split('/')
    container_name = parts[-2]
    blob_name = parts[-1]

    # Lê blob
    blob_client = blob_service_client.get_blob_client(container=container_name, blob=blob_name)
    blob_data = blob_client.download_blob().readall()
    json_data = json.loads(blob_data)

    try:
        # Valida com Pydantic
        Pessoa(**json_data)
        target_container = "validado"
    except ValidationError as e:
        logging.warning(f"Validação falhou: {e}")
        target_container = "rejeitado"

    # Move para container final
    new_blob_client = blob_service_client.get_blob_client(container=target_container, blob=blob_name)
    new_blob_client.upload_blob(blob_data, overwrite=True)

    logging.info(f"Arquivo {blob_name} movido para {target_container}")
