import { storiesOf } from "@storybook/html";
import { boolean, number } from "@storybook/addon-knobs";
import { withReadme } from "storybook-readme";
import readme from "./readme.md";
import {
  layoutKnobs,
  backgroundKnobs,
  selectCommon,
  bgColor
} from "../../../.storybook/commonKnobs";

import progressBar from "./index";

const returnKnobs = () => {
  return {
    stepCount: number(
      "Number of Steps",
      8,
      {
        range: true,
        min: 1,
        max: 15,
        step: 1
      },
      "Component"
    ),
    currentStep: number(
      "Current Step",
      1,
      {
        range: true,
        min: 1,
        max: 15,
        step: 1
      },
      "Component"
    ),
    rounded: boolean("Rounded Corners", true, "Component"),
    theme: selectCommon(bgColor, "Color", "EasterPurple"),
    // Common Props are below - Remove if unneeded
    ...layoutKnobs(),
    ...backgroundKnobs()
  };
};

storiesOf("Progress Bar", module)
  .addDecorator(withReadme(readme))
  .add("Default", () => progressBar(returnKnobs()));
