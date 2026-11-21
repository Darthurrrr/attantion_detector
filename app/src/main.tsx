import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import '@fontsource-variable/nunito'
import './styles/global.css'
import './styles/ui.css'
import './styles/home.css'
import './styles/map.css'
import './styles/play.css'
import './styles/summon.css'
import './styles/collection.css'
import './styles/modals.css'
import './styles/splash.css'
import App from './App'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
