import { defineConfig } from 'vitest/config'; 
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig ({
    plugins: [react()],
    test: {
        globals: true, //Habilita globais como 'describe', 'test', 'expect' e 'beforeEach' sem precisar importar
        environment: 'jsdom', //Define o ambiente de teste do navegador 
        setupFiles: './src/setupTests.ts', // Arquivo que vai rodar antes de todos os testes
        alias: {
            '@': path.resolve(__dirname, './src'), //Atalhos de pasta para o testes entenderem o "@/"
        },
    },
})
