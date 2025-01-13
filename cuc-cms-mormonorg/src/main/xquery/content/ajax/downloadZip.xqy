xquery version "1.0-ml";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../modules/utility-functions.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../modules/access-control-functions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../modules/ldse-settings.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare boundary-space preserve;
declare option xdmp:mapping "true";

let $lang as xs:string := (xdmp:get-request-field("lang"), "eng")[1]
let $has-permission as xs:boolean := ac:has-any-permissions(('ldse:view-tranlation-archive', 'ldse:send-to-translation'), $lang, '')

let $folder as xs:string := $settings:to-zip-path

let $fileName as xs:string := xdmp:get-request-field("zip", "")     
let $zip as item() := fn:doc(fn:concat($folder,$fileName))

return (
    if ($has-permission and fn:exists($zip)) then (
            xdmp:add-response-header('Content-Disposition', fn:concat('attachment; filename="', $fileName,'"')),
            xdmp:set-response-content-type('application/octet-stream'),
            $zip
    ) else ( 
        let $errorMsg as xs:string:="Sorry, You don't have permission" 
        let $errorTitle as xs:string:= "Access Denied!"
        return xdmp:redirect-response(fn:concat($settings:shared-prefix,"/error?errorMsg=",$errorMsg,"&amp;errorTitle=",$errorTitle))
   )
)
