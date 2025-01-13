xquery version "1.0-ml";

import module namespace content-search = "http://lds.org/code/shared/lds-edit/content/content-search" at "../modules/content-search.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../modules/access-control-functions.xqy";

declare variable $site as xs:string? := xdmp:get-request-field('site');

declare option xdmp:mapping "true";

(:Calls the search function and returns a serialized JSON object:)
(:TODO no cache?:)

xdmp:set-response-content-type("application/json"),
if ( ac:has-permission('ldse:edit-doc', "", "", $site) or ac:has-permission('ldse:edit-submission', "", "", $site) ) then (
    content-search:jsonSearch(xdmp:get-request-field("rSum") = "true")
) else ()