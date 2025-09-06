import datetime
import json
import os
import random
import logging
from faker import Faker
from azure.storage.blob import BlobServiceClient
import azure.functions as func


fake = Faker()

def main(mytimer: func.TimerRequest) -> None:
    utc_timestamp = datetime.datetime.utcnow().strftime("%Y%m%d_%H%M%S")

    # Gera dados fake
    data = {
        "id": random.randint(1, 10000),
        "name": fake.name(),
        "email": fake.email(),
        "created_at": utc_timestamp
    }

    # Conexão com Blob Storage via Service Principal (usando env var)
    connection_string = os.environ["AZURE_STORAGE_CONNECTION_STRING"]
    blob_service_client = BlobServiceClient.from_connection_string(connection_string)

    # Container "raw"
    container_name = os.environ.get("RAW_CONTAINER_NAME", "raw")
    blob_name = f"fake_data_{utc_timestamp}.json"

    # Serializa JSON
    file_content = json.dumps(data, indent=4, ensure_ascii=False)

    # Upload para o Blob
    blob_client = blob_service_client.get_blob_client(container=container_name, blob=blob_name)
    blob_client.upload_blob(file_content, overwrite=True)

    logging.info(f"Arquivo enviado para container '{container_name}' com nome '{blob_name}'")
    logging.info(f"Conteúdo: {data}")
