# Icon

Script that injects a span for a given icon, then replaces it via JS with the actual SVG

## Props

- `name` - string, the filename of the svg (minus the `.svg` part)
- `pkg` - string, which collection of icons to use. This has been depreciated
- `title` - string, title text of svg
- `inline` - boolean, should the svg coe be put inline instead of a reference to be injected via JS later

## Dev Details

- For the component to work, you have to specify the correct package that corresponds to the icon name. If the `pkg` and `name` do not correspond, the component will return an empty `<span>`. By default, it is set to the "std" package.
