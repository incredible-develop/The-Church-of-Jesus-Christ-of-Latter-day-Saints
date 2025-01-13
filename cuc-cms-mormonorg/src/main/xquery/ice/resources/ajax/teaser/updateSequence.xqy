xquery version "1.0-ml";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../../../modules/utility-functions.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "../../../../modules/ldse-meta.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../../../modules/ldse-settings.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../../../modules/access-control-functions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../../../modules/ldse-core.xqy";

declare boundary-space preserve;
declare namespace ldse = "http://lds.org/code/lds-edit";
declare option xdmp:mapping "true";
declare option xdmp:update "true";

declare variable $lang as xs:string := util:escape-chars(xdmp:get-request-field("lang", "eng"));
declare variable $country as xs:string? := util:escape-chars(xdmp:get-request-field("country", ""));
declare variable $locale as xs:string := if ($country ne '') then (fn:concat($lang, '-', $country)) else ($lang);

let $currentPage as xs:string := xdmp:get-request-field("currentPage", "")
let $id as xs:string := util:escape-chars(xdmp:get-request-field("id", ""))

let $preSequence  as xs:string := xdmp:get-request-field("sequence", "1")
let $sequence  as xs:string := fn:replace($preSequence,'\D','')
                
let $teaser as element(teaser)? := ldsemeta:get-file-by($id, $locale, (), ())

return
if (ac:has-permission('ldse:edit-teaser-sequence', $locale, $currentPage) and fn:exists($teaser) ) then (
    let $newSequence as attribute() := attribute sequence {$sequence}
    let $save as empty-sequence() := 
        if ( fn:exists($teaser/@sequence) ) then (
             xdmp:node-replace($teaser/@sequence, $newSequence) 
         ) else (
             xdmp:node-insert-child($teaser, $newSequence)
         )
    return (
        xdmp:redirect-response( core:build-url($currentPage, $locale, ()) )
    )
) else (
     let $errorMsg as xs:string:="Sorry, You don't have permission" 
     let $errorTitle as xs:string:= "Access Denied!"
     return xdmp:redirect-response(fn:concat($settings:shared-prefix,"/error?errorMsg=",$errorMsg,"&amp;errorTitle=",$errorTitle))
)
