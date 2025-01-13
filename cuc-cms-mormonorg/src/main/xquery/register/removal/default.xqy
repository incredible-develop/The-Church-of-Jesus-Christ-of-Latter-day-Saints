xquery version "1.0-ml";

import module namespace template = "http://lds.org/shared/lds-edit/template" at "../../modules/template.xqy";
import module namespace regis-functions = "http://lds.org/code/register/regis-functions" at "/register/registration/modules/functions.xqy";
import module namespace form = "http://lds.org/code/shared/lds-edit/dynamicForms" at "../../ice/modules/dynamicForms.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../modules/ldse-settings.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../modules/ldse-core.xqy";
import module namespace ldse-meta = "http://lds.org/code/shared/lds-edit/meta-functions" at "../../modules/ldse-meta.xqy";


declare namespace search = "http://marklogic.com/appservices/search";
declare namespace ldse = "http://lds.org/code/lds-edit";

declare option xdmp:output "method = html";
declare option xdmp:mapping "true";

declare variable $shared-prefix as xs:string? := $settings:shared-prefix;
declare variable $message as xs:string? := xdmp:get-request-field("save");
declare variable $current-user as xs:string? := form:getVariable('user');

let $this-page as xs:string := '/default'
let $scripts as element(script)* := (
    <script src="{$shared-prefix}/registration/resources/scripts/registration.js" type="text/javascript"></script>
)
let $title as xs:string := "Removal List"
let $search as element()* := (
    cts:search(/registration,
        core:get-filter-query()
    )
)
return(
    template:apply(
        $title,
        $this-page,
        <page>
            <head>
                <link href="{$shared-prefix}/registration/resources/styles/registration.css" rel="stylesheet"></link>
            </head>
            <content>
                <section id="basic-info" class="ldse-section ldse-summary cf">
                    <header class="ldse-section--header">
                        <h2>Removal Site List</h2>
                    </header>
                    <div class="ldse-section--body">
                        <br/>
                        <br />
                        <table class="ldse-table">
                            <thead>
                                <tr>
                                    <th></th>
                                    <th id="fileType">Site Name</th>
                                </tr>
                            </thead>
                            <tbody>
                                {for $site in $search
                                    let $site-name as xs:string := $site/basic-data/site-name
                                    let $site-id as xs:string := ldse-meta:get-document-id($site)
                                    let $uri as xs:string := ldse-meta:get-document-uri($site)
                                    let $each-site := (
                                         <form action="/register/removal/delete?lang=eng" method="post">
                                             <input type="hidden" name="uri" value="{$uri}" />
                                             <input type="hidden" name="id" value="{$site-id}" />
                                             <tr>
                                                 <td><button id="clearFilterBtn" class="destructive ldse-button">Delete</button></td>
                                                 <td><a href="{$site-id}">{$site-name}</a></td>
                                             </tr>
                                         </form>
                                    ) 
                                     order by xs:string($site) ascending
                                     return (
                                         if ($site/ldse:ldse-meta/ldse:created[@username = $current-user] or $current-user = "jasongh4") then (
                                             $each-site
                                         ) else ()
                                     )
                                }
                            </tbody>
                        </table>
                    </div>
                </section>
            </content>
            <scripts>
                <script src="{$shared-prefix}/registration/resources/scripts/registration.js" type="text/javascript"></script>
            </scripts>
            <button-groups></button-groups>
            <options>
                <ldse-logo-image-class>xl</ldse-logo-image-class>
            </options>
        </page>
    )
)