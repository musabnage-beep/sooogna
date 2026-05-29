# Souq Sudan — Database Schema

Reference for every Firestore collection, subcollection, document shape and
composite index the app depends on. All timestamps are server-side
(`FieldValue.serverTimestamp()`); all IDs are auto-generated `String`s unless
noted.

Sections:

1. [Collections overview](#1-collections-overview)
2. [`users/`](#2-users)
3. [`users/{uid}/notifications/`](#3-usersuidnotifications)
4. [`ads/`](#4-ads)
5. [`chats/`](#5-chats)
6. [`chats/{chatId}/messages/`](#6-chatschatidmessages)
7. [`reviews/`](#7-reviews)
8. [`reports/`](#8-reports)
9. [Storage layout](#9-storage-layout)
10. [Composite indexes](#10-composite-indexes)
11. [Security model summary](#11-security-model-summary)

---

## 1. Collections overview

```
users/{uid}                          – user profile (1 per Auth user)
   └── notifications/{notifId}       – in-app + FCM mirror notifications
ads/{adId}                           – classified ads
chats/{chatId}                       – 1:1 conversation between two users about an ad
   └── messages/{messageId}          – chat messages
reviews/{reviewId}                   – ratings buyers/sellers leave for each other
reports/{reportId}                   – moderation reports (admin only)
```

No other top-level collections are written by the client.

---

## 2. `users/`

Doc ID = Firebase Auth UID.

| Field              | Type                   | Required | Notes |
|--------------------|------------------------|----------|-------|
| `id`               | `string`               | yes      | Mirror of UID, used in denormalised refs. |
| `phone`            | `string` (E.164)       | yes      | `+249...`. Cannot be edited by the user. |
| `name`             | `string` (1–50)        | yes      | Display name. |
| `profileImageUrl`  | `string?`              | no       | Public download URL in `profile_images/{uid}/...`. |
| `bio`              | `string?` (0–280)      | no       | Free-text bio. |
| `location`         | `string?`              | no       | Free-text city/state. |
| `role`             | `'user' \| 'admin'`    | yes      | Defaults to `'user'`. Only an admin can change. |
| `isVerified`       | `boolean`              | yes      | Admin-controlled trust badge. |
| `isBanned`         | `boolean`              | yes      | When `true` rules deny all writes. |
| `rating`           | `number` (0–5)         | yes      | Cached average of `reviews/` where `userId == this.id`. |
| `reviewCount`      | `number` (>=0)         | yes      | Cached count. |
| `fcmTokens`        | `string[]`             | yes      | `FieldValue.arrayUnion` on sign-in, `arrayRemove` on sign-out. |
| `createdAt`        | `timestamp`            | yes      | Set on create only. |
| `lastActiveAt`     | `timestamp`            | yes      | Touched on every cold start. |

Example:

```json
{
  "id": "uJ8c7Y...",
  "phone": "+249912345678",
  "name": "محمد عثمان",
  "profileImageUrl": "https://firebasestorage.googleapis.com/.../profile.jpg",
  "bio": "تاجر هواتف بالخرطوم",
  "location": "الخرطوم",
  "role": "user",
  "isVerified": false,
  "isBanned": false,
  "rating": 4.6,
  "reviewCount": 23,
  "fcmTokens": ["dC9..."],
  "createdAt": "2026-02-14T09:11:03Z",
  "lastActiveAt": "2026-05-29T18:42:11Z"
}
```

**Self-write restrictions** (enforced in `firestore.rules`): the user may
edit `name`, `profileImageUrl`, `bio`, `location`, `fcmTokens`,
`lastActiveAt`. Any attempt to change `role`, `isBanned`, `isVerified`,
`rating`, `reviewCount`, `createdAt`, `phone`, `id` is rejected. Admins may
edit everything.

---

## 3. `users/{uid}/notifications/`

In-app inbox. Mirrors any FCM the user receives so they have history.

| Field        | Type                                                         | Notes |
|--------------|--------------------------------------------------------------|-------|
| `id`         | `string`                                                     | = doc id |
| `type`       | `'chat' \| 'ad_approved' \| 'ad_rejected' \| 'review' \| 'system'` | |
| `title`      | `string`                                                     | Arabic title. |
| `body`       | `string`                                                     | Arabic body. |
| `targetId`   | `string?`                                                    | `chatId`, `adId`, `userId` depending on `type`. |
| `imageUrl`   | `string?`                                                    | Optional thumbnail. |
| `isRead`     | `boolean`                                                    | Single write the user is allowed to flip. |
| `createdAt`  | `timestamp`                                                  | Server time. |

Reads/writes are scoped to the owning user. Server (Cloud Function or admin
SDK) is the only writer for `type != 'chat'`; chat notifications are written
client-side as a side effect of sending a message *to* the other participant.

Index: `(isRead asc, createdAt desc)` for the "unread first" inbox view.

---

## 4. `ads/`

The marketplace entity. Doc ID auto-generated.

| Field             | Type                                          | Required | Notes |
|-------------------|-----------------------------------------------|----------|-------|
| `id`              | `string`                                      | yes      | Mirror of doc id. |
| `userId`          | `string`                                      | yes      | Owner UID. Immutable after create. |
| `title`           | `string` (3–100)                              | yes      | Arabic preferred. |
| `description`     | `string` (10–2000)                            | yes      |  |
| `price`           | `number` (>=0)                                | yes      | SDG, integer or decimal. |
| `currency`        | `'SDG'` (fixed)                               | yes      |  |
| `isNegotiable`    | `boolean`                                     | yes      | |
| `category`        | `string`                                      | yes      | Slug from `AppConstants.categories`. |
| `subcategory`     | `string?`                                     | no       | |
| `condition`       | `'new' \| 'used' \| 'refurbished'`           | yes      | |
| `images`          | `string[]` (1–10)                             | yes      | Public download URLs. |
| `location`        | `string`                                      | yes      | Sudanese state, e.g. `الخرطوم`. |
| `latitude`        | `number?`                                     | no       | |
| `longitude`       | `number?`                                     | no       | |
| `phone`           | `string`                                      | yes      | Contact phone (may differ from account phone). |
| `whatsappEnabled` | `boolean`                                     | yes      | Show WhatsApp CTA. |
| `status`          | `'pending' \| 'active' \| 'rejected' \| 'sold'` | yes    | Defaults to `pending`. Only admin can promote to `active`/`rejected`. Owner can flip `active ↔ sold`. |
| `rejectionReason` | `string?`                                     | no       | Set by admin when status = `rejected`. |
| `isFeatured`      | `boolean`                                     | yes      | Admin-only toggle. |
| `viewCount`       | `number` (>=0)                                | yes      | Incremented atomically on detail view. |
| `searchKeywords`  | `string[]`                                    | yes      | Lower-cased tokens from title/description for prefix search. |
| `createdAt`       | `timestamp`                                   | yes      | |
| `updatedAt`       | `timestamp`                                   | yes      | Bumped on every owner/admin edit. |

Example:

```json
{
  "id": "Xc91...",
  "userId": "uJ8c7Y...",
  "title": "آيفون 14 برو 256 جيجا",
  "description": "حالة ممتازة، استخدام شهرين، مع العلبة الأصلية والشاحن.",
  "price": 950000,
  "currency": "SDG",
  "isNegotiable": true,
  "category": "electronics",
  "subcategory": "mobiles",
  "condition": "used",
  "images": [
    "https://firebasestorage.googleapis.com/.../1.jpg",
    "https://firebasestorage.googleapis.com/.../2.jpg"
  ],
  "location": "الخرطوم",
  "phone": "+249912345678",
  "whatsappEnabled": true,
  "status": "active",
  "rejectionReason": null,
  "isFeatured": false,
  "viewCount": 132,
  "searchKeywords": ["ايفون", "14", "برو", "256", "جيجا"],
  "createdAt": "2026-05-20T10:00:00Z",
  "updatedAt": "2026-05-28T14:11:02Z"
}
```

### Write rules

- **Create** (signed-in, non-banned): must set `status=pending`,
  `isFeatured=false`, `viewCount=0`, 1–10 images, valid title/description
  lengths. `userId` must equal `request.auth.uid`.
- **Owner update**: cannot change `userId`, `isFeatured`, `viewCount`,
  `status` (except `active → sold`).
- **View counter**: a dedicated rule allows any signed-in user to increment
  `viewCount` by exactly 1 without touching other fields.
- **Admin**: full write access.

---

## 5. `chats/`

One document per buyer↔seller pair *per ad*.

| Field           | Type                  | Notes |
|-----------------|-----------------------|-------|
| `id`            | `string`              | = doc id |
| `userIds`       | `string[]` (length 2) | Sorted ascending so the pair is canonical. |
| `adId`          | `string`              | The ad that triggered the chat. |
| `adTitle`       | `string`              | Denormalised for chat list. |
| `adImage`       | `string?`             | First image of the ad. |
| `lastMessage`   | `string`              | Plain text (or `'📷 صورة'` if last msg was image). |
| `lastMessageAt` | `timestamp`           | Used to sort chat list. |
| `lastSenderId`  | `string`              | UID of the last sender. |
| `unreadCount`   | `map<string,number>`  | `{ "<uid>": int }` per participant. |
| `createdAt`     | `timestamp`           | |

Read/update are allowed only if `request.auth.uid in resource.data.userIds`.
Create requires the caller to be one of the two `userIds`.

### `chats/{chatId}/messages/`

| Field        | Type                              | Notes |
|--------------|-----------------------------------|-------|
| `id`         | `string`                          | = doc id |
| `senderId`   | `string`                          | UID. |
| `text`       | `string?` (0–2000)                | Either `text` or `imageUrl` (or both) must be present. |
| `imageUrl`   | `string?`                         | From `chat_images/{chatId}/...` |
| `isRead`     | `boolean`                         | Set true by the recipient on open. |
| `createdAt`  | `timestamp`                       | |

Only the two participants of the parent chat can read/write. Messages are
immutable except for `isRead`.

---

## 7. `reviews/`

| Field           | Type                  | Notes |
|-----------------|-----------------------|-------|
| `id`            | `string`              | = doc id |
| `reviewerId`    | `string`              | Author UID. |
| `userId`        | `string`              | Subject UID — the one being rated. |
| `adId`          | `string?`             | Optional, links the review to a specific deal. |
| `rating`        | `number` (1–5, int)   | |
| `comment`       | `string?` (0–500)     | |
| `createdAt`     | `timestamp`           | |

Rules:

- Public read.
- Create: signed-in, `reviewerId == auth.uid`, `userId != auth.uid`,
  `rating` 1–5.
- Delete: the author or an admin.
- Update: forbidden — reviews are immutable. Edit by deleting + recreating.

After every create/delete a Cloud Function (out of scope of this Flutter app)
should recompute `users/{userId}.rating` and `.reviewCount`.

---

## 8. `reports/`

User-to-user / user-to-ad reports for moderation.

| Field           | Type                                                | Notes |
|-----------------|-----------------------------------------------------|-------|
| `id`            | `string`                                            | = doc id |
| `reporterId`    | `string`                                            | UID. |
| `reporterName`  | `string`                                            | Denormalised for admin list. |
| `targetType`    | `'user' \| 'ad'`                                    | |
| `targetId`      | `string`                                            | UID or adId. |
| `reason`        | `string` (1–500)                                    | Arabic free-text. |
| `isResolved`    | `boolean`                                           | Defaults `false`. |
| `adminNote`     | `string?`                                           | Set when admin resolves. |
| `resolvedBy`    | `string?`                                           | Admin UID. |
| `resolvedAt`    | `timestamp?`                                        | |
| `createdAt`     | `timestamp`                                         | |

Rules:

- Read: admins only.
- Create: any signed-in user; must set `isResolved=false` and
  `reporterId == auth.uid`.
- Update/delete: admins only.

---

## 9. Storage layout

```
profile_images/{uid}/<filename>         – avatar; public read; self write; ≤5 MB
ad_images/{adId}/<filename>             – ad gallery; public read; any signed-in write; ≤5 MB
chat_images/{chatId}/<filename>         – chat attachments; participants only; ≤5 MB
```

All paths only accept `image/*` MIME types.

> The `chat_images` rules call `firestore.get(/databases/(default)/documents/chats/$(chatId))`
> to confirm the caller is one of the two `userIds` on every read. This is a
> billable Firestore read per Storage request — acceptable for the volume but
> worth caching if you grow.

---

## 10. Composite indexes

All indexes live in `firebase/firestore.indexes.json` and are deployed via
`firebase deploy --only firestore:indexes`.

| # | Collection (group) | Fields | Used by |
|---|--------------------|--------|---------|
| 1 | `ads` | `status` asc, `createdAt` desc | Home feed (active ads newest first). |
| 2 | `ads` | `status` asc, `isFeatured` desc, `createdAt` desc | Featured carousel on home. |
| 3 | `ads` | `status` asc, `category` asc, `createdAt` desc | Category screen. |
| 4 | `ads` | `status` asc, `location` asc, `createdAt` desc | Location filter. |
| 5 | `ads` | `status` asc, `price` asc | Sort by price ascending. |
| 6 | `ads` | `status` asc, `price` desc | Sort by price descending. |
| 7 | `ads` | `userId` asc, `createdAt` desc | "My Ads" screen for non-admin viewing self. |
| 8 | `ads` | `userId` asc, `status` asc, `createdAt` desc | User profile tab filtered to active ads. |
| 9 | `ads` | `searchKeywords` array-contains, `createdAt` desc | Search screen. |
| 10 | `chats` | `userIds` array-contains, `lastMessageAt` desc | Chat list. |
| 11 | `messages` (collection group) | `chatId` asc, `createdAt` asc | Chat room stream. |
| 12 | `reviews` | `userId` asc, `createdAt` desc | Profile reviews tab. |
| 13 | `reviews` | `reviewerId` asc, `userId` asc | "Has the current user already reviewed this seller?" |
| 14 | `reports` | `isResolved` asc, `createdAt` desc | Admin reports tabs. |
| 15 | `notifications` (collection group) | `isRead` asc, `createdAt` desc | Inbox sort. |

If you add a new query in code, add the matching index here **and** redeploy.

---

## 11. Security model summary

| Action | Rule |
|--------|------|
| Read user profile | Public read. |
| Edit own profile  | Restricted fields list (see §2). |
| Read ads (any status) | Public read — client-side filters hide `pending`/`rejected` for non-owners. |
| Create ad | Signed-in, non-banned, validation per §4. |
| Approve / reject ad | Admin only. |
| Increment `viewCount` | Any signed-in user, +1 exactly. |
| Read chat / messages | Only the two participants. |
| Send message | Only the two participants. |
| Read reviews | Public. |
| Write review | Signed-in, not self, rating 1–5. |
| Read reports | Admin. |
| Create report | Signed-in. |
| Resolve report | Admin. |
| Storage uploads | ≤5 MB, image MIME, scoped per path (§9). |
| Banned users | All writes denied; reads still allowed so app can show the "محظور" screen. |

The complete enforcement logic — including the `isAdmin()`, `isBanned()`,
`isSelf()` helpers — lives in `firebase/firestore.rules` and
`firebase/storage.rules`.
