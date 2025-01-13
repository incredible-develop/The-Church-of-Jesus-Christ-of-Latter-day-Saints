import { storiesOf } from "@storybook/html";
import { text } from "@storybook/addon-knobs";
import { withReadme } from "storybook-readme";
import readme from "./readme.md";
import {
  selectCommon,
  justification,
  bool,
  layoutKnobs,
  backgroundKnobs
} from "../../../.storybook/commonKnobs";

import blockQuote from "./index";

const returnKnobs = () => {
  return {
    type: "mo-block-quote",
    textJustification: selectCommon({ ...justification, groupId: "Component" }),
    invertTextColor: selectCommon(
      { ...bool, groupId: "Component" },
      "Invert Text Color",
      "false"
    ),
    text: text(
      "Text",
      '"And if ye shall ask with a sincere heart, with real intent, having faith in Christ, he will manifest the truth of it unto you, by the power of the Holy Ghost."',
      "Component"
    ),
    citation: text("Citation", "Moroni 10:4", "Component"),
    ...layoutKnobs(),
    ...backgroundKnobs({ colorKey: "bgColor" })
  };
};

storiesOf("Quote - Pull Quote", module)
  .addDecorator(withReadme(readme))
  .add("Default", () => blockQuote(returnKnobs()));
