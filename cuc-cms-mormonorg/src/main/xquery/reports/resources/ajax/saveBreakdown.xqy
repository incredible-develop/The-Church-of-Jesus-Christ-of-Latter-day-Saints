xquery version "1.0-ml";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../../modules/utility-functions.xqy";
import module namespace report = "http://lds.org/code/shared/lds-edit/reportFunctions" at "../../modules/reportsFunctions.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../../modules/access-control-functions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../../modules/ldse-settings.xqy";

declare option xdmp:mapping "true";

declare variable $permission as xs:string := "ldse:view-reports-admin";

if (ac:has-permission($permission, '', '')) then (
    let $reportName as xs:string := fn:replace(xdmp:get-request-field('report-name', ''), ' ', '-')
    let $breakdowns as xs:string := fn:string-join(xdmp:get-request-field('breakdown', ''), ',')
    
    let $report as element(report) := report:getReport('web-content')
    let $allBreakdowns as element(break-down)* := report:getBreakdowns($report)
    let $breakDownNames as xs:string* := report:verifyBreakDowns($breakdowns, $allBreakdowns)
    
    let $breakDownString as xs:string := fn:string-join($breakDownNames, ',')
    
    let $heir as element(hierarchy) := 
        element hierarchy {
            attribute name {$reportName},
            $breakDownString
        }
    let $existing as element(hierarchy)? := $report/hierarchies/hierarchy[. eq $breakDownString]
    
    let $save as item()* := 
        if (fn:exists($existing)) then () else (
            xdmp:node-insert-child($report/hierarchies, $heir)
        )
    let $hash as xs:string := if (fn:exists($existing)) then ($existing/@name) else ($reportName)
    let $url as xs:string := fn:concat($util:host, $settings:shared-prefix, '/shared/lds-edit/reports?lang=eng#detail=', $hash)
    return (
        xdmp:redirect-response($url)
    )
) else ()
