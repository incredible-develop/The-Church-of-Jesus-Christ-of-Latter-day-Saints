xquery version "1.0-ml";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "/modules/utility-functions.xqy";
import module namespace layout = "http://lds.org/code/shared/lds-edit/layout-functions" at "/modules/layout-functions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "/modules/ldse-settings.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "/modules/ldse-core.xqy";
import module namespace okta = 'http://lds.org/code/cms/modules/okta-library' at "/modules/okta-library.xqy";

declare boundary-space preserve;

declare option xdmp:mapping "true";

declare variable $lang as xs:string := util:escape-chars(xdmp:get-request-field("lang", "eng"));
declare variable $country as xs:string? := util:escape-chars(xdmp:get-request-field("country"));
declare variable $locale as xs:string := if ($country ne '') then (fn:concat($lang,'-',$country)) else ($lang);

declare variable $thisPage as xs:string := '/shared/lds-edit/binary';
declare variable $title as xs:string := 'Binary Manager';

let $login := okta:okta-login()
return
    if (ac:has-permission('ldse:view-binary-manager', '', '')) then (
    xdmp:set-response-content-type( "text/html" ),
    '<!DOCTYPE html >',
    <html xmlns="http://www.w3.org/1999/xhtml">
        <head>
            <!-- Ensure IE8 Standards mode -->
            <meta http-equiv="x-ua-compatible" content="IE=8"/>

            {layout:addResources($title)}
            <script type="text/javascript" src="{$settings:shared-prefix}/resources/scripts/ldsedit.js"/>
            <script type="text/javascript" src="{$settings:shared-prefix}/binary/resources/scripts/burce.js"/>
            <script type="text/javascript" src="{$settings:shared-prefix}/reports/resources/scripts/reports.js"/>
            <link rel="stylesheet" type="text/css" media="all" href="{$settings:shared-prefix}/binary/resources/styles/binary.css"/>
            <link rel="stylesheet" type="text/css" media="screen, projection" href="{$settings:shared-prefix}/reports/resources/css/reports.css" />
            <link rel="stylesheet" href="{$settings:shared-prefix}/resources/css/ldspublisher.css" />
            <link rel="stylesheet" type="text/css" media="screen, projection" href="{$settings:shared-prefix}/ice/resources/styles/binaryManager.css" />
            <script type="text/javascript">
                var lang = {xdmp:to-json-string($lang)};
                var locale = {xdmp:to-json-string($locale)};
        		$(function(){{
            		if(typeof jsloaded === 'undefined'){{
            			jsloaded = true;
            			createBC({{
    						adminLibrary: true,
    						apiUrl: '{$settings:shared-prefix}/ice/burce',
    						wrapperSelector: 'binary-wrapper',
    						scrollBatch : 1000
    					}});
            		}}
        		}});
			</script>
        </head>

        <body class="master-detail">
           {layout:buildHeader($title)}
           {(: we are not calling the standard subheader here cuz we need to add stuff to it :)}
            <div class="ixf-subheader padding-xs" role="navigation">
                <p class="ixf-breadcrumb padding-xs text-md">
                    <span class="padding-right-xs">You are here:</span> <span>{$core:site}</span> <span class="padding-left-xs padding-right-xs">&gt;</span> <span class="current">Binary Manager</span>
                </p>
            </div><!-- END ixf-subheader -->

            <div class="ixf-panels">
                <div class="ixf-panel ui-layout-west" data-layout-size="250" data-layout-minSize="150">

                    <table class="ixf-table ixf-fixed master lds-masterDetail fixHeaderApplied">
                        <thead>
                            <tr>
                                <th><span class="text-md padding-top-sm padding-left-sm"></span></th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr id="search">
                                <td>
                                    <input type="text" name="filter-box" id="filter-box" class="search-box" value="" placeholder="Search">
                                        <span class="clearsearch"></span>
                                    </input>
                                </td>
                            </tr>
                        </tbody>
                    </table><!-- /ixf-table -->
                </div><!-- /ixf-panel -->

                <div id="imageCropper" class="ixf-panel ui-layout-center ui-layout-pane ui-layout-pane-center imageCropper"/>
                <div class="ixf-panel ui-layout-center ui-layout-pane ui-layout-pane-center" id="detail" role="region">{
                        <div class="padding-md" >
                            <h3 id="workingDir">Working Directory: <span id="workDir"></span></h3>
                            <div class="binary-wrapper" style="border:1px solid #999">&nbsp;</div>
                        </div>
                }</div>
                <!-- /ixf-panel -->
            </div>
            <!-- END ixf-panels -->
            {layout:buildAppMenu($thisPage, $locale)}

	        <section class="ldse-section ldse-modal" style="display:none;" id="modal1"><div></div></section>
	        <section class="ldse-section ldse-modal" style="display:none;" id="alertModal"><div></div></section>
        </body>
    </html>
    ) else (
        let $errorMsg as xs:string:="Sorry, You don't have permission"
        let $errorTitle as xs:string:= "Access Denied!"
        return xdmp:redirect-response(fn:concat($settings:shared-prefix,"/error?errorMsg=",$errorMsg,"&amp;errorTitle=",$errorTitle))
    )
