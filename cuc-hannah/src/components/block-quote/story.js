import { storiesOf } from "@storybook/html";
import { text } from "@storybook/addon-knobs";
import { withReadme } from "storybook-readme";
import readme from "./readme.md";
import {
  image,
  imageKnobs,
  layoutKnobs,
  backgroundKnobs
} from "../../../.storybook/commonKnobs";

import blockQuote from "./index";

const returnKnobs = () => {
  return {
    type: "mo-block-quote",
    text: text(
      "Text",
      '"I stick closely to the principles taught in the Word of Wisdom and have found that by staying away from highly addictive drinks and substances, I enjoy a lot of freedom and happiness."',
      "Component"
    ),
    citation: text("Citation", "\n\n—Ali, University Student\n\n", "Component"),
    image: imageKnobs({
      imageProps: [{ ...image, groupId: "Component" }, 6]
    }),
    ...layoutKnobs(),
    ...backgroundKnobs()
  };
};

storiesOf("Quote - Block Quote", module)
  .addDecorator(withReadme(readme))
  .add("Default", () => blockQuote(returnKnobs()));
