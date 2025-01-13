xquery version "1.0-ml";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../../modules/utility-functions.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../../modules/access-control-functions.xqy";
import module namespace link = "http://lds.org/code/shared/lds-edit/link-checker-functions" at "../../modules/link-checker-functions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../../modules/ldse-settings.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare option xdmp:mapping "true";

let $urls as xs:string* := xdmp:get-request-field("url[]")

let $location-host as xs:string? := xdmp:get-request-field("location-host")
let $location-protocol as xs:string? := xdmp:get-request-field("location-protocol")

let $location-origin as xs:string? := xdmp:get-request-field("location-origin")


let $live-host as xs:string? := $settings:live-domain

return (
    xdmp:set-response-content-type("application/json"),
    link:validate($urls, $location-origin, $live-host)
)
