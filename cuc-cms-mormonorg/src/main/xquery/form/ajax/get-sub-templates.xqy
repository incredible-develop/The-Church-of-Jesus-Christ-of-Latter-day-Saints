xquery version "1.0-ml";

import module namespace sp = "http://lds.org/code/modules/site-properties" at "../../modules/site-properties.xqy";

xdmp:set-response-content-type('text/html'),

let $template as xs:string? := xdmp:get-request-field("template")
let $sub-template as xs:string? := xdmp:get-request-field("sub-template")
let $id as xs:string? := xdmp:get-request-field("id")
let $index as xs:string? := xdmp:get-request-field("index")

return sp:get-sub-templates($template, $sub-template, $id, $index)