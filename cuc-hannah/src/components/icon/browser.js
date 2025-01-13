import { callbackWhenInView, initComponent } from "../../utilities/common";
import SVG from "../svg/browser";

export default class Icon {
  constructor(element) {
    const name = element.dataset.iconName;
    const url = `${window.PUBLIC_ENV.STATIC_DIRECTORY}/svgs/${name}.svg`;
    const title = element.dataset.svgTitle;
    if (name) SVG.renderSVG(url, element, title);
  }
}

export const init = () => {
  initComponent(
    "icon",
    (icon) => {
      callbackWhenInView({
        elems: [icon],
        callback: (icon) => {
          new Icon(icon);
        }
      });
    },
    "[data-icon-name]"
  );
};
init();
