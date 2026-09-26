# Satoshi in published artifacts (owner only)

Font host: https://claude.ai/artifact/Drxp3yVXSG5JMdwuiFj8MB
Asset ids: Variable `3cc611628fed814f55e39ca95a23e274`, Italic `27f4bcb0e0b46ae13ab9cd1f87677f85`.

1. Publish the new artifact with `capabilities: {"assets": {}}`.
2. Copy the fonts: Artifact publish with `url` = the new artifact, `asset: true`, `from_url` = the font host URL, `asset_ids` = both ids above. Use the returned URLs exactly.
3. Declare them:
   ```css
   @font-face { font-family: Satoshi; src: url("<returned Variable URL>") format("woff2"); font-weight: 300 900; font-display: swap; }
   @font-face { font-family: Satoshi; src: url("<returned Italic URL>") format("woff2"); font-weight: 300 900; font-style: italic; font-display: swap; }
   ```
4. Set `--pa-font-sans: Satoshi, -apple-system, system-ui, sans-serif;`.

A page that declares `assets` is organization-internal and cannot be shared publicly.
