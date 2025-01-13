xquery version "1.0-ml";

import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "/modules/ldse-meta.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "/modules/ldse-core.xqy";
import module namespace json = "http://marklogic.com/json" at "../../modules/fasterjson.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "/modules/ldse-settings.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "/modules/utility-functions.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";

declare option xdmp:mapping "true";

declare variable $username as xs:string := ac:getUserName();
declare variable $userid as xs:string? := ac:getPersonId();
declare variable $id as xs:string := xdmp:get-request-field("id");
declare variable $locale as xs:string := xdmp:get-request-field("locale");
declare variable $sensitive as xs:string? := xdmp:get-request-field("sensitive");
declare variable $stakeholder as xs:string? := xdmp:get-request-field("stakeholder");

let $file as element() := ldsemeta:get-file-by($id, (), (), ())
let $date as xs:dateTime := fn:current-dateTime()
let $update-file as item()* := ldsemeta:update-sensitive-file($file, $sensitive, $stakeholder, "yes", "yes", (), ())
let $new-file as item()* := core:update-file("ldse:preview", xdmp:node-uri($file), $update-file)
let $subject as xs:string := fn:concat("Request for approval to publish ", core:get-title($file))
let $email as xs:string := util:get-stakeholder-email($stakeholder)
let $body as element() :=
    <html xmlns="http://www.w3.org/1999/xhtml">
        <head>
            <title>{$subject}</title>
        </head>
        <body>
            <div>
                <div>
                    <p>{core:get-title($file)} has been requested to be published. You can view and approve the item <a href="{fn:concat(core:get-domain($file, $locale), $settings:shared-prefix)}/sensitive/approve?lang=eng">here</a>.</p>
                </div>
            </div>
{(:                    <div class="footer">
                <div>Modify your notification settings by visiting this link: <a href="publisher-preview{$env}.lds.org/publishing/notifications">settings</a></div>
                <div>To unsubscribe from ALL future emails: <a href="publisher-preview{$env}.lds.org/publishing/notifications/unsubscribe?email={$email}&amp;h={$hash}">unsubscribe</a></div>
            </div>:)}
        </body>
    </html>
let $email as item()* := util:send-email($email, "", $subject, $body, "no-reply@ldschurch.org", "LDS Publisher")

return (
    xdmp:set-response-content-type('application/json'),
    json:obj((
    	json:escapedKeyValue('success', "true"),
    	json:escapedKeyValue("message", "item has been sent for approval to your stakeholder"),
    	json:escapedKeyValue("approvalSent", "yes")
    ))
)
