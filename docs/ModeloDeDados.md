# Modelo de dados: Painel de Gastos
 
Banco: PostgreSQL do Nhost, com API GraphQL via Hasura. Autenticação (email/senha, Google e Apple) gerenciada pelo Nhost. Visual e telas: ver `plano-consolidado.md`.
 
## Convenções
- **Valores em centavos** (inteiro, bigint). Nunca ponto flutuante em cálculo monetário.
- **Datas de lançamento como data civil (sem hora)**, para não haver problema de fuso. Meses são guardados como o primeiro dia do mês. `created_at` e `updated_at` em UTC.
- **Todas as tabelas têm** `id` (uuid), `user_id` (dono), `created_at` e `updated_at`.
- **Nada de exclusão destrutiva** em contas e categorias com histórico: elas são **arquivadas**.
- **Regras críticas valem no banco** (constraints e funções), não só na interface.
- Mudanças de schema versionadas por migrations (Nhost/Hasura CLI) no repositório; migrations e exclusões são mudanças de alto risco.
## Regras financeiras (fonte única de verdade)
 
**Precisão e arredondamento**
- Moeda única na v1: BRL. Percentuais são calculados com precisão decimal no banco e arredondados para 1 casa (meio para cima) apenas na exibição.
**Tipos de lançamento:** receita, despesa, transferência de saída e transferência de entrada.
 
**Status (contas que não são cartão):** pendente ou efetivado.
- Só lançamentos **efetivados** alteram o saldo da conta.
- Parcelas futuras nascem pendentes. Pendente com data passada aparece como "vencido" (calculado, não gravado).
- Lançamentos em **conta de cartão não usam status**: a compra já aconteceu. O que fica pendente ou pago é a **fatura**.
**Saldo da conta** = saldo inicial + receitas efetivadas − despesas efetivadas + transferências de entrada efetivadas − transferências de saída efetivadas.
 
**Saldo total** = soma dos saldos das contas que **não** são cartão. Cartões aparecem à parte como "a pagar em faturas".
 
**Totais do mês (por data do lançamento)**
- Receitas e despesas do mês contam todos os lançamentos com data no mês, efetivados ou pendentes.
- Transferências nunca entram em receitas nem em despesas (inclusive o pagamento de fatura, para não contar a despesa duas vezes).
- Estornos reduzem as despesas da categoria e não são contados como receita.
- "Você economizou" = receitas − despesas do mês.
**Parcelamento**
- O valor total é dividido em N parcelas inteiras em centavos. O resto da divisão é distribuído de 1 centavo nas primeiras parcelas, de modo que **a soma das parcelas é exatamente o total**.
- Parcelas mensais no mesmo dia do mês; se o mês não tiver esse dia, usa o último dia do mês.
- Todas as parcelas são criadas de uma vez, em uma única operação. Editar uma parcela altera só ela; excluir o grupo exige confirmação explícita.
**Transferência**
- Criada sempre como **duas linhas** (saída e entrada) com o mesmo identificador de transferência, contas diferentes, mesmo valor e mesma data, sem categoria.
- Criada, editada e excluída **em uma única operação no banco** (nunca duas chamadas separadas do cliente).
**Estorno**
- É um lançamento que aponta para a despesa original, na mesma categoria.
- A soma dos estornos de uma despesa nunca passa do valor dela.
**Cartão e fatura**
- A fatura é identificada por cartão e **mês de fechamento**.
- Compra com dia ≤ dia de fechamento entra na fatura que fecha naquele mês; depois do fechamento, na do mês seguinte. (Premissa: compra feita no próprio dia de fechamento entra na fatura que fecha nesse dia. Alguns bancos diferem.)
- Vencimento: no mesmo mês do fechamento se o dia de vencimento for maior que o de fechamento; caso contrário, no mês seguinte.
- O mês de fechamento é gravado no lançamento ao criá-lo e recalculado se a data ou o cartão mudarem. Mudar o dia de fechamento do cartão não altera faturas passadas.
- **Pagamento de fatura** = transferência da conta de origem para o cartão, com referência à fatura. Status da fatura (calculado): aberta, fechada, parcialmente paga ou paga.
**Orçamento:** consumo da categoria = despesas do mês na categoria − estornos.
 
## Usuários
O Nhost mantém os usuários no schema de autenticação. As tabelas do painel referenciam o ID desse usuário. Todos os métodos de login geram o mesmo tipo de usuário e token.
 
## Tabelas da versão 1
 
