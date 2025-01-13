xquery version "1.0-ml";

import module namespace form = "http://lds.org/code/shared/lds-edit/dynamicForms" at "/ice/modules/dynamicForms.xqy";
import module namespace ice = "http://lds.org/code/shared/lds-edit/iceFunction" at "/ice/modules/iceFunctions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "/modules/ldse-settings.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "/modules/ldse-core.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";
import module namespace okta = 'http://lds.org/code/cms/modules/okta-library' at "/modules/okta-library.xqy";

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

let $login := okta:okta-login()
let $has-permission as xs:boolean := ac:has-permission('ldse:view-xml', $locale, ())

let $referer as xs:string := form:getVariable("referer")
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
            "/files",
            <page>
                <head>
                    <link rel="stylesheet" type="text/css" media="all" href="{$settings:shared-prefix}/form/resources/styles/form.css" />
                    <link rel="stylesheet" type="text/css" media="all" href="{$settings:shared-prefix}/files/resources/styles/files.css" />
                    <link rel="stylesheet" type="text/css" media="all" href="{$settings:shared-prefix}/scripts/resources/codemirror/lib/codemirror.css" />
                    <link rel="stylesheet" type="text/css" media="all" href="{$settings:shared-prefix}/scripts/resources/codemirror/theme/xq-light.css" />
                    <link rel="stylesheet" href="{$settings:shared-prefix}/translation/resources/styles/calendar.css" />
                </head>
                <content>
                    <section id="duplicate-files">
            			<section class="ldse-section ldse-summary ldse-clearfix">
            				<header class="ldse-section--header">
            					<h2>Duplicate Files</h2>
            				</header>
            				<form>
                              	<div class="ldse-clearfix">
                      				<div class="ldse-table-buttons">
                                        <button class="ldse-button secondary ldse-show-single" onclick="getFilesByIdForm(); return false;">Find Duplicate Files By ID</button>
                                    </div>
                                </div>
                                <table id="detail-table" class="ldse-table ldse-fullbleed">
                                    <thead>
                    					<tr>
                    						<th class="sorts" data-name="file-id"><a href="#d" onclick="sortColumn(this)">File Id</a></th>
                    						<th class="sorts hide-small" data-name="locale"><a href="#d" onclick="sortColumn(this)">Locale</a></th>
                    						<th class="sorts" data-name="title"><a href="#d" onclick="sortColumn(this)">Title</a></th>
                    						<th class="sorts" data-name="uri"><a href="#d" onclick="sortColumn(this)">URI</a></th>
                    						<th class="sorts hide-large" data-name="file-path"><a href="#d" onclick="sortColumn(this)">File Path</a></th>
                        				</tr>
                                    </thead>
                    				<tbody id="detail-table-body">
                    				</tbody>
                                </table>
                            </form>
                        </section>
                    </section>
                </content>
                <scripts>
                    <script type="text/javascript" src="{$settings:cdn-path}/scripts/jquery/plugins/validation/jquery.validate.1.8.1.min.js">&nbsp;</script>
                    <script type="text/javascript" src="{$settings:cdn-path}/scripts/jquery/plugins/validation/additional-methods1.8.1.min.js">&nbsp;</script>
                    <script type="text/javascript" src="{$settings:shared-prefix}/scripts/resources/codemirror/lib/codemirror.js">&nbsp;</script>
                    <script type="text/javascript" src="{$settings:shared-prefix}/scripts/resources/codemirror/mode/xml/xml.js">&nbsp;</script>
                    <script type="text/javascript" src="{$settings:shared-prefix}/scripts/resources/codemirror/addon/edit/matchbrackets.js">&nbsp;</script>
                    <script type="text/javascript" src="{$settings:shared-prefix}/scripts/resources/codemirror/addon/selection/active-line.js">&nbsp;</script>
            		{ice:get-ice-script()}
            		{ form:jsVariableMap() }
            		{<script type="text/javascript" src="{$settings:shared-prefix}/files/resources/scripts/files.js"/>}
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
