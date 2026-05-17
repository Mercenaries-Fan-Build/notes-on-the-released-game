import path from 'path'
import { fileURLToPath } from 'url'
import { defineConfig, loadEnv } from 'vite'
import { reviewAssetsPlugin } from './vite-plugin-review-assets.js'

const __dirname = path.dirname(fileURLToPath(import.meta.url))

export default defineConfig(({ mode }) => {
  const loaded = loadEnv(mode, __dirname, '')
  for (const [k, v] of Object.entries(loaded)) {
    if (k.startsWith('MERCS2_') && v !== undefined) {
      process.env[k] = v
    }
  }

  return {
    root: '.',
    plugins: [reviewAssetsPlugin()],
    server: { port: 5173, open: true },
    preview: { port: 5173 },
    publicDir: 'public',
    build: {
      rollupOptions: {
        input: {
          main: path.resolve(__dirname, 'index.html'),
          placementPreview: path.resolve(__dirname, 'placement-preview.html'),
          placementBbox: path.resolve(__dirname, 'placement-bbox.html'),
        },
      },
    },
  }
})
