# Likes

Button that tracks likes of users

## Props

- `counterGroup` - object, the group in the database that the counter will read and write to
- `counterId` - string, a specific id from above the group in the database that the counter will read and write to
- `justification` - boolean, adjusts the horizontal alignment of the button
- `ariaLabel` - string, specifies what the aria label is, this is set in the string bundles
- `countUpdatedString` - string, used for accessibility purposes as part of the `aria-label` for screenreaders to announce that the count has been updated. Set in string bundles

### Common Props

- `background` - object, see the `background` component for details
- `layout` - object, see the `layout` component for details

## Dev Details

- The Like button uses AWS to store the number of times users have clicked to "like" specific content.
- Each Like button MUST have a `counterGroup` ID. AWS stores the number of clicks for the button under this ID. A `counterId` can be used as a subset of the `counterGroup`. This is set up so that Like buttons can be used to track individual actions as well as a collection of actions.
- For example, a Like button could have a counterGroup set as "lightTheWorldVideos". This would track all of the times users clicked a Like button to "like" a Light The World Video. If the button also had a counterId set for a specific video, for example "day1Video", the counter would count and display the number of times users clicked specifically to "like" the Day 1 Light the World video, and it would also update the total number of likes for the "lightTheWorldVideos" group.
- Each time a Like button is clicked, a cookie is set signifying that the button has been clicked. Once the cookie is set, the button is disabled to the user.
