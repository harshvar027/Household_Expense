import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { ThemeProvider } from './context/ThemeContext';
import SiteShell from './components/SiteShell';
import HomePage from './pages/HomePage';
import ProductPage from './pages/ProductPage';
import PrivacyPage from './pages/PrivacyPage';
import PricingPage from './pages/PricingPage';
import DownloadPage from './pages/DownloadPage';
import AboutPage from './pages/AboutPage';
import NewsPage from './pages/NewsPage';

export default function App() {
  return (
    <ThemeProvider>
      <BrowserRouter>
        <Routes>
          <Route element={<SiteShell />}>
            <Route index element={<HomePage />} />
            <Route path="product" element={<ProductPage />} />
            <Route path="privacy" element={<PrivacyPage />} />
            <Route path="pricing" element={<PricingPage />} />
            <Route path="download" element={<DownloadPage />} />
            <Route path="news" element={<NewsPage />} />
            <Route path="about" element={<AboutPage />} />
            <Route path="*" element={<Navigate to="/" replace />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </ThemeProvider>
  );
}
