# Plano consolidado: Painel de Gastos ("Manso")
 
Reúne o planejamento anterior com o modelo visual enviado (Modelo_de_Painel_Financeiro). Documentos relacionados: `modelo-de-dados.md` (inclui as regras financeiras) e `motion-kit-instrucoes.md`.
 
## 1. Decisão-base (assumida)
O modelo enviado é usado como **referência visual e de estrutura**, não como base técnica. Ele é um template de outro framework (React Router, Drizzle, Better Auth e recursos de agente de IA), que conflita com a stack já decidida (Nhost e TanStack Router). Aproveitamos dele só o que define a aparência e a organização do painel. Se preferir adotar o template inteiro, ver a seção 7.
 
## 2. Stack final
| Camada | Ferramenta |
|---|---|
| Linguagem e UI | TypeScript, React, Tailwind CSS |
| Rotas | TanStack Router (SPA) |
| Backend, banco e auth | Nhost (PostgreSQL + Hasura/GraphQL) |
| Login | Email e senha, Google e Apple (todos na v1) |
| Dados no front | TanStack Query + cliente GraphQL leve |
| Formulários e validação | React Hook Form + Zod |
| Gráficos | Recharts |
| Animações | motion-kit |
| Ícones | Tabler Icons (os mesmos do modelo) |
| Fonte | Inter |
| Tema | Claro e escuro |
| Testes | Vitest |
 
## 3. Identidade visual (extraída do modelo)
**Conceito:** Manso, um espaço calmo e firme para ter clareza sobre o dinheiro. Tom de texto em pt-BR, acolhedor e direto ("Seu dinheiro, com clareza.").
 
**Cores (tokens)**
| Token | Claro | Escuro |
|---|---|---|
| Fundo da página | #f1efe6 | #0b0d0b |
| Barra lateral | #f7f5ee | #0b0d0b |
| Painéis e cards | #fcfbf6 | #111310 |
| Texto principal | #292e25 | #e4e7de |
| Texto secundário | #777b6d | #8b9284 |
| Linhas e bordas | #e2e3d7 | #292e25 |
| Destaque (verde-sálvia) | #596b43 | #a8b78f |
| Destaque suave | #e4e9d9 | #232b1d |
| Card em destaque | #dfe6d2 | #20291b |
 
- **Cores dos gráficos e categorias:** #7b8c64, #b8a784, #8faba0, #b39480, #c4c8b4.
- **Alerta e exclusão:** #bd6c5f.
- **Forma:** cantos de 8 a 16 px, bordas finas, sem gradientes decorativos e sem sombras fortes.
- **Tipografia:** Inter, base de 13 px, números em peso médio. O modelo usa textos de 7 a 9 px em vários rótulos; na implementação, usar no mínimo 11 px.
- **Layout:** barra lateral fixa de 224 px, barra superior de 80 px, conteúdo com largura máxima de 1352 px em telas grandes. Quebras responsivas em 1120, 850 e 560 px.
- **Evitar:** cinza genérico de SaaS, cores neon de fintech, sombras exageradas, tipografia gigante e ilustrações decorativas.
## 4. Telas
| Tela | No modelo | Fase |
|---|---|---|
| Login, cadastro, recuperar senha, verificar email (com botões Google e Apple) | Não existe; desenhar no estilo Manso | v1 |
| Visão geral | Pronta (4 cards, evolução, categorias, transações recentes, metas) | v1 |
| Nova/Editar transação (janela) | Pronta (descrição, tipo, valor, categoria, conta, data); acrescentar status, parcelas, transferência, estorno e comprovante | v1 |
| Transações (lista completa, filtros, busca, status) | Só item de menu | v1 |
| Contas e cartões (saldos, faturas por cartão, pagar fatura) | Só item de menu | v1 |
| Orçamentos | Só item de menu | v1 |
| Metas financeiras | Só item de menu (painel resumido na Visão geral) | v1 |
| Configurações (perfil, tema, categorias) | Só item de menu | v1 enxuta |
| Relatórios | Só item de menu | v2 |
| Ajuda | Só item de menu | v2 |
 
## 5. De onde vêm os dados da Visão geral
| Bloco | Fonte |
|---|---|
| Saldo total e variação | View saldo por conta (só efetivados, sem cartões) |
| Receitas, despesas e variação contra o mês anterior | View resumo mensal |
| "Você economizou" (valor e % das receitas) | View resumo mensal |
| Evolução financeira (6 ou 12 meses) | View saldo acumulado por mês |
| Despesas por categoria | View gasto por categoria e mês |
| Transações recentes (20 últimas) | Tabela transactions |
| Metas | Tabela goals |
 
