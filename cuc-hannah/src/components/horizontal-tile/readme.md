# Horizontal Tile

Creates a small picture with a heading and text. It can be used as a link

## Props

- `invertTextColor` - boolean, "true" will turn the text white and "false" will turn it dark.
- `tiles` - array  
   Each tile is an object
  - `pageGlobals` - Look at the comment for the `pageGlobals` variable in the component [index.js](/src/components/index.js) file
  - `heading` - string, hanges heading for tile
  - `content` - string, changes text in tile
  - `image` - object, chooses a titan image. Requires `"type": "titan-image"`, `titanId` and `renditions` array. Publisher uses the `titanId` to pull the rest of the information.
  - `portraitCardLink` - object, the heading and the image become links
    - `URL` - string, url to address. If local, will open on the same page. If a different domain, opens in new tab.
    - `newTab` - boolean, will determine if a link is opened in a new tab. true = New tab, false = Current tab.

### Common Props

- `background` - object, see the `background` component for details
- `layout` - object, see the `layout` component for details
