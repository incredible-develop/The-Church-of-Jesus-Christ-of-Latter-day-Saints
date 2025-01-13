xquery version "1.0-ml";


import module namespace content-workflow = "http://lds.org/code/shared/lds-edit/content/content-workflow" at "../modules/content-workflow.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "../../modules/ldse-meta.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../modules/access-control-functions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../modules/ldse-settings.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";

(: Forces this transaction to be an update transaction :)
declare option xdmp:update "true";
declare option xdmp:mapping "true";

let $file-ids as xs:string* := fn:distinct-values(xdmp:get-request-field('id[]')[. ne ''])
let $files as element()* := 
    if (fn:exists($file-ids)) then (
        ldsemeta:get-files-by($file-ids, (), (), ())
    ) else ()    

let $status as xs:string := xdmp:get-request-field('status')[. ne '']
let $action as xs:string := xdmp:get-request-field('action')[. ne '']

let $step as element(ldse:step) := content-workflow:get-step-by-name($status)
let $action-element as element() := content-workflow:get-action-from-step($step, $action)
let $isValidCheck :=
    for $file as element() in $files
    let $uri as xs:string? := ldsemeta:get-document-uri($file)
    let $locale as xs:string? := ldsemeta:get-document-locale($file)
    let $has-permission as xs:boolean := content-workflow:has-action-permission($action-element, $locale, $uri)
    where fn:not($has-permission)
    return (
        xdmp:set-response-code(409, "Not Authorized"),
        xdmp:add-response-header("json", '{"success":false,"error":["permission"]}'),
        xdmp:rollback()
    )
let $fileCheck as item()* :=
    if ( fn:empty($files) ) then (
        xdmp:set-response-code(409, "No Files Found"),
        xdmp:add-response-header("json", '{"success":false,"error":["id[]"]}'),
        xdmp:rollback()
    ) else ()
return (
        xdmp:set-response-content-type("application/json"),
        content-workflow:apply-action($status, $action, $files)
)
