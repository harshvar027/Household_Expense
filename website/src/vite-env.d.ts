/// <reference types="vite/client" />

declare const __INSTALL_ORIGIN__: string;

interface ImportMetaEnv {
  readonly VITE_ADSENSE_CLIENT?: string;
  readonly VITE_ADSENSE_SLOT_BANNER?: string;
  readonly VITE_ADSENSE_SLOT_INLINE?: string;
  readonly VITE_ADSENSE_SLOT_RECT?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}

