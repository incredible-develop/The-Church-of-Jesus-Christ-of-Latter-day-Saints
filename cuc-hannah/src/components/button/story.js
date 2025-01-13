import { storiesOf } from "@storybook/html";
import { text, select, boolean } from "@storybook/addon-knobs";
import { withReadme } from "storybook-readme";
import readme from "./readme.md";
import {
  selectCommon,
  justification,
  btnVariant,
  bgColor,
  btnSize,
  icon,
  layoutKnobs,
  backgroundKnobs,
  remoteTriggerId,
  link
} from "../../../.storybook/commonKnobs";
import { remoteComponentSubscribe } from "../remote-trigger/browser";

import button from "./index";

const returnKnobs = () => {
  return {
    type: "mo-button",
    label: text("Label", "Button Label", "Component"),
    title: text("ARIA description of the button", "Click me", "Component"),
    ...link(),
    variant: selectCommon({ ...btnVariant, groupId: "Component" }),
    colorVariant: selectCommon({
      ...bgColor,
      groupId: "Component",
      label: "Color Variant"
    }),
    size: selectCommon({ ...btnSize, groupId: "Component" }),
    icon: selectCommon({ ...icon, groupId: "Component" }),
    iconPosition: select(
      "Icon Position",
      ["before", "after"],
      "before",
      "Component"
    ),
    invertArrowDirection: boolean(
      "Invert Text Link (points left)",
      false,
      "Component"
    ),
    invertIconColor: boolean("Invert Icon Color", false, "Component"),
    btnJustification: selectCommon(
      { ...justification, groupId: "Component" },
      "Button Justification"
    ),
    ...remoteTriggerId({ groupId: "Component" }),
    downloadRef: text("Download Ref", "", "Component"),
    fakeButton: boolean("Fake Button", false, "Component"),
    isFullWidth: boolean("Full Width", false, "Component"),
    ...layoutKnobs(),
    ...backgroundKnobs()
  };
};

storiesOf("Button", module)
  .addDecorator(withReadme(readme))
  .add("Default", () => {
    const knobs = returnKnobs();
    remoteComponentSubscribe(knobs.remoteTriggerId, () => {
      alert("Remote component triggered");
    });
    return button(knobs);
  })
  .add("All buttons", () => {
    const knobs = returnKnobs();
    let buttonExamples = "";

    btnVariant.options.forEach((variant) => {
      buttonExamples += `<h3>${variant}</h3>`;
      bgColor.options.forEach((colorVariant) => {
        knobs.colorVariant = colorVariant;
        knobs.variant = variant;

        buttonExamples += button(knobs);
      });
    });

    return buttonExamples;
  });
