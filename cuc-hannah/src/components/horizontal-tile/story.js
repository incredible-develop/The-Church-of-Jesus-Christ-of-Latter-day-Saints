import { storiesOf } from "@storybook/html";
import { text, number, boolean } from "@storybook/addon-knobs";
import { withReadme } from "storybook-readme";
import readme from "./readme.md";
import {
  layoutKnobs,
  backgroundKnobs,
  image,
  imageKnobs,
  link
} from "../../../.storybook/commonKnobs";

import horizontalTile from "./index";

const makeTile = (index) => ({
  heading: `Heading ${index + 2}`,
  content:
    Math.random() < 0.8
      ? `Some filler content.${
          Math.random() < 0.2
            ? ` An example of what longer text would do to the alignment and size of the tile.`
            : ""
        }`
      : "",
  image: image.array[index % image.array.length],

  ...link({
    linkKey: "portraitCardLink",
    URLLabel: "URL" + (index + 2),
    newTabLabel: "Open Url in New Tab " + (index + 2)
  })
});

const makeTiles = (number) => {
  const arr = [];
  for (let i = 0; i < number; i++) {
    arr.push(makeTile(i));
  }
  return arr;
};

const returnKnobs = () => {
  const numberOfTiles = number(
    "Number of Tiles",
    3,
    {
      range: true,
      min: 1,
      max: 15,
      step: 1
    },
    "Component"
  );
  return {
    type: "mo-horizontal-tile",
    tiles: [
      {
        primaryMeta: text("Primary Meta", "Primary Meta", "Component"),
        secondaryMeta: text("Secondary Meta", "Secondary Meta", "Component"),
        heading: text("Heading", "Baptism", "Component"),
        content: text(
          "Content",
          "Follow the Savior's perfect example",
          "Component"
        ),
        image: imageKnobs({
          imageProps: [{ ...image, groupId: "Component" }, 11]
        }),
        ...link({
          linkKey: "portraitCardLink"
        })
      },
      ...makeTiles(numberOfTiles)
    ],
    invertTextColor: boolean("Invert Text Color", false, "Component"),
    ...layoutKnobs(),
    ...backgroundKnobs()
  };
};

storiesOf("Horizontal Tile", module)
  .addDecorator(withReadme(readme))
  .add("Default", () => horizontalTile(returnKnobs()));
