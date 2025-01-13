import { storiesOf } from "@storybook/html";
import { text, select, boolean } from "@storybook/addon-knobs";
import { withReadme } from "storybook-readme";
import readme from "./readme.md";
import {
  selectCommon,
  image,
  imageKnobs,
  bool,
  link
} from "../../../.storybook/commonKnobs";

import articleTile from "./index";

const returnKnobs = () => {
  return {
    type: "mo-article-tile",
    heading: text("Heading", "Who was Jesus Christ?", "Component"),
    primaryMeta: text("Primary Meta", "Primary Meta", "Component"),
    secondaryMeta: text("Secondary Meta", "Secondary Meta", "Component"),
    content: text(
      "Content",
      "In the Bible, Jesus is called the King of kings, the Messiah, the Prince of Peace, the Savior of all humankind.",
      "Component"
    ),
    ...link(),
    download: selectCommon(bool, "Download", "false"),
    icon: select(
      "Icon",
      {
        None: "",
        Video: "video"
      },
      "",
      "Component"
    ),
    image: imageKnobs({ imageProps: [image, 2] }),
    showProgress: boolean("Show Progress", false, "Component")
  };
};

storiesOf("Article Tile", module)
  .addDecorator(withReadme(readme))
  .add("Default", () => articleTile(returnKnobs()));
