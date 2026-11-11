## Plugin

- id:
- repositório:
- commit (40 caracteres):
- versão:
- programas que executa (`permissions`):
- app externo (acesso total)? sim / não — se sim, o Release com os executáveis:

## Conferi

- [ ] O manifesto, `README.md` e `LICENSE` estão na raiz do repositório (ou em `path`).
- [ ] `permissions` no índice é igual a `[permissions] exec` do manifesto.
- [ ] Instalei localmente com `miniutils --instalar <id> registry.json` (índice local, sem chave).
- [ ] O plugin não executa nada além do que descrevi.
- [ ] (app externo) Os executáveis foram gerados pelo CI a partir da tag do `commit`, e os
      `sha256` do índice são os do Release.
