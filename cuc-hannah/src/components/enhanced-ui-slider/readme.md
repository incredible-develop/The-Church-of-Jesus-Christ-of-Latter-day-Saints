# Enhanced UI Slider

A container for flickity that houses several components is a horizontal container.

## Props

- `components` - array<Object>, the components that will be displayed within the slider. Each element will be wrapped in a cell. The data for the cells may need transforming before being rendered.
- `size` - string, can be "small" or "large". It will set the cell widths to "narrow" when small and to "normal" when large.
- `wrapAround` - boolean, true means that the carousel wraps around and repeats after the last index and before the first.
- `ratio` - string, sets an aspect ratio for media being passed into the slider. This ratio will override the aspect ratios set in the children components.
- `borderRadius` - string, will set a border radius for media being passed into the slider. This border radius will override the border radius set in the children components.
- `ariaPrevious` - string, will set an aria-label to the bottom previous arrow.
- `ariaNext` - string, will set an aria-label to the bottom next arrow.
- `captionAlignment` - string, left or center text alignment on the caption (although whatever component is rendered will be passed this variable)
- `invertTextColor` - boolean, on true will invert text color to white.
- `pageGlobals` - Look at the comment for the `pageGlobals` variable in the component [index.js](/src/components/index.js) file
- `uniqueKey` - string, a unique string that will modify remote triggers and display dependencies when multiple forms are on the same page. This value is generated dynamically, not by by the CMS.

### Common Props

- `background` - object, see the `background` component for details
- `layout` - object, see the `layout` component for details

## Dev Details

- The top arrows only display when the UI Slider content width is set to "normal".
- Most data needs to be transformed before being passed into the `components` array. When adding compatibility for a new component, be sure to check any properties that need to be changed.
- The data attributes `contains-primary-content` and `is-primary-content` are used to display and hide content in components while they are not in the selected cell. The `contains-primary-content` should go in the parent element. All content in the parent element will be hidden while that carousel cell is not selected. To display the primary content while a cell is not selected, add the `is-primary-content` to that element. When a cell is selected, all content inside the `contains-primary-content` element will be visible.

For Example:

```html
<!--All the div contents will be hidden because of the contains-primary-content attribute-->
<div contains-primary-content class="carousel-cell">
  <!--The is-primary-content attribute unhides the img tag-->
  <img is-primary-content src="evil-cats.jpeg" />
  <!--The p and button tag will be hidden until this carousel cell is selected-->
  <p>A description about cats and how unbearable they are.</p>
  <button>Click Here to Buy a Dog Instead</button>
</div>
```
