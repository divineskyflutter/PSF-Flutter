# PSF App — Code Guide

Flutter app for **Parivar Suraksha Foundation (PSF)** members: sign in, see the
membership dashboard, view/edit the profile, and carry a digital member card
(with a wallet, QR code and downloadable PDF).

* State management / DI / routing / translations: **GetX**
* Networking: **Dio** (interceptors for auth, token refresh and errors)
* Languages: **English, Hindi, Gujarati** (`.tr` everywhere)
* Sizing: `.px(context)` (responsive) — never hard-coded pixel sizes in widgets
* Flavors: `dev` / `prod` (`lib/main_dev.dart`, `lib/main_prod.dart`)

Run / build (uses the FVM Flutter SDK):

```bash
.fvm/flutter_sdk/bin/flutter run --flavor dev -t lib/main_dev.dart
.fvm/flutter_sdk/bin/flutter build apk --release --flavor dev -t lib/main_dev.dart
```

---

## 1. Architecture at a glance

Each feature follows the same shape:

```
features/<name>/
  bindings/       GetX dependency wiring for the feature
  data/           models (JSON), remote datasources, repository implementations
  domain/         entities + repository interfaces (only where the feature needs them)
  presentation/   controllers (state), pages (screens), widgets
```

Cross-cutting code lives in `app/` (config, constants, routes), `core/`
(network, storage, localization, theme) and `shared/` (reusable widgets,
utils, models).

---

## 2. Folder map

### `lib/app/`
| File | What it holds / why |
|---|---|
| `bindings/initial_binding.dart` | Registers app-wide services (network, storage, language, loader…) at startup. |
| `config/app_flavor.dart`, `config/env/*` | Dev/prod environment values (base URL, keys). `*.g.dart` are generated. |
| `constants/api_end_points.dart` | Every backend URL in one place. **Added:** `getMemberQrCode` (`POST /api/Api/GetMemberQrCode?Id=`). |
| `constants/app_assets.dart` | Asset paths. **Added:** `cardPaper`, `chairmanSignature`. |
| `constants/app_colors.dart` | Theme colours. **Added:** `accentGold` (card trim / highlights). |
| `routes/app_routes.dart`, `routes/app_pages.dart` | Route names and the page + binding for each. **Added:** `/loans`. |

### `lib/core/`
| File | What it holds / why |
|---|---|
| `network/dio_client.dart` | Builds the Dio instance and attaches the interceptors. |
| `network/network_caller.dart` | The one API entry point (`get/post/patch…`). **Added:** `postRequestBytes` for endpoints that return an image/file (QR). |
| `network/interceptors/auth_interceptor.dart` | Adds the access token to requests. |
| `network/interceptors/token_refresh_interceptor.dart` | Single place that handles an expired session: refresh once, retry the request. |
| `network/interceptors/error_interceptor.dart` | Turns errors into toasts / the offline dialog. **Added:** `suppressErrorToast` so a request can fail quietly (the QR shows its own inline "retry"). |
| `network/auth/token_manager.dart` | In-memory access/refresh token (seeded from secure storage at startup). |
| `storage/app_prefs.dart`, `app_secure_storage.dart` | SharedPreferences (cache) and flutter_secure_storage (tokens, member id). |
| `localization/en_us.dart`, `hi_in.dart`, `gu_in.dart` | All translation keys. **Added:** card, drawer, wallet, enum (`enum_*`) and layout-switch keys. |
| `localization/language_controller.dart` | Current language + switching. |
| `theme/*` | App theme and theme controller. |

### `lib/features/auth/` — sign-in and registration
* `presentation/pages/login_screen.dart` + `controllers/login_controller.dart` — mobile + password login.
* `data/repositories/login_repository_impl.dart` — calls `MemberLogin`, parses the nested response (`memberDetail`, `nominees`, `healthDeclaration`, tokens) and caches it.
  * `ignoreLoginStatusUntilBackendFixesIt = true` — the backend currently returns `status:false` even on success; this flag lets login through when member data is present. **Set it to `false` once the backend is fixed.**
* `data/models/member_model.dart` — the member profile. **Added:** `memberNo` (the real member number, separate from the database id).
* `pages/registration/*` — the 4-step registration form, preview and pending screens.

