xquery version "1.0-ml";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "/modules/utility-functions.xqy";
import module namespace template = "http://lds.org/shared/lds-edit/template" at "/modules/template.xqy";
import module namespace form = "http://lds.org/code/shared/lds-edit/dynamicForms" at "/ice/modules/dynamicForms.xqy";
import module namespace ice = "http://lds.org/code/shared/lds-edit/iceFunction" at "/ice/modules/iceFunctions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "/modules/ldse-settings.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "/modules/ldse-core.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";
import module namespace security = "http://lds.org/code/shared/common/security/security-functions" at "/shared/common/security/securityFunctions.xqy";
import module namespace history = "http://lds.org/code/shared/lds-edit/history/history" at "/history/history.xqy";
import module namespace translation = "http://lds.org/code/shared/lds-edit/translationFunctions" at "/translation/modules/translationFunctions.xqy";
import module namespace form-functs = "http://lds.org/code/shared/lds-edit/form/form-functions" at "/form/modules/form-functions.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "/modules/ldse-meta.xqy";
import module namespace ff = "http://lds.org/code/shared/lds-edit/file-functions" at "/files/modules/file-functions.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace its = "http://www.w3.org/2005/11/its";

declare option xdmp:output "method = html";
declare option xdmp:mapping "true";

(: MAIN PARAMS :)
declare variable $currentUser as xs:string := ac:getUserName();
declare variable $lang as xs:string := form:getVariable('lang');
declare variable $country as xs:string? := form:getVariable('country');
declare variable $locale as xs:string := form:getVariable('locale');   (: lang or lang-country :)
declare variable $id as xs:string? := form:getVariable('id');
declare variable $form-name as xs:string? := (form:getVariable('form'),xdmp:get-request-field("form"))[1];
declare variable $uri as xs:string := form:getVariable('uri');  (: xml uri :)
declare variable $page as xs:string := form:getVariable('page'); (: current page uri, if differnt from uri:)
declare variable $action as xs:string := form:getVariable('action'); (: edit, add, view :)
declare variable $options as xs:string := form:getVariable('option')[1];
declare variable $following as xs:string* := form-functs:get-follower($currentUser, $id, $locale);

let $has-permission as xs:boolean := ac:has-permission('ldse:view-xml', $locale, ())

let $referer as xs:string := form:getVariable("referer")
let $actions as element(ldse:action)+ := ($settings:actions)
let $disabled-on-add as xs:string? :=
    if ($action = "add") then (
        "disabled"
    ) else ()
let $tooltip-on-add as attribute()? :=
    if ($action = "add") then (
        attribute data-tooltip {"This feature is not available when creating a document."}
    ) else ()

return (
    if ($has-permission) then (
        core:template-apply(
            "File Manager",
            "/files/all-duplicates",
            <page>
                <head>
                    <link rel="stylesheet" type="text/css" media="all" href="{$settings:shared-prefix}/shared/lds-edit/form/resources/styles/form.css" />
                    <link rel="stylesheet" type="text/css" media="all" href="{$settings:shared-prefix}/files/resources/styles/files.css" />
                    <link rel="stylesheet" type="text/css" media="all" href="{$settings:shared-prefix}/scripts/resources/codemirror/lib/codemirror.css" />
                    <link rel="stylesheet" type="text/css" media="all" href="{$settings:shared-prefix}/scripts/resources/codemirror/theme/xq-light.css" />
                    <link rel="stylesheet" href="{$settings:shared-prefix}/translation/resources/styles/calendar.css" />
                </head>
                <content>
{(:                    <section id="duplicate-files">
            			<section class="ldse-section ldse-summary ldse-clearfix">
            				<header class="ldse-section--header">
            					<h2>Duplicate Files</h2>
            				</header>
            				<form>
                              	<div class="ldse-clearfix">
                      				<div class="ldse-table-buttons">
                                        <button class="ldse-button secondary ldse-show-single" onclick="getAllDuplicateFilesForm(); return false;">Find All Duplicate Files</button>
                                    </div>
                                </div>
                                <table id="detail-table" class="ldse-table ldse-fullbleed">
                                    <thead>
                    					<tr>
                    						<th class="sorts hide-large" data-name="file-path"><a href="#d" onclick="sortColumn(this)">File Path</a></th>
                        				</tr>
                                    </thead>
                    				<tbody id="detail-table-body">
                    				    {ff:get-saved-duplicates()}
                    				</tbody>
                                </table>
                            </form>
                        </section>
                    </section>:)}
                </content>
                <scripts>
                    <script type="text/javascript" src="{$settings:cdn-path}/scripts/jquery/plugins/validation/jquery.validate.1.8.1.min.js"/>
                    <script type="text/javascript" src="{$settings:cdn-path}/scripts/jquery/plugins/validation/additional-methods1.8.1.min.js"/>
                    <script type="text/javascript" src="{$settings:shared-prefix}/scripts/resources/codemirror/lib/codemirror.js"></script>
                    <script type="text/javascript" src="{$settings:shared-prefix}/scripts/resources/codemirror/mode/xml/xml.js"></script>
                    <script type="text/javascript" src="{$settings:shared-prefix}/scripts/resources/codemirror/addon/edit/matchbrackets.js"></script>
                    <script type="text/javascript" src="{$settings:shared-prefix}/scripts/resources/codemirror/addon/selection/active-line.js"></script>
            		{ice:get-ice-script()}
            		{ form:jsVariableMap() }
            		<script type="text/javascript" src="{$settings:shared-prefix}/files/resources/scripts/files.js"/>
                </scripts>
                <options>
                </options>
            </page>
        )
    ) else (
        let $errorMsg as xs:string:="Sorry, you don't have permission to view this page."
        let $errorTitle as xs:string:= "Error!"
        return xdmp:redirect-response(fn:concat($settings:shared-prefix,"/error?errorMsg=",$errorMsg,"&amp;errorTitle=",$errorTitle))
    )
)
