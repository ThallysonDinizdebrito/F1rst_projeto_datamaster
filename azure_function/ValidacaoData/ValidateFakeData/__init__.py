import logging
import azure.functions as func
import json

def main(event: func.EventGridEvent):
    logging.info('EventGridEvent received')

    # O evento tem dados do blob
    data = event.get_json()
    logging.info(f"Data: {json.dumps(data)}")

    blob_url = data.get("url")
    logging.info(f"Blob URL: {blob_url}")

    # Aqui você pode baixar/processar o blob
    # Ex: chamar sua função de validação passando a URL ou conteúdo
