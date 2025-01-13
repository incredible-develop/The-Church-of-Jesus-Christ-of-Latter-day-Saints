xquery version "1.0-ml";

import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../modules/access-control-functions.xqy";
import module namespace cf = "http://lds.org/code/shared/lds-edit/collections/functions" at "../modules/collections-functions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../modules/ldse-settings.xqy";

declare boundary-space preserve;

declare namespace its = "http://www.w3.org/2005/11/its";
declare namespace xhtml = "http://www.w3.org/1999/xhtml";
declare namespace ldse = "http://lds.org/code/lds-edit";

declare option xdmp:mapping "true";
declare option xdmp:update "true";

let $teasers as xs:string* := fn:distinct-values(fn:tokenize(xdmp:get-request-field("newOrder"), ","))
let $newTeasers as xs:string* := fn:distinct-values(fn:tokenize(xdmp:get-request-field("newFiles"), ","))[. != ""]
let $saveOrder as xs:boolean := xdmp:get-request-field("save") = 'true'
let $location as xs:string := xdmp:get-request-field("location")
let $pageUri as xs:string := xdmp:get-request-field("uri")
let $action as xs:string := xdmp:get-request-field("status")

return (
    if ( ac:has-permission('ldse:teaser-manager', "", "") ) then (
        cf:update-files($teasers, $newTeasers, $saveOrder, $location, $pageUri, $action)
    ) else (
        let $errorMsg as xs:string := "Sorry, You don't have permission" 
        let $errorTitle as xs:string := "Access Denied!"
        return (
            xdmp:redirect-response(fn:concat($settings:shared-prefix, "/error?errorMsg=", $errorMsg, "&amp;errorTitle=", $errorTitle))
        )
    )
)
