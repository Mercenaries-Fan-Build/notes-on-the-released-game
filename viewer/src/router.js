import { createRouter, createWebHistory } from 'vue-router'

const routes = [
  {
    path: '/',
    name: 'dashboard',
    component: () => import('./views/DashboardView.vue'),
  },
  {
    path: '/viewer',
    redirect: '/workbench',
  },
  {
    path: '/workbench',
    name: 'workbench',
    component: () => import('./views/AssetWorkbenchView.vue'),
  },
  {
    path: '/placements',
    name: 'placements',
    component: () => import('./views/PlacementPreviewView.vue'),
  },
  {
    path: '/placement-qa',
    name: 'placement-qa',
    component: () => import('./views/PlacementBboxView.vue'),
  },
  {
    path: '/blocks',
    name: 'blocks',
    component: () => import('./views/BlockBrowserView.vue'),
  },
  {
    path: '/blocks/:id',
    name: 'block-detail',
    component: () => import('./views/BlockDetailView.vue'),
    props: true,
  },
  {
    path: '/review',
    name: 'review',
    component: () => import('./views/ReviewQueueView.vue'),
  },
  {
    path: '/zones',
    name: 'zones',
    component: () => import('./views/ZoneEditorView.vue'),
  },
  {
    path: '/search',
    name: 'search',
    component: () => import('./views/SearchView.vue'),
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

export default router
