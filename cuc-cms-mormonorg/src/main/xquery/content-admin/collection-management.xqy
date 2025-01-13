xquery version "1.0-ml";

import module namespace template = "http://lds.org/shared/lds-edit/template" at "../modules/template.xqy";
import module namespace ice = "http://lds.org/code/shared/lds-edit/iceFunction" at "../ice/modules/iceFunctions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../modules/ldse-settings.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../modules/access-control-functions.xqy";
import module namespace af = "http://lds.org/code/lds-edit/content-admin/admin-functions" at "modules/functions.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";

declare option xdmp:output "method = html";
declare option xdmp:mapping "true";

declare variable $page as xs:string := '/content-admin';
declare variable $site as xs:string? := ( xdmp:get-request-field('site')[. != ''], $af:site )[1];
declare variable $asset-id as xs:string? := xdmp:get-request-field('asset-id')[. != ''];

let $test := ($site)

return (
    if ( ac:has-permission("ldse:view-lds-edit-home", "", "", $site) ) then (
        xdmp:set-response-content-type("text/html"),
        '<!DOCTYPE html>',
        <html>
            <head>
                <meta charset="utf-8" />
                <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1" />
                <meta name="viewport" content="width=device-width" />
                <link rel="stylesheet" type="text/css" media="screen" href="{$settings:shared-prefix}/resources/css/ldspublisher-ice.css" />
                <link rel="stylesheet" type="text/css" href="{$settings:shared-prefix}/resources/css/ldspublisher.css" />
                <link rel="stylesheet" href="{$settings:shared-prefix}/content-admin/resources/css/screen.css" />
                <link rel="stylesheet" href="{$settings:shared-prefix}/content-admin/resources/css/nodes.css" />
                <link rel="stylesheet" href="{$settings:shared-prefix}/content-admin/resources/css/isotope.css" />
                <link rel="stylesheet" href="{$settings:shared-prefix}/content-admin/resources/css/dashboard.css"/>
                <link rel="stylesheet" href="{$settings:shared-prefix}/content-admin/resources/css/smoothness/jquery-ui-1.10.3.custom.min.css"/>
                <link rel="stylesheet" href="{$settings:shared-prefix}/content-admin/resources/css/shadows.css"/>
                <link rel="stylesheet" href="{$settings:shared-prefix}/content-admin/resources/css/dashboard.responsive.css"/>
                <style>
                    <![CDATA[
                    #nodes h1, #nodes h2 { margin-left: 17px; }
                ]]>
                </style>
            </head>
            <body>
                <section class="ldse-page">
                    { af:buildAdminPageLinks() }
                    <div id="page">
                        <section id="nodes">{ 
                            if ( fn:exists($asset-id) ) then (
                                <h1>Collection Results</h1>,
                                <button class="ldse-button ldse-responsive-button ldse-icon-trash destructive collection-update-button" id="remove-collections-button" style="display:none;" onclick="updateAsset('remove'); return false;">Remove from Collections</button>,
                                <button class="ldse-button ldse-responsive-button ldse-icon-unpublish destructive collection-update-button" id="unpublish-collections-button" style="display:none;" onclick="updateAsset('unpublish'); return false;">Un-Publish from Collections</button>,
                                <button class="ldse-button ldse-responsive-button ldse-icon-send primary collection-update-button" id="publish-collections-button" style="display:none;" onclick="updateAsset('publish'); return false;">Publish to Collections</button>,
                                <table id="detail-table" class="ldse-table ldse-fullbleed lanyon-detail-table">
                                    <thead>
                                        <tr>
                                            <td />
                                            <td>Collection Title</td>
                                            <td>Collection ID</td>
                                            <td>Asset Status in Collection</td>
                                        </tr>
                                    </thead>
                                    <tbody id="detail-table-body">{ af:build-asset-collection-list($af:lang, $site, $asset-id) }</tbody>
                                </table>
                            ) else ( 
                                <h1>Asset Results</h1>,
                                <table id="detail-table" class="ldse-table ldse-fullbleed lanyon-detail-table">
                                    <thead>
                                        <tr>
                                            <td>Asset ID</td>
                                            <td>Asset Title</td>
                                            <td>Asset Type</td>
                                        </tr>
                                    </thead>
                                    <tbody id="detail-table-body">{ af:build-asset-list($af:lang, $site) }</tbody>
                                </table>
                            )
                        }</section>
                    </div>
                </section>

                <scripts>
                    <script type="text/javascript" src="{$settings:cdn-path}/scripts/jquery/1.7.2/jquery.min.js"></script>
                    {ice:get-ice-script()}
                    {af:addPageEdit($page, $af:lang, (), (), fn:false())}
                    <script src="{$settings:shared-prefix}/content-admin/resources/js/jquery.isotope.min.js"></script>
                    <script src="{$settings:shared-prefix}/content-admin/resources/js/nodes.js"></script>
                    <script src="{$settings:shared-prefix}/content-admin/resources/js/dashboard.js"></script>
                    <script src="{$settings:shared-prefix}/content-admin/resources/js/highcharts.js"></script>
                </scripts>
            </body>
        </html>
    ) else (
        template:error-access-denied("Error!", "Sorry, you don't have permission to view this page.")
    )
)
