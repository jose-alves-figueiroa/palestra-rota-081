# Roteiro de Apresentação — Autenticação

> Duração alvo: ~60 minutos de fala + espaço pra perguntas. Os tempos abaixo são um guia, não um cronômetro — ajuste no ritmo da sala. Total planejado: ~55 min de conteúdo + ~5 min de encerramento/perguntas.
>
> Diretriz geral: como o time pode adotar Hydra, Keycloak, Auth0, Okta ou Cognito, trate o Ory Hydra como **um exemplo de implementação**, não como o assunto principal. Toda vez que o roteiro focar em "Authorization Server" genérico, é intencional — cite o Hydra rapidamente e siga adiante.

---

## Slide 1 — Escalando uma autenticação legada
**Tempo:** 1–2 min

**Conteúdo do slide:** Escalando uma autenticação legada

**Fala sugerida:**
Abertura. Contextualize o "antes": autenticação acoplada ao monolito, regras de negócio de login espalhadas, cada serviço reimplementando validação de sessão/senha do seu jeito. É o problema que motiva a palestra — não é sobre uma ferramenta específica, é sobre como desacoplar autenticação de um sistema legado sem reescrever tudo do zero.

---

## Slide 2 — whoami
**Tempo:** 1–2 min

**Conteúdo do slide:** José Ricardo Alves Figueirôa · Techlead @ Jusfy · Computer Engineer (UFPE) · IoT Master (Polytech Nice Côte d'Azur)

**Imagens:** image5.png

**Fala sugerida:**
Rápida apresentação pessoal — cargo, tempo de experiência, por que você foi a pessoa que tocou esse projeto de migração de autenticação. Não precisa de mais que 1 minuto; é só pra dar contexto de credibilidade antes de entrar no conteúdo técnico.

---

## Slide 3 — Objetivo
**Tempo:** 3–4 min

**Conteúdo do slide:**
- Desacoplar autenticação do monolito
- Centralizar regras de negócio de login
- Remover boilerplate, duplicações de soluções e superfícies de ataque no login

**Imagens:** image13.png

**Fala sugerida:**
Aqui você vende o "porquê" antes do "como". Três motivadores:
1. **Desacoplamento** — autenticação vira um serviço próprio, o monolito para de saber como validar credencial, ele só passa a confiar em um token.
2. **Centralização de regras de negócio de login** — política de senha, bloqueio de conta, MFA, expiração de sessão, tudo num lugar só, em vez de replicado (e divergente) em cada serviço.
3. **Redução de superfície de ataque** — cada implementação própria de login é um lugar novo pra ter bug de segurança. Menos código de auth espalhado = menos chance de alguém reinventar (mal) a roda.

Deixe claro que o restante da talk é sobre os conceitos que sustentam essa decisão — AuthN/AuthZ, tokens, OAuth2 — e não sobre uma ferramenta específica.

---

## Slide 4 — Autenticação
**Tempo:** ~1 min

**Fala sugerida:** Transição de bloco. "Antes de falar de implementação, vamos alinhar os conceitos fundamentais de autenticação."

---

## Slide 5 — Autenticação (AuthN) vs Autorização (AuthZ)
**Tempo:** 5 min

**Imagens:** image8.png

**Fala sugerida:**
Distinção clássica, mas vale reforçar porque é a base de tudo que vem depois:
- **AuthN (Authentication)** responde "quem é você?". É a etapa de comprovar identidade — login com senha, biometria, certificado.
- **AuthZ (Authorization)** responde "o que você pode fazer?". É a etapa de decidir permissões — ver esse recurso, editar aquele registro, chamar essa API.

Analogia simples: crachá de acesso ao prédio (autenticação — prova que é você) vs. quais andares/salas o crachá abre (autorização — o que você pode acessar). São etapas independentes: dá pra estar autenticado e ainda assim não autorizado a fazer algo (ex: usuário logado tentando acessar painel de admin).

No mundo de APIs, isso se traduz em: **token de identidade** (quem é) vs. **scopes/claims/roles** (o que pode). Isso já prepara o terreno pra falar de JWT.

---

## Slide 6 — Três formas de provar quem você é
**Tempo:** 5 min

**Imagens:** image3.png

**Fala sugerida:**
Os três fatores clássicos de autenticação:
1. **Algo que você sabe** — senha, PIN, resposta secreta. Fator mais fraco, o mais fácil de vazar/phishar.
2. **Algo que você tem** — celular (SMS/push), token físico (YubiKey), certificado instalado num dispositivo.
3. **Algo que você é** — biometria: digital, face, íris.

MFA (autenticação multifator) é simplesmente combinar dois ou mais desses fatores — por isso senha + código do celular é mais forte que senha isolada: um atacante precisaria comprometer dois fatores de natureza diferente, não só vazar uma senha de um banco de dados.

Gancho pra próxima seção: depois que você prova quem é, o sistema precisa **carregar essa prova** de forma verificável entre serviços — é aí que entra o JWT.

---

## Slide 7 — JWTs
**Tempo:** ~1 min

**Fala sugerida:** Transição de bloco. "Agora que sabemos o que é provar identidade, vamos ver como essa identidade viaja entre sistemas."

---

## Slide 8 — JWT (e JWKS)
**Tempo:** 12–14 min — bloco mais denso da talk

**Conteúdo do slide:** JWT (JSON Web Token) é um formato padronizado para transportar informações entre sistemas de forma compacta e verificável.

**Imagens:** image2.png

**Fala sugerida:**

### JWT — estrutura
Um JWT tem três partes separadas por ponto, cada uma em Base64URL: `header.payload.signature`.
- **Header** — metadados: `alg` (algoritmo de assinatura, ex. `RS256`, `HS256`) e `kid` (identificador de qual chave foi usada — vamos voltar nisso já já).
- **Payload** — os *claims*: dados sobre o token e o titular. Alguns padronizados (`iss` emissor, `sub` sujeito/usuário, `aud` audiência/pra quem o token vale, `exp` expiração, `iat` emitido em), outros customizados pelo seu domínio (roles, tenant_id, etc).
- **Signature** — garante integridade: prova que o payload não foi alterado depois de emitido, e que foi realmente o Authorization Server que emitiu.

Importante deixar claro: **JWT não é criptografado por padrão, é só assinado e codificado em Base64**. Qualquer um consegue *ler* o conteúdo (é só decodificar Base64), mas não consegue *forjar* um token válido sem a chave privada. Não coloque dado sensível no payload de um JWT pensando que está protegido — ele é público, só é inviolável.

Dois jeitos de assinar:
- **Simétrico (HS256)** — mesma chave assina e valida. Só funciona quando quem emite e quem valida confiam um no outro com o segredo compartilhado (ex: monolito validando token próprio).
- **Assimétrico (RS256/ES256)** — chave privada assina, chave **pública** valida. É o que se usa quando várias APIs/serviços diferentes precisam validar o token sem ter acesso ao segredo de emissão. É aqui que entra o JWKS.

### JWKS — JSON Web Key Set
Este é o ponto que costuma ficar vago em talks sobre JWT, então vale um tempo maior:

- **O que é**: um endpoint HTTP, geralmente em `/.well-known/jwks.json`, que expõe as **chaves públicas** que o Authorization Server usa para assinar tokens. Faz parte do discovery do OIDC — o documento `/.well-known/openid-configuration` tem um campo `jwks_uri` apontando pra ele.
- **Formato**: um JSON com um array `keys`, e cada chave tem campos como `kid` (key id), `kty` (tipo, ex. `RSA`), `alg`, `use` (`sig` para assinatura), e os componentes matemáticos da chave pública (`n`/`e` para RSA, `x`/`y` para EC). Nunca tem a chave privada — isso fica só no Authorization Server.
- **Por que existe**: com assinatura assimétrica, o Resource Server (sua API) precisa da chave pública pra verificar a assinatura do JWT. Em vez de cada API guardar essa chave manualmente (e ter que atualizar toda vez que ela mudar), ela **busca a chave dinamicamente** nesse endpoint.
- **O papel do `kid`**: o header do JWT carrega um `kid`. Quando o Resource Server recebe o token, ele lê esse `kid` e busca, dentro do array de `keys` do JWKS, exatamente a chave com aquele id. Isso é o que permite **rotação de chaves sem downtime**: o Authorization Server pode publicar uma chave nova no JWKS, passar a assinar tokens novos com ela, e ainda manter a chave antiga publicada por um tempo — assim tokens antigos (ainda não expirados) continuam validando, e tokens novos já usam a chave nova. Sem isso, toda rotação de chave quebraria tokens em voo.
- **Cache**: bibliotecas cliente (ex: `jwks-rsa`, `jose`, `python-jose`) buscam o JWKS e cacheiam localmente por um TTL curto. Isso é o que torna essa validação **stateless e rápida**: depois do primeiro fetch, o Resource Server valida assinatura localmente, sem chamar o Authorization Server em cada requisição.
- **Fluxo completo, na prática**:
  1. Cliente manda requisição com `Authorization: Bearer <jwt>`.
  2. Resource Server decodifica o header do JWT (sem validar ainda) e lê o `kid`.
  3. Busca a chave correspondente no cache local do JWKS (ou faz `GET /.well-known/jwks.json` se ainda não tiver ela em cache).
  4. Usa a chave pública pra verificar a assinatura.
  5. Se válida, confia nos claims (`exp`, `aud`, `iss`) e segue o processamento — sem nenhuma chamada de rede extra ao Authorization Server.
- **Contraste com Introspection (RFC 7662)**: existe uma alternativa em que o Resource Server chama um endpoint do Authorization Server a cada validação (`/oauth2/introspect`), o que permite revogação instantânea mas custa uma chamada de rede por request. JWKS + validação local é o padrão quando você prioriza performance e aceita que a revogação vale até o `exp` do token (por isso tokens de acesso costumam ter vida curta).

Se der tempo, aponte no diagrama de Topologia (mostrado mais adiante) a seta `GET /.well-known/jwks.json` saindo dos Backend Services — é exatamente esse fluxo acontecendo na arquitetura real do time.

---

## Slide 9 — Bearer Token
**Tempo:** 4 min

**Conteúdo do slide:**
- Bearer Authentication é um mecanismo de autenticação HTTP em que o cliente envia um token junto com a requisição.
- "Bearer" = "quem portar esse token pode usá-lo."
- A API não verifica quem está segurando o token; ela apenas verifica se o token é válido.

**Fala sugerida:**
Bearer é só o **transporte** — o header `Authorization: Bearer <token>`. O nome já entrega a implicação de segurança: **posse é suficiente**. A API não pergunta "esse token é seu?", ela pergunta "esse token é válido?". Isso tem duas consequências práticas que vale destacar:
1. **HTTPS é obrigatório, sem exceção** — se o token for interceptado em trânsito, quem pegar pode usá-lo como se fosse o titular original.
2. **Tokens de acesso devem ter vida curta** — já que não tem verificação de posse além da validade do token, o TTL curto limita o estrago de um token vazado. É por isso que o padrão é access token de minutos + refresh token de vida mais longa pra renovar sem pedir login de novo.

Conecta direto com o que foi dito sobre JWKS: o "token válido" que a API checa é validado exatamente pelo fluxo de assinatura + chave pública que acabamos de ver.

---

## Slide 10 — Hydra
**Tempo:** ~1 min

**Fala sugerida:**
Transição de bloco — e aqui vale um disclaimer explícito: "O time usa Ory Hydra como Authorization Server, mas tudo que vou mostrar agora é conceito de OAuth2/OIDC — funciona igual com Keycloak, Auth0, Okta ou Cognito. Hydra é só a peça que escolhemos encaixar." Isso evita que a talk pareça um pitch de ferramenta.

---

## Slide 11 — O papel de um Authorization Server
**Tempo:** 3 min (resumido de propósito)

**Conteúdo original do slide:** O que é o Ory Hydra? É o server de autorização OAuth2/OIDC, desenvolvido e mantido pela Ory. Valida tokens, emite tokens, assina tokens, revoga tokens.

**Fala sugerida:**
Generalize em vez de detalhar Hydra: todo Authorization Server compatível com OAuth2/OIDC — Hydra, Keycloak, Auth0, Okta, Cognito — cumpre o mesmo papel:
- **Emite** tokens após autenticação bem-sucedida.
- **Assina** tokens com sua chave privada.
- **Expõe** a chave pública via JWKS (voltamos ao que já vimos).
- **Revoga** tokens/sessões quando necessário.

Não entre em detalhe de configuração específica do Hydra aqui — o ponto é "existe uma peça de infraestrutura dedicada a isso, e ela é intercambiável". Se alguém perguntar "por que Hydra e não Keycloak", responda em uma frase (ex: footprint mais leve, sem UI acoplada, mais controle sobre telas de login) e siga.

---

## Slide 12 — Topologia
**Tempo:** 4–5 min

**Imagens:** image12.png

**Fala sugerida:**
Mostre o diagrama e narre o caminho da requisição, sem se prender ao nome "Hydra" — trate como "Authorization Server":
- **Internet**: SPA/Mobile e Backend Services ficam do lado de fora do cluster.
- SPA/Mobile fala com o Authorization Server via **Auth code + PKCE** (login interativo) — vamos detalhar PKCE em breve.
- Backend Services fazem **`GET /.well-known/jwks.json`** — exatamente o fluxo de validação local que explicamos no bloco de JWT/JWKS.
- Tudo passa por um **WAF** antes de entrar na rede privada do cluster.
- Dentro do cluster: um **Auth Service** próprio do time faz a ponte entre o Authorization Server e a base de credenciais (**Credentials DB**) — ele decide aceitar/rejeitar desafios de login e consentimento, enquanto a parte pública do Authorization Server (**Public**) cuida de token exchange, refresh e revogação, e a parte administrativa (**Admin**) cuida de gerenciamento de clients.
- Cada peça (Authorization Server, Auth Service) tem seu próprio banco — separação de dados de token vs. dados de credencial.

O ponto chave: essa topologia — App pública fazendo Auth Code + PKCE, backends fazendo JWKS, um Auth Service isolado guardando credenciais — é o desenho que resolve o objetivo do Slide 3 (desacoplar do monolito), independente de qual produto está por trás do bloco "Authorization Server".

---

## Slide 13 — OAuth2
**Tempo:** ~1 min

**Fala sugerida:**
Transição de bloco. "Vimos a peça de infraestrutura; agora vamos ver o protocolo que ela implementa." Defina rapidamente os quatro papéis do OAuth2 antes de entrar nos fluxos: **Resource Owner** (o usuário), **Client** (a aplicação que quer acesso), **Authorization Server** (quem autentica e emite token) e **Resource Server** (a API que aceita o token).

---

## Slide 14 — Client Credentials
**Tempo:** 4 min

**Imagens:** image1.png

**Fala sugerida:**
Fluxo **machine-to-machine**, sem usuário envolvido: um serviço autentica direto com `client_id` + `client_secret` contra o Authorization Server e recebe um access token de volta, que usa pra chamar outra API.
Use quando: comunicação servidor-para-servidor, jobs/workers, integrações internas — nunca em código que roda no navegador ou app mobile, porque o `client_secret` precisa ficar protegido num ambiente que o usuário final não acessa. Esse é justamente o motivo do próximo fluxo existir.

---

## Slide 15 — PKCE
**Tempo:** 5 min

**Imagens:** image7.png

**Fala sugerida:**
PKCE (Proof Key for Code Exchange) resolve o problema de **clients públicos** — SPA, app mobile — que não têm onde guardar um secret com segurança (JS no browser e APK são inspecionáveis).

Passo a passo (segue o diagrama):
1. O client gera um **`code_verifier`** (string aleatória) e deriva dele um **`code_challenge`** (hash SHA-256).
2. Manda o `code_challenge` na requisição de autorização (`/authorize`).
3. Usuário autentica e consente.
4. Authorization Server devolve um **authorization code**.
5. O client troca esse code por token em `/oauth/token`, mas agora enviando o **`code_verifier`** original (não o hash).
6. O Authorization Server recalcula o hash do `code_verifier` recebido e compara com o `code_challenge` que guardou no passo 2 — só libera o token se bater.

Por que isso importa: mesmo que alguém intercepte o *authorization code* no meio do caminho (ex: via redirect em app mobile), não consegue trocá-lo por um token, porque não tem o `code_verifier` — que nunca saiu do client. É o Authorization Code Flow "tradicional" só que blindado contra interceptação de código, e hoje é recomendado até para clients confidenciais, não só públicos.

---

## Slide 16 — Fluxo Implementado
**Tempo:** 5 min

**Imagens:** image11.png

**Fala sugerida:**
Aqui você amarra tudo que foi explicado num fluxo real, ponta a ponta, como o time implementou:
- Login inicia com **Authorization Code + PKCE** (Slide 15) partindo do client público.
- O **Auth Service** entra no meio do fluxo pra decidir os desafios de **login** e **consent** que o Authorization Server pergunta (accept/reject) — é a integração customizada que conecta o protocolo genérico com as regras de negócio específicas do produto (verificação de credencial contra a base própria, MFA se aplicável, etc).
- Depois do consentimento aceito, o Authorization Server emite o **authorization code**, o client troca por token validando o `code_verifier`.
- Token final é um JWT assinado, validado pelos Resource Servers via JWKS — fechando o ciclo com o que vimos no Slide 8.

Fale em termos de "etapas do protocolo + onde nosso serviço customizado entra", sem se prender a nomes de componentes específicos do Hydra na sequência — o público já entendeu que a peça é intercambiável.

---

## Slide 17 — Arquitetura
**Tempo:** ~1 min

**Fala sugerida:** Transição de bloco. "Pra fechar, a visão de arquitetura completa — como essas peças convivem na infraestrutura real."

---

## Slide 18 — Arquitetura (componentes e middlewares)
**Tempo:** 3 min

**Imagens:** image10.png

**Fala sugerida:**
Mostre como cada Resource Server (Backend, Other Service) tem seu próprio **Auth Middleware** na frente, responsável por validar o token (via JWKS) antes de deixar a requisição chegar no serviço de negócio. O **Auth Service** central é o único ponto que fala com a base de usuários e decide accept/reject de login — os demais serviços nunca tocam em credencial, só em token já validado. Essa separação é literalmente o "centralizar regras de negócio de login" do Slide 3 se materializando em componentes.

---

## Slide 19 — Arquitetura (visão completa, com configuração)
**Tempo:** 3 min

**Imagens:** image4.png

**Fala sugerida:**
Versão mais completa do mesmo diagrama, incluindo Ingress/Gateway na frente de cada pod e um **Configuration Service** com a configuração OIDC/do Authorization Server centralizada — reforça que até a configuração de integração OAuth2/OIDC é tratada como algo gerenciado, não hardcoded em cada serviço. Fechamento natural: "isso tudo nasceu dos três objetivos do início — desacoplamento, centralização, menos superfície de ataque."

---

## Slide 20 — Obrigado
**Tempo:** 4–5 min (+ perguntas)

**Imagens:** image6.png, image9.png

**Fala sugerida:**
Encerramento. Recapitule em uma frase os três blocos: conceitos (AuthN/AuthZ, JWT/JWKS) → protocolo (OAuth2, Client Credentials, PKCE) → arquitetura real implementada. Abra pra perguntas — pontos que tendem a gerar pergunta: diferença entre JWT opaco vs. token de referência, por que expiração curta em vez de revogação, e "por que Hydra e não X" (resposta curta preparada, sem alongar).