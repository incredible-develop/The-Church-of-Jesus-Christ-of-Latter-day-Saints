import { storiesOf } from "@storybook/html";
import { withReadme } from "storybook-readme";
import readme from "./readme.md";
import {
  selectCommon,
  image,
  aspectRatio,
  imageKnobs
} from "../../../.storybook/commonKnobs";
import styles from "./critical.css";

import mediaBlock from "../media-block";

const returnKnobs = () => {
  return {
    aspectRatio: selectCommon(aspectRatio),
    image: imageKnobs({ imageProps: [image] })
  };
};
let exampleCode = "";
aspectRatio.options.forEach((ratio) => {
  exampleCode += `<div class="example ${styles.aspectRatio} ${
    styles[`is${ratio}`]
  }">${ratio}</div>`;
});
exampleCode += "<h3>Desktop only</h3>";
aspectRatio.options.forEach((ratio) => {
  exampleCode += `<div class="example ${styles.aspectRatio} ${
    styles[`is${ratio}Desktop`]
  }">${ratio}</div>`;
});
// other configs
exampleCode += "<h3>Different for mobile vs desktop</h3>";
exampleCode +=
  "<p><code>is16x9and1x1</code> and <code>is8x5and16x5</code> change at <code>700px</code> for some reason, where the rest do it at <code>481px</code></p>";
[
  "is8x3and16x9",
  "is8x2and16x9",
  "is8x1and16x9",
  "is16x9and1x1",
  "is8x5and16x5"
].forEach((ratio) => {
  exampleCode += `<div class="example ${styles.aspectRatio} ${
    styles[`${ratio}`]
  }">${ratio}</div>`;
});

storiesOf("Utilities/Aspect Ratio", module)
  .addDecorator(withReadme(readme))
  .add("Default", () =>
    mediaBlock({
      ...returnKnobs(),
      mobileAspectRatio: returnKnobs().aspectRatio
    })
  )
  .add(
    "All Sizes",
    () =>
      `<style>
  .example {
    background: #ccc;
    margin-bottom: 10px;
    max-width: 300px;
  }
  .aspect-ratio_is16x9and1x1,
  .aspect-ratio_is8x5and16x5 {
    max-width:none;
  }
  .wrapper {
    // width: 300px;
  }
  </style>
  <div class="wrapper">${exampleCode}</div>`
  );
