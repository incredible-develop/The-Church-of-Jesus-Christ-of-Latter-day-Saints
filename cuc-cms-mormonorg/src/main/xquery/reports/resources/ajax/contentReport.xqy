xquery version "1.0-ml";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../../modules/utility-functions.xqy";
import module namespace report = "http://lds.org/code/shared/lds-edit/reportFunctions" at "../../modules/reportsFunctions.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../../modules/access-control-functions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../../modules/ldse-settings.xqy";

declare boundary-space preserve;
declare option xdmp:mapping "true";

declare variable $report as element(report) := report:getReport('web-content');
declare variable $allBreakdowns as element(break-down)* := report:getBreakdowns($report);
declare variable $breakDownParams as xs:string := xdmp:get-request-field('bds', '');
declare variable $breakDownNames as xs:string := report:verifyBreakDowns($breakDownParams, $allBreakdowns);

declare variable $genReport as element(generated-report) := report:getGeneratedReport($report, $breakDownNames);

declare variable $permission as xs:string := "ldse:view-reports-admin";

if (ac:has-permission($permission, '', '')) then (
    xdmp:set-response-content-type( "text/html" ),
    <div class="padding-md">
        <a type="button" href="{$settings:shared-prefix}/shared/lds-edit/reports/resources/ajax/exportReport?lang=eng&amp;bds={fn:string-join($breakDownNames, ',')}" class="ixf-button secondary float-right">Export</a>
        <h2>Report: {xs:string($report/hierarchies/hierarchy[. eq $breakDownParams]/@name)}</h2>
        <table class="ixf-table">
            <thead>
                <tr>
                    <th class="xxl"></th>
                    <th class="md right">Words</th>
                    <th class="md right">TGP</th>
                    <th class="md right">Count</th>
                </tr>
            </thead>
            {
                report:buildBreakdownRow($genReport/break-down)
            }
        </table>
    </div>
) else ()
