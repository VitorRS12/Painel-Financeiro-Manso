# Manso Motion Kit

Movimento calmo, curto e com propósito. Inspirado no vídeo de referência (painel "Corbel Supply Co."):
o tema se espalha a partir do clique, o destaque do menu desliza entre as abas, a página entra com um
leve desfoque e os números e gráficos "se constroem" a partir do zero.

Código: `src/lib/motion/` (tokens + tema) e `src/components/motion/` (componentes).
Biblioteca: `motion` (`motion/react`). Recharts para gráficos.

---

## 1. Tokens (`src/lib/motion/tokens.ts`)

| Token | Valor | Uso |
|---|---|---|
| `EASE` / `EASE_CSS` | `cubic-bezier(0.22, 1, 0.36, 1)` | Curva padrão de tudo (saída suave, sem quique) |
| `DURATION.fast` | 150 ms | Hover, pressionar, saída de página |
| `DURATION.base` | 300 ms | Troca de ícone, pequenos estados |
| `DURATION.page` | 350 ms | Entrada de página |
| `DURATION.number` | 900 ms | Contagem de números e barras de progresso |
| `DURATION.chart` | 900 ms | `animationDuration` dos gráficos Recharts |
| `DURATION.theme` | 650 ms | Revelação circular do tema |
| `SPRING_NAV` | stiffness 420, damping 36, mass 0.8 | Destaque deslizante do menu |

Regra: nunca escrever durações soltas no código — importar dos tokens.

---

## 2. Troca de tema claro ⇄ escuro

**Comportamento (vídeo):** o novo tema cresce como um círculo a partir do ponto clicado até cobrir a
tela inteira. O ícone sol/lua gira e troca.

**Implementação:** `transitionTheme(dark, origin?)` em `theme-transition.ts`.
1. `document.startViewTransition()` tira um "retrato" da tela atual.
2. Dentro do callback a classe `.dark` é aplicada em `<html>`.
3. Em `vt.ready`, anima `clip-path: circle(0 → raio)` no pseudo-elemento `::view-transition-new(root)`.
   O raio é a distância do clique até o canto mais distante (`Math.hypot`).
4. CSS em `styles.css` desliga a animação padrão do navegador (`animation: none`) e põe a nova
   camada por cima (`z-index: 2`).

**Origem do círculo:** o botão passa `{x, y}` do clique. Se nenhum for passado, usa a última
posição de `pointerdown` registrada globalmente (útil no seletor de tema em Configurações) e, sem
nada, o canto superior direito.

**Onde é usado:** botão sol/lua no cabeçalho (`ThemeToggle` em `_app.tsx`) e seletor em
Configurações. A troca é otimista: anima na hora e salva no perfil em segundo plano.
`useApplyTheme` aplica sem animação no primeiro carregamento e com animação quando o tema muda por
outro caminho (ex.: tema do sistema mudou).

**Fallback:** sem View Transitions (Firefox antigo) ou com movimento reduzido → troca instantânea.

**Ícone sol/lua sempre sincero:** o botão lê o tema da classe em `<html>`
(`useDocumentDark` em `src/hooks/use-document-dark.ts`), que é a fonte da verdade na tela. Assim o
ícone nunca fica mostrando o sol com a tela escura — vale para troca pelo cabeçalho, pelo seletor
de Configurações, por outra aba do navegador ou pelo tema do sistema.

---

## 3. Navegação entre abas

**Comportamento (vídeo):** a "pílula" escura da aba ativa desliza até a nova aba com mola suave,
em vez de sumir e aparecer.

**Implementação:** em `SidebarNav`, o item ativo renderiza
`<motion.span layoutId="nav-pill-{grupo}" transition={SPRING_NAV} />` atrás do ícone e do texto
(ícone e texto ficam `relative` para ficar por cima). O Motion interpola posição e tamanho entre
itens. `layoutGroup` separa o menu do desktop do menu móvel para não "voar" entre os dois.

**Ao reaproveitar:** qualquer grupo de abas (ex.: 6 meses / 12 meses, filtros) pode usar o mesmo
padrão — um único elemento com `layoutId` dentro do item ativo. O elemento é `NavPill` (`_app.tsx`).

