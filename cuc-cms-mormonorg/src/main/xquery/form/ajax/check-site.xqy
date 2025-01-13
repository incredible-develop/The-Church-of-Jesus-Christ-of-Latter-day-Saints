xquery version "1.0-ml";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../modules/utility-functions.xqy";
import module namespace sp = "http://lds.org/code/modules/site-properties" at '../../modules/site-properties.xqy';
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../modules/ldse-core.xqy";

declare option xdmp:mapping "true";

let $site-name as xs:string? := util:escape-chars(xdmp:get-request-field("siteName"))[. != '']
let $action as xs:string? := util:escape-chars(xdmp:get-request-field("action"))[. != '']
let $id as xs:string? := util:escape-chars(xdmp:get-request-field("id"))[. != '']
let $sites as element(sub-site)* := 
    cts:search(/sub-site,
        cts:and-query((
            core:get-filter-query(),
            cts:element-value-query(xs:QName('name'), $site-name, 'exact')
        ))
    )
let $count as xs:int? := fn:count($sites[name = $site-name])
return (
    if ( ( fn:empty($sites) or $id = $sites/@id ) and $count <= 1 ) then (
        'true'
    ) else ( 'false' )
)