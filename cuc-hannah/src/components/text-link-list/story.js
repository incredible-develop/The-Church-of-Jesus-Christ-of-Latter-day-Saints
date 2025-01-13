import { storiesOf } from "@storybook/html";
import { text, select, number } from "@storybook/addon-knobs";
import { withReadme } from "storybook-readme";
import readme from "./readme.md";
import {
  layoutKnobs,
  backgroundKnobs,
  link
} from "../../../.storybook/commonKnobs";

import textLink from "./index";

const makeLink = (index) => {
  return {
    label: `Link #${++index}`,
    link: {
      URL: "#"
    }
  };
};

const makeLinks = (arrLength) => {
  const arr = [];
  for (let i = 0; i + 1 < arrLength; i++) arr.push(new makeLink(i + 1));
  return arr;
};

const returnKnobs = () => {
  const numberOfLinks = number(
    "Number of Links",
    3,
    {
      range: true,
      min: 1,
      max: 10,
      step: 1
    },
    "Component"
  );
  return {
    links: [
      {
        label: text("Label", "Label", "Component"),
        ...link()
      },
      ...makeLinks(numberOfLinks)
    ],
    variant: select(
      "Variant",
      {
        whiteText: "whiteText",
        defaultText: "defaultText"
      },
      "defaultText",
      "Component"
    ),
    ...layoutKnobs(),
    ...backgroundKnobs()
  };
};

storiesOf("Text Link List", module)
  .addDecorator(withReadme(readme))
  .add("Default", () => textLink(returnKnobs()));
