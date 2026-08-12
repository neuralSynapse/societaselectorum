# Integração com a infraestrutura existente

Auditoria de leitura do projeto WebsitePublisher 25063, realizada antes de qualquer alteração em produção.

## Autenticação atual

- autenticação de visitantes: habilitada;
- métodos: código de 6 dígitos e magic link por e-mail;
- nome solicitado no acesso: sim;
- sessão verificada: 7 dias;
- redirecionamento atual após verificação: `/comunidade/meu-centro.html`.

A V1 do app **não cria outro login**. Até haver contrato de sessão seguro entre origens, o app direciona a autenticação para o domínio oficial.

## Dados já existentes que o app deve reutilizar

### Centro
`member_profile`
- display_name
- plan_name
- access_status
- current_stage
- current_route
- current_portal
- progress_percent
- next_action
- streak_days
- current_reading_title
- current_reading_progress
- last_activity_at

`member_orientation`
- title
- instruction
- category
- status
- priority
- due_at
- completed_at
- source
- sort_order

### Biblioteca e continuidade de leitura
`armarium_publication` é catálogo público e contém metadados editoriais, capa, nível de acesso e versão.

`member_reading` é privado e contém:
- título e autor;
- tipo de material;
- progresso;
- seção atual;
- próximo passo;
- status;
- última abertura.

`armarium_reader_state` é privado e contém:
- publication_slug;
- publication_title;
- progress_percent;
- current_anchor;
- completed;
- favorite;
- reader_theme;
- font_scale;
- last_opened_at.

Portanto, favoritos, continuar lendo, tema, escala tipográfica e posição de leitura **já possuem modelo de dados**. Não devem ser recriados em um segundo banco.

### Acesso e assinatura
`membership_access` é privado e já registra:
- plano;
- pagamento;
- status de acesso;
- tenant;
- usuário do tenant;
- início;
- expiração;
- provisionamento.

O app nunca deve decidir acesso apenas no cliente. O estado de autorização precisa vir da infraestrutura protegida.

## Catálogo público incorporado à V1

A branch `app-v1` recebeu um snapshot somente dos registros cujo estado atual é `publicado`. Registros meramente `catalogados` não são mostrados no app inicial.

O snapshot é uma solução de bootstrap/offline. A versão de produção deve consumir o catálogo público real para que atualizações editoriais apareçam sem novo deploy.

## Contrato a implementar

1. sessão autenticada validada no servidor;
2. endpoint de perfil do usuário atual, sem aceitar e-mail arbitrário do cliente;
3. endpoint de Centro agregando perfil + orientações + leitura atual;
4. endpoint de biblioteca protegida aplicando `membership_access` e regras de entitlement;
5. endpoint de leitura para atualizar `armarium_reader_state`;
6. endpoint de progresso/caminho;
7. endpoint de práticas e registros;
8. logout e revogação refletidos imediatamente.

## Regra de origem

O service worker atual limita cache à própria origem e não intercepta autenticação, APIs nem conteúdo remoto. Conteúdo autenticado nunca deve entrar em cache público por acidente.
