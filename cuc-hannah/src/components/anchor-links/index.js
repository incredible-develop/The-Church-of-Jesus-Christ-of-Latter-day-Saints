import styles from "./styles.css";
import { layoutInner, layoutOuter } from "components/layout";
import background from "components/background";
import linkAttrs from "../link-attrs";
import { renderChecker } from "../server.js";

export default (props) => {
  return renderChecker(component, props, "anchor-links");
};

export const component = (props) => {
  const { links } = props;
  let content = "";
  links.forEach((l) => {
    content += `<a class="${styles.link}" ${linkAttrs(l.link)}>${l.label}</a>`;
  });

  // prettier-ignore
  return `
    <div data-type="anchor-links" class="${layoutOuter(props)}">
        ${background(props)}
        <div class="${layoutInner(props)}">
            ${content}
        </div>
    </div>
`;
};
