import { storiesOf } from "@storybook/html";
import { number, select } from "@storybook/addon-knobs";
import { withReadme } from "storybook-readme";
import readme from "./readme.md";
import {
  selectCommon,
  aspectRatio,
  image,
  imageKnobs,
  layoutKnobs,
  backgroundKnobs
} from "../../../.storybook/commonKnobs";

import imageBlock from "./index";

const returnKnobs = () => {
  return {
    image: {
      ...imageKnobs({
        imageProps: [{ ...image, groupId: "Component" }, 4],
        altTextLabel: "Image Alt Text",
        imgAlignmentLabel: "Image Alignment",
        horizontalPositionLabel: "Horizontal Position (Left to Right)",
        verticalPositionLabel: "Vertical Position (Bottom to Top)",
        zoomLevelLabel: "Zoom Level"
      })
    },
    aspectRatio: selectCommon(aspectRatio, "Desktop Aspect Ratio"),
    mobileAspectRatio: selectCommon(aspectRatio, "Mobile Aspect Ratio"),
    borderRadius: select(
      "Border Radius",
      ["0px", "2px", "8px", "50percent"],
      "0px",
      "Component"
    ),
    ...layoutKnobs(),
    ...backgroundKnobs(),
    minSize: number("Min Size", 130, "", "Component"),
    maxSize: number("Max Size", 1280, "", "Component")
  };
};

storiesOf("Image Block", module)
  .addDecorator(withReadme(readme))
  .add("Default", () => imageBlock(returnKnobs()))
  .add("View Output", () => {
    const html = imageBlock(returnKnobs());
    return (
      html +
      `<textarea style="width: 100%; height: 500px; font-size: 10px;">Below is the HTML output of the above to more easily see the min/max working
${html}</textarea>`
    );
  });
