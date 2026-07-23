// Canonical Prettier config for the JS/TS profile. Consumers re-export this so
// formatting settings live in one place.
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

const here = fileURLToPath(new URL('./.prettierrc.json', import.meta.url));
export default JSON.parse(readFileSync(here, 'utf8'));
