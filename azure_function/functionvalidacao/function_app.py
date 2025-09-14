import logging
import azure.functions as func
import json
import os
from azure.storage.blob import BlobServiceClient

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
    logging.info(f"Blob recebido: {blob_url}")

    # lógica de validação
    if not blob_url:
        logging.error("Blob URL não encontrada no evento!")
        return

    blob_name = blob_url.split("/")[-1]

    storage_conn_srt = os.getenv("AzureWebJobsStorage") 
    raw_container = os.getenv("RAW_CONTAINER_NAME", "raw") 
    Validado_container = "validado" 
    Rejeitado_container = "rejeitado" 

    container_name = os.getenv("RAW_CONTAINER_NAME", "raw")

    # ================================================================
    # Carrega schema JSON
    # ================================================================

def load_schema(filename="schema.json"):
    schema_path = os.path.join(os.path.dirname(__file__), filename)
    with open(schema_path, "r") as f:
        return json.load(f)
    
    SCHEMA = load_schema()

    # ================================================================
    # Conecta no Blob Storage
    # ================================================================
    blob_service = BlobServiceClient.from_connection_string(storage_conn_srt)
    raw_container_client = blob_service.get_container_client(raw_container)


