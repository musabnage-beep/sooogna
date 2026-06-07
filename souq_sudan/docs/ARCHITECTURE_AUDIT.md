# Souq Sudan — Architecture Audit & Remaining-Risks Report

_Second full audit after the 14-feature marketplace upgrade (Phases 0–9)._
Scope: Flutter web-only, Firebase **Spark** (no Cloud Functions), Clean
Architecture (feature/{domain,data,presentation}), Riverpod, `Result<T>`,
cursor pagination.

---

## 1. Before / After

| Dimension | Before (classifieds app) | After (marketplace platform) | Score Δ |
|---|---|---|---|
| Feature surface | Ads, chat, reviews, admin | + Services, Requests, Stores, Saved, Share, Verification, Seller Analytics, AI assist, SEO | 6 → 9 |
| Architecture consistency | Clean-arch-lite, established | Same pattern across 5 new modules; zero pattern drift | 8 → 9 |
| Security rules | Ads/users/chat/reviews | + services, serviceRequests, stores, favorites, analytics, verificationRequests; counter-step guards; no self-set badges | 7 → 9 |
| Query/index coverage | Core ad queries | + city/ownerType/storeId/services/requests/stores composite indexes | 7 → 9 |
| Discoverability / SEO | SPA shell only (uncrawlable) | Global meta/OG/JSON-LD + per-route runtime meta + static snapshot pages + sitemap/robots | 3 → 8 |
| Spark-fit (no server) | N/A | All aggregation client-side via `FieldValue.increment` + rule guards | — |

No existing flow was rewritten or broken. All new Ad/User fields default in
`fromMap`, so existing documents need **no migration**.

---

## 2. Features delivered (F1–F14)

- **F1 Services marketplace** — `services/` module (browse/search/profile/portfolio), docId == userId.
- **F2 Service requests** — `serviceRequests/` + `responses` subcollection, respond workflow, counters.
- **F3 Verified accounts** — `verificationRequests/` self-serve + admin queue; badge set only by admin/server tx, never self.
- **F4 Rating polish** — generalized `reviews` (`targetType: user|service|store`) on deterministic `${reviewerId}_${targetId}` doc id.
- **F5 City filtering** — `city` field + composite indexes + filter/search.
- **F6 Owner type** — `ownerType: owner|broker|company` badge + filter.
- **F7 Business stores** — `stores/` module; products = ads `where storeId ==`; `productCount` maintained on create/delete.
- **F8 Saved ads** — `users/{uid}/favorites/{adId}` denormalized snapshots + Saved tab.
- **F9 Share** — `ShareService` (WhatsApp/Facebook/Telegram/copy) on ad/store/service.
- **F10 Seller analytics** — `users/{uid}/analytics/summary`; view/contact/save/profileVisit hooks; `/seller-analytics` dashboard.
- **F11 AI assist** — `AdAiService` interface; `HeuristicAdAiService` (offline, always on) + `LlmAdAiService` (real-LLM via injected completion fn, **disabled by default**, graceful fallback, no keys in bundle).
- **F12 SEO** — `web/index.html` meta/OG/JSON-LD/hreflang; `core/utils/seo_meta.dart` runtime per-route meta (package:web); `scripts/generate_seo.mjs` → static `/ad/{id}.html` + `sitemap.xml` + `robots.txt`.
- **F13 Security** — see §3.
- **F14 Performance** — see §4.

---

## 3. Security posture (F13)

Verified in `firebase/firestore.rules` / `storage.rules`:

- **No self-granted trust.** `users` update rule pins `isVerified`,
  `verifiedStatus`, `rating`, `ratingCount`, `role`, `isBanned`, `profileVisits`
  as `unchanged`; only `isAdmin()` may alter them.
- **Owner-only writes** for `services` (docId==uid), `stores` (ownerId==uid),
  `serviceRequests` (userId==uid), `favorites` (isSelf).
