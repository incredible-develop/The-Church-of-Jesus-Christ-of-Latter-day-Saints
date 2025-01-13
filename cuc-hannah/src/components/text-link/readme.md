# Text Link

Text that is used as a hyperlink or to trigger a remote component, such as a modal

## Props

- `label` - string, label of the link displayed to user
- `link` - object
  - `URL` - string, link URL
  - `newTab` - boolean, will determine if a link is opened in a new tab. true = New tab, false = Current tab.
- `variant` - string, determines the styling of the link, can be either "defaultText", which gives the link the default blue color, or "whiteText", which gives the link a white color
- `withMargin` - boolean, when set to "true" the link will appear with a bottom margin of 24px
- `remoteTriggerId` - string, this ID tells a remote component to do something. The remote component will listen via `postMessage` for this ID, and will do something when it sees it
