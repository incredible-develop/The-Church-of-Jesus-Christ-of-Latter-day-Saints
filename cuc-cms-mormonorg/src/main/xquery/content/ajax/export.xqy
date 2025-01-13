xquery version "1.0-ml";

import module namespace excel = "http://marklogic.com/openxml/excel" at "../../modules/spreadsheet-ml-support.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../modules/utility-functions.xqy";

import module namespace content-search = "http://lds.org/code/shared/lds-edit/content/content-search" at "../modules/content-search.xqy";
import module namespace export-functions = "http://lds.org/code/shared/lds-edit/content/export" at "../modules/export-functions.xqy";
import module namespace content-workflow = "http://lds.org/code/shared/lds-edit/content/content-workflow" at "../modules/content-workflow.xqy";

import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../modules/ldse-settings.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../modules/access-control-functions.xqy";

declare namespace xhtml = "http://www.w3.org/1999/xhtml";
declare namespace its = "http://www.w3.org/2005/11/its";

declare boundary-space preserve;
declare option xdmp:mapping "true";

let $ids as xs:string* := fn:tokenize(xdmp:get-request-field("id"),',')[. ne '']
let $status as xs:string? := xdmp:get-request-field('status')
let $selectedDocs as element()* := 
    if ( fn:exists($ids) and $status = "comments" ) then (
        export-functions:get-history-doc($ids)
    ) else if ( fn:exists($ids) ) then (
        export-functions:getDocsByIds($ids)
    ) else (
        content-search:getAllDocsByFilters()
    )
let $fileName as xs:string := fn:concat("Content_Export_", fn:current-date(), '.xlsx')
let $table as element(table) := export-functions:buildExportTable($selectedDocs, $status)
let $excel as binary() := excel:create-xlsx-from-xml-table($table)
let $steps as item()* := $content-workflow:steps

return (
    if (ac:has-permission('ldse:edit-doc', "", "") and fn:exists($excel) and fn:exists($steps)) then (
            xdmp:add-response-header('Content-Disposition', fn:concat('attachment; filename="', $fileName,'"')),
            xdmp:set-response-content-type('application/octet-stream'),
            $excel
    ) else ( 
        let $errorMsg as xs:string:="Sorry, the excel sheet failed to load. You may not have permissions to export these files."
        let $errorTitle as xs:string:= "Error!"    
        return xdmp:redirect-response(fn:concat($settings:shared-prefix,"/error?errorMsg=",$errorMsg,"&amp;errorTitle=",$errorTitle)) )
) 
