// We use the global footer for the bottom links,logo, etc, but this is still used to provide our own CUC wide footer-level things like the lang selector, etc
import styles from "./styles.css";
import { render } from "..";
import { layoutInner, layoutOuter } from "components/layout";
import background from "components/background";
import { renderChecker } from "../server.js";

export default (props) => {
  return renderChecker(component, props, "footer");
};

export const component = (props) => {
  const {
    meta,
    components: { langSel } = {},
    additionalComponents,
    req,
    code
  } = props;

  // prettier-ignore
  return `
  <footer data-type="footer" class="${styles.pageFooter} ${layoutOuter(props)}">
    ${background(props)}
    <div class="${styles.pageFooterInner} ${layoutInner(props)}">
      ${additionalComponents ? additionalComponents.map(component => render({componentData: component, req, code, meta})).join(""): ""}
      ${langSel ? `<div class="${styles.langSel}">${render({componentData: langSel})}</div>` : ""}
    </div>
  </footer>`;
};
