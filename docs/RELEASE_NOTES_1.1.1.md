# Release notes — 1.1.1 (build 7)

Dev-flavor release. Main feature: **query-based member form editing after login**.

## What's new

### Query-resolution flow (edit mode only)
When an admin flags specific fields on a member's record, `MemberLogin` returns `isInEditMode: true` plus a `queries` list. The app now opens the registration wizard in a restricted mode:

- Only the flagged fields are editable; everything else is locked (images, dropdowns, toggles and chips included).
- Wizard opens directly on the first table that has queries (Personal Details → Nominee → Health Declaration); tables with no queries are skipped going forward.
- Each field's required script comes from its enum name: `G…` → Gujarati, `H…` → Hindi, no prefix → English. Wrong-script input is blocked with an inline message and a toast.
- Language passes on the same screen: Gujarati → Hindi → English. After each pass the app saves, resolves that pass's queries, and shows a toast such as "Gujarati data updated. Now enter Hindi data." (text follows the selected app language).
- Every unresolved queried field is red and shows "This field must be entered in <language>"; it turns green once edited.
- Auto-scroll and focus jump to the first field that still needs fixing.
- No transliteration/translate calls are made in this mode; the member types each language themselves.
- Nominee step: all queried nominees are editable together. Next saves each queried nominee (`SaveNominee`, one at a time), then resolves each nominee's queries one by one, then finalises the step. Nominees are identified by `itemNumber` (1-based, ascending `nomineeId`).
- Health Declaration: queried yes/no toggles, disease chips and detail fields are unlocked (including the hereditary-illness detail, even if the checkbox is unticked). Next saves first, then resolves all queries one by one.
- The Rules step (step 4) is skipped in this mode: after the last queried step the app opens Preview directly; **Submit** calls `SavePreviewScreen` and opens the review ("awaiting approval") screen.
- Duplicate nominee Aadhaar numbers are rejected across visible nominee slots.

### Other changes
- Top-right language icon on the wizard (query mode) opens the same language sheet as the drawer and changes the real app language; labels and toasts follow it.
- Login password field switches from the letters keyboard to the number pad after exactly 4 letters (like the PAN field). If the member switches keyboards themselves earlier (e.g. `NK` then digits), nothing is auto-switched.
- Member card / wallet panels now show only the address line (no village/taluka/district/state).
- New localized strings (English / Hindi / Gujarati) for all query-mode messages and toasts.

## APIs

| API | Change |
|---|---|
| `POST /api/Api/MemberLogin` | Response now parsed for `queries[]` (`queryId`, `tableId`, `fieldId`, `memberId`, `isResolved`, `itemNumber`). Not persisted; in-memory for the session only. |
| `GetEnumBundle` | Four new request flags/lists: `Querytables`, `tblMemberField`, `tblNomineeField`, `tblHealthDeclarationFields` (used to map a query's `fieldId` to its `G`/`H`/plain name). |
| `POST /api/Member/QueryResolve` | **New.** Body `{ "id": <queryId> }`. Called once per resolved query, sequentially, after the related save succeeds. |
| `SaveMemberPersonalDetail` | Existing. Called before resolving Personal Details queries. |
| `SaveNominee` (+ `SaveDocument`) / `SaveNomineeScreen` | Existing. Each queried nominee is saved, then its queries resolved, then `SaveNomineeScreen`. |
| `SaveMemberHealthDeclaration` | Existing. Called before resolving Health queries. |
| `SavePreviewScreen` | Existing. Called on Submit from Preview. |

All query-mode behaviour is gated on the query state being active, so the normal registration flow is unchanged.

## Notes
- Version bumped from 1.1.0+6 to 1.1.1+7.
- Test coverage was manual, on-device (moto g51 5G, dev debug build): full flow login → Personal Details (3 passes) → Nominee → Health → Preview → Submit → review screen, with the backend confirming all queries cleared.
- Real Gujarati/Hindi text entry could not be automated with adb; those passes were verified by re-touching fields that already held valid text.
