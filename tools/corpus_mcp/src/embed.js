import { EMBED_MODEL, QUERY_PREFIX } from './config.js';

let extractorPromise = null;

async function getExtractor() {
  if (!extractorPromise) {
    extractorPromise = (async () => {
      const { pipeline, env } = await import('@huggingface/transformers');
      env.allowLocalModels = false;
      return pipeline('feature-extraction', EMBED_MODEL, { dtype: 'q8' });
    })();
  }
  return extractorPromise;
}

/** Embed passage texts -> array of Float32Array(384), L2-normalized. */
export async function embedPassages(texts, batchSize = 24) {
  const extractor = await getExtractor();
  const out = [];
  for (let i = 0; i < texts.length; i += batchSize) {
    const batch = texts.slice(i, i + batchSize).map((t) => t.slice(0, 6000) || ' ');
    const res = await extractor(batch, { pooling: 'mean', normalize: true });
    const [n, dim] = res.dims;
    const data = res.data;
    for (let j = 0; j < n; j++) {
      out.push(new Float32Array(data.buffer, data.byteOffset + j * dim * 4, dim).slice());
    }
    res.dispose?.();
  }
  return out;
}

export async function embedQuery(text) {
  const [v] = await embedPassages([QUERY_PREFIX + text]);
  return v;
}
