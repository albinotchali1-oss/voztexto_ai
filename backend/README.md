# VozTexto AI — Backend

Backend FastAPI para envio de áudio à API Groq. O único modelo utilizado é
`whisper-large-v3-turbo`; não há fallback para outro fornecedor nem ativação de
planos pagos.

## Instalação no Parrot OS

```bash
cd /home/tchali/Meus-projetos/voztexto_ai/backend
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
pip install -r requirements.txt
cp .env.example .env
```

Edite `.env` e coloque apenas a chave pessoal em `GROQ_API_KEY`.

## Executar

```bash
cd /home/tchali/Meus-projetos/voztexto_ai/backend
source .venv/bin/activate
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Para verificar:

```bash
curl http://127.0.0.1:8000/health
curl -F "file=@/caminho/para/audio.mp3" -F "language=pt" http://127.0.0.1:8000/api/transcriptions
```

## Endpoint

`POST /api/transcriptions`

Envio `multipart/form-data`:

- `file`: áudio entre os formatos suportados, máximo 25 MB.
- `language`: `pt` ou `en`.

Resposta:

```json
{
  "success": true,
  "transcription": "Texto reconhecido no áudio.",
  "language": "pt",
  "model": "whisper-large-v3-turbo"
}
```

## Limites gratuitos

Com HTTP 429, o backend devolve `free_limit_reached` e interrompe o pedido.
Não existem repetições automáticas nem outro fornecedor. Aguarde a renovação do
limite gratuito da Groq antes de enviar novos ficheiros.

## Comunicação Android

No mesmo Wi-Fi, descubra o endereço IPv4 do Parrot OS:

```bash
hostname -I
```

No Flutter, configure `VOZTEXTO_API_BASE_URL=http://IP_DO_PARROT:8000` ao executar,
ou ajuste o endereço padrão de `TranscriptionService`.

Emulador Android: use `http://10.0.2.2:8000` quando o backend roda no PC.
Dispositivo físico: use o IP da rede local do PC e mantenha PC e telefone na
mesma rede.
