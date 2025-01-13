# Download Button

Index.js returns a customizable button element with `data-type="download-button"` and the browser.js returns a class that can add functionality to a button.

## Props

### Index Props

- `ariaLabel` - string, will be the aria-label for the button
- `children` - array`<string>` | (defaultChildren: array`<string>`) => array`<string>`, the child elements to go inside the download button. To access the default children, you can use a function, which gives access to the default children, and return an array of strings.
- `cssClasses` - array`<string>`, css classes that can be passed from a parent component. You can include postcss classes like `styles.download` because postcss classes return strings.
- `htmlAttrs` - array`<string>`, a list of HTML attributes that can be passed to the button element. The attribute and value should be included in the same string.

### Browser Props

- `element` - HTML Element, the button you wish to click to trigger the download
- `showProgress` - (DownloadButton) => void , a function that fires immediately when the user clicks the download button, without waiting for `onClick` to finish. The default will show the spinning icon.
- `onClick` - (DownloadButton) => void | Promise, the main function that will perform the download
- `onLoad` - (DownloadButton) => void | Promise, any additional processing needed after `onClick` is finished
- `showComplete` - (DownloadButton) => void, a function that fires after the `onLoad` is finished. The default will hide the spinning icon.
- `onError` - (Error, DownloadButton) => void, fires on any unresolved error

## Dev Details

- All of the Browser Props that are functions have access to the DownloadButton instance.

- When a user clicks the button the sequence of events is as follows:

  - `onClick`
  - `showProgress`
  - `onLoad`
  - `showComplete`

- If an error occurs the `showComplete` fires before `onError`, allowing for cleanup inside `onError`.

- Example:

```javascript
// index.js
import downloadButton from "../download-button";

export default function ({ videoUrl }) {
  const vidDownload = downloadButton({
    htmlAttrs: [`video-url="${videoUrl}"`]
  });
  return `<div>${imgDownload}</div>`;
}
```

```javascript
// browser.js
const downloadBtn = document.querySelector('[data-type="download-button"]');

new DownloadButton({
  element: downloadBtn,
  onClick: () => someDownloadFunction(element.getAttribute("video-url"))
});
```
