import { defineConfig, loadEnv } from 'vite';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';
import os from 'node:os';
import { createRequire } from 'node:module';
import type { IncomingMessage, ServerResponse } from 'node:http';

const require = createRequire(import.meta.url);
const { fetchMarketBundle } = require('../api/finnhub.cjs') as {
  fetchMarketBundle: () => Promise<unknown>;
};

const DEV_PORT = 5177;

function lanOrigin(port: number) {
  try {
    const nets = os.networkInterfaces();
    for (const addrs of Object.values(nets)) {
      for (const addr of addrs ?? []) {
        const v4 = addr.family === 'IPv4' || addr.family === 4;
        if (v4 && !addr.internal) return `http://${addr.address}:${port}`;
      }
    }
  } catch {
    // Restricted environments (Vercel build, sandboxes) cannot list interfaces.
  }
  return `http://localhost:${port}`;
}

function marketNewsApi() {
  return {
    name: 'market-news-api',
    configureServer(server: {
      middlewares: { use: (fn: (req: IncomingMessage, res: ServerResponse, next: () => void) => void) => void };
    }) {
      server.middlewares.use((req, res, next) => {
        const path = req.url?.split('?')[0] ?? '';
        if (path !== '/api/market-news') {
          next();
          return;
        }
        fetchMarketBundle()
          .then((payload) => {
            res.setHeader('Content-Type', 'application/json');
            res.setHeader('Cache-Control', 'no-store');
            res.end(JSON.stringify(payload));
          })
          .catch(() => {
            res.statusCode = 502;
            res.setHeader('Content-Type', 'application/json');
            res.end(JSON.stringify({ error: 'Market news is unavailable right now.' }));
          });
      });
    },
  };
}

function apkHeaders() {
  return {
    name: 'apk-headers',
    configureServer(server: { middlewares: { use: (fn: (req: IncomingMessage, res: ServerResponse, next: () => void) => void) => void } }) {
      server.middlewares.use((req, res, next) => {
        const path = req.url?.split('?')[0] ?? '';
        if (path.endsWith('.apk')) {
          res.setHeader('Content-Type', 'application/vnd.android.package-archive');
          res.setHeader('Content-Disposition', 'attachment; filename="HouseholdExpense.apk"');
        }
        next();
      });
    },
  };
}

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '');
  if (env.FINNHUB_API_KEY) {
    process.env.FINNHUB_API_KEY = env.FINNHUB_API_KEY;
  }

  return {
    define: {
      __INSTALL_ORIGIN__: JSON.stringify(lanOrigin(DEV_PORT)),
    },
    plugins: [react(), tailwindcss(), apkHeaders(), marketNewsApi()],
    server: { port: DEV_PORT, host: true },
  };
});
