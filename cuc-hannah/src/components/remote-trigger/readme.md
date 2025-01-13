Remote Trigger is meant to be the glue that binds together one component that needs to tell (trigger) a different (remote) component to do whatever it is that it needs to do.

The remote component adds a listener/subscriber to the window waiting for a message to be posted with a given ID.

The triggering component adds a publisher so when acted upon it will broadcast the same ID telling whatever component that is listening (could technically be multiple) to do their thing if the ID matches.

## index.js exports

The default export is just the logic for injecting the correct `data-` attribute. Abstracting it to the component allows us to change in one place if needed.

## browser.js exports

`triggerAttribute` - the name of the attribute, mainly for use in the above `data-` attribute
`remoteComponentBind` - A standardized way to bind an event to the publishing component which will in turn broadcast the correct information to the message system.
`remoteComponentSubscribe` - A standardized way to listen on the receiving component for the correct message.

## Examples

These components subscribe to a remote trigger event (not a definitive list)

- Drawer
- Modal
- Popup
- Save Data

These components publish a remote trigger event

- Button
