import { initComponent } from "../../utilities/common.js";

export const triggerAttribute = "remote-trigger-id"; // if changed, update in index.js as well
const remoteTriggerDataset = "remoteTriggerId";

export const remoteComponentBind = (elem) => {
  const eventType = elem.dataset["remoteTriggerEventType"] || "click"; // use provided event type or fallback
  // only add the event if the element has a remoteTriggerId
  if (
    elem.dataset[remoteTriggerDataset] &&
    !elem.hasAttribute("remote-setup")
  ) {
    const whenTriggered = (event) => {
      remoteComponentPublish(elem, event);
    };
    elem.addEventListener(eventType, whenTriggered);
    elem.setAttribute("remote-setup", "");
  }
};

export const remoteComponentPublish = (idToTrigger, event) => {
  // send a postMessage for the remote component to listen for and do its thing
  // Passing the original event details as part of the post message so that the component subscribing to the remote trigger event has access to original event details in callback. Made as an object so that other event details could be added in future if needed.
  window.postMessage(
    {
      type: triggerAttribute,
      // allow the idToTrigger to be a string (dom selector) or an element to get the id from
      remoteId:
        typeof idToTrigger === "string"
          ? idToTrigger
          : idToTrigger.dataset[remoteTriggerDataset],
      event: {
        detail: event?.detail
      }
    },
    "*"
  );
};

window.remoteComponentSubscribeList = [];
export const remoteComponentSubscribe = (id, callback) => {
  // listen for a remote component to say to do something with a shared ID
  window.addEventListener(
    "message",
    (event) => {
      if (event.data.type === triggerAttribute && event.data.remoteId === id) {
        callback(event.data.event);
      }
    },
    false
  );
  // track the IDs that have been subscribed to for use in other components as needed
  window.remoteComponentSubscribeList.push(id);
};

export const init = () => {
  initComponent(
    "remote-trigger",
    (element) => {
      remoteComponentBind(element);
    },
    // only hook up elements that have a trigger-remote-id attribute, not scoped to a component so any component on the page will get hooked up
    `[data-${triggerAttribute}]`
  );
};
init();
