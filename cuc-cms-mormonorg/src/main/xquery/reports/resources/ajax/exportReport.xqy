xquery version "1.0-ml";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../../modules/utility-functions.xqy";
import module namespace excel = "http://marklogic.com/openxml/excel" at "../../../modules/spreadsheet-ml-support.xqy";
import module namespace report = "http://lds.org/code/shared/lds-edit/reportFunctions" at "../../modules/reportsFunctions.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../../modules/access-control-functions.xqy";

declare boundary-space preserve;
declare option xdmp:mapping "true";

declare variable $report as element(report) := report:getReport('web-content');
declare variable $allBreakdowns as element(break-down)* := report:getBreakdowns($report);
declare variable $breakDownParams as xs:string := xdmp:get-request-field('bds', '');
declare variable $breakDownNames as xs:string := report:verifyBreakDowns($breakDownParams, $allBreakdowns);

declare variable $genReport as element(generated-report) := report:getGeneratedReport($report, $breakDownNames);
      
declare variable $permission as xs:string := "ldse:view-reports-admin";

if (ac:has-permission($permission, '', '')) then (              
    let $fileName as xs:string := fn:concat('Report_',fn:string-join($breakDownNames, '_'), '.xlsx')
    let $table as element(table) := 
        <table>{
            report:buildBreakdownExport($genReport/break-down)
        }</table>
    let $excel as binary() := excel:create-xlsx-from-xml-table($table)
    
    return (
        if ( fn:exists($excel) ) then (
                xdmp:add-response-header('Content-Disposition', fn:concat('attachment; filename="', $fileName,'"')),
                xdmp:set-response-content-type('application/octet-stream'),
                $excel
        ) else ( xdmp:redirect-response("/error.xqy") )
    )
) else ()
