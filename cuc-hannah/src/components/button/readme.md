# Button

Creates a button that can include a label, link, download reference, etc.

## Props

- `label` - string, the text inside the button
- `title` - string, ARIA description of the button
- `link` - object
  - `URL` - string, the url that opens when clicking the link. urls with the same domain will open in the same window. urls outside the domain open in a new tab
  - `newTab` - boolean, will determine if a link is opened in a new tab. true = New tab, false = Current tab.
- `variant`- string, changes style properties of the button
- `colorVariant` - string, changes additional color properties of the button
- `icon` - string, the name of the icon. Icon will go before the label text
- `iconPosition` - string, places the icon before or after the button text
- `invertArrowDirection` - boolean, if true, points the direction of the text-link variant to the left (mostly used in the back button on the `stepped-form`)
- `btnJustification` - string, adjust the vertical alignment
- `size` - string, choose between "big" and "small"
- `remoteTriggerId` - string, this ID tells a remote component to do something. The remote component will listen via `postMessage` for this ID, and will do something when it sees it
- `downloadRef` - string, uses a url to select a file to download. Concats `?download=true` to the end of the url.
- `fakeButton` - boolean, is this a fake button, meaning a wrapping element is an `a` or `button` so it is just there for looks. a `link.url` will trump this so needs to be blank

### Common Props

- `background` - object, see the `background` component for details
- `layout` - object, see the `layout` component for details
