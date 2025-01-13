xquery version "3.0";
module namespace mofc = "http://lds.org/code/shared/lds-edit/mormonOrgSteppedFormComponents";
declare function mofc:get-mormon-org-stepped-form-components(
)
{
    (
        <mo-form-address-block>Address Block</mo-form-address-block>,
        <mo-form-checkboxes-group>Checkboxes Group</mo-form-checkboxes-group>,
        <mo-form-confirmation-pref>Confirmation Pref</mo-form-confirmation-pref>,
        <mo-form-email-field>Email Field</mo-form-email-field>,
        <mo-heading>Heading</mo-heading>,
        <mo-form-hidden-field>Hidden field</mo-form-hidden-field>,
        <mo-form-name-field>Name Field (First Name or Last Name)</mo-form-name-field>,
        <mo-form-offer-selector>Offer Selector</mo-form-offer-selector>,
        <mo-form-offer-details-list>Offer Details List</mo-form-offer-details-list>,
        <mo-form-phone-field>Phone Field</mo-form-phone-field>,
        <mo-form-predefined-questions>Predefined Questions</mo-form-predefined-questions>,
        <mo-form-radio-button-group>Radio Button Group</mo-form-radio-button-group>,
        <mo-form-select-box>Select Box</mo-form-select-box>,
        <mo-form-short-field>Short Field (First Name and Last Name)</mo-form-short-field>,
        <mo-form-space>Spacing</mo-form-space>,
        <mo-form-text-area>Text Area</mo-form-text-area>,
        <mo-form-text-block>Text Block</mo-form-text-block>,
        <mo-form-text-field>Text Field</mo-form-text-field>,
        <mo-text-link>Text Link</mo-text-link>
    )
};
