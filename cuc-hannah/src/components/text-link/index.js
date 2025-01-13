import styles from "./styles.css";
import remoteTrigger from "components/remote-trigger";
import linkAttrs from "../link-attrs";
import invertTextStyles from "../invert-text-color";
import { renderChecker } from "../server";

export default (props) => {
  return renderChecker(component, props, "text-link");
};

export const component = (props) => {
  const {
    label,
    link = "",
    variant = "",
    withMargin = false,
    remoteTriggerId,
    invertTextColor = "false"
  } = props;

  const remoteTriggerAttribute = remoteTriggerId
    ? remoteTrigger({ remoteTriggerId })
    : "";

  return `
        <div data-type="text-link" use-analytics class="${
          withMargin ? styles.withMargin : ""
        }">
            ${
              link && link.URL
                ? `<a ${linkAttrs(link)} class="${styles.link} ${
                    variant ? styles[variant] : styles.defaultText
                  }">${label}</a>`
                : `<button class="${styles.link} ${styles.button} ${
                    variant ? styles[variant] : styles.defaultText
                  } ${invertTextStyles(
                    invertTextColor
                  )}"${remoteTriggerAttribute}>${label}</button>`
            }
        </div>
`;
};
