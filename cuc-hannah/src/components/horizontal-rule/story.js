import { storiesOf } from "@storybook/html";
import { boolean } from "@storybook/addon-knobs";
import { withReadme } from "storybook-readme";
import readme from "./readme.md";
import { layoutKnobs, backgroundKnobs } from "../../../.storybook/commonKnobs";

import horizontalRule from "./index";

const returnKnobs = () => {
  return {
    // Common Props are below - Remove if unneeded
    invertColor: boolean("Invert Color", false, "Component"),
    ...layoutKnobs(),
    ...backgroundKnobs()
  };
};

storiesOf("Horizontal Rule", module)
  .addDecorator(withReadme(readme))
  .add("Default", () => horizontalRule(returnKnobs()));
