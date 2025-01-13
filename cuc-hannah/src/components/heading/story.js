import { storiesOf } from "@storybook/html";
import { text, select, boolean } from "@storybook/addon-knobs";
import { withReadme } from "storybook-readme";
import readme from "./readme.md";
import {
  selectCommon,
  bgColor,
  justification,
  layoutKnobs,
  backgroundKnobs
} from "../../../.storybook/commonKnobs";

import heading from "./index";

const returnKnobs = () => {
  return {
    text: text("Text", "Heading", "Component"),
    level: select(
      "Level",
      {
        H1: "h1",
        "H1-Mckay": "h1-Mckay",
        H2: "h2",
        H3: "h3",
        H4: "h4",
        H5: "h5",
        H6: "h6"
      },
      "h5",
      "Component"
    ),
    textColor: selectCommon({ ...bgColor, groupId: "Component" }, "Text Color"),
    textJustification: selectCommon(
      { ...justification, groupId: "Component" },
      "left"
    ),
    styleOnly: boolean("Style Only", false, "Component"),
    ...layoutKnobs(),
    ...backgroundKnobs()
  };
};

storiesOf("Heading", module)
  .addDecorator(withReadme(readme))
  .add("Default", () => heading(returnKnobs()));
