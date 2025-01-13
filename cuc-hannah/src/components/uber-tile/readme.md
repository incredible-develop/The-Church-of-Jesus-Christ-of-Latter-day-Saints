# Uber Tile

Uber Tile allows for variety of options to simplify things for publishers and also give a variety of options that help the user have a good experience (fading to dark rather than a whole tile dark, etc.)

This has a bit of unique handling of its padding. It will do the normal `no-padding` if there is no background and `hasBg` padding if there is a background. But if the `content-width` is set to `flush` it will use some larger padding specific to Uber Tile. The `flush` for extra padding can be set on desktop vs mobile separately.

## Props

- `barColor` - string, color of the horizontal bar on the tile
- `heading` - string, heading for the tile
- `link` - object, contains an internal or external URL (string) that the user will be sent to when the tile is clicked on and a label (string) for a text link. Text links are only used on text only tiles.
- `body` - string, body for the tile
- `verticalStyle` - string, changes the vertical alignment
- `horizontalStyle` - string, changes the horizontal alignment
- `textStyle` - string, justification for text
- `invertTextColor` - string, specifies whether text/icons should be white
- `headingFont` - string, changes font for heading
- `bodyFont` - string, changes font for body
- `btn` - object - this button is visible when there is a button label
- `aspectRatio` - string, select an aspect ratio for the tile
- `video` - object, contains the props for a Video component (see `Video` for details)
- `remoteTriggerId` - string, this ID tells a remote component to do something. The remote component will listen via `postMessage` for this ID, and will do something
  when it sees it
- `isExtraBold` - boolean, specifies whether the heading will be extra bold or not

### Common Props

- `layout` - object, see the `layout` component for details
- `background` - object, see the `background` component for details; gradient will appear when background image or video is applied
