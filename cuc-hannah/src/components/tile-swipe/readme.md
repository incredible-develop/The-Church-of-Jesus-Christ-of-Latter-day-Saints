# TileSwipe

Creates cards of links and media.

## Props

- `title` - string, creates a large title above the cards
- `layoutStyle` - object,
  - `Emphasized` - string, "emphasized" is where the first card is large and will take the height of two cards. The other cards will stack to 2 high. "singleRow" is for smaller cards with a single row of cards. Users can slide across to view more cards.
- `tiles` - array, each object is a tile. See `article-tile` for more details.

### Common Props

- `background` - object, see the `background` component for details
- `layout` - object, see the `layout` component for details
