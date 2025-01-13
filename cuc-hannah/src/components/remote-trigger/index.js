const triggerAttribute = "remote-trigger-id"; // if changed, update in browser.js as well
import { renderChecker } from "../server.js";

export default (props) => {
  return renderChecker(component, props, "remote-trigger");
};

export const component = (props) => {
  const { remoteTriggerId, eventType = "click" } = props;
  return remoteTriggerId
    ? ` data-${triggerAttribute}="${remoteTriggerId}" data-remote-trigger-event-type="${eventType}"`
    : "";
};
