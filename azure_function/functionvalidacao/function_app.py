import logging
import azure.functions as func
import json
from azure.storage.blob import BlobServiceClient
from jsonschema import validate, ValidationError
import os

# Configurações de container
STORAGE_CONN_STR = os.getenv("AzureWebJobsStorage")
RAW_CONTAINER = os.getenv("RAW_CONTAINER_NAME", "raw")
VALIDADO_CONTAINER = "validado"
REJEITADO_CONTAINER = "rejeitado"

# Carrega schema
SCHEMA_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), "schema_json", "schema.json")
with open(SCHEMA_PATH, "r") as f:
    SCHEMA = json.load(f)


def main(azeventgrid: func.EventGridEvent):
    logging.info("Evento do Event Grid recebido.")

    event_data = azeventgrid.get_json()
    blob_url = event_data.get("url")
    if not blob_url:
        logging.error("Blob URL não encontrada no evento!")
        return

    blob_name = blob_url.split("/")[-1]
    blob_service = BlobServiceClient.from_connection_string(STORAGE_CONN_STR)
    raw_container_client = blob_service.get_container_client(RAW_CONTAINER)

    try:
        blob_data = raw_container_client.get_blob_client(blob_name).download_blob().readall().decode("utf-8")
        data = json.loads(blob_data)
    except Exception as e:
        logging.error(f"Erro ao ler JSON ou baixar blob: {e}")
        return

    try:
        validate(instance=data, schema=SCHEMA)
        logging.info(f"JSON válido [ OK] - {blob_name} enviado para '{VALIDADO_CONTAINER}'")
    except ValidationError as e:
        logging.warning(f"JSON inválido [X] - {blob_name}: {e.message}")

