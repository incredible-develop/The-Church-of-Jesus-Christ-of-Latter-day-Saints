xquery version "1.0-ml";
import module namespace content-search = "http://lds.org/code/shared/lds-edit/new-content-manager/content-search" at "../modules/content-search.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../modules/access-control-functions.xqy";

declare option xdmp:mapping "true";
xdmp:set-response-content-type("application/json"),
(:Calls the search function and returns a serialized JSON object:)
(:TODO no cache?:)
let $generate-facets as xs:boolean := 
    if ( xdmp:get-request-field("generateFacets") = "true" ) then (
        fn:true()
    ) else (
        fn:false()
    )
return (
    if (ac:has-permission('ldse:edit-doc', "", "") or ac:has-permission('ldse:edit-submission', "", "") ) then (
        content-search:jsonSearch($generate-facets, xdmp:get-request-field("rSum") = "true")
    ) else ()
)
