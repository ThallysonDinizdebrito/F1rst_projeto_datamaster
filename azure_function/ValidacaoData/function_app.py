import logging
import azure.functions as func
import json

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

    # Aqui você pode implementar a lógica de validação
    if blob_url and blob_url.endswith(".txt"):
        logging.info("Arquivo válido! Enviar para o container 'validado'.")
        # TODO: código para copiar/mover para 'validado'
    else:
        logging.warning("Arquivo rejeitado! Enviar para o container 'rejeitado'.")
        # TODO: código para copiar/mover para 'rejeitado'
