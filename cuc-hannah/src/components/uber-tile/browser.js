import { initComponent, styleSetup } from "../../utilities/common";
export default class UberTile {
  constructor(element) {
    // Loop through the body and heading elements and add listeners for the mobile/desktop styles respectively
    [
      "body",
      "heading",
      "grid",
      "vertical",
      "horizontal",
      "text",
      "gradient"
    ].forEach((type) =>
      ["Mobile", "Desktop"].forEach((size) => styleSetup(type, size, element))
    );
  }
}
export const init = () => {
  initComponent("uber-tile", (element) => new UberTile(element));
};
init();
