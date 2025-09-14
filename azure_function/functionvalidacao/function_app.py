import logging
import azure.functions as func
import json
# import os
# from azure.storage.blob import BlobServiceClient
# from jsonschema import validate, ValidationError

# ================================================================
# Cria a aplicação de funções
# ================================================================
app = func.FunctionApp()

# ================================================================
# Function disparada por Event Grid
# ================================================================
@app.event_grid_trigger(arg_name="azeventgrid")
def validate_fake_data(azeventgrid: func.EventGridEvent):
    logging.info("Evento do Event Grid recebido.")

    # Converte os dados do evento em JSON
    event_data = azeventgrid.get_json()
    logging.info(f"Evento recebido: {json.dumps(event_data)}")

    # Pega a URL do blob que disparou o evento
    blob_url = event_data.get("url")
    logging.info(f"Blob recebido: {blob_url}")

    if not blob_url:
        logging.error("Blob URL não encontrada no evento!")
        return

    blob_name = blob_url.split("/")[-1]
    print(blob_name)

#     # ================================================================
#     # Configuração de storage e containers
#     # ================================================================
#     STORAGE_CONN_STR = os.getenv("AzureWebJobsStorage")
#     RAW_CONTAINER = os.getenv("RAW_CONTAINER_NAME", "raw")
#     VALIDADO_CONTAINER = "validado"
#     REJEITADO_CONTAINER = "rejeitado"

#     # ================================================================
#     # Carrega schema JSON
#     # ================================================================
#     SCHEMA_FILE = os.path.join(os.path.dirname(__file__), "schema.json")
#     with open(SCHEMA_FILE, "r") as f:
#         SCHEMA = json.load(f)

#     # ================================================================
#     # Conecta no Blob Storage
#     # ================================================================
#     blob_service = BlobServiceClient.from_connection_string(STORAGE_CONN_STR)
#     raw_container_client = blob_service.get_container_client(RAW_CONTAINER)

#     try:
#         blob_data = raw_container_client.get_blob_client(blob_name).download_blob().readall().decode("utf-8")
#         data = json.loads(blob_data)
#     except Exception as e:
#         logging.error(f"Erro ao ler JSON ou baixar blob: {e}")
#         mover_blob(blob_service, blob_name, blob_data if 'blob_data' in locals() else "", REJEITADO_CONTAINER)
#         return

#     try:
#         # Validação usando JSON Schema
#         validate(instance=data, schema=SCHEMA)
#         logging.info(f"JSON válido ok - {blob_name} enviado para '{VALIDADO_CONTAINER}'")
#         mover_blob(blob_service, blob_name, blob_data, VALIDADO_CONTAINER)
#     except ValidationError as e:
#         logging.warning(f"JSON inválido x - {blob_name} enviado para '{REJEITADO_CONTAINER}': {e.message}")
#         mover_blob(blob_service, blob_name, blob_data, REJEITADO_CONTAINER)


# # ================================================================
# # Função auxiliar para mover blob
# # ================================================================
# def mover_blob(blob_service: BlobServiceClient, blob_name: str, content: str, destino: str):
#     try:
#         container_client = blob_service.get_container_client(destino)
#         container_client.upload_blob(name=blob_name, data=content, overwrite=True)
#         logging.info(f"Blob {blob_name} movido para {destino}")
#     except Exception as e:
#         logging.error(f"Erro ao mover blob {blob_name} para {destino}: {e}")