**Barra horizontal do topo (`TopTabs`, em `_app.tsx`):** em telas estreitas (abaixo de `lg`, onde a
barra lateral some), as mesmas seis abas viram uma faixa horizontal dentro do cabeçalho, com
exatamente o mesmo comportamento: uma pílula com `layoutId="nav-pill-topbar"` desliza com a mesma
`SPRING_NAV`, o item ativo fica com texto de destaque e `aria-current="page"`, e o item ativo é
centralizado na faixa com `scrollTo` suave (instantâneo com movimento reduzido). A faixa é
rolável na horizontal sem barra de rolagem visível (utilitário `no-scrollbar` em `styles.css`);
`layoutScroll` no contêiner faz a pílula acompanhar a rolagem sem "pular".
No desktop a faixa fica oculta (`lg:hidden`) — a pílula continua só na barra lateral, para não
haver duas navegações disputando a mesma atenção.

---

## 4. Transição de página

**Comportamento (vídeo):** a página antiga esmaece rápido; a nova entra subindo alguns pixels,
saindo de um leve desfoque.

**Implementação:** `PageTransition` em `_app.tsx` envolve o `<Outlet />` com
`AnimatePresence mode="wait"`, chave = `pathname`.
- Entrada: `opacity 0→1`, `y 10→0`, `blur 4px→0`, 350 ms, `EASE`.
- Saída: `opacity →0`, `y →-6`, `blur →2px`, 150 ms (saída sempre mais curta que a entrada).
- `initial={false}` no primeiro carregamento para não animar a abertura do app.

Dentro da página, os painéis continuam com a classe `.reveal` (fade + 6 px) e podem receber
`animationDelay` escalonado de ~60 ms por item.

---

## 5. Números

**Comportamento (vídeo):** valores como "$37.163" ou "86" rolam do valor anterior até o novo ao
entrar na tela ou quando o filtro muda.

**Implementação:** `<AnimatedNumber value={cents} format={formatCents} />`.
- Começa em 0 na primeira vez que fica visível (`useInView`, uma vez).
- Em mudanças seguintes, anima do valor mostrado atual até o novo (não volta a 0).
- Escreve direto no nó DOM a cada quadro — sem re-render do React.
- Mantém `aria-label` com o valor final, para leitores de tela não lerem a contagem.
- Dinheiro continua em centavos inteiros; o arredondamento acontece só na exibição.

**Onde é usado:** cartões de resumo da Visão geral. Use também em totais de contas, orçamentos e metas.

---

## 6. Gráficos e barras

**Comportamento (vídeo):** a linha do gráfico se desenha da esquerda para a direita; medidores e
barras crescem até o valor.

**Implementação:**
- Área/linha (Recharts): `animationDuration={DURATION.chart}` + `animationEasing="ease-out"`.
  Trocar o período usa `key={months}` no contêiner para redesenhar do zero.
- Rosca de categorias: mesma duração, `animationBegin={150}` para entrar logo depois dos números.
- `ProgressTrack` (metas, orçamentos): `motion.div` com `width 0 → pct%` via `whileInView`,
  `DURATION.number`, `EASE`.

---

## 7. Ordem (coreografia) ao abrir uma página

1. Página entra (0–350 ms).
2. Cartões aparecem escalonados (`.reveal`, +60 ms cada).
3. Números contam (900 ms) enquanto…
4. Gráficos desenham (900 ms, rosca com 150 ms de atraso).
5. Barras de progresso enchem quando chegam à tela.

Nada fica em loop. Nada pisca ou pulsa.

---

## 8. Acessibilidade e desempenho

- `prefers-reduced-motion`: tema troca instantâneo, página não desliza, números aparecem prontos,
  `.reveal` desligado.
- Animar só `transform`, `opacity`, `filter` e `clip-path`; larguras só em barras pequenas.
- Números escrevem no DOM direto; gráficos usam a animação interna do Recharts.
- Sem bibliotecas extras além de `motion`.

## 9. Proibido

Loops, contadores que reiniciam sem mudança de dado, brilho pulsante, parallax, partículas,
gradientes animados, durações acima de 1 s (exceto a revelação do tema, 650 ms, e números, 900 ms).
