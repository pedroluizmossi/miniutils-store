# Loja de plugins do MiniUtils

Índice dos plugins da comunidade para o [MiniUtils](https://github.com/pedroluizmossi/hub-app-rust),
o hub de mini-apps para o desktop Linux. Este repositório guarda **só o índice**: cada plugin
vive no repositório do autor, e o índice aponta para um commit revisado dele.

## Usar no MiniUtils

Em Configurações > **Loja de plugins**, informe:

| Campo | Valor |
|---|---|
| Índice | `https://raw.githubusercontent.com/pedroluizmossi/miniutils-store/main/registry.json` |
| Chave pública | `070dba03dd19902eeed1d02573272be1fa3fc263f4a8eda3cf10b3beca98464e` |

Pela linha de comando:

```sh
miniutils --loja https://raw.githubusercontent.com/pedroluizmossi/miniutils-store/main/registry.json --chave 070dba03dd19902eeed1d02573272be1fa3fc263f4a8eda3cf10b3beca98464e
```

O MiniUtils confere a assinatura (`registry.json.sig`) com essa chave e recusa um índice
adulterado. Na instalação, clona o repositório do plugin, confere que veio exatamente o
`commit` do índice e mostra o que o plugin vai executar antes de instalar.

## Enviar um plugin

1. Publique o plugin num repositório público próprio, com `manifest.toml`, `README.md` e
   `LICENSE` na raiz (e `view.slint` + `main.rhai`, se tiver tela própria, mais `ui/*.slint`
   e `assets/*.png|jpg|svg` se precisar). O formato está no topo de `src/core/plugins.rs`
   e `src/apps/plugin.rs` do MiniUtils.
2. Abra um pull request aqui acrescentando o plugin em `registry.json`:
   - `id`: `io.github.<seu-usuário>.<nome>` (minúsculas, `.`, `-`, `_`); `cyber.*` é reservado;
   - `repo`: endereço `https://` do repositório; `path`, se o plugin estiver numa subpasta;
   - `commit`: o SHA completo (40 caracteres) da versão a revisar;
   - `permissions`: exatamente os programas de `[permissions] exec` do manifesto;
   - `net`: exatamente os domínios de `[permissions] net` (se o plugin usa a rede);
   - `uses`: exatamente os provedores de `uses` (se o plugin lê CPU, Docker etc.);
   - `license`: obrigatória.
3. Para atualizar, outro pull request trocando `commit` e `version`.

Não assine nada: quem mantém a loja revisa o código daquele commit e assina o índice.

## O que é revisado

- O manifesto valida no MiniUtils, e as permissões do índice são as do manifesto.
- Os programas pedidos fazem sentido para o que o plugin promete (nada de `sh`, `bash`,
  `curl`, `rm` ou parecidos sem um motivo muito claro).
- O script (`main.rhai`) só usa `run()` com esses programas e não tenta se esconder.
- Os domínios de `net` fazem sentido, e o que o script manda para eles também. Atenção
  especial a quem lê `agents` (os pedidos feitos aos agentes de IA) e tem rede.
- A tela carrega imagens só de `assets/` (o MiniUtils também confere).
- Licença livre declarada.

## Para quem mantém

```sh
miniutils --loja-assinar registry.json <chave privada>   # depois de aceitar o PR
```

A chave privada nunca entra neste repositório.