## 6. Movimento (motion-kit) aplicado ao modelo
| Elemento do modelo | Peça do kit |
|---|---|
| 4 cards de resumo | AnimatedNumber com Reveal escalonado |
| Evolução financeira | ChartLine |
| Botões 6 e 12 meses, troca de abas | TabPill |
| Despesas por categoria (rosca) | Recharts puro (o kit não tem rosca); no modelo é um desenho CSS fixo e deve virar gráfico real com as cores das categorias |
| Metas e orçamentos | ProgressBar; medidor na tela de Orçamentos |
| Lista de transações | Reveal com índice |
| Troca de mês | `key` no container para reanimar |
 
**Ajustes obrigatórios no kit:** tema escuro é requisito, então tooltip, trilha da barra de progresso e borda do ponto ativo usam os tokens da seção 3. Destaque dos gráficos: verde-sálvia; cor de queda no `flash`: #bd6c5f. Demais ajustes em `motion-kit-instrucoes.md`.
 
## 7. O que NÃO aproveitar do template
- **Framework e infraestrutura:** React Router, pacotes agent-native, Drizzle, Better Auth e recursos de agente de IA e terminal.
- **Dados de exemplo:** nome "Marina Costa", valores, metas e categorias fixas no código.
- **Esquema de dados do template:** transação com categoria e conta como texto e valor com sinal.
- **Configurações de implantação:** o arquivo de hospedagem desliga a autenticação em produção e outro traz identificadores de analytics e origens do fornecedor. Não copiar.
- **Se quiser adotar o template inteiro:** seria preciso trocar Nhost por Neon + Better Auth, TanStack Router por React Router e refazer o modelo de dados em Drizzle.
## 8. Decisões
**Fechadas:** tema escuro desde o início; cartão com fatura, transferências entre contas, status pago/pendente, login Apple e email próprio **entram na v1**.
 
**Adiado por escolha sua:** domínio de produção. Consequências a aceitar:
- Usar os endereços padrão do Nhost e da hospedagem escolhida até comprar o domínio.
- O login Apple exige HTTPS e não funciona em localhost: só pode ser testado em ambiente publicado.
- Provedores de email costumam exigir um domínio verificado para enviar do seu próprio endereço. Até lá, usar o remetente padrão do Nhost ou o modo de teste do provedor.
- Antes de usuários reais, comprar o domínio: trocar as URLs de retorno depois exige reconfigurar Nhost, Google e Apple, e a reputação do email depende dele.
**A definir depois (não bloqueiam o início):**
1. **Provedor de envio de email** (verificação e recuperação de senha). No desenvolvimento, usar o remetente padrão do Nhost.
2. **Conta no Apple Developer Program** (paga): pré-requisito do login Apple, no fim do Marco 3. A aprovação pode levar dias, então convém iniciar com antecedência.
**Premissas de regra em vigor** (valem até você dizer o contrário; detalhes em `modelo-de-dados.md`): compra no dia do fechamento do cartão entra na fatura que fecha nesse dia; saldo total exclui cartões; estorno reduz a despesa e não conta como receita.
 
## 9. Ordem de execução sugerida (v1 em marcos)
**Marco 1: núcleo**
1. Projeto no Nhost, modelo de dados base, permissões do Hasura e funções do banco.
2. Tokens de tema (claro e escuro), barra lateral e barra superior.
3. Login por email e Google; telas de autenticação.
4. Transações simples (janela e lista), categorias e contas.
5. Visão geral com as views e as animações.
**Marco 2: regras financeiras**
6. Status pago/pendente, parcelamento, transferências e estornos.
 
**Marco 3: complemento**
7. Cartão com faturas e pagamento de fatura.
8. Orçamentos e metas.
9. Login Apple (depende da conta de desenvolvedor e de ambiente publicado), comprovantes, configurações.
 
## 10. Testes críticos (Vitest e testes no banco)
- Parcelamento: soma das parcelas é exatamente o total (ex.: R$ 100,00 em 3 vezes = 33,34 + 33,33 + 33,33), incluindo meses curtos.
- Transferência: criação, edição e exclusão sempre afetam as duas linhas ou nenhuma.
- Estorno: nunca excede a despesa original.
- Fatura: compras antes, no dia e depois do fechamento caem na fatura correta; pagamento de fatura não entra nas despesas.
- Saldo: pendentes não alteram saldo; efetivar altera uma única vez.
- Isolamento: um usuário não lê nem altera dados de outro (tabelas e views), pelos três métodos de login.
- Valores: zero, negativo e duplicidade rejeitados.
## 11. Estrutura de pastas do projeto
 
Um único repositório com o backend como código (pasta do Nhost) e o front-end em SPA. A organização do front é **por funcionalidade**, com as regras financeiras puras separadas da interface.
 
