import { storiesOf } from "@storybook/html";
import { text, select, number, boolean } from "@storybook/addon-knobs";
import { withReadme } from "storybook-readme";
import readme from "./readme.md";

import relatedArticles from "./index";
import {
  selectCommon,
  image,
  layoutKnobs,
  backgroundKnobs
} from "../../../.storybook/commonKnobs";

const tiles = () => {
  return {
    heading: text("Heading", "Tile Heading", "Component"),
    primaryMeta: text("Primary Meta", "Tile primaryMeta", "Component"),
    secondaryMeta: text("Secondary Meta", "Tile secondaryMeta", "Component"),
    content: text("Content", "Tile content", "Component"),
    download: select("Download", [true, false], true, "Component"),
    link: {
      URL: text("URL", "Tile URL", "Component")
    },
    image: selectCommon(image),
    showProgress: boolean("Show Progress", false, "Component")
  };
};

const makeNewTile = (arrLength) => {
  const arr = [];
  for (let i = 0; i < arrLength; i++) arr.push(new tiles(i));
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
    title: text("Title", "Related Articles Title", "Component"),
    tileStyle: select(
      "Title Style",
      {
        "Editorial(Uneven Tiles)": "editorial",
        "Utility (Uniform Tiles)": "utility"
      },
      "",
      "Component"
    ),
    tiles: makeNewTile(numberOfTiles),
    ...layoutKnobs(),
    ...backgroundKnobs()
  };
};

storiesOf("Related Articles", module)
  .addDecorator(withReadme(readme))
  .add("Default", () => relatedArticles(returnKnobs()));
