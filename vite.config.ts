import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

const plugins = [react()];

try {
  const { tanstackRouter } = require('@tanstack/router-plugin/vite');
  plugins.push(tanstackRouter({ target: 'react', autoCodeSplitting: true }));
} catch {
  // Optional dependency not installed; skip TanStack Router Vite plugin.
}

try {
  const tailwindcss = require('@tailwindcss/vite');
  plugins.push(tailwindcss());
} catch {
  // Optional dependency not installed; skip Tailwind Vite plugin.
}

//https://vitejs.dev/config/
export default defineConfig({
  plugins,
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    port: 3000, //Define a porta local fixa com 3000
    open: true, //Abre o navegador automaticamente ao rodar "bun run dev"  
  },
});
