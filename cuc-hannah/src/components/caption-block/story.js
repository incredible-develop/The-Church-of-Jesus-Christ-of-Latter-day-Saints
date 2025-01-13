import { storiesOf } from "@storybook/html";
import { text, select, boolean } from "@storybook/addon-knobs";
import { withReadme } from "storybook-readme";
import readme from "./readme.md";
import {
  selectCommon,
  bgColor,
  icon,
  layoutKnobs,
  btnSize
} from "../../../.storybook/commonKnobs";

import captionBlock from "./index";

const returnKnobs = () => {
  return {
    type: "caption-block",
    heading: text("Caption heading", "I am a caption heading", "Component"),
    caption: text("Caption", "I am the caption", "Component"),
    citation: text("Citation", "I am the citation", "Component"),
    btn: {
      link: {
        URL: text(
          "CTA Button - Link",
          "https://comeuntochrist.org",
          "Component"
        )
      },
      variant: select(
        "CTA Button - Variant",
        {
          "secondary-color-text": "secondary-color-text",
          "secondary-white-text": "secondary-white-text"
        },
        "secondary-color-text",
        "Component"
      ),
      colorVariant: selectCommon(
        { ...bgColor, groupId: "Component" },
        "CTA Button - Color"
      ),
      label: text("CTA Button - Label", "Label", "Component"),
      icon: selectCommon(
        { ...icon, groupId: "Component" },
        "CTA Button - Icon"
      ),
      size: selectCommon({
        ...btnSize,
        label: "CTA Button - Size",
        groupId: "Component"
      })
    },
    downloadLabel: text(
      "Download Label",
      "I am the download label",
      "Component"
    ),
    invertTextColor: boolean("Invert Text Color", false, "Component"),
    textAlign: select("Text Align", ["Left", "Center"], "Left", "Component"),
    limitTextWidth: boolean("Limit Text Width", true, "Component"),
    ...layoutKnobs({ spacingTop: "unite-2-8px", paddingTop: "no-padding" })
  };
};

storiesOf("Caption Block", module)
  .addDecorator(withReadme(readme))
  .add("Default", () => captionBlock(returnKnobs()));
