# Instruções: integrar o motion-kit ao Painel de Gastos
 
**Veredito:** compatível. Só depende de React 18+ e Recharts, e funciona em SPA (TanStack Router puro, sem SSR). A checagem de tipos passou com React 18 e Recharts 3.10. Visual e telas: ver `plano-consolidado.md`.
 
## Instalação
- Copiar a pasta para `src/motion-kit`.
- Configurar o Tailwind para varrer essa pasta.
## Ajustes obrigatórios
1. **Idioma e moeda:** trocar os textos em inglês (rótulo padrão do medidor, tooltips) por pt-BR e formato BRL.
2. **Centavos:** o `AnimatedNumber` interpola valores com casas decimais, então o formatador deve arredondar e converter centavos em reais.
3. **Tema claro e escuro (obrigatório, o modelo visual tem os dois):** o tooltip (fundo branco), a trilha da `ProgressBar` (cinza-claro) e a borda branca do ponto ativo da linha são fixos e devem usar os tokens do tema Manso (painel, linha, destaque suave).
4. **Cores:** o destaque dos gráficos é o verde-sálvia do tema (via `className`/`currentColor`). No `flash` do `AnimatedNumber`, subir usa o verde de destaque e descer usa #bd6c5f, no lugar do verde e do rosa padrão do kit.
## Onde usar
| Peça | Uso |
|---|---|
| `AnimatedNumber` | Saldo, receitas, despesas e "Você economizou" (`flash` quando o valor muda) |
| `ChartLine` | Evolução financeira (saldo acumulado em 6 ou 12 meses) |
| `ChartBars` | Receitas e despesas por mês (Relatórios, v2) |
| `ArcGauge` / `ChartGauge` | % do orçamento consumido |
| `ProgressBar` | Progresso por categoria, orçamentos e metas |
| `Reveal` | Entrada de cards e linhas |
| `TabPill` | Botões 6/12 meses e troca de abas |
 
## Atenção
- **Gráfico por categoria (rosca):** o kit não tem. Fazer com Recharts puro, usando as cores das categorias.
- **Barras do Recharts** animam todas juntas (sem sequência) e o `ChartGauge` não tem marcador girando; para isso usar o `ArcGauge`.
- **Reanimar ao trocar de mês, aba ou rota:** usar `key` no container.
- **Animar com moderação:** cards de resumo, gráficos principais e medidor. Evitar a tabela de transações inteira.
