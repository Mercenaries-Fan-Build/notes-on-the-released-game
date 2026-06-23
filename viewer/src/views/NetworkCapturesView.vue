<template>
  <div class="flex h-full bg-gray-950">
    <!-- Left: live capture log -->
    <div class="flex min-w-0 flex-1 flex-col">
      <!-- Header / toolbar -->
      <div class="sticky top-0 z-20 border-b border-gray-800 bg-gray-950/95 px-6 pt-5 pb-3 backdrop-blur">
        <div class="mb-3 flex items-center justify-between">
          <div>
            <h1 class="text-2xl font-bold text-gray-100">Network Captures</h1>
            <p class="mt-0.5 text-xs text-gray-500">
              Every request the game makes to the Modkit capture server — like httpbin.
              <span class="text-gray-600">{{ total }} events</span>
            </p>
          </div>
          <div class="flex items-center gap-2">
            <label class="flex items-center gap-1.5 text-xs text-gray-400">
              <input v-model="autoRefresh" type="checkbox" class="accent-blue-600" />
              Live
            </label>
            <button
              class="rounded border border-gray-700 px-3 py-1 text-xs text-gray-300 hover:bg-gray-800"
              @click="refresh"
            >Refresh</button>
            <button
              class="rounded border border-red-800/60 px-3 py-1 text-xs text-red-300 hover:bg-red-900/20"
              @click="onClear"
            >Clear</button>
          </div>
        </div>

        <div class="flex flex-wrap items-center gap-2">
          <select
            v-model="protocol"
            class="rounded border border-gray-700 bg-gray-800 px-3 py-1.5 text-xs text-gray-200 focus:border-blue-600 focus:outline-none"
            @change="refresh"
          >
            <option value="">All protocols</option>
            <option value="http">HTTP</option>
            <option value="https">HTTPS</option>
            <option value="fesl">FESL</option>
            <option value="theater">Theater</option>
            <option value="tcp">TCP (raw)</option>
            <option value="udp">UDP</option>
          </select>
          <input
            v-model="search"
            type="text"
            placeholder="Search path / TXN / params / body…"
            class="flex-1 rounded border border-gray-700 bg-gray-800 px-3 py-1.5 text-xs text-gray-200 placeholder-gray-500 focus:border-blue-600 focus:outline-none"
            @keyup.enter="refresh"
          />
        </div>
      </div>

      <!-- Table -->
      <div class="flex-1 overflow-auto">
        <div v-if="error" class="m-6 rounded-lg border border-red-800 bg-red-900/20 p-4 text-sm text-red-300">
          {{ error }}
        </div>
        <div v-else-if="!captures.length && !loading" class="py-16 text-center text-sm text-gray-500">
          No captures yet. Point the game (via the Winsock redirect ASI or hosts file) at this Modkit
          host and the requests will stream in here.
        </div>
        <table v-else class="w-full text-xs">
          <thead class="sticky top-0">
            <tr class="border-b border-gray-800 bg-gray-900">
              <th class="px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Time</th>
              <th class="px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Proto</th>
              <th class="px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Host</th>
              <th class="px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Method / Type</th>
              <th class="px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Path / TXN</th>
              <th class="px-3 py-2 text-right text-[10px] font-semibold uppercase tracking-wider text-gray-500">Len</th>
              <th class="px-3 py-2 text-left text-[10px] font-semibold uppercase tracking-wider text-gray-500">Note</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="c in captures"
              :key="c.id"
              class="cursor-pointer border-b border-gray-800/50 transition-colors hover:bg-gray-800/40"
              :class="selected?.id === c.id ? 'bg-gray-800/60' : ''"
              @click="selected = c"
            >
              <td class="whitespace-nowrap px-3 py-1.5 font-mono text-[10px] text-gray-500">{{ fmtTime(c.created_at) }}</td>
              <td class="px-3 py-1.5">
                <span class="rounded-full px-2 py-0.5 text-[10px] font-medium" :class="protoClass(c.protocol)">{{ c.protocol }}</span>
              </td>
              <td class="max-w-[160px] truncate px-3 py-1.5 text-gray-400" :title="c.host">{{ c.host || '—' }}</td>
              <td class="px-3 py-1.5 font-mono text-[11px] text-gray-300">{{ c.method || c.fesl_type || '—' }}</td>
              <td class="max-w-[280px] truncate px-3 py-1.5 font-mono text-[11px] text-gray-200" :title="c.path || c.fesl_txn">
                {{ c.path || c.fesl_txn || '—' }}
              </td>
              <td class="px-3 py-1.5 text-right font-mono text-[10px] text-gray-500">{{ c.body_len ?? 0 }}</td>
              <td class="px-3 py-1.5">
                <span v-if="c.notes === 'unhandled'" class="rounded-full border border-red-700/50 bg-red-900/20 px-2 py-0.5 text-[10px] text-red-300">unhandled</span>
                <span v-else-if="c.notes" class="text-[10px] text-gray-500">{{ c.notes }}</span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Right: detail panel (httpbin-style dump) -->
    <aside v-if="selected" class="w-[440px] shrink-0 overflow-auto border-l border-gray-800 bg-gray-900/40">
      <div class="sticky top-0 flex items-center justify-between border-b border-gray-800 bg-gray-900 px-4 py-3">
        <h2 class="text-sm font-semibold text-gray-200">Capture #{{ selected.id }}</h2>
        <button class="text-gray-500 hover:text-gray-300" @click="selected = null">✕</button>
      </div>
      <div class="space-y-4 p-4 text-xs">
        <dl class="grid grid-cols-[110px_1fr] gap-y-1.5">
          <dt class="text-gray-500">Protocol</dt><dd class="text-gray-200">{{ selected.protocol }}</dd>
          <dt class="text-gray-500">Peer</dt><dd class="font-mono text-gray-300">{{ selected.peer_addr || '—' }}</dd>
          <dt class="text-gray-500">Port</dt><dd class="font-mono text-gray-300">{{ selected.server_port ?? '—' }}</dd>
          <dt class="text-gray-500">Host</dt><dd class="text-gray-300">{{ selected.host || '—' }}</dd>
          <template v-if="selected.method"><dt class="text-gray-500">Method</dt><dd class="text-gray-300">{{ selected.method }}</dd></template>
          <template v-if="selected.path"><dt class="text-gray-500">Path</dt><dd class="break-all font-mono text-gray-300">{{ selected.path }}</dd></template>
          <template v-if="selected.fesl_type"><dt class="text-gray-500">FESL type</dt><dd class="font-mono text-gray-300">{{ selected.fesl_type }}</dd></template>
          <template v-if="selected.fesl_txn"><dt class="text-gray-500">TXN</dt><dd class="font-mono text-gray-300">{{ selected.fesl_txn }}</dd></template>
          <template v-if="selected.response_summary"><dt class="text-gray-500">Reply</dt><dd class="text-gray-300">{{ selected.response_summary }}</dd></template>
          <template v-if="selected.notes"><dt class="text-gray-500">Note</dt><dd class="text-gray-300">{{ selected.notes }}</dd></template>
        </dl>

        <div v-if="selected.params && Object.keys(selected.params).length">
          <h3 class="mb-1 text-[10px] font-semibold uppercase tracking-wider text-gray-500">Params</h3>
          <pre class="overflow-auto rounded bg-gray-950 p-3 font-mono text-[11px] text-emerald-300">{{ pretty(selected.params) }}</pre>
        </div>

        <div v-if="selected.headers && Object.keys(selected.headers).length">
          <h3 class="mb-1 text-[10px] font-semibold uppercase tracking-wider text-gray-500">Headers</h3>
          <pre class="overflow-auto rounded bg-gray-950 p-3 font-mono text-[11px] text-sky-300">{{ pretty(selected.headers) }}</pre>
        </div>

        <div v-if="selected.body_text">
          <h3 class="mb-1 text-[10px] font-semibold uppercase tracking-wider text-gray-500">Body (text)</h3>
          <pre class="max-h-60 overflow-auto whitespace-pre-wrap break-all rounded bg-gray-950 p-3 font-mono text-[11px] text-gray-300">{{ selected.body_text }}</pre>
        </div>

        <div v-if="selected.body_hex">
          <h3 class="mb-1 text-[10px] font-semibold uppercase tracking-wider text-gray-500">Body (hex)</h3>
          <pre class="max-h-60 overflow-auto break-all rounded bg-gray-950 p-3 font-mono text-[10px] text-gray-500">{{ selected.body_hex }}</pre>
        </div>
      </div>
    </aside>
  </div>
