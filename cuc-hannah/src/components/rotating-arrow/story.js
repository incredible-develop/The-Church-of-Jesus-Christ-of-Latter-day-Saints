import { storiesOf } from "@storybook/html";
import { withReadme } from "storybook-readme";
import readme from "./readme.md";
import { text, select, boolean } from "@storybook/addon-knobs";

import rotatingArrow from "./index";

const returnKnobs = () => {
  return {
    alignment: select(
      "Label and Arrow Alignment",
      ["vertical", "horizontal", "horizontalTop"],
      "vertical",
      "Component"
    ),
    label: text(
      "Label",
      "This is a very long label to show how the label will wrap next to the arrow button",
      "Component"
    ),
    iconType: select(
      "Icon Type",
      ["normal", "condensed"],
      "normal",
      "Component"
    ),
    notAButton: boolean("Don't Include Button Tag?", false, "Component")
  };
};

storiesOf("Rotating Arrow", module)
  .addDecorator(withReadme(readme))
  .add("Default", () => rotatingArrow(returnKnobs()));