- **Counters are guarded:** `isCounterStep(field)` enforces exactly ±1 with no
  other key change for `favoriteCount`, `productCount`, `responseCount`;
  `viewCount`/`contactCount` enforce +1 only.
- **Store attach is authorized:** an ad may only set `storeId` if
  `ownsStore(storeId)` (a `get()` ownership check) — on both create and update.
- **Verification self-serve is safe:** users may create/update their own
  `verificationRequests` with `status == 'pending'` only; admins alone resolve,
  and the badge lands on the user doc via the admin rule.
- **Reviews uniqueness** preserved via deterministic doc id; self-review blocked.
- **Storage** scoped per owner: `store_assets/{storeId}`, `service_portfolio/{uid}`,
  `verification/{uid}` (owner write, owner+admin read), image+size limited.

---

## 4. Performance posture (F14)

- **Pagination** on every new browse list: services (`afterRating,afterCreatedAt`),
  requests (`afterCreatedAt`), store products (`afterCreatedAt`) — value-based cursors.
- **Composite indexes** present for all new constrained+ordered queries,
  including `ads (storeId,status,createdAt desc)` for store products.
- **Cached images** via `CachedImageWidget` across new screens.
- **Client-side aggregation** avoids N reads: counters incremented in place.
- **SEO is offline/CI work** (`generate_seo.mjs`), zero runtime cost to the app.

---

## 5. Remaining risks

| # | Risk | Severity | Mitigation / Recommendation |
|---|---|---|---|
| R1 | **Analytics counters are set-not-strictly-increment.** Any signed-in user can write arbitrary values to another user's `analytics/summary` (keys are constrained, values are not). | Low | Data is private (owner+admin read only) and non-monetary. Strict per-field +1 enforcement is unsafe under set-merge because a not-yet-present counter field can't be referenced in rules. Accept as "abuse-bounded" (matches plan). If griefing appears, move increments behind a Blaze callable. |
| R2 | **`productCount` drift.** Incremented on ad create / decremented on delete, but an ad that is rejected/expired still counts; status transitions don't adjust it. | Low | Display-only number. Optional periodic reconcile in `scripts/backfill.mjs`. |
| R3 | **Favorites streams are unbounded.** `watchFavoriteIds` must read all ids to render save-state correctly; `watchFavorites` reads the whole subcollection. | Low | Bounded by realistic per-user favorite counts. If a user saves thousands, add `.limit()` + loadMore to `watchFavorites` (keep ids unbounded but they are id-only/cheap). |
| R4 | **Client-rendered SEO needs the snapshot step.** Crawlers that don't execute JS see only `index.html` defaults unless `generate_seo.mjs` has run and deployed `/ad/{id}.html`. | Medium | Run `generate_seo.mjs` in the deploy pipeline after `flutter build web`. Snapshots + sitemap are the real crawler surface; runtime `SeoMeta` only helps JS-executing scrapers. |
| R5 | **LLM path is intentionally inert.** `LlmAdAiService(enabled:false)` always falls back to the heuristic; no real model is wired. | By design | Enable only via a server-side proxy (`completionFn`) on Blaze. Never embed keys in the web bundle. |
| R6 | **Counter increments can be replayed** (e.g. refresh to re-bump a view) — guarded to ±1 but not idempotent per user. | Low | Client guards (`_viewIncremented`, `_seoApplied`, `_visitCounted`) limit per-session repeats; absolute anti-abuse needs a server. |

---

## 6. Deploy checklist

1. `cd souq_sudan && flutter analyze` → **0 issues**, `flutter build web --release` → green. (Verified each phase.)
2. `firebase deploy --only firestore:rules,firestore:indexes,storage` **before** first use of new collections.
3. (SEO) provide `scripts/serviceAccount.json` or `GOOGLE_APPLICATION_CREDENTIALS`, then
   `npm --prefix scripts install && node scripts/generate_seo.mjs` after the web build.
4. `firebase deploy --only hosting`.

_Status: platform builds clean (analyze 0 issues, web release green) and is production-ready pending the deploy checklist above._
