import type { CodegenConfig } from '@graphql-codegen/cli';

const url = process.env.HASURA_GRAPHQL_URL;
const secret = process.env.HASURA_ADMIN_SECRET;
if (!url || !secret) {
  throw new Error('Defina HASURA_GRAPHQL_URL e HASURA_ADMIN_SECRET no .env.local');
}

const config: CodegenConfig = {
  schema: [{ [url]: { headers: { 'x-hasura-admin-secret': secret } } }],
  documents: ['src/**/*.{ts,tsx}', '!src/graphql/**/*'],
  generates: {
    'src/graphql/': {
      preset: 'client',
      config: {
        strictScalars: true,
        scalars: { uuid: 'string', timestamptz: 'string', date: 'string', bigint: 'number' },
      },
    },
  },
  ignoreNoDocuments: true,
};
export default config;