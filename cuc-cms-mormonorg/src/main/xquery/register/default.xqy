xquery version "1.0-ml";

import module namespace template = "http://lds.org/shared/lds-edit/template" at "/modules/template.xqy";
import module namespace regis-functions = "http://lds.org/code/register/regis-functions" at "/register/registration/modules/functions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "/modules/ldse-settings.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "/modules/ldse-core.xqy";
import module namespace okta = 'http://lds.org/code/cms/modules/okta-library' at "/modules/okta-library.xqy";

declare option xdmp:output "method = html";
declare option xdmp:mapping "true";

declare variable $message as xs:string? := xdmp:get-request-field("save");

let $login := okta:okta-login()
return
  template:apply(
    "Site List",
    '/default',
    <page>
        <head>
            <link href="{$settings:shared-prefix}/register/registration/resources/styles/registration.css" rel="stylesheet"></link>
        </head>
        <content>
            <section id="basic-info" class="ldse-section ldse-summary cf">
                <header class="ldse-section--header">
                    <h2>Registration Site List</h2>
                </header>
                <div class="ldse-section--body">
                    <a href="{$settings:shared-prefix}/register/registration"><button id="clearFilterBtn" class="ldse-button secondary ldse-icon-ko-add" onclick="">New Registration</button></a>
                    <br/>
                    <br/>
                    <table class="ldse-table">
                        <thead>
                            <tr>
                                <th id="fileType">Site Name</th>
                                <th id="fileType" class="center">Translation Service</th>
                            </tr>
                        </thead>
                        <tbody>{
                            for $site as element(registration) in cts:search(/registration, core:get-filter-query() )
                            let $site-name as xs:string := $site/basic-data/display-name
                            let $translation as xs:string? := $site/translation-checkbox
                            order by $site-name ascending
                            return (
                                <tr>
                                    <td><a href="{regis-functions:site-list($site/@id)}">{$site-name}</a></td>
                                    <td class="center">{if( fn:exists($translation) and fn:not($translation = "") ) then ( <span class="ldse-icon-check2" /> ) else ( <span class="ldse-icon-x" /> )}</td>
                                </tr>
                            )
                        }</tbody>
                    </table>
                </div>
            </section>
        </content>
        <scripts>
            <script src="{$settings:shared-prefix}/register/registration/resources/scripts/registration.js" type="text/javascript">&nbsp;</script>
        </scripts>
    </page>
)