### profiles (1 por usuário)
- user_id (chave primária e referência ao usuário)
- nome de exibição (saudação e iniciais do avatar)
- moeda (BRL)
- tema (claro, escuro ou sistema)
- (O campo "dia de início do mês financeiro" foi retirado da v1: o mês é o calendário.)
### accounts (contas e cartões)
- nome (ex.: Nubank, Itaú)
- tipo: conta corrente, poupança, carteira ou cartão de crédito (a tela mostra nome e tipo, como "Nubank · Débito")
- saldo inicial (centavos; não se aplica a cartão)
- dia de fechamento e dia de vencimento (obrigatórios para cartão, proibidos nos demais)
- cor
- arquivada (sim/não)
### categories
- nome
- tipo: receita ou despesa
- categoria pai (opcional)
- cor e ícone
- arquivada (sim/não)
- **Padrão no cadastro do usuário:** despesas Moradia, Alimentação, Transporte, Lazer, Saúde e Outros; receitas Salário, Freelance e Outros.
### transactions (tabela central)
- account_id
- tipo (receita, despesa, transferência de saída, transferência de entrada)
- category_id (obrigatória, exceto em transferência; tipo da categoria igual ao do lançamento)
- valor (centavos, sempre positivo)
- data do lançamento
- status (pendente ou efetivado; fixo como efetivado em conta de cartão) e data de efetivação (opcional)
- descrição e observação (opcional)
- parcelamento: grupo, número da parcela e total
- identificador de transferência (liga as duas linhas)
- estorno de (referência opcional à despesa original)
- mês de fechamento da fatura (só em conta de cartão) e, nos pagamentos de fatura, a fatura paga (cartão e mês)
- referência opcional ao comprovante (storage do Nhost)
### budgets
- category_id, mês (primeiro dia) e valor limite (centavos)
- Um orçamento por categoria por mês; ao abrir um mês novo, copia o do mês anterior.
### goals
- nome, valor alvo, valor guardado (centavos, atualizado diretamente na v1), prazo (mês e ano), cor, ícone e arquivada
- Progresso calculado (valor guardado ÷ alvo). Valor guardado nunca negativo.
## Tabelas da versão 2
| Tabela | Finalidade |
|---|---|
| goal_contributions | Histórico de aportes de cada meta |
| recurring_rules | Gastos e receitas recorrentes: frequência, próximo vencimento, data final, ativo |
| tags e transaction_tags | Etiquetas livres nas transações |
| Importação de extrato | Registro de lotes importados para evitar duplicatas |
 
## Relações
- usuário tem muitos accounts, categories, transactions, budgets, goals (e um profile)
- account tem muitas transactions; category tem muitas transactions e budgets; category pode ter pai
- duas transactions de transferência compartilham o mesmo identificador
- estorno aponta para uma transaction de despesa
## Regras de integridade (aplicadas no banco)
- Valor maior que zero; parcela atual entre 1 e o total.
- Conta, categoria e metas usadas precisam pertencer ao mesmo usuário.
- Transferência: exatamente duas linhas, contas diferentes, mesmo valor e data.
- Estorno: despesa original existente, mesmo usuário, soma dos estornos ≤ valor original.
- Campos de fechamento e vencimento só em cartão; mês de fechamento só em lançamento de cartão.
- Orçamento único por usuário, categoria e mês.
- Excluir categoria ou conta com lançamentos é bloqueado; a ação correta é arquivar.
- Excluir o usuário remove todos os seus dados.
## Índices principais
- transactions por usuário e data (mais recente primeiro)
- transactions por usuário, categoria e data
- transactions por usuário, conta e data
- transactions por cartão e mês de fechamento
- budgets por usuário e mês
## Views de agregação
O Hasura não agrupa dados, então as somas ficam em views do PostgreSQL, que expõem o user_id para as permissões funcionarem.
 
| View | Alimenta |
|---|---|
| Resumo mensal (receitas, despesas, economia e mês anterior) | Cards de resumo |
| Saldo acumulado por mês | Evolução financeira (6 ou 12 meses) |
| Gasto por categoria e mês (com estornos descontados) | Rosca por categoria |
| Orçamento versus gasto | Tela de Orçamentos |
| Saldo por conta (só efetivados) e total a pagar nos cartões | Saldo total e lista de contas |
| Faturas do cartão (total, pagamentos, vencimento, status) | Tela Contas e cartões |
 
## Permissões no Hasura (papel "user")
- Todas as tabelas: ler, inserir, alterar e excluir só linhas com `user_id` igual ao usuário autenticado.
- No insert, o `user_id` é preenchido pelo servidor a partir da sessão, nunca enviado pelo front-end.
- Colunas protegidas (id, user_id, created_at) não são alteráveis pelo cliente.
- Transferências, parcelamentos e estornos são criados por funções do banco (operação única e atômica), com as regras de integridade acima.
- Views: somente leitura, filtradas pelo mesmo critério.
