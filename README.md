# VozTexto AI

Aplicativo Flutter para apoiar a conversão, transcrição e tradução de arquivos
de áudio e vídeo. O desenvolvimento começa pelo Android.

## Estado atual

A primeira versão contém a identidade visual e a página inicial com atalhos para
Conversor, Transcrição, Tradução e Histórico. Esses recursos e a seleção de
arquivos ainda não foram implementados; a interface informa essa limitação e
não simula o processamento.

## Organização do código

- `lib/core/`: tema, cores e utilitários compartilhados.
- `lib/features/`: telas e componentes agrupados por funcionalidade.
- `lib/services/`: espaço reservado para integrações de mídia e API.
- `lib/shared/`: espaço reservado para componentes reutilizáveis.
- `assets/`: imagens e ícones da aplicação.

## Executar e validar

Com o Flutter instalado e um dispositivo Android conectado ou um emulador aberto:

```bash
flutter pub get
flutter run
```

Para verificar o código e os testes automatizados:

```bash
flutter analyze
flutter test
```

Para gerar uma versão de depuração para Android:

```bash
flutter build apk --debug
```

Ainda não há backend nem serviços de conversão, transcrição ou tradução.