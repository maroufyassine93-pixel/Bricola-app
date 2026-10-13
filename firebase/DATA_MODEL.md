# Bricola — Firestore Data Model

All timestamps are Firestore `Timestamp`. Money is in **DZD** (integer).

## `users/{uid}` — one doc per Firebase Auth user
| field | type | notes |
|---|---|---|
| phone | string | `+213…` from phone auth |
| phonePrivate | string | raw number — **readable only by the owner** (rules) |
| displayName | string | |
| role | string | `customer` \| `craftsman` \| `admin` |
| craftsmanId | string? | set after application approved |
| wilayaCode | number? | home wilaya |
| referralCode | string | 6-char invite code |
| fcmTokens | string[] | |
| createdAt | timestamp | |

## `craftsmen/{craftsmanId}` — public craftsman profile
| field | type | notes |
|---|---|---|
| userId | string | owner uid |
| displayName | string | |
| photoUrl | string? | avatar |
| trades | string[] | trade ids (`electricien`, `plombier`, …) |
| wilayaCode | number | e.g. 31 = وهران |
| commune | string | |
| phoneVerified | bool | true after OTP login |
| chamberVerified | bool | **admin-only flip** → drives the "حرفي موثّق" badge |
| verification | map? | chamber card / certificate upload (see below) |
| ratingAvg | number | recomputed on each review |
| ratingCount | number | |
| skills | string[] | free-form chips |
| portfolioUrls | string[] | `craftsmen/{uid}/portfolio/` |
| priceRanges | map[] | `{tradeId, minDzd, maxDzd}` — أسعار استرشادية |
| availableNow | bool | "متاح الآن" toggle (owner) |
| urgentAvailable | bool | offers تدخل مستعجل 🚨 |
| urgentSurchargePct | number | default 30 |
| lat / lng | number? | |
| featuredUntil | timestamp? | paid/free featured placement |
| status | string | `pending` → `approved` \| `rejected` \| `suspended` |
| createdAt | timestamp | |

### `verification` object (chamber card / certificate)
| field | type | notes |
|---|---|---|
| fileUrl | string | Storage: `craftsmen/{uid}/verification/chamber_card.{jpg,pdf}` |
| fileType | string | `photo` \| `pdf` |
| status | string | `pending` → `approved` \| `rejected` (admin) |
| submittedAt | timestamp | |

While `status == 'pending'` the profile shows the **"قيد المراجعة"** badge;
when `chamberVerified == true` it shows **"حرفي موثّق ✓"**; otherwise **"غير موثّق بعد"**.

## `bookings/{bookingId}`
| field | type | notes |
|---|---|---|
| customerId / craftsmanId | string | |
| tradeId | string | |
| serviceLabel | string | e.g. `كهربائي / Électricien` |
| description | string | |
| photoUrls | string[] | `bookings/{id}/` |
| preferredTime | timestamp? | |
| urgent | bool | +surcharge applies |
| status | string | `pending` → `accepted` → `inProgress` → `completed`; or `cancelled` / `noShow` (no-show triggers ضمان بريكولا) |
| priceAgreedDzd | number? | |
| paidConfirmed | bool | customer taps "تم الدفع" (cash on completion) |
| contactRevealed | bool | true after accept — phone unmasked |
| contactPhone | string? | **backend-written only** (Cloud Function on accept) |
| createdAt / updatedAt | timestamp | |

## `chats/{chatId}` → `messages/{msgId}`
Thread: `participants[]`, `bookingId?`, `otherName`, `lastMessage`, `lastMessageAt`.
Message: `senderId`, `type` (`text`|`voice`|`image`), `text`, `mediaUrl?`
(`chats/{chatId}/…`, voice = `.m4a`), `durationSec`, `createdAt`, `readBy[]`.

## `reviews/{reviewId}`
`craftsmanId`, `bookingId`, `customerId`, `customerName`, `rating` (1–5),
`comment`, **`workPhotoUrl` (REQUIRED — enforced in UI + rules)**,
`createdAt`. Creating a review atomically bumps the craftsman's
`ratingAvg`/`ratingCount`.

## `notifications/{notifId}`
`userId`, `title`, `body`, `type` (`booking`|`message`|`review`|`reward`|`system`),
`data` (deep-link payload), `read`, `createdAt`.

## `referrals/{referralId}`
`code`, `ownerId`, `invitedUserId`, `status` (`pending`|`completed`),
`rewardGranted`, `createdAt`. One referral per invited user.

## `rewards/{rewardId}` — ledger (backend-written)
`userId`, `kind` (`points`|`featuredDays`), `amount`,
`reason`, `used`, `expiresAt?`, `createdAt`.
100 pts per completed invite; 300 pts = 7 days of featured placement.

## Business rules encoded
- **0% launch commission** — no commission fields anywhere (by design).
- **Phone masking** — raw numbers never in `craftsmen/`; reveal only via
  backend after booking acceptance.
- **Review integrity** — photo of completed work mandatory.
- **Cash first** — `paidConfirmed` is the payment primitive; online card
  payment (SATIM / CIB / EDAHABIA) is a roadmap item, not in the schema.
