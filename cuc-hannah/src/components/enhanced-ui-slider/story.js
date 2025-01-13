import { storiesOf } from "@storybook/html";
import { number, select, boolean, text } from "@storybook/addon-knobs";
import { withReadme } from "storybook-readme";
import readme from "./readme.md";
import { backgroundKnobs, layoutKnobs } from "../../../.storybook/commonKnobs";

import enhancedUISlider from "./index";
import { renderMediaBlock } from "./mocks";

const makeCaroImgs = (arrLength) => {
  const arr = [];
  for (let i = 0; i < arrLength; i++) arr.push(renderMediaBlock(i));
  return arr;
};

const returnKnobs = () => {
  const numberOfCaroImgs = number(
    "Number of Images",
    5,
    {
      range: true,
      min: 1,
      max: 15,
      step: 1
    },
    "Component"
  );

  return {
    type: "enhanced-ui-slider",
    size: select("Size", ["large", "small"], "small", "Component"),
    wrapAround: boolean("Wrap Around", false, "Component"),
    desktopAspectRatio: select(
      "Desktop Ratio",
      ["1x1", "16x9"],
      "16x9",
      "Component"
    ),
    moblieAspectRatio: select(
      "Mobile Ratio",
      ["1x1", "16x9"],
      "16x9",
      "Component"
    ),
    borderRadius: select(
      "Border Radius",
      ["0px", "2px", "8px", "50percent"],
      "0px",
      "Component"
    ),
    ariaPrevious: text(
      "Accessibility Label for Previous",
      "previous",
      "Component"
    ),
    ariaNext: text("Accessibility Label for Next", "next", "Component"),
    captionAlignment: select(
      "Text Alignment",
      { Left: "Left", Center: "Center", None: "" },
      "Left",
      "Component"
    ),
    invertTextColor: boolean("Invert Text Color", false, "Component"),
    components: [...makeCaroImgs(numberOfCaroImgs)],
    ...backgroundKnobs(),
    ...layoutKnobs()
  };
};

storiesOf("Enhanced UI Slider", module)
  .addDecorator(withReadme(readme))
  .add("Default", () => enhancedUISlider(returnKnobs()));
