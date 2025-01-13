import { storiesOf } from "@storybook/html";
import { text, select, boolean } from "@storybook/addon-knobs";
import { withReadme } from "storybook-readme";
import readme from "./readme.md";
import {
  layoutKnobs,
  backgroundKnobs,
  selectCommon,
  icon
} from "../../../.storybook/commonKnobs";

import boldText from "./index";

const returnKnobs = () => {
  return {
    fitContainer: boolean("Fit Inside Container", true, "Component"),
    heading: text("Heading", "Heading", "Component"),
    miniText: text("Mini Text", "3:45", "Component"),
    miniTextIcon: select(
      "Mini Text Icon",
      { None: "", "Chevron Right": "chevron-right", Play: "play" },
      "",
      "Component"
    ),
    fontFamily: select("Font Family", ["h1", "mcKay"], "h1", "Component"),
    color: select("Color", ["Light", "Dark"], "Dark", "Component"),
    contentAlign: select(
      "Content Align",
      ["BottomCenter", "BottomLeft", "CenterCenter"],
      "BottomLeft",
      "Component"
    ),
    includeBtn: boolean("Include Button", true, "Component"),
    btnLabel: text("Button Label", "Play", "Component"),
    btnIcon: selectCommon(icon, "play"),
    overlay: boolean("Include Overlay", false, "Component"),

    // Common Props are below - Remove if unneeded
    ...layoutKnobs(),
    ...backgroundKnobs()
  };
};

storiesOf("Bold Display", module)
  .addDecorator(withReadme(readme))
  .add("Default", () => boldText(returnKnobs()));
