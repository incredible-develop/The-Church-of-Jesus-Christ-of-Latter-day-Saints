import { storiesOf } from "@storybook/html";
import { text, select, number } from "@storybook/addon-knobs";
import { withReadme } from "storybook-readme";
import readme from "./readme.md";

import {
  image,
  imageKnobs,
  layoutKnobs,
  backgroundKnobs
} from "../../../.storybook/commonKnobs";

import tileSwipe from "./index";

const tile = (index) => {
  const firstItem = index === 0;
  const tileNum = `Tile ${index + 1}`;
  return {
    type: "mo-article-tile",
    heading: text(`${tileNum} Heading`, `${tileNum} Heading`, "Component"),
    primaryMeta: firstItem
      ? text(`${tileNum} Primary Meta`, `${tileNum} Primary Meta`, "Component")
      : `${tileNum} Primary Meta`,
    secondaryMeta: firstItem
      ? text(
          `${tileNum} Secondary Meta`,
          `${tileNum} Secondary Meta`,
          "Component"
        )
      : `${tileNum} Secondary Meta`,
    content: firstItem
      ? text(
          `${tileNum} Content`,
          "In the Bible, Jesus is called the King of kings, the Messiah, the Prince of Peace, the Savior of all humankind.",
          "Component"
        )
      : "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut",
    link: {
      URL: "https://churchofjesuschrist.org"
    },
    download: "false",
    icon: firstItem
      ? select(
          `${tileNum} Icon`,
          {
            None: "",
            Video: "video"
          },
          "",
          "Component"
        )
      : "",
    image: firstItem
      ? imageKnobs({
          imageProps: [
            { ...image, groupId: "Component" },
            `${tileNum} Image`,
            (index + 2) % image.array.length
          ],
          altTextLabel: `${tileNum} Image Alt Text`
        })
      : image.array[(index + 2) % image.array.length]
  };
};

const makeTiles = (arrLength) => {
  const arr = [];
  for (let i = 0; i < arrLength; i++) arr.push(new tile(i));
  return arr;
};

const returnKnobs = () => {
  const numberofTiles = number(
    "Number of Tiles",
    10,
    {
      range: true,
      min: 1,
      max: 10,
      step: 1
    },
    "Component"
  );

  return {
    type: "mo-tile-swipe",
    title: text("Title", "Learn More About Jesus Christ", "Component"),
    layoutStyle: select(
      "Layout",
      {
        emphasized: "emphasized",
        "Single Row": "singleRow"
      },
      "emphasized",
      "Component"
    ),
    tiles: makeTiles(numberofTiles),
    ...layoutKnobs(),
    ...backgroundKnobs()
  };
};

storiesOf("Tile Swipe", module)
  .addDecorator(withReadme(readme))
  .add("Default", () => tileSwipe(returnKnobs()));
