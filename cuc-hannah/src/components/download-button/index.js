import iconRender from "../icon";
import { renderChecker } from "../server.js";

export default (props) => {
  return renderChecker(component, props, "download-button");
};

export const component = (props) => {
  const { invertIconColor } = props;
  let defaultChildren = [
    iconRender({ name: "download", invertIconColor }),
    iconRender({ name: "loading-spinner", hidden: true, invertIconColor })
  ];

  const {
    ariaLabel = "download",
    children = defaultChildren,
    cssClasses = [],
    htmlAttrs = []
  } = props;

  let childrenNodes =
    typeof children === "function" ? children(defaultChildren) : children;
  // prettier-ignore
  return `
    <button data-type="download-button" aria-label="${ariaLabel}" ${htmlAttrs.join(" ")} class="${cssClasses.join(" ")}">
        ${childrenNodes.join("")}
    </button>`;
};
