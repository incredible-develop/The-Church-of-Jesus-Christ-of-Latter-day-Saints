import styles from "./styles.css";
import textLink from "../text-link";
import { layoutInner, layoutOuter } from "components/layout";
import background from "components/background";
import { renderChecker } from "../server";

export default (props) => {
  return renderChecker(component, props, "text-link-list");
};

export const component = (props) => {
  const { links, variant } = props;
  let content = "";
  links.forEach(function (l, index) {
    //Applies a margin between the links, excluding the last link in the list.
    if (index !== links.length - 1) {
      content += textLink({ ...l, variant: variant, withMargin: true });
    } else {
      content += textLink({ ...l, variant: variant });
    }
  });
  // prettier-ignore
  return `
    <div data-type="text-link-list" class="${layoutOuter(props)}">
        ${background(props)}
        <div class="${styles.linkList} ${layoutInner(props)}">
            ${content}
        </div>
    </div>`;
};
