import path from 'path'
import { fileURLToPath } from 'url'
import { defineConfig, loadEnv } from 'vite'
import vue from '@vitejs/plugin-vue'
import tailwindcss from '@tailwindcss/vite'
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
    plugins: [vue(), tailwindcss(), reviewAssetsPlugin()],
    resolve: {
      alias: {
        '@': path.resolve(__dirname, 'src'),
        'vue': 'vue/dist/vue.esm-bundler.js',
      },
    },
    server: {
      port: 5173,
      open: true,
      proxy: {
        '/api': {
          target: 'http://127.0.0.1:8000',
          changeOrigin: true,
        },
      },
    },
    preview: { port: 5173 },
    publicDir: 'public',
    build: {
      chunkSizeWarningLimit: 700,
      rollupOptions: {
        input: {
          main: path.resolve(__dirname, 'index.html'),
        },
        output: {
          manualChunks: {
            three: ['three'],
          },
        },
      },
    },
  }
})
