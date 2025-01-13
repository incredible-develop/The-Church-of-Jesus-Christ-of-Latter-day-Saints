import { storiesOf } from "@storybook/html";
import { text, select, boolean } from "@storybook/addon-knobs";
import { withReadme } from "storybook-readme";
import readme from "./readme.md";
import textLink from "./index";
import { link } from "../../../.storybook/commonKnobs";

const returnKnobs = () => {
  return {
    label: text("Label", "Label", "Component"),
    ...link(),
    variant: select(
      "Variant",
      {
        whiteText: "whiteText",
        defaultText: "defaultText"
      },
      "defaultText",
      "Component"
    ),
    withMargin: boolean("With Margin", false, "Component")
  };
};

storiesOf("Text Link", module)
  .addDecorator(withReadme(readme))
  .add("Default", () => textLink(returnKnobs()));
