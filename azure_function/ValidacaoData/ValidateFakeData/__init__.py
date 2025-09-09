import logging
import azure.functions as func
import json

def main(event: func.EventGridEvent):
    logging.info('CloudEvent received')

    # O evento CloudEvent tem dados do blob em event.get_json()['data']
    cloud_event = event.get_json()
    logging.info(f"CloudEvent: {json.dumps(cloud_event)}")

    data = cloud_event.get("data", {})
    blob_url = data.get("url")
    logging.info(f"Blob URL: {blob_url}")

    if blob_url:
        # Aqui você pode chamar sua função de validação passando a URL ou conteúdo
        logging.info(f"Pronto para processar o blob: {blob_url}")
    else:
        logging.warning("Nenhuma URL de blob encontrada no evento")
