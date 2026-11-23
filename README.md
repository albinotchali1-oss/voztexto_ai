# VozTexto AI

Aplicativo Flutter para conversão de vídeo em áudio e transcrição online de
arquivos de áudio. O desenvolvimento começa pelo Android.

## Estado atual

- Identidade visual e navegação principais implementadas.
- Conversão de MP4 em MP3 já disponível no dispositivo.
- Transcrição online disponível através de FastAPI + Groq.
- O único modelo usado é `whisper-large-v3-turbo`.
- Não há fallback automático, plano pago ou outro fornecedor.
- Tradução e histórico ainda não foram implementados.

## Organização

- `lib/core/`: tema e cores compartilhadas.
- `lib/features/converter/`: seleção de vídeo e conversão MP4 → MP3.
- `lib/features/transcription/`: tela, serviço e modelo da transcrição.
- `lib/features/translation/` e `lib/features/history/`: funcionalidades reservadas.
- `lib/shared/`: navegação e componentes compartilhados.
- `backend/`: API FastAPI separada do aplicativo Flutter.

## Backend FastAPI

Consulte `backend/README.md` para os detalhes completos.

Dependências Python:

```text
fastapi
uvicorn[standard]
groq
python-multipart
python-dotenv
pydantic
pydantic-settings
```

Instalação e execução no Parrot OS:

```bash
cd /home/tchali/Meus-projetos/voztexto_ai/backend
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
pip install -r requirements.txt
cp -n .env.example .env
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Configure `GROQ_API_KEY` apenas no ficheiro local `backend/.env`. O ficheiro
`.env` está protegido pelo `.gitignore`.

Verificação básica:

```bash
curl http://127.0.0.1:8000/health
curl -F "file=@/caminho/para/audio.mp3" -F "language=pt" http://127.0.0.1:8000/api/transcriptions
```

## Aplicativo Flutter

Para o Android emulado:

```bash
cd /home/tchali/Meus-projetos/voztexto_ai
flutter pub get
flutter run --dart-define=VOZTEXTO_API_BASE_URL=http://10.0.2.2:8000
```

Para um telefone físico na mesma rede do Parrot OS:

```bash
cd /home/tchali/Meus-projetos/voztexto_ai
flutter pub get
flutter run --dart-define=VOZTEXTO_API_BASE_URL=http://IP_DO_PARROT:8000
```

Descubra o IP no Parrot OS com `hostname -I` e use um endereço da rede local.

## Segurança e limites

- A chave da Groq nunca fica no Flutter.
- Os ficheiros são enviados apenas ao backend próprio e encaminhados à Groq.
- Os ficheiros não são guardados permanentemente pelo backend.
- HTTP 429 é apresentado como `free_limit_reached`.
- Ao atingir o limite gratuito, a aplicação informa para aguardar a renovação;
  não tenta outro fornecedor nem repete automaticamente o pedido.