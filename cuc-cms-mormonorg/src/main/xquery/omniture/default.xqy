xquery version "1.0-ml";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "/modules/utility-functions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "/modules/ldse-settings.xqy";
import module namespace omni = "http://lds.org/code/lds-edit/omniture" at "/modules/omniture.xqy";
import module namespace okta = 'http://lds.org/code/cms/modules/okta-library' at "/modules/okta-library.xqy";

declare namespace ldso = "http://lds.org/code/lds-edit/omniture";

declare option xdmp:mapping "true";

declare variable $lang    as xs:string := util:escape-chars(xdmp:get-request-field("lang", "eng"));

declare variable $pageName as xs:string := omni:sanitizePageName(xdmp:get-request-field("pageName"));

(: build the html :)
let $login := okta:okta-login()
return
    xdmp:set-response-content-type("text/html"),
        <script src="{$settings:shared-prefix}/shared/lds-edit/resources/scripts/highcharts/highcharts.js">&nbsp;</script>,
        <script type="text/javascript" src="{$settings:shared-prefix}/shared/lds-edit/omniture/scripts/omniture.js">&nbsp;</script>,
        <link rel="stylesheet" type="text/css" href="{$settings:shared-prefix}/shared/lds-edit/omniture/styles/omniture.css" />,
        <div id="omnitureWindow">
            <div class="tabBar">{
                let $dateRanges as xs:string* := ('7','30','90','180','365')
                for $dayRange as xs:string in $dateRanges
                return <span class='ldse-button secondary margin-xs' onclick='loadChartDays({$dayRange})'>{$dayRange} Days</span>
            }</div>
            <div id="loadDiv"></div>
            <span id="helpLink"><a href="https://preview.lds.org/lds-edit-help/article/view/58" target="_blank">Help</a></span>
            <div class="legendTxt">Click on the legend labels below to show/hide different metrics.</div>
          <div id="chart-container"> </div>
              <!--This script creates js variables named by the metric id and equal to data to produce graphs.
                  This way the metric id can be passed into the onclick() methods on the table rows rather than a large json string -->
               <script type="text/javascript">
                   var OMNITUREDATA = {omni:get-data($pageName)};
                   setTimeout("createChartFunc()",250);
                   function createChartFunc(){{
                       if(typeof Highcharts === "undefined"){{
                           setTimeout("createChartFunc()",250);
                       }}
                       else{{
                           createChart("Omniture Stats 30 Days","","");

                       }}
                   }}
               </script>
         </div>
