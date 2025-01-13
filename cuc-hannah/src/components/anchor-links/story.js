import { storiesOf } from "@storybook/html";
import { number } from "@storybook/addon-knobs";
import { withReadme } from "storybook-readme";
import readme from "./readme.md";
import {
  link,
  layoutKnobs,
  backgroundKnobs
} from "../../../.storybook/commonKnobs";

import anchorLinks from "./index";

const makeLink = (index) => {
  return {
    label: `Link #${index}`,
    ...link({
      URLLabel: "URL" + index,
      newTabLabel: "Open Url in New Tab " + index
    })
  };
};

const makeLinks = (arrLength) => {
  const arr = [];
  for (let i = 0; i < arrLength; i++) arr.push(new makeLink(i + 1));
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
    links: makeLinks(numberOfLinks),
    ...layoutKnobs(),
    ...backgroundKnobs()
  };
};

storiesOf("Anchor Links", module)
  .addDecorator(withReadme(readme))
  .add("Default", () => anchorLinks(returnKnobs()));