### `lib/features/enum_bundle/`
* `data/models/enum_bundle_model.dart` — Gender / status / marital-status lists from `GetEnumBundle`. **Changed:** `nameFor(..., localized:)` returns names in the selected language (`Male` → `पुरुष`) via `enum_*` keys; `localized: false` gives plain English.
* `data/repository/enum_bundle_repository.dart` — fetches the bundle.

### `lib/features/home/`
* `presentation/pages/home_screen.dart` — Home tab (dashboard).
* `presentation/widgets/home_header.dart` — **Rewritten:** pinned, wavy gradient header that collapses smoothly; menu button opens the side drawer.
* `member_summary_card.dart`, `payment_reminder_card.dart` — dashboard cards.

### `lib/features/loans/`
Loans tab and instalment details (data → domain → presentation). Only small
route/UI touch-ups this round.

### `lib/features/navigation/` — the signed-in shell
| File | What it holds / why |
|---|---|
| `presentation/pages/main_navigation_screen.dart` | The shell: Profile / Home / Card tabs in an `IndexedStack` (tabs keep state), floating bottom bar, swipe-from-left drawer. |
| `presentation/controllers/main_navigation_controller.dart` | Selected tab + the `Scaffold` key (so any tab can open the drawer). Tab order: Profile, Home (opens first), Card. |
| `presentation/widgets/app_bottom_nav_bar.dart` | **Redesigned:** compact floating bar, raised Home button, no ripple. |
| `presentation/widgets/app_side_drawer.dart` | **New:** full-screen frosted drawer — member photo/name/mobile (photo opens My Profile) and the wallet + card (`MemberWalletPanel`). |
| `bindings/main_navigation_binding.dart` | Wires every tab's controllers, including `MemberCardController`. |

### `lib/features/profile/`
* `pages/profile_screen.dart` — Profile tab.
* `pages/my_profile_page.dart` — **Reworked:** header + sliding Personal / Nominee / Health tabs, framed images, image-count badge.
* `widgets/my_profile_*_tab.dart` — the three tabs.
* `widgets/profile_card_style.dart` — **New:** shared card look (border + shadow) and `FramedImage` used for every photo on My Profile.
* `widgets/document_thumbnail.dart` — labelled framed image tile.
* `controllers/profile_controller.dart` — profile, nominees, health data and the enum bundle. **Changed:** `ensureEnumBundle()` fetches the bundle if login hasn't cached it yet, so profile/card show names instead of ids.

### `lib/features/member_card/` — the digital member card (new feature)

```
data/
  member_card_data.dart        display-ready card values (all plain strings)
  member_card_repository.dart  calls GetMemberQrCode; image download helper
  member_qr_image.dart         parses the QR response (raw bytes / URL / base64)
presentation/
  controllers/member_card_controller.dart
  member_card_layout.dart
  printed_card_pdf.dart
  pages/member_card_screen.dart
  widgets/
    printed_card_style.dart
    horizontal_card_faces.dart
    vertical_card_faces.dart
    member_wallet_panel.dart
    horizontal_wallet_panel.dart
    vertical_wallet_panel.dart
    wallet_pouch.dart
    wallet_controls.dart
    wallet_layout_switch.dart
    member_qr_view.dart
```

