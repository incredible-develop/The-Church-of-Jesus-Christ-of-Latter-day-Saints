xquery version "1.0-ml";

(:import module namespace json = "http://lds.org/code/shared/common/json/json-functions" at "/shared/common/json/jsonFunctions.xqy";:)
import module namespace action = "http://lds.org/code/shared/lds-edit/action-functions" at "../../ice/modules/action-functions.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../modules/utility-functions.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "../../modules/ldse-meta.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../modules/access-control-functions.xqy";

declare boundary-space preserve;

declare namespace ldse = "http://lds.org/code/lds-edit";

declare option xdmp:mapping "true";

let $action as xs:string := xdmp:get-request-field("action", "")
let $id as xs:string := xdmp:get-request-field("id", "")
let $uri as xs:string := xdmp:get-request-field("uri", "")
let $name as xs:string := xdmp:get-request-field("name", "")
let $folder as xs:string := xdmp:get-request-field("folder", "")
let $locale as xs:string := util:escape-chars(xdmp:get-request-field("locale", ""))
let $page as xs:string := xdmp:get-request-field("uri", "")
let $file as element()? := ldsemeta:get-file-by($id, $locale, (), ())
let $map as map:map := map:map()
let $_ as empty-sequence() := map:put($map, "$file", $file)
let $has-permission as xs:boolean :=  ac:is-action-allowed($action, $locale, $page, $map)
let $setContentType as empty-sequence() := xdmp:set-response-content-type("application/json")

return (
    if ( $has-permission ) then (
        action:perform-action($action, $uri, $locale, $name, $folder, (), $id)
    ) else ( 
        fn:false(), "You don't have permissions to perform this action"
    )
)