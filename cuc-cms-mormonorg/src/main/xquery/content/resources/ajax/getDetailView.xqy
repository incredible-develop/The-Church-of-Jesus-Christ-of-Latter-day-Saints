xquery version "1.0-ml";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../../modules/utility-functions.xqy";
import module namespace content = "http://lds.org/code/shared/lds-edit/contentFunctions" at "../../modules/contentFunctions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../../modules/ldse-settings.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../../modules/access-control-functions.xqy";

declare option xdmp:mapping "true";

declare variable $lang as xs:string := util:escape-chars(xdmp:get-request-field("locale", "eng"));

declare variable $permission as xs:string := 'ldse:view-content-admin';
declare variable $localesWithRights as xs:string* := ac:locales-by-permission($permission);
declare variable $locale as xs:string := if ($lang eq $localesWithRights) then ($lang) else ($localesWithRights[1]);

declare variable $uri as xs:string := util:escape-chars(xdmp:get-request-field("s", "/"));

declare variable $files as element()* := content:getContentByUri($locale, $uri);

if (ac:has-permission($permission, $locale, '')) then (
    xdmp:set-response-content-type( "text/html" ),
    <div class="padding-md">
        <a type="button" href="{$settings:shared-prefix}/content/resources/ajax/export?lang=eng&amp;locale={$locale}&amp;s={$uri}" class="ixf-button secondary float-right">Export</a>
        <h2>Section : {$uri}</h2>
        <table class="ixf-table ixf-table-default ixf-fixed" data-dt-rows="999999">
            <thead>
                <tr>
                    <th class="sorting xxl"><a href="#">Url</a></th>
                    <th class="sorting sm"><a href="#">Type</a></th>
                    <th class="sorting_desc lg"><a href="#">Title</a></th>
                    <th class="sorting sm"><a href="#">Status</a></th>
                    <th class="sorting xs"><a href="#">Options</a></th>
                    <th class="sorting sm"><a href="#">Translation</a></th>
                    {
                        if (ac:has-permission('ldse:view-xml', $locale, ''))then (
                            <th class="sm"><a href="#">View File</a></th>
                        ) else ()
                    }
                </tr>
            </thead>
            {
                content:buildRows($files)
            }
        </table>
    </div>
) else ()
