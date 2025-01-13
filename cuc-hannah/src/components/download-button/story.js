import { storiesOf } from "@storybook/html";
import { withReadme } from "storybook-readme";
import readme from "./readme.md";
import { boolean } from "@storybook/addon-knobs";

import downloadButton from "./index";
import DownloadButton from "./browser";

setTimeout(() => {
  const downloadBtnStorybook = document
    .querySelector("[dl-btn-sb]")
    ?.querySelector("[data-type='download-button']");
  if (downloadBtnStorybook)
    new DownloadButton({
      element: downloadBtnStorybook,
      onClick: () =>
        new Promise((res) =>
          setTimeout(() => {
            alert("Fake download completed");
            res();
          }, 3000)
        )
    });
});

const returnKnobs = () => {
  // TODO: add some knobs to this component
  return { invertIconColor: boolean("Invert Icon Color", false, "Component") };
};

storiesOf("Download Button", module)
  .addDecorator(withReadme(readme))
  .add(
    "Default Tile",
    () =>
      `<div dl-btn-sb>
      <p>Click the button to see a simulated 3 second download</p>
      ${downloadButton(returnKnobs())}
      </div>`
  );
