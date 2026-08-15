import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';
import './index.css';

const stored = localStorage.getItem('he-showcase-theme');
const initial =
  stored === 'light' || stored === 'dark'
    ? stored
    : window.matchMedia('(prefers-color-scheme: light)').matches
      ? 'light'
      : 'dark';
document.documentElement.setAttribute('data-theme', initial);

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
