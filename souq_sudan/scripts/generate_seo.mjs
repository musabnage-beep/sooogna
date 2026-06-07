// Souq Sudan — offline SEO snapshot + sitemap generator (Feature 12).
//
// Flutter web is client-rendered, so crawlers see an empty shell. This script
// runs with firebase-admin (locally or in CI) to pre-render lightweight static
// HTML pages for each active ad at `build/web/ad/{id}.html`, plus a global
// `sitemap.xml` and `robots.txt`. These files are deployed alongside the Flutter
// bundle. The static pages carry full meta/OG/JSON-LD for crawlers and meta-
// refresh real users into the SPA route `/ad/{id}`.
//
// Usage:
//   1) Provide credentials via GOOGLE_APPLICATION_CREDENTIALS=/path/to/sa.json
//      (or place serviceAccount.json next to this script).
//   2) Build the web app first:  flutter build web --release
//   3) npm --prefix scripts install && node scripts/generate_seo.mjs
//
// No keys are embedded in the client bundle; this runs server-side only.

import { existsSync, mkdirSync, writeFileSync, readFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { initializeApp, cert, applicationDefault } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));
const PROJECT_ROOT = resolve(__dirname, '..');
const WEB_OUT = join(PROJECT_ROOT, 'build', 'web');
const BASE_URL = 'https://souq-sudan.app';
const MAX_ADS = 5000;

function initAdmin() {
  const localKey = join(__dirname, 'serviceAccount.json');
  if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    return initializeApp({ credential: applicationDefault() });
  }
  if (existsSync(localKey)) {
    const sa = JSON.parse(readFileSync(localKey, 'utf8'));
    return initializeApp({ credential: cert(sa) });
  }
  throw new Error(
    'No credentials. Set GOOGLE_APPLICATION_CREDENTIALS or add scripts/serviceAccount.json'
  );
}

function esc(s) {
  return String(s ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function truncate(s, max) {
  const clean = String(s ?? '').replace(/\s+/g, ' ').trim();
  return clean.length <= max ? clean : clean.slice(0, max - 1) + '…';
}

function adHtml(id, ad) {
  const title = esc(truncate(ad.title || 'إعلان', 70));
  const desc = esc(truncate(ad.description || ad.title || '', 160));
  const image = esc((ad.images && ad.images[0]) || `${BASE_URL}/icons/Icon-512.png`);
  const url = `${BASE_URL}/ad/${id}.html`;
  const appUrl = `${BASE_URL}/ad/${id}`;
  const price = Number(ad.price || 0);
  const jsonLd = {
    '@context': 'https://schema.org',
    '@type': 'Product',
    name: ad.title || 'إعلان',
    description: truncate(ad.description || '', 300),
    image: (ad.images && ad.images[0]) || undefined,
    offers: {
      '@type': 'Offer',
      price: price,
      priceCurrency: 'SDG',
      availability: 'https://schema.org/InStock',
      url: appUrl,
    },
  };
  return `<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>${title} - سوق السودان</title>
<meta name="description" content="${desc}">
<link rel="canonical" href="${esc(appUrl)}">
<meta property="og:type" content="product">
<meta property="og:site_name" content="سوق السودان">
<meta property="og:title" content="${title}">
<meta property="og:description" content="${desc}">
<meta property="og:image" content="${image}">
<meta property="og:url" content="${esc(url)}">
<meta property="product:price:amount" content="${price}">
<meta property="product:price:currency" content="SDG">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="${title}">
<meta name="twitter:description" content="${desc}">
<meta name="twitter:image" content="${image}">
<script type="application/ld+json">${JSON.stringify(jsonLd)}</script>
<meta http-equiv="refresh" content="0; url=${esc(appUrl)}">
</head>
<body>
<h1>${title}</h1>
<p>${desc}</p>
<p><a href="${esc(appUrl)}">عرض الإعلان في سوق السودان</a></p>
</body>
</html>
`;
}

function staticUrls() {
  return ['/', '/services', '/requests', '/search'].map((p) => `${BASE_URL}${p}`);
}

async function main() {
  if (!existsSync(WEB_OUT)) {
    throw new Error(`Build output not found at ${WEB_OUT}. Run "flutter build web --release" first.`);
  }
  initAdmin();
  const db = getFirestore();

  const snap = await db
    .collection('ads')
    .where('status', '==', 'active')
    .orderBy('createdAt', 'desc')
    .limit(MAX_ADS)
    .get();

  const adDir = join(WEB_OUT, 'ad');
  mkdirSync(adDir, { recursive: true });

  const urls = [...staticUrls()];
  let count = 0;
  snap.forEach((doc) => {
    const ad = doc.data();
    writeFileSync(join(adDir, `${doc.id}.html`), adHtml(doc.id, ad), 'utf8');
    urls.push(`${BASE_URL}/ad/${doc.id}.html`);
    count++;
  });

  const now = new Date().toISOString();
  const sitemap = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${urls
    .map((u) => `  <url><loc>${esc(u)}</loc><lastmod>${now}</lastmod></url>`)
    .join('\n')}
</urlset>
`;
  writeFileSync(join(WEB_OUT, 'sitemap.xml'), sitemap, 'utf8');

  writeFileSync(
    join(WEB_OUT, 'robots.txt'),
    `User-agent: *\nAllow: /\n\nSitemap: ${BASE_URL}/sitemap.xml\n`,
    'utf8'
  );

  console.log(`Generated ${count} ad pages + sitemap.xml (${urls.length} urls) + robots.txt in ${WEB_OUT}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
