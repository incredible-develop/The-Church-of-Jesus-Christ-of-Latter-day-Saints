xquery version "1.0-ml";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "/modules/utility-functions.xqy";
import module namespace layout = "http://lds.org/code/shared/lds-edit/layout-functions" at "/modules/layout-functions.xqy";
import module namespace report = "http://lds.org/code/shared/lds-edit/reportFunctions" at "/reports/modules/reportsFunctions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "/modules/ldse-settings.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "/modules/ldse-core.xqy";
import module namespace okta = 'http://lds.org/code/cms/modules/okta-library' at "/modules/okta-library.xqy";

declare boundary-space preserve;
declare option xdmp:mapping "true";

declare variable $lang as xs:string := util:escape-chars(xdmp:get-request-field("lang", "eng"));
declare variable $country as xs:string? := util:escape-chars(xdmp:get-request-field("country"));
declare variable $locale as xs:string := if ($country ne '') then (fn:concat($lang,'-',$country)) else ($lang);

declare variable $thisPage as xs:string := '/shared/lds-edit/reports';
declare variable $title as xs:string := 'Reports';

declare variable $permission as xs:string := "ldse:view-reports-admin";

let $login := okta:okta-login()
let $report as element(report)? := report:getReport('web-content')
let $allBreakdowns as element(break-down)* := report:getBreakdowns($report)
let $heirs as element(hierarchy)* := $report/hierarchies/hierarchy

return (
    if (ac:has-permission($permission, '', '')) then (
    xdmp:set-response-content-type( "text/html" ),
    '<!DOCTYPE html >',
    <html xmlns="http://www.w3.org/1999/xhtml">
        <head>
            {layout:addResources($title)}
            <script type="text/javascript" src="{$settings:shared-prefix}/shared/lds-edit/reports/resources/scripts/reports.js"/>
            <link rel="stylesheet" type="text/css" media="screen, projection" href="{$settings:shared-prefix}/shared/lds-edit/reports/resources/css/reports.css" />

        </head>

        <body class="master-detail">
           {layout:buildHeader($title)}
           {(: we are not calling the standard subheader here cuz we need to add stuff to it :)}
            <div class="ixf-subheader padding-xs" role="navigation">
                <p class="ixf-breadcrumb padding-xs text-md">
                    <span class="padding-right-xs">You are here:</span> <span>{$core:site}</span> <span class="padding-left-xs padding-right-xs">&gt;</span> <span class="current">Reports</span>
                    <span style="float: right;"><a href="#createReport" title="Create Report" class="ixf-popup" data-pop-size="sm">Create Report</a></span>
                </p>
            </div><!-- END ixf-subheader -->

            <div class="ixf-panels">
                <div class="ixf-panel ui-layout-west" data-layout-size="250" data-layout-minSize="150">

                    <table class="ixf-table ixf-fixed master lds-masterDetail">
                        <thead>
                            <tr>
                                <th><span class="text-md padding-top-sm padding-left-sm">Reports</span></th>
                            </tr>
                        </thead>
                        <tbody>{
                            for $heir as element() in $heirs
                            let $name as xs:string := $heir/@name
                            let $dbs as xs:string := $heir
                            return (
                                <tr id="{$name}">
                                    <td>
                                        <a href="{$settings:shared-prefix}/shared/lds-edit/reports/resources/ajax/contentReport?lang=eng&amp;bds={$dbs}">{ $name }</a>
                                    </td>
                                </tr>
                            )
                        }</tbody>
                    </table><!-- /ixf-table -->
                </div><!-- /ixf-panel -->


                <div class="ixf-panel ui-layout-center" id="detail">{
                        <div class="padding-md">
                            <p>Select or Create a report</p>
                        </div>
                }</div>
                <!-- /ixf-panel -->
            </div>
            <!-- END ixf-panels -->

            {layout:buildAppMenu($thisPage, $locale)}
            <div id="createReport" style="display: none;" class="padding-sm">
                    <form class="ixf-form" method="post" action="{$settings:shared-prefix}/shared/lds-edit/reports/resources/ajax/saveBreakdown?lang=eng">
                        <fieldset>
                            <dl>
                                <dt><label for="reportName">Report Name</label></dt>
                                <dd><input type="text" class="lg" name="report-name" value="" id="reportName"/></dd>
                            </dl>
                            <ul class="breakdowns sortable">{
                                for $breakdown as element() at $index in (<break-down name="type"/>, $allBreakdowns)
                                let $name as xs:string := $breakdown/@name
                                return (
                                    <li><fieldset class="table">
                                        <dl>
                                            <dd><input type="checkbox" name="breakdown" value="{$name}" id="{$name}{$index}"/></dd>
                                            <dt><label for="{$name}{$index}">{$name}</label></dt>

                                        </dl></fieldset>
                                    </li>
                                )
                            }</ul>

                            <dl>
                                <dt><label for="file">&nbsp;</label></dt>
                                <dd><input type="submit" class="ixf-button primary" value="Create Report"/></dd>
                            </dl>
                        </fieldset>
                    </form>
            </div>
        </body>
    </html>
    ) else (
     let $errorMsg as xs:string:="Sorry, You don't have permission"
     let $errorTitle as xs:string:= "Access Denied!"
     return xdmp:redirect-response(fn:concat($settings:shared-prefix,"/shared/lds-edit/error?errorMsg=",$errorMsg,"&amp;errorTitle=",$errorTitle))
    )
)
