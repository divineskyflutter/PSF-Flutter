# PSF App: Release Notes, Version 1.1.2 (Build 8)

## New feature: fix your details after the admin raises a query
If the admin marks some of your details as wrong, the app opens straight to those details after you log in.

- Only the marked fields can be edited. Everything else is locked.
- Marked fields show in red with a message saying which language to type in, and turn green once corrected.
- The app goes straight to the first section that has a problem (Personal Details, Nominee or Health) and scrolls to the field. Sections with no problem are skipped.
- **Language order:** Gujarati fields first, then Hindi, then English. Typing in the wrong language is blocked with a message.
- After each language round, a message tells you what was updated and what to enter next, in the language you selected.
- **Nominee:** all nominees with problems can be corrected together. Pressing Next saves each nominee one by one, clears their queries, then moves on to Health.
- **Health:** the marked questions, disease options and detail boxes are unlocked. Pressing Next saves your health details first, then clears the queries.
- **Finishing:** the Rules and Declaration step is skipped. You go straight to the Preview screen (with the book animation). Pressing Submit shows the "under review" screen.
- Details are always saved first, and only then is each query marked as solved.
- A short red note at the top of each step lists the fields the admin marked, so nothing marked is ever hidden.

## Every marked field can now be corrected
- **Personal Details:** photo, Aadhaar photos, PAN photo, signature, all three parts of the name in English, Hindi and Gujarati, father's name, date of birth, gender, marital status, address, village, taluka, district, state, occupation, Aadhaar number, PAN number and mobile number 2.
- **Nominee:** name, date of birth, relation, share, photo, Aadhaar number, Aadhaar photos and passbook/cheque photo.
- **Health:** every Yes/No question, all disease options, and every detail box (illness, hereditary illness, surgery and date, medication, allergy, other details).
- Fields nobody can change in the app (ID, status, login mobile number) are ignored so they never block you.

## Other improvements
- **Language button (top right):** opens the same language list as the side menu and changes the whole app. The saved details (name, address, village, nominee names, health details and so on) now also switch to the selected language, not just the labels. Numbers such as Aadhaar and PAN stay the same.
- **Login password:** the keyboard switches to numbers after 4 letters. If you switch keyboards yourself earlier, for example `NK1234`, it leaves your keyboard alone.
- **Member card:** shows only the address line.
- **Nominee Aadhaar:** the same Aadhaar number can no longer be used for two nominees.
- All new messages are available in English, Hindi and Gujarati.

## Fixes
- Marked fields that showed no red border on some accounts (name, date of birth, gender, marital status, mobile 2 and several Health details) are now highlighted.
- Fields such as Gender and HeartDisease were wrongly treated as Gujarati/Hindi fields. They are now treated as normal fields.
- If login finished before the field list had loaded, nothing was highlighted. Login now waits for it.
- The hereditary illness detail now shows in the selected language and is saved.
- Nominee Next no longer skips ahead without saving the nominee.
- Correct language names in the "updated" message.
- Fixed an error banner on the top bar and layout glitches on the correction screens.

## Note
Normal new registration works exactly as before. All of the above only applies when the admin has raised a query.
