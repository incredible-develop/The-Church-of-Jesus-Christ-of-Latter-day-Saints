import { storiesOf } from "@storybook/html";
import { text, select, number, boolean } from "@storybook/addon-knobs";
import { withReadme } from "storybook-readme";
import readme from "./readme.md";
import {
  layoutKnobs,
  backgroundKnobs,
  selectCommon,
  link,
  justification,
  btnVariant,
  bgColor,
  btnSize,
  pageRoot,
  remoteTriggerId,
  spotIllustration
} from "../../../.storybook/commonKnobs";
import multiButtons from "./index";

const defaultProps = (index, hasIcons) => {
  return {
    type: "default",
    label: `Button Label #${index + 1}`,
    title: text(
      `ARIA description of the button #${index + 1} `,
      "Click me",
      "Component"
    ),
    ...link(),
    variant: selectCommon({ ...btnVariant, groupId: "Component" }),
    colorVariant: selectCommon({
      ...bgColor,
      groupId: "Component",
      label: `Color Variant #${index + 1}`
    }),
    size: selectCommon({ ...btnSize, groupId: "Component" }),
    icon: hasIcons
      ? spotIllustration.options[(index + 4) % spotIllustration.options.length]
      : "",
    iconPosition: select(
      "Icon Position",
      ["before", "after"],
      "before",
      "Component"
    ),
    invertIconColor: boolean("Invert Icon Color", false, "Component"),
    ...remoteTriggerId({ groupId: "Component" }),
    ...layoutKnobs(),
    ...backgroundKnobs()
  };
};

const variantProps = (index, hasIcons) => {
  return {
    type: "variant",
    label: `Button Label #${index + 1}`,
    title: text(
      `ARIA description of the button #${index + 1} `,
      "Click me",
      "Component"
    ),
    ...link(),
    variant: selectCommon({ ...btnVariant, groupId: "Component" }),
    colorVariant: selectCommon({
      ...bgColor,
      groupId: "Component",
      label: `Color Variant #${index + 1}`
    }),
    size: selectCommon({ ...btnSize, groupId: "Component" }),
    icon: hasIcons
      ? spotIllustration.options[(index + 4) % spotIllustration.options.length]
      : "",
    iconPosition: select(
      "Icon Position",
      ["before", "after"],
      "before",
      "Component"
    ),
    invertIconColor: boolean("Invert Icon Color", false, "Component"),
    ...remoteTriggerId({ groupId: "Component" }),
    ...layoutKnobs(),
    ...backgroundKnobs()
  };
};
// currently for demo long text not icon only
const longtextProps = (index) => {
  return {
    type: "longtext",
    label: `Button Label #${index + 1}`,
    title: text(
      `ARIA description of the button #${index + 1} `,
      "Click me",
      "Component"
    ),
    ...link(),
    variant: selectCommon({ ...btnVariant, groupId: "Component" }),
    colorVariant: selectCommon({
      ...bgColor,
      groupId: "Component",
      label: `Color Variant ${index + 1}`
    }),
    size: selectCommon({ ...btnSize, groupId: "Component" }),

    ...remoteTriggerId({ groupId: "Component" }),
    ...layoutKnobs(),
    ...backgroundKnobs()
  };
};

const makeButtons = (arrLength, hasIcons, buttonType) => {
  const arr = [];
  for (let i = 0; i < arrLength; i++)
    arr.push(new makeCustomDynButton(i, hasIcons, buttonType));
  return arr;
};

const makeCustomDynButton = (index, hasIcons, buttonType) => {
  if (buttonType === "Random") {
    buttonType = index;
  }
  // do a different type based on the index
  const types = ["default", "variant", "longtext"];
  let typeProps;
  switch (buttonType % types.length) {
    case 0:
      typeProps = defaultProps(index, hasIcons);
      break;
    case 1:
      typeProps = variantProps(index, hasIcons);
      break;
    case 2:
      typeProps = longtextProps(index);
      break;
  }
  // TODO make better for icon only variant when using for uber tile enhancement task
  let buttonLabelKnob = text(
    `Button Label #${index + 1} `,
    `Button Label #${index + 1} `,
    "Component"
  );
  return {
    ...typeProps,
    label: buttonLabelKnob
  };
};
const returnKnobs = () => {
  const hasIcons = boolean("Add icons to the buttons?", false, "Component");

  const numberOfBtns = number(
    "Number of Buttons",
    2,
    {
      range: true,
      min: 1,
      max: 10,
      step: 1
    },
    "Component"
  );
  const buttonType = select(
    "Button Type",
    {
      default: 0,
      variant: 1,
      longtext: 2,
      Random: "Random"
    },
    "Random",
    "Component"
  );
  return {
    wrapperJustification: selectCommon({
      ...justification,
      groupId: "Component"
    }),
    ...layoutKnobs(),
    ...backgroundKnobs(),
    buttons: makeButtons(numberOfBtns, hasIcons, buttonType),
    ...pageRoot
  };
};

storiesOf("Multi Buttons", module)
  .addDecorator(withReadme(readme))
  .add("Default", () => multiButtons(returnKnobs()));
