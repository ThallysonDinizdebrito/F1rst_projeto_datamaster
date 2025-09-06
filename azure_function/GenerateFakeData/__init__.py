import random
from faker import Faker
import datetime
import json
import logging
import os
import azure.functions as func
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient

fake = Faker()

# Timer trigger function
def main(mytimer: func.TimerRequest) -> None:
    utc_timestamp = datetime.datetime.utcnow().replace(
        tzinfo=datetime.timezone.utc).isoformat()

    logging.info('Python timer trigger function ran at %s', utc_timestamp)

    try:
        # Recupera o nome da conta de storage (definido no Terraform como APP SETTING)
        account_name = os.environ["AZURE_STORAGE_ACCOUNT_NAME"]
        container_name = "raw"

        # Conecta no Storage via Managed Identity
        account_url = f"https://{account_name}.blob.core.windows.net"
        credential = DefaultAzureCredential()
        blob_service_client = BlobServiceClient(account_url=account_url, credential=credential)

        # Gera dados fake
        data = {
        "id": random.randint(1, 10000),
        "name": fake.name(),
        "email": fake.email(),
        "created_at": utc_timestamp
        }
        

        blob_name = f"dados_{datetime.datetime.utcnow().strftime('%Y%m%d%H%M%S')}.json"
        blob_data = json.dumps(data)

        # Envia para o container raw
        container_client = blob_service_client.get_container_client(container_name)
        container_client.upload_blob(name=blob_name, data=blob_data, overwrite=True)

        logging.info(f"Arquivo {blob_name} enviado com sucesso para o container {container_name}!")

    except Exception as e:
        logging.error(f"Erro ao processar a função: {e}")
