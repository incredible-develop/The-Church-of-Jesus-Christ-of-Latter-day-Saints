import { storiesOf } from "@storybook/html";
import { boolean, select, text } from "@storybook/addon-knobs";
import { withReadme } from "storybook-readme";
import readme from "./readme.md";
import {
  icon,
  spotIllustration,
  bgColor,
  selectCommon
} from "../../../.storybook/commonKnobs";

import iconComp from "./index";

const returnKnobs = () => {
  return {
    name: select(
      "Icon Name",
      [...icon.options, ...spotIllustration.options],
      "add",
      "Component"
    ),
    title: text("Icon SVG Image Title", "", "Component"),
    iconColor: selectCommon({ ...bgColor, groupId: "Component" }, "Icon Color"),
    invertIconColor: boolean("Invert Icon Color", false, "Component"),
    hidden: boolean("Hidden", false, "Component"),
    inline: boolean("Inline", false, "Component")
  };
};

storiesOf("Icon", module)
  .addDecorator(withReadme(readme))
  .add(
    "Default",
    () => `
  <p>Current Selected Icon</p>
  ${iconComp(returnKnobs())}
  <hr/>
  <h3 style="text-align:center">All Icons</h3>
  <div style="display: grid; grid-auto-columns: auto; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));">
  ${icon.options
    .slice(1) // ignore blank "" first option
    .map((item) => `<div>${iconComp({ name: item })} ${item}</div>`)
    .join("")}
  </div>
  `
  );
