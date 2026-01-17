import azure.functions as func
import os
import json
import random
import string
from faker import Faker
from datetime import datetime
from azure.storage.blob import BlobServiceClient


# =========================
# Funções auxiliares
# =========================
def gerar_id(prefixo, tamanho=6):
    return prefixo + ''.join(random.choices(string.digits, k=tamanho))

def gerar_cnpj():
    return ''.join(random.choices(string.digits, k=14))

def gerar_cpf():
    return ''.join(random.choices(string.digits, k=11))

def gerar_placa():
    letras = ''.join(random.choices(string.ascii_uppercase, k=3))
    numeros = ''.join(random.choices(string.digits, k=4))
    return f"{letras}-{numeros}"

def agora():
    # return datetime.now().strftime("%Y-%m-%d-%H-%M-%S-%f")
    return datetime.now().strftime("%Y-%m-%d-%H-%M-%S.%f")

# =========================
# Função principal do Azure Function
# =========================
def main(mytimer: func.TimerRequest) -> None:
    try:
        fake = Faker("pt_BR")

        # Timestamp para arquivos
        timestamp = datetime.now().strftime("%Y-%m-%d-%H%M%S%f")

        # =========================
        # Criação das tabelas
        # =========================
        # Entregadores (drivers)
        entregadores = []
        for _ in range(1):
            entregadores.append({
                "DriversID": gerar_id("D"),
                "nome": fake.name(),
                "endereco": fake.address(),
                "veiculo": random.choice(["moto", "carro", "bicicleta"]),
                "placa": gerar_placa(),
                "created_at": agora()
            })

        # Restaurantes (merchants)
        restaurantes = []
        for _ in range(1):
            restaurantes.append({
                "MerchantID": gerar_id("R"),
                "nome": fake.company(),
                "endereco": fake.address(),
                "CNPJ": gerar_cnpj(),
                "created_at": agora()
            })



        # Clientes
        clientes = []
        for _ in range(1):
            clientes.append({
                "ClientID": gerar_id("C"),
                "nome": fake.name(),
                "endereco": fake.address(),
                "CPF": gerar_cpf(),
                "tipo_pagamento": random.choice(["PIX", "CARTÃO CREDITO", "CARTÃO DEBITO", "VOUCHER"]),
                "created_at": agora()
            })

        # Itens (produtos) vinculados ao restaurante
        categorias = ["Hamburguer", "Pizza", "Comida Japonesa", "Sobremesa", "Bebida"]
        produtos = []
        for restaurante in restaurantes:
            for _ in range(8):
                produtos.append({
                    "ItemID": gerar_id("I"),
                    "nome": fake.word(),
                    "categoria": random.choice(categorias),
                    "preco": round(random.uniform(10, 120), 2),
                    "MerchantID": restaurante["MerchantID"],
                    "created_at": agora()
                })

        # Pedidos
        pedidos = []
        for _ in range(8):
            cliente = random.choice(clientes)
            restaurante = random.choice(restaurantes)
            entregador = random.choice(entregadores)

            # Escolhe 2 a 4 produtos do restaurante escolhido
            itens_escolhidos = random.sample(
                [p for p in produtos if p["MerchantID"] == restaurante["MerchantID"]],
                k=random.randint(2, 4)
            )

            itens_detalhados = []
            valor_total = 0
            quantidade_total = 0

            for item in itens_escolhidos:
                qtd = random.randint(1, 3)
                valor_item = item["preco"] * qtd
                itens_detalhados.append({
                    "ItemID": item["ItemID"],
                    "nome": item["nome"],
                    "categoria": item["categoria"],
                    "preco": item["preco"],
                    "quantidade": qtd,
                    "valor_total_item": round(valor_item, 2),
                    "created_at": agora()
                })
                valor_total += valor_item
                quantidade_total += qtd

            pedidos.append({
                "PedidoID": gerar_id("P"),
                "ClientID": cliente["ClientID"],
                "MerchantID": restaurante["MerchantID"],
                "DriversID": entregador["DriversID"],
                "Produtos": itens_detalhados,
                "quantidade_total": quantidade_total,
                "valor_total": round(valor_total, 2),
                "tipo_pagamento": cliente["tipo_pagamento"],
                "created_at": agora()
            })

        # =========================
        # Preparar dados para upload
        # =========================
        json_files = {
            f"clientes-{timestamp}.json": clientes,
            f"restaurantes-{timestamp}.json": restaurantes,
            f"items-{timestamp}.json": produtos,
            f"drivers-{timestamp}.json": entregadores,
            f"orders-{timestamp}.json": pedidos,
        }

        # =========================
        # Conectar ao Blob Storage
        # =========================
        connect_str = os.getenv("AzureWebJobsStorage")
        if not connect_str:
            raise ValueError("A variável de ambiente AzureWebJobsStorage não está definida!")

        container_name = "source"
        blob_service_client = BlobServiceClient.from_connection_string(connect_str)
        container_client = blob_service_client.get_container_client(container_name)

        # Cria container se não existir
        try:
            container_client.create_container()
        except Exception:
            pass  # ignora se já existe

        # =========================
        # Upload de cada arquivo JSON
        # =========================
        for filename, data in json_files.items():
            blob_name = f"{filename}"  # tudo direto no raw, sem subpastas
            json_data = json.dumps(data, ensure_ascii=False, indent=2)
            blob_client = container_client.get_blob_client(blob_name)
            blob_client.upload_blob(json_data, overwrite=True)
            print(f"[OK] Arquivo enviado para {container_name}/{blob_name}")

    except Exception as e:
        print(f"[ERRO] {str(e)}")
