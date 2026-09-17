# Release Notes – PSF Application (Registration Module Update)

નમસ્તે! 🙏

આ update માં Registration flow ના ઘણા બધા issues fix કરવામાં આવ્યા છે, અને હવે બધું બરાબર (properly) કામ કરે છે. નીચે બધા changes ની list છે:

## ✅ શું શું Fix થયું છે

**Signature & Preview Screen**
- Preview screen માં signature image હવે બરાબર center માં દેખાય છે.
- Mobile Number 2 field ખાલી હોય તો "Not provided" ના બદલે હવે just blank દેખાય છે.

**Date Picker (Date of Birth વગેરે)**
- Date picker સંપૂર્ણપણે નવેસરથી (from scratch) બનાવ્યું છે — હવે dd/mm/yyyy format બરાબર follow થાય છે.
- "/" separator કાયમ માટે fix રહે છે, અને day/month માં એક જ digit લખો તો આપોઆપ 0 add થઈને (દા.ત. 5 → 05) બરાબર થઈ જાય છે.
- ખોટી date (દા.ત. 32 તારીખ) enter કરો તો proper validation error આવે છે — અને error message પણ તમારી selected language (Hindi/Gujarati/English) માં જ દેખાય છે.
- Typing કરતી વખતે number clip/cut થઈ જવાની issue પણ fix કરી છે.
- Age હવે years અને months બંને સાથે દેખાય છે (પહેલા ફક્ત years હતું).

**PAN Card Field**
- PAN card number type કરો ત્યારે keyboard automatic switch થાય છે — પહેલા 5 letters માટે alphabet keyboard, પછી 4 digits માટે number keyboard, અને છેલ્લે 1 letter માટે ફરી alphabet keyboard.
- Number ની વચ્ચે (middle) થી કોઈ character delete કરો ત્યારે વધારે characters delete થઈ જવાની bug હતી — એ પણ fix કરી છે.

**Registration Pending Screen (Success Screen)**
- Fireworks/crackers animation હવે continuously ચાલે છે, વચ્ચે અટકી ને ફરી શરૂ થાય એવું feel નથી થતું.
- Fireworks sound effect add કર્યો છે — real fireworks recording માંથી.
- Sound ની clarity માટે background noise ઓછો કરીને only crackers/pops નો sound rakhyo છે.
- Sound હવે loop માં continuously play થાય છે, વચ્ચે pause-play જેવું feel નથી થતું.
- Call કે WhatsApp icon પર tap કરીને app background માં જાય, ત્યારે sound આપોઆપ બંધ થઈ જાય છે, અને પાછા app માં આવો ત્યારે ફરી શરૂ થાય છે.
- WhatsApp icon હવે real WhatsApp logo બતાવે છે (પહેલા generic chat icon હતું).

---

## ⚠️ ધ્યાન રાખવા જેવા 3 Points (Important Notes)

**1️⃣ Splash Screen Background Image**

Splash screen ની image quality increase કરી હતી, પણ result બરાબર નથી લાગતું. આ માટે પહેલા decide કરવું પડશે કે exactly કેવા type નું background/image જોઈએ છે (style, color, design) — એ confirm થાય પછી directly એ જ final image use કરી લઈશું, વધારે changes ની જરૂર નહીં પડે.

**2️⃣ Fireworks/Crackers Sound**

Sound effect implement કરી દીધું છે અને હાલ પૂરતું બરાબર લાગે છે. Testing દરમિયાન કોઈ issue મળે તો next build માં fix કરી દઈશું.

**3️⃣ PAN Card Keyboard – Final Behavior**

PAN field માં હાલ 5 alphabet લખાય પછી keyboard close થઈને number keyboard open થાય છે — આ જ final configuration છે. Android ના standard system keyboard માં આનાથી વધારે smooth/flexible switching શક્ય નથી (આ Android ની પોતાની limitation છે, app ની નહીં). ભવિષ્યમાં જો એકદમ smooth switching જોઈએ, તો પોતાનું custom keyboard બનાવવું પડે — જે એક અલગ, મોટું અને time-consuming કામ છે.

---

બાકી બધું test કરી લીધું છે, હવે full rebuild કરીને check કરી લેજો. 🎉
