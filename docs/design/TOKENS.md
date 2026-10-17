# Tokens

`design/tokens.json` is the only source for palette, spacing, radii, and motion.
Run `dart run tool/generate_tokens.dart` to produce
`lib/design/tokens.g.dart`. Feature code consumes the theme extension rather
than literal colors. The minimum target is 44 pt, or 56 pt in Workshop mode.
