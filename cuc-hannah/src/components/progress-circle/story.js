import { storiesOf } from "@storybook/html";
import { number } from "@storybook/addon-knobs";
import { withReadme } from "storybook-readme";
import readme from "./readme.md";

import progressCircle from "./index";
import { bgColor, selectCommon } from "../../../.storybook/commonKnobs";

const returnKnobs = () => {
  return {
    percent: number(
      "Percent",
      25,
      { range: true, min: 0, max: 100, step: 1 },
      "Component"
    ),
    color: selectCommon({ ...bgColor, groupId: "Component" }, "Border Color")
  };
};

storiesOf("Progress Circle", module)
  .addDecorator(withReadme(readme))
  .add("Default", () => progressCircle(returnKnobs()));