```
painel-gastos/
├─ nhost/                     Backend como código (Nhost CLI)
│  ├─ nhost.toml              Configuração (provedores de login, email); sem segredos
│  ├─ metadata/               Hasura: tabelas, relações e permissões por papel
│  ├─ migrations/             Migrations SQL versionadas (tabelas, views, funções, constraints)
│  └─ seeds/                  Dados fictícios para desenvolvimento
├─ src/
│  ├─ main.tsx                Entrada da aplicação
│  ├─ routes/                 Rotas do TanStack Router (uma por tela)
│  │  ├─ __root.tsx           Raiz: providers (Nhost, Query, tema)
│  │  ├─ login, cadastro, recuperar-senha, verificar-email, auth-callback
│  │  ├─ _app.tsx             Layout protegido: barra lateral e superior; bloqueia quem não tem sessão
│  │  └─ _app/                visao-geral, transacoes, contas, orcamentos, metas, configuracoes
│  ├─ features/               Uma pasta por funcionalidade
│  │  ├─ auth/                Formulários de login, botões Google e Apple, sessão
│  │  ├─ transactions/        Janela de transação, lista, filtros
│  │  ├─ accounts/            Contas, cartões e faturas
│  │  ├─ categories/
│  │  ├─ budgets/
│  │  ├─ goals/
│  │  ├─ dashboard/           Cards e gráficos da Visão geral
│  │  └─ settings/
│  │     (cada feature: components/, api/ com as consultas e mutações GraphQL,
│  │      schemas.ts com Zod, messages.ts com os textos pt-BR, index.ts como porta de entrada)
│  ├─ domain/                 Regras financeiras puras, sem React nem rede
│  │  ├─ money.ts             Centavos, formatação BRL, percentuais
│  │  ├─ installments.ts      Divisão de parcelas e datas
│  │  ├─ invoices.ts          Mês de fechamento e vencimento da fatura
│  │  ├─ balances.ts          Saldo, totais do mês e estornos
│  │  └─ *.test.ts            Testes ao lado de cada regra
│  ├─ components/
│  │  ├─ ui/                  Base reutilizável: botão, campo, cartão, janela, aviso
│  │  └─ layout/              Barra lateral, barra superior, estrutura da página
│  ├─ motion-kit/             Kit de animações (copiado e ajustado ao tema)
│  ├─ lib/                    Cliente Nhost, cliente GraphQL, TanStack Query, formatação de datas
│  ├─ graphql/                Tipos gerados a partir do schema (não editar à mão)
│  └─ styles/                 Tokens do tema Manso (claro e escuro) e estilos globais
├─ tests/
│  └─ db/                     Testes no banco: isolamento entre usuários, funções, constraints
├─ docs/                      Cópia dos três documentos do planejamento
├─ .env.example               Apenas variáveis públicas (subdomínio e região do Nhost)
└─ configurações da raiz      package.json, tsconfig, vite, vitest, geração de tipos, lint, .gitignore
```
 
**Regras de organização**
1. **`domain/` não conhece React nem rede.** Só recebe números e datas e devolve resultados. É onde ficam os testes das regras monetárias.
2. **O banco é a fonte de verdade das regras.** `domain/` serve para pré-visualizar na tela (ex.: simular parcelas) e testar; os mesmos casos de teste devem ser rodados contra a função do banco para garantir que os dois concordem.
3. **Features não importam umas das outras por dentro.** Só pelo `index.ts` de cada uma. Código compartilhado sobe para `domain/`, `components/` ou `lib/`.
4. **Rotas ficam finas:** só montam a tela com componentes das features e definem proteção de acesso.
5. **Idioma:** identificadores no código em inglês (transactions, accounts); textos da interface em pt-BR, concentrados em `messages.ts` de cada feature; endereços das telas em português sem acento (`/transacoes`).
6. **Segredos:** nada de chave administrativa ou segredo de provedor no front-end nem no git. O `.env.example` só leva variáveis públicas; segredos do Nhost ficam no arquivo local do CLI, listado no `.gitignore`.
7. **Banco só por migration:** nenhuma alteração de schema feita direto no painel de administração sem virar migration versionada.
**Pastas por marco**
| Marco | Pastas principais |
|---|---|
| 1 | `nhost/`, `styles/`, `components/layout/`, `features/auth`, `features/transactions`, `features/dashboard`, `motion-kit/` |
| 2 | `domain/` (parcelas, saldos), funções em `nhost/migrations/`, `tests/db/` |
| 3 | `features/accounts` (faturas), `features/budgets`, `features/goals`, `features/settings`, login Apple em `features/auth` |
