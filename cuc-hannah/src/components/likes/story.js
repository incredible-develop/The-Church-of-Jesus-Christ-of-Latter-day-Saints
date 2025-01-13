import { storiesOf } from "@storybook/html";
import { boolean, text } from "@storybook/addon-knobs";
import { withReadme } from "storybook-readme";
import readme from "./readme.md";
import {
  selectCommon,
  justification,
  layoutKnobs,
  backgroundKnobs
} from "../../../.storybook/commonKnobs";

import likes from "./index";

const returnKnobs = () => {
  return {
    counterGroup: text("Counter Group", "alpha", "Component"),
    counterId: text("Counter ID", "test5", "Component"),
    justification: selectCommon({ ...justification, groupId: "Component" }),
    ariaLabel: text("Aria Label", "Likes", "Component"),
    countUpdatedString: text(
      "Counter Updated String",
      "Likes updated",
      "Component"
    ),
    invertIconColor: boolean("Invert Icon Color", false, "Component"),
    ...layoutKnobs(),
    ...backgroundKnobs()
  };
};

//This is for testing 100 likes and how they update
const oneHundred = () => {
  const makeLike = (index) => ({
    counterGroup: "alpha",
    counterId: `${index}`,
    justification: "center"
  });
  let array = [];
  for (let i = 0; i <= 100; i++) {
    array.push(makeLike(i));
  }
  return array.map(likes).join("");
};

storiesOf("Likes", module)
  .addDecorator(withReadme(readme))
  .add(
    "Default",
    () => `
    <p>This component uses sessionStorage so users can only click the like one time. For testing, you can clear the session and refresh the component.</p>
    <button onclick="localStorage.removeItem('participationCounter'); document.location.reload();">Clear Session</button>
    ${likes(returnKnobs())}
    `
  )
  .add(
    "One Hundred Likes",
    () => `<p>Testing how updates work with a hundred likes.</p>${oneHundred()}`
  );
