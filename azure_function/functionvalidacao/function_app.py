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
    # Lê o blob raw
    # ================================================================
    try:
        blob_data = raw_container_client.get_blob_client(blob_path).download_blob().readall().decode("utf-8")
        data = json.loads(blob_data)
    except Exception as e:
        logging.error(f"Erro ao ler JSON ou baixar blob: {e}")
        mover_blob(blob_service, blob_path, blob_data if 'blob_data' in locals() else "", rejeitado_container)
        return

    # ================================================================
    # Validação item por item
    # ================================================================
    valid_items = []
    invalid_items = []

    for i, item in enumerate(data):
        try:
            validate(instance=item, schema=SCHEMA)
            valid_items.append(item)
            logging.info(f"Item {i} válido: {item['id']}")
        except ValidationError as e:
            invalid_items.append({"item": item, "erro": e.message})
            logging.warning(f"Item {i} inválido: {item['id']} - Motivo: {e.message}")

    # ================================================================
    # Move blobs separados para validado e rejeitados
    # ================================================================
    if valid_items:
        mover_blob(blob_service, blob_path, json.dumps(valid_items, indent=2), validado_container)
        logging.info(f"{len(valid_items)} itens válidos enviados para '{validado_container}'")

    if invalid_items:
        invalid_data = [i["item"] for i in invalid_items]
        mover_blob(blob_service, blob_path, json.dumps(invalid_data, indent=2), rejeitado_container)
        logging.warning(f"{len(invalid_items)} itens inválidos enviados para '{rejeitado_container}'")