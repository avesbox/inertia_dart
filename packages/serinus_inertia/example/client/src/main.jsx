import { createInertiaApp } from '@inertiajs/react'
import { createRoot, hydrateRoot } from 'react-dom/client'
import './index.css'

createInertiaApp({
  title: (title) => (title ? `${title} | Serinus Inertia` : 'Serinus Inertia'),
  resolve: (name) => {
    const pages = import.meta.glob('./Pages/**/*.jsx', { eager: true })
    return pages[`./Pages/${name}.jsx`]
  },
  setup({ el, App, props }) {
    if (el.hasChildNodes()) {
      hydrateRoot(el, <App {...props} />)
      return
    }
    createRoot(el).render(<App {...props} />)
  },
})
