xquery version "1.0-ml";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../modules/utility-functions.xqy";
import module namespace template = "http://lds.org/shared/lds-edit/template" at "../modules/template.xqy";
import module namespace ice = "http://lds.org/code/shared/lds-edit/iceFunction" at "../ice/modules/iceFunctions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../modules/ldse-settings.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../modules/access-control-functions.xqy";
import module namespace af = "http://lds.org/code/lds-edit/content-admin/admin-functions" at "modules/functions.xqy";
import module namespace bp = "http://lds.org/code/cms/modules/bulk-publishing" at "../modules/bulk-publishing.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";

declare option xdmp:output "method = html";
declare option xdmp:mapping "true";

declare variable $page as xs:string := '/content-admin';
declare variable $site as xs:string? := ( xdmp:get-request-field('site')[. != ''], $af:site )[1];
declare variable $asset-id as xs:string? := xdmp:get-request-field('asset-id')[. != ''];

let $test := ($site)

let $results := bp:query-content-api(())
let $facet-locales := bp:get-facet-values($results)
let $json :=
    object-node {
        'facets': array-node {
            object-node {
                'sectionTitle': 'Locales',
                'options': array-node {
                    for $facet-locale as xs:string in $facet-locales
                    let $name as xs:string? := ( util:get-full-language-name-by-locale($facet-locale), $facet-locale )[1]
                    order by $name ascending
                    return (
                        object-node {
                            'id': fn:string($facet-locale),
                            'value': fn:string($facet-locale),
                            'title': fn:string($name)
                        }
                    )
                }
            }
        }
    }
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
                <link rel="stylesheet" href="{$settings:shared-prefix}/content-admin/resources/css/publishing.css"/>
{(:                <link rel="stylesheet" href="{$settings:shared-prefix}/content-admin/resources/css/dashboard.css"/>:)}
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
                <section class="ldse-page" ng-app="LDSP">
                    <h1>Publishing</h1>
                    <div id="page">
                        <bulk-publishing></bulk-publishing>
                    </div>
                </section>

                <scripts>
                    <script type="text/javascript">
                        var site = '{ $site }';
                    </script>
                    <script type="text/javascript" src="{$settings:shared-prefix}/resources/scripts/angularjs/angular-1.5.min.js"></script>
                    <script type="text/javascript" src="{$settings:cdn-path}/scripts/jquery/1.7.2/jquery.min.js"></script>
                    {ice:get-ice-script()}
                    {af:addPageEdit($page, $af:lang, (), (), fn:false())}
                    <script src="{$settings:shared-prefix}/content-admin/resources/scripts/bulk-publishing.js"></script>
                    <script src="{$settings:shared-prefix}/content-admin/resources/scripts/facets.js"></script>
                    <script src="{$settings:shared-prefix}/content-admin/resources/scripts/facet.js"></script>
                    <script src="{$settings:shared-prefix}/content-admin/resources/scripts/facet-results.js"></script>
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
