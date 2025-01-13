xquery version "1.0-ml";

import module namespace form-functs = "http://lds.org/code/shared/lds-edit/form/form-functions" at "../modules/form-functions.xqy";

declare option xdmp:mapping "true";

xdmp:set-response-content-type("html"),

let $id as xs:string? := xdmp:get-request-field("id")
let $form-name as xs:string := xdmp:get-request-field("form")
let $option as xs:string? := xdmp:get-request-field("option")

return form-functs:translation-table($id, $form-name, $option)