| File | What it holds / why |
|---|---|
| `member_card_data.dart` | One flat model with everything the card shows (name, member no, mobile, DOB, address, photo…). Cards and PDF only read this — no parsing in widgets. |
| `member_card_repository.dart` | `getMemberQr(id)` → raw bytes → `MemberQrImage`. |
| `member_qr_image.dart` | The QR endpoint's format isn't documented, so this accepts raw image bytes, a URL or base64 (also inside a JSON envelope). |
| `member_card_controller.dart` | Loads the QR; `buildData(localized:)` turns the cached profile into `MemberCardData` in the selected language; holds the chosen `layout`; `downloadCard()` builds the PDF and opens the save dialog. `setLayout` / `takeResumeOpen` let a layout switch keep the wallet open. |
| `member_card_layout.dart` | `enum MemberCardLayout { horizontal, vertical }`. |
| `printed_card_style.dart` | Shared look of the printed card: colours, paper texture, founders' details, member-number format (`PSK  -`), the chairman signature widget, `CardShell`, `CardFieldRow`, `CardTimelineIcon`. Both layouts use it so they always match. |
| `horizontal_card_faces.dart` | `HorizontalCardFront/Back` — exact reproduction of the foundation's printed card (landscape). Everything is scaled from a 1050-wide design, so it looks identical on screen and in the PDF. |
| `vertical_card_faces.dart` | `VerticalCardFront/Back` — same design re-flowed for portrait (540-wide design). |
| `horizontal_wallet_panel.dart` | Wallet for the landscape card: the cover slides in from the **left**, tap → slides out to the left, tap the card to flip (3-D), flip arrows, layout switch, Download, Close. |
| `vertical_wallet_panel.dart` | Same for the portrait card: the pocket drops from above and slides down when opened. |
| `member_wallet_panel.dart` | Picks the panel for the selected layout and cross-fades between them. |
| `wallet_pouch.dart` | The wallet drawings: `WalletBack` and `WalletPocket` (QR, stitching, "tap to open"). |
| `wallet_controls.dart` | Shared buttons: label pill, flip arrows, Download button. |
| `wallet_layout_switch.dart` | The Horizontal \| Vertical switch (sliding highlight). |
| `member_qr_view.dart` | QR box with loading and "unavailable — tap to retry" states. |
| `printed_card_pdf.dart` | Builds the PDF: renders the same card widgets off-screen to images and places them on the page (so Gujarati/Hindi text needs no PDF fonts). Horizontal → front above back; vertical → side by side; 16 pt margin, 14 pt gap. |
| `member_card_screen.dart` | The Card tab — intentionally empty for now (the wallet lives in the drawer). |

**Card data flow:** login caches profile → `ProfileController` → `MemberCardController.buildData()` → `MemberCardData` → card faces (screen) and `PrintedCardPdf` (download).

**Assets** (`assets/images/card/`): `card_paper.jpg` (paper texture) and
`chairman_signature.png` (signature block taken from the printed card, made
transparent).

### `lib/shared/`
| File | What it holds / why |
|---|---|
| `utils/app_date_format.dart` | **New:** dates in the selected language (`medium`) and `dd / MM / yyyy` (`numeric`). Needs `initializeDateFormatting()` (called in `main.dart`). |
| `utils/localized_field.dart` | Picks the Hindi/Gujarati transliteration of a field when available. |
| `extensions/new_responsive_extensions.dart` | The `.px(context)` sizing helper. |
| `widgets/common/app_header_curve_clipper.dart` | **Changed:** wave clip for every gradient header (`waveScale`, `mirrored`). |
| `widgets/common/app_sub_page_header.dart` | **Changed:** fixed curved header for sub-pages (content scrolls under it), plain back arrow. |
| `widgets/windows/common_image_preview.dart` | **Changed:** zoomable full-screen image preview. |
| `widgets/*`, `utils/*` | Buttons, text fields, loaders, dialogs, validators, toast, PDF helpers — unchanged. |

### `lib/main.dart`
**Changed:** calls `initializeDateFormatting()` so dates can be shown in Hindi/Gujarati.

### Native / config
| File | Change |
|---|---|
| `android/app/src/main/AndroidManifest.xml` | `EnableImpeller=false` — on the test phone (moto g51 5G) Impeller made animations ~120 ms/frame; Skia ~5 ms. Remove the entry to go back to Impeller later. |
| `pubspec.yaml` | Version `1.1.0+3`; registers `assets/images/card/`. |

---

## 3. Key decisions (the "why")

* **Card = widgets, PDF = the same widgets as images.** One design, so the PDF is exactly what the member sees, in their language, with no font bundling.
* **Design-width scaling (`f(v) = v × width / 1050`).** The card looks identical at any size (phone, PDF).
* **Wallet pieces move by the same pixel distance** so the wallet reads as one solid object; animations use transition widgets around prebuilt children to avoid per-frame rebuilds.
* **QR has its own failure state** and never blocks the card (the endpoint has failed on the server before).
* **Member number is separate from the DB id.** It shows `PSK  -` until a real `memberNo` exists.
* **Layout choice is in memory only** (not saved between app restarts).

---

## 4. Known issues / to-dos

* Backend login returns `status:false` on success → bypass flag in `login_repository_impl.dart` (revert when fixed).
* `GetMemberQrCode` returned empty 500 errors earlier; it loaded in the latest test. The card handles both cases.
* `MemberCardRepository.downloadImage` is currently unused (kept for future image embedding).
* Impeller opt-out is deprecated by Flutter; revisit when Impeller performs well on target devices.
