xquery version "1.0-ml";

import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../modules/ldse-core.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../modules/access-control-functions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../modules/ldse-settings.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";

declare option xdmp:mapping "true";

let $id as xs:string := xdmp:get-request-field("id")
return (
    if ( ac:has-permission('ldse:teaser-manager', "", "") ) then (
        let $teaser as element() := 
            cts:search(fn:collection(),
                cts:and-query((
                    core:get-filter-query(),
                    cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('id'), $id, 'exact')
                ))
            )/*
        let $dbPath as xs:string := xdmp:node-uri($teaser)
        return (
            core:preform-action-and-update("ldse:remove", $teaser)
        )
    ) else (
        let $errorMsg as xs:string:="Sorry, You don't have permission" 
        let $errorTitle as xs:string:= "Access Denied!"
        return (
            xdmp:redirect-response(fn:concat($settings:shared-prefix, "/error?errorMsg=", $errorMsg, "&amp;errorTitle=", $errorTitle))
        )
    )
)