</template>

<script setup>
import { onMounted, onUnmounted, ref } from 'vue'
import { storeToRefs } from 'pinia'
import { useNetworkCapturesStore } from '../stores/networkCaptures'

const store = useNetworkCapturesStore()
const { captures, total, loading, error } = storeToRefs(store)

const protocol = ref('')
const search = ref('')
const selected = ref(null)
const autoRefresh = ref(true)
let timer = null

async function refresh() {
  await store.fetchCaptures({ protocol: protocol.value, search: search.value, limit: 200 })
}

async function onClear() {
  if (confirm('Clear all captured network events?')) {
    await store.clearCaptures()
    selected.value = null
  }
}

function fmtTime(ts) {
  if (!ts) return '—'
  const d = new Date(ts)
  return d.toLocaleTimeString('en-US', { hour12: false }) + '.' + String(d.getMilliseconds()).padStart(3, '0')
}

function pretty(obj) {
  try { return JSON.stringify(obj, null, 2) } catch { return String(obj) }
}

function protoClass(p) {
  const map = {
    http:    'border border-blue-700/50 bg-blue-900/20 text-blue-300',
    https:   'border border-cyan-700/50 bg-cyan-900/20 text-cyan-300',
    fesl:    'border border-amber-700/50 bg-amber-900/20 text-amber-300',
    theater: 'border border-purple-700/50 bg-purple-900/20 text-purple-300',
    tcp:     'border border-gray-600/50 bg-gray-800/50 text-gray-400',
    udp:     'border border-emerald-700/50 bg-emerald-900/20 text-emerald-300',
  }
  return map[p] || 'border border-gray-600/50 bg-gray-800/50 text-gray-400'
}

onMounted(() => {
  refresh()
  timer = setInterval(() => { if (autoRefresh.value) refresh() }, 2000)
})
onUnmounted(() => clearInterval(timer))
</script>
