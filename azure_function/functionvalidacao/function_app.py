import logging
import azure.functions as func
import json
import os
from azure.storage.blob import BlobServiceClient, ContainerClient
from jsonschema import validate, ValidationError

# ================================================================
# Função auxiliar para carregar schema JSON
# ================================================================
def load_schema(filename="schema.json"):
    schema_path = os.path.join(os.path.dirname(__file__), filename)
    with open(schema_path, "r") as f:
        return json.load(f)

SCHEMA = load_schema()

# ================================================================
# Função auxiliar para criar container se não existir
# ================================================================
def ensure_container(blob_service: BlobServiceClient, container_name: str):
    try:
        container_client = blob_service.get_container_client(container_name)
        if not container_client.exists():
            container_client.create_container()
            logging.info(f"Container '{container_name}' criado.")
        return container_client
    except Exception as e:
        logging.error(f"Erro ao garantir container '{container_name}': {e}")
        raise

# ================================================================
# Função auxiliar para mover blob
# ================================================================
def mover_blob(blob_service: BlobServiceClient, blob_name: str, content: str, destino: str):
    try:
        container_client = ensure_container(blob_service, destino)
        container_client.upload_blob(name=blob_name, data=content, overwrite=True)
        logging.info(f"Blob {blob_name} movido para '{destino}'")
    except Exception as e:
        logging.error(f"Erro ao mover blob {blob_name} para {destino}: {e}")

# Cria a aplicação de funções
app = func.FunctionApp()

# Function disparada por Event Grid
@app.event_grid_trigger(arg_name="azeventgrid")
def validate_fake_data(azeventgrid: func.EventGridEvent):
    logging.info("Evento do Event Grid recebido.")

    # Converte os dados do evento em JSON
    event_data = azeventgrid.get_json()
    logging.info(f"Evento recebido: {json.dumps(event_data)}")

    # Pega a URL do blob que disparou o evento
    blob_url = event_data.get("url")
    if not blob_url:
        logging.error("Blob URL não encontrada no evento!!")
        return
    logging.info(f"Blob recebido: {blob_url}")

    # Extrai container e blob_path da URL
    parts = blob_url.split("/")
    container_name_from_url = parts[3]  # ex: 'raw'
    blob_path = "/".join(parts[4:])      # ex: 'json/2025-09-14-233810.json'

    storage_conn_srt = os.getenv("AzureWebJobsStorage") 
    blob_service = BlobServiceClient.from_connection_string(storage_conn_srt)
    raw_container_client = blob_service.get_container_client(container_name_from_url)

    # Containers de destino
    validado_container = "validado"
    rejeitado_container = "rejeitados"

    # ================================================================
    # Lê o blob
    # ================================================================
    try:
        blob_data = raw_container_client.get_blob_client(blob_path).download_blob().readall().decode("utf-8")
        data = json.loads(blob_data)
    except Exception as e:
        logging.error(f"Erro ao ler JSON ou baixar blob: {e}")
        mover_blob(blob_service, blob_path, blob_data if 'blob_data' in locals() else "", rejeitado_container)
        return

    # ================================================================
    # Validação JSON
    # ================================================================
    try:
        validate(instance=data, schema=SCHEMA)
        logging.info(f"JSON válido ✔ - {blob_path} enviado para '{validado_container}'")
        mover_blob(blob_service, blob_path, blob_data, validado_container)
    except ValidationError as e:
        logging.warning(f"JSON inválido ✘ - {blob_path} enviado para '{rejeitado_container}': {e.message}")
        mover_blob(blob_service, blob_path, blob_data, rejeitado_container)
