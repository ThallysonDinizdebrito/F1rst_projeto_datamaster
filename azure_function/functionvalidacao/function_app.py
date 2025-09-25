import logging
import azure.functions as func
import json
import os
from azure.storage.blob import BlobServiceClient
from jsonschema import validate, ValidationError

# ================================================================
# Função auxiliar para carregar schema JSON
# ================================================================
def load_schema(filename):
    schema_path = os.path.join(os.path.dirname(__file__), filename)
    with open(schema_path, "r") as f:
        return json.load(f)

# Carrega todos os schemas
SCHEMAS = {
    "clientes-": load_schema("schema_clientes.json"),
    "drivers-": load_schema("schema_drivers.json"),
    "restaurantes-": load_schema("schema_restaurantes.json"),
    "items-": load_schema("schema_items.json"),
    "orders-": load_schema("schema_orders.json")
}

# ================================================================
# Função auxiliar para criar container se não existir
# ================================================================
def ensure_container(blob_service: BlobServiceClient, container_name: str):
    container_client = blob_service.get_container_client(container_name)
    if not container_client.exists():
        container_client.create_container()
        logging.info(f"Container '{container_name}' criado.")
    return container_client

# ================================================================
# Função auxiliar para enviar blob
# ================================================================
def mover_blob(blob_service: BlobServiceClient, blob_name: str, content: str, destino: str):
    try:
        container_client = ensure_container(blob_service, destino)
        container_client.upload_blob(name=blob_name, data=content, overwrite=True)
        logging.info(f"Blob {blob_name} enviado para '{destino}'")
    except Exception as e:
        logging.error(f"Erro ao enviar blob {blob_name} para {destino}: {e}")

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
    if not blob_url:
        logging.error("Blob URL não encontrada no evento!!")
        return

    logging.info(f"Blob recebido: {blob_url}")

    # Extrai container e blob_filename da URL
    parts = blob_url.split("/")
    container_name_from_url = parts[3]  # ex: 'raw'
    blob_filename = os.path.basename(blob_url) # ex: "orders-2025-09-22-224600017234.json"

    # Conecta no storage
    storage_conn_str = os.getenv("AzureWebJobsStorage") 
    blob_service = BlobServiceClient.from_connection_string(storage_conn_str)
    raw_container_client = blob_service.get_container_client(container_name_from_url)

    # ================================================================
    # Determina qual schema usar baseado no prefixo do arquivo
    # ================================================================
    current_schema = None
    pasta = None
    for prefix, schema in SCHEMAS.items():
        if blob_filename.startswith(prefix):
            current_schema = schema
            pasta = prefix.replace("-", "")  # subpasta dentro de "validado"
            break

    if current_schema is None:
        logging.warning(f"Nenhum schema correspondente encontrado para {blob_filename}.")
        return

    # ================================================================
    # Lê o blob do raw
    # ================================================================
    try:
        blob_data = raw_container_client.get_blob_client(blob_filename).download_blob().readall().decode("utf-8")
        data = json.loads(blob_data)
    except Exception as e:
        logging.error(f"Erro ao ler JSON ou baixar blob: {e}")
        return

    # ================================================================
    # Validação item por item
    # ================================================================
    for i, item in enumerate(data):
        try:
            validate(instance=item, schema=current_schema)
            item["VALIDACAO"] = "VALIDADO"
            item["MOTIVO"] = None
        except ValidationError as e:
            item["VALIDACAO"] = "REJEITADO"
            item["MOTIVO"] = e.message

    # ================================================================
    # Envia o JSON completo para container "validado", mantendo subpastas
    # ================================================================
    validado_container = "raw"
    destino_path = f"{pasta}/{blob_filename}"  # ex: "orders/orders-2025-09-22-224600017234.json"
    mover_blob(blob_service, destino_path, json.dumps(data, indent=2, ensure_ascii=False), validado_container)
    logging.info(f"Arquivo processado e enviado para {destino_path} no container '{validado_container}'")
