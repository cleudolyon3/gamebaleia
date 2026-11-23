# Whale game images — English prompts (copy and paste each one)

TIP: generate ONE image per prompt. Keep the same style in all of them.
Add this line at the END of every prompt:
**STYLE:** cute children's educational game illustration, flat vector look, bold clean outlines, bright saturated colors. **NO TEXT, NO LETTERS, NO WATERMARK, NO PEOPLE.**

For "cut-out" items (1, 2, 5, 6, 7, 8) also add: **plain pure white background, single object centered, full object visible, no shadow, no scenery.**

---
## 1. baleia_fechada.png  (aspect 2:1)
A single humpback whale, side view, facing RIGHT, swimming, mouth CLOSED. Dark blue-gray back, light cream belly with throat grooves, very long pectoral fin, small bumps on the snout, small friendly eye, tail slightly curved. Cute children's game character.

## 2. baleia_boca.png  (aspect 2:1)
The SAME humpback whale, same size, same side view facing RIGHT, now with the mouth WIDE OPEN: lower jaw dropped down, pink-red mouth interior, tongue, rows of baleen plates hanging from the upper jaw. Calm, friendly, NOT scary. No teeth. Same colors as the closed-mouth whale.

## 3. fundo_mar.jpg  (16:9, 1920x1080)
Underwater seascape, tropical turquoise sea, sunbeams coming from the surface, colorful coral reef and sandy bottom, a few tiny fish far away. The center area is EMPTY and calm (nothing big in the middle). No whales, no people, no boats.

## 4. fundo_menu.jpg  (16:9, 1920x1080)
Tropical sea at sunrise, half above and half below the water line: orange-pink sky, gentle waves, tiny islands in the distance, sunbeams entering blue water. Empty space in the center. No people, no boats, no animals.

## 5. rede_cai.png  (1:1)
A tangled round fishing net floating in the sea, beige-yellow ropes, small red buoys on the edge, front view. Looks dangerous but cartoon-style.

## 6. saco_plastico.png  (1:1)
A crumpled transparent plastic bag floating in water, see-through with blue reflections, handles floating. Cartoon style.

## 7. krill.png  (3:2)
Three tiny orange-pink krill shrimp swimming together, cute, black dot eyes. Cartoon style.

## 8. barco.png  (2:1)
Side view of a large fishing boat, dark brown hull, white cabin, a crane with a hanging cable. NO people, NO text on the hull. Cartoon style.

---
## DEFEAT SEQUENCE (the student loses: whale is caught and sinks)

## 9. baleia_pescada.jpg  (16:9, 1920x1080)
Underwater view: a humpback whale tangled in a big yellow fishing net, being pulled up by a rope toward the dark hull of a fishing boat at the top of the picture. Bubbles and light rays. Sad but child-friendly mood: NO blood, NO injuries, NO people. Cold blue colors, the net in yellow.

## 10. baleia_afunda.jpg  (16:9, 1920x1080)
A humpback whale sinking slowly into deep dark water, side view, pieces of broken net floating above it, a trail of bubbles going up, one faint beam of light far above at the surface. Sad and quiet but child-friendly: NO blood, NO people. Navy blue and black colors.

---
## NEGATIVE PROMPT (if your tool has this field)
text, letters, words, logo, watermark, people, humans, faces, blood, gore, realistic photo, cartoon characters from movies, extra whales, extra limbs

## IF THE RESULT IS WRONG
- Whale looks like a shark or fish: add "humpback WHALE, a large marine MAMMAL, NOT a shark, NOT a fish, NOT a dolphin".
- Cartoon bubbles or text appear: repeat "no text, no letters".
- Background is not white: add "isolated on pure white #FFFFFF background, sticker style".

---
## OPTIONAL VIDEO (Veo / Sora / Runway / Kling)
**Video A – whale opens its mouth (6 s):**
Underwater, fixed camera. A cartoon humpback whale swims toward the camera and slowly opens its huge mouth, a cloud of tiny krill is sucked in, blue sunbeams, smooth motion. Children's animation style. No text, no people.

**Video B – caught and sinking (10 s):**
Children's animation style. Shot 1: a humpback whale swims calmly. Shot 2: a fishing net drops from above and wraps around it. Shot 3: the net is pulled up by a cable toward a fishing boat hull at the top of the frame. Shot 4: the cable releases and the whale sinks slowly into dark water with bubbles. Ends in dark blue. No people, no blood, no text.

---
## Where to save
`assets/img/` with EXACT names: baleia_fechada, baleia_boca, fundo_mar, fundo_menu, rede_cai, saco_plastico, krill, barco, baleia_pescada, baleia_afunda (.png, .webp or .jpg).
For white-background items run: `python tools/tirar_fundo.py assets/img/NAME.png`
