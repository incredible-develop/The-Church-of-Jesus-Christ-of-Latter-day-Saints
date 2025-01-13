import { storiesOf } from "@storybook/html";
import { text } from "@storybook/addon-knobs";
import { withReadme } from "storybook-readme";
import readme from "./readme.md";

import anchor from "./index";

const returnKnobs = () => {
  return {
    id: text("Id", "0", "Component")
  };
};

storiesOf("Anchor", module)
  .addDecorator(withReadme(readme))
  .add(
    "Default",
    () => `
  <a href="#${returnKnobs().id}">Click to go to anchor</a>
  (Will redirect to another page first)
  <br/><br/><br/><br/><br/><br/>
  <br/><br/><br/><br/><br/><br/>
  <br/><br/><br/><br/><br/><br/>
  <br/><br/><br/><br/><br/><br/>
  <br/><br/><br/><br/><br/><br/>
  <br/><br/><br/><br/><br/><br/>
  <br/><br/><br/><br/><br/><br/>
  <br/><br/><br/><br/><br/><br/>
  <div>${anchor(returnKnobs())}Testing</div>
  <br/><br/><br/><br/><br/><br/>
  <br/><br/><br/><br/><br/><br/>
  <br/><br/><br/><br/><br/><br/>
  <br/><br/><br/><br/><br/><br/>
  <br/><br/><br/><br/><br/><br/>
  <br/><br/><br/><br/><br/><br/>
  <br/><br/><br/><br/><br/><br/>
  <br/><br/><br/><br/><br/><br/>
  <br/><br/><br/><br/><br/><br/>
  `
  );
