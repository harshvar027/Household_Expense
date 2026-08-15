import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';
import os from 'node:os';
import type { IncomingMessage, ServerResponse } from 'node:http';

const DEV_PORT = 5177;

function lanOrigin(port: number) {
  const nets = os.networkInterfaces();
  for (const addrs of Object.values(nets)) {
    for (const addr of addrs ?? []) {
      const v4 = addr.family === 'IPv4' || addr.family === 4;
      if (v4 && !addr.internal) return `http://${addr.address}:${port}`;
    }
  }
  return `http://localhost:${port}`;
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

export default defineConfig({
  define: {
    __INSTALL_ORIGIN__: JSON.stringify(lanOrigin(DEV_PORT)),
  },
  plugins: [react(), tailwindcss(), apkHeaders()],
  server: { port: DEV_PORT, host: true },
});
