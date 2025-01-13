import styles from "../flickity/styles.css";
import articleStyles from "../article-tile/styles.css";
import articleTiles from "../article-tile";
import titanStyles from "../titan-image/styles.css";
import typographyStyles from "../typography/critical.css";
import { layoutInner, layoutOuter } from "components/layout";
import background from "../background";
import { renderChecker } from "../server.js";

function buildItems(items, layout) {
  switch (layout) {
    case "emphasized":
      // eslint-disable-next-line no-case-declarations
      let firstItem = `
		        <div class="${styles.rowTile}">
		        	${articleTiles(items[0])}
		        </div>`;

      // eslint-disable-next-line no-case-declarations
      let remaining = items.splice(1);
      // let halfLength = Math.ceil(remaining.length / 2);
      // let firstHalf = remaining.splice(0,halfLength);
      // let secondHalf = remaining;

      return `
				${firstItem}
				${
          remaining.length > 0
            ? `${remaining
                .map((item, index) => {
                  if (index % 2 === 0) {
                    return `
			                <div class="${styles.rowGroup}">
			                	<div class="${styles.rowTile} ${titanStyles.gradientOnHover}">
			                		${articleTiles(item)}
			                	</div>
			                ${index === remaining.length - 1 ? `</div>` : ``}`;
                  } else {
                    return `
			                	<div class="${styles.rowTile} ${titanStyles.gradientOnHover}">
			                		${articleTiles(item)}
			                	</div>
			                </div>
			                `;
                  }
                })
                .join("")}`
            : ""
        }
			`;
    case "singleRow":
      return `
				${
          items.length > 0
            ? `${items
                .map((item) => {
                  return `<div class="${styles.rowTile} ${
                    titanStyles.gradientOnHover
                  }">
	                		${articleTiles(item)}
	                	</div>`;
                })
                .join("")}`
            : ""
        }
			`;
  }
}

export default (props) => {
  return renderChecker(component, props, "tile-swipe");
};

export const component = (props) => {
  const { layoutStyle = "emphasized", title = "", tiles = {} } = props;

  const actualMobileSize = props.layout.contentWidthMobile
    ? props.layout.contentWidthMobile
    : props.layout.contentWidthDesktop === "uncontrolled" ||
      props.layout.contentWidthDesktop === "pop"
    ? "uncontrolled"
    : "normal";

  return `
    <div data-type="tile-swipe" extra-css="flickity" class="${layoutOuter(
      props
    )}">
    ${background(props)}
        	<div class=" ${layoutInner(props)} ${styles.container} ${
    props.background.bgColor && props.layout.backgroundWidth === "uncontrolled"
      ? styles.coloredBg
      : ""
  }
  }">

				<div class="${styles.wrapper} ${
    props.layout.contentWidthDesktop === "uncontrolled"
      ? styles["desktop-uncontrolled"]
      : ""
  } ${styles["mobile-" + actualMobileSize]}">
					${
            title
              ? `<h2 class="${styles.title} ${typographyStyles.h2}">${title}</div>`
              : ""
          }
					<div class="${
            layoutStyle
              ? `${styles[layoutStyle]} ${articleStyles[layoutStyle]}`
              : ""
          } ${
    styles.innerWrapper
  }" data-swipe-wrapper data-layout="${layoutStyle}">
					${tiles ? `${buildItems(tiles, layoutStyle)}` : ""}
					</div>
				</div>
			</div>
		</div>`;
};
