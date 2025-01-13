# Audio Player

Plays a piece of audio, includes basic audio controls and has download capabilities.

## Props

- `audioSrc` - string, the src of the audio
- `trackName` - string, displays bold above the audio player
- `artistName` - string, displays between the `trackName` and audio player
- `fileName` - string, will be the name of the file when someone downloads the audio
- `color` - string, can be either "Light" or "Dark." Will change the color of the control icons, the current time span and the duration span.
- `ariaLabels` - object <String>, aria labels for the control buttons. If left blank, the corresponding button will not be visible on the audio player.
  - `volume`
  - `replayTen`
  - `playPause`
  - `forwardTen`
  - `download`

### Common Props

- `background` - object, see the `background` component for details
- `layout` - object, see the `layout` component for details

## Dev Details

- If the `audioSrc` is not a same-origin URL, the download will not start automatically. Instead the user will be redirected to the href and will be able to download the file from there. https://developer.mozilla.org/en-US/docs/Web/HTML/Element/a
- This component allows the audio player to stay ltr for rtl languages per conventions set forth by the web. See https://material.io/design/usability/bidirectionality.html#mirroring-elements
