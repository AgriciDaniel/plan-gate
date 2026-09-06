# Cover provenance

`cover-plan-gate.jpg` is the committed cover, 2400x1018, 21:9.

It was made in two steps, so the artwork is generated but **the text is not**.

## 1. Artwork

Generated with Google Gemini `gemini-3.1-flash-image` (Nano Banana 2) via the
`banana-claude` skill, 21:9 at 2K, one attempt, $0.101, not retained by Google.
Full machine-readable provenance including the prompt hash is in
`cover-plan-gate.art.jpg.json`.

Prompt intent: a single path running left to right, a stack of paper resting on
it, a geometric archway straddling the path further along, and open bright space
beyond. Warm off-white, ink blue, muted amber. Upper-left deliberately left empty
for the title. No text was requested from the model.

## 2. Text

Composed as real vector text with `banana`'s `typeset.py`, which writes a
deterministic SVG over the raster. The title is never AI-rendered, so it cannot
be misspelled or malformed.

```json
[
  {"type":"text","text":"Plan Gate","x":210,"y":430,"font_size":168,
   "font_family":"Helvetica Neue, Helvetica, Arial, sans-serif",
   "font_weight":"600","fill":"#17385C","anchor":"start","letter_spacing":-2},
  {"type":"text","text":"Show the plan before you touch anything.","x":216,"y":530,
   "font_size":58,"font_family":"Helvetica Neue, Helvetica, Arial, sans-serif",
   "font_weight":"400","fill":"#5A6B7D","anchor":"start"}
]
```

Applied against the 3168x1344 artwork, then rasterized and resized to 2400px wide.

## Regenerating the text

The intermediate SVG and the full-resolution artwork are kept out of the repo
because together they are about 5 MB. To change the wording, re-run `typeset.py`
against the artwork with edited layer values above.
