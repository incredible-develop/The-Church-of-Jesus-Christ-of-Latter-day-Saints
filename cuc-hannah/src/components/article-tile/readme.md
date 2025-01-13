# ArticleTile

Creates a single tile to be used with tile swipe.

## Props

- `heading` - string, the main large text. The hyper link is in this text.
- `primaryMeta` - string, optional small text that goes above the heading and below the image.
- `secondaryMeta` - string, optional small text that does under the heading and content. It displays in all caps.
- `content` - string, displays text between the heading and secondary meta. This text will need to be short in order for all of it to be visible `layout` is set to "singleRow."
- `pageGlobals` - Look at the comment for the `pageGlobals` variable in the component [index.js](/src/components/index.js) file
- `link` - object
  - `URL` - string, the url that opens when clicking the link. urls with the same domain will open in the same window. urls outside the domain open in a new tab
  - `newTab` - boolean, will determine if a link is opened in a new tab. true = New tab, false = Current tab.
- `download` - string, uses a url to select a file to download. Concats `?download=true` to the end of the url.
- `icon` - string, uses the name of an std icon. Only the "video" icon is available because the icon is hard-coded in `index.js`.
- `image` - object, titan image that will act as a thumbnail until the user plays the video. Requires `"type": "titan-image"`, `titanId` and `renditions` array. Publisher uses the `titanId` to pull the rest of the information.
