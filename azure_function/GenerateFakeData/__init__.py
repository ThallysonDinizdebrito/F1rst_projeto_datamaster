import azure.functions as func
from azure.storage.blob import BlobServiceClient
from datetime import datetime
from faker import Faker
import json
import random
import os

def main(mytimer: func.TimerRequest) -> None:
    try:
        fake = Faker()
        dados = []
        for _ in range(5):
            dados.append({
                "id": fake.uuid4(),
                "nome": fake.name(),
                "email": fake.email(),
                "telefone": fake.phone_number(),
                "endereco": fake.address(),
                "idade": random.randint(18, 80),
                "criado_em": datetime.utcnow().isoformat()
            })

        # Pega a connection string da variável de ambiente
        connect_str = os.getenv("AZURE_STORAGE_CONNECTION_STRING")
        if not connect_str:
            raise ValueError("A variável de ambiente AZURE_STORAGE_CONNECTION_STRING não está definida!")

        container_name = os.getenv("RAW_CONTAINER_NAME", "raw")
        directory = os.getenv("BLOB_DIRECTORY", "json")
        file_name = f"{directory}/{datetime.utcnow().strftime('%Y-%m-%d-%H%M%S')}.json"

        # Conecta ao Blob Storage
        blob_service_client = BlobServiceClient.from_connection_string(connect_str)
        container_client = blob_service_client.get_container_client(container_name)

        # Cria container se não existir
        try:
            container_client.create_container()
        except Exception:
            pass

        # Faz upload do JSON
        json_data = json.dumps(dados, ensure_ascii=False, indent=2)
        blob_client = container_client.get_blob_client(file_name)
        blob_client.upload_blob(json_data, overwrite=True)

        print(f"[OK] Arquivo salvo em {container_name}/{file_name}")

    except Exception as e:
        print(f"[ERRO] {str(e)}")
