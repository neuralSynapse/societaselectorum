# Societas Electorum App — V1

Primeira camada do aplicativo móvel/PWA da Societas Electorum.

## Regra de segurança

Este código está isolado na branch `app-v1` e não modifica a branch `main`, o funil atualmente publicado, o WebsitePublisher ou o domínio oficial.

## Objetivo da V1

Criar a experiência mobile principal com:

- Centro
- Biblioteca
- Caminho
- Práticas
- Perfil
- instalação PWA
- shell offline local
- interface responsiva e acessível

## Fonte de verdade

O aplicativo não cria um segundo cadastro nem simula dados de membro. Nesta etapa, autenticação, biblioteca, progresso, Cartografia e práticas aparecem como integrações pendentes. Até que a ponte de dados seja implementada, os pontos seguros levam às rotas reais do site existente.

## Integração

`config.js` mantém explicitamente `sync.* = false` enquanto os contratos de autenticação e API não forem confirmados. Nenhuma API foi inventada.

O service worker armazena somente o shell local da PWA. Ele não intercepta autenticação, APIs ou conteúdo remoto do domínio oficial.

## Próximas etapas

1. Auditar autenticação e entidades reais do projeto WebsitePublisher 25063 em modo leitura.
2. Definir contrato de identidade única e sessão entre site e app.
3. Conectar biblioteca real e permissões.
4. Conectar progresso, ciclo de 33 dias e registros.
5. Conectar práticas e Cartografia.
6. Adicionar ícones PNG 192/512, screenshots e metadados finais de instalação.
7. Mover esta pasta para um repositório dedicado `societas-electorum-app` antes da publicação definitiva.
8. Publicar em `app.sociedadedoseleitos.com`.
9. Validar PWA com Lighthouse e testes reais em Android/iOS.
10. Empacotar com Capacitor apenas depois da PWA estabilizada.

## Critérios antes de produção

- nenhuma regressão no site atual;
- login único verificado;
- permissões de conteúdo verificadas;
- compras/assinaturas preservadas;
- nenhum dado fictício mostrado como real;
- navegação mobile validada;
- acessibilidade mínima validada;
- instalação e atualização PWA testadas;
- cache não deve reter páginas autenticadas indevidamente;
- logout e revogação de acesso devem refletir no app.
