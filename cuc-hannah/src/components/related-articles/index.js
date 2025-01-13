import { layoutInner, layoutOuter } from "components/layout";
import background from "components/background";
import styles from "./styles.css";
import articleTiles from "../article-tile";
import articleStyles from "../article-tile/styles.css";
import typographyStyles from "../typography/critical.css";
import { renderChecker } from "../server";

const generateTile = (tile, tileStyle) => {
  if (
    tile.image &&
    (tile.image.type === "titan-image" || tile.image.type === "mo-titan-image")
  ) {
    tile.image = {
      type: "image-block",
      image: tile.image,
      aspectRatio: "16x9",
      variant: "noLimit",
      maxSize: 400
    };
  }

  return `
        ${
          tileStyle !== "utility"
            ? `<div class="${styles.tile}">
            ${tile ? articleTiles(tile) : ""}
        </div>`
            : `${tile ? articleTiles(tile) : ""}`
        }
    `;
};

export default (props) => {
  return renderChecker(component, props, "related-articles");
};

export const component = (props) => {
  const { title, tiles, tileStyle = "utility" } = props;
  // prettier-ignore
  return `
    <div data-type="related-articles" class="${styles.wrapper} ${layoutOuter(props)}">
        ${background(props)}
        <div class="${styles.container} ${layoutInner(props)}">
            <div class="${tileStyle === "utility" ? styles.utility : ''} ${tileStyle === "utility" ? articleStyles.utility : 'notutility'}">
                ${title ? `<div class="${styles.title} ${typographyStyles.h2}">${title}</div>` : ''}
                ${tiles ? `<div class="${styles.tiles}">
                    ${tiles.map((tile) => generateTile(tile, tileStyle)).join('')}
                </div>` : ''}
            </div>
        </div>
    </div>`;
};
