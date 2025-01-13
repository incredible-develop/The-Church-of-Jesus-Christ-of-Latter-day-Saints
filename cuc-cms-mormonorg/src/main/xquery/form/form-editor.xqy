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
import module namespace version = "http://lds.org/code/lds-edit/versions" at "/modules/versions-functions.xqy";
import module namespace correlation = "http://lds.org/code/shared/lds-edit/correlation" at "/correlation/modules/correlation-functions.xqy";
import module namespace enrich = "http://lds.org/code/shared/lds-edit/enrich" at "/enrich/enrich-functions.xqy";
import module namespace fbf = "http://lds.org/code/shared/lds-edit/form-builder-functions" at "/form/modules/form-builder-functions.xqy";
import module namespace mljson = "http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";

declare namespace search = "http://marklogic.com/appservices/search";
declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace cldse = "http://lds.org/code/lds-edit/correlation";
declare namespace hldse = "http://lds.org/code/lds-edit/history";
declare namespace its = "http://www.w3.org/2005/11/its";

declare option xdmp:output "method = html";
declare option xdmp:mapping "true";

(: MAIN PARAMS :)
declare variable $currentUser as xs:string := ac:getUserName();
declare variable $lang as xs:string := form:getVariable('lang');
declare variable $country as xs:string? := form:getVariable('country');
declare variable $locale as xs:string := form:getVariable('locale');   (: lang or lang-country :)
declare variable $id as xs:string? := form:getVariable('id');
declare variable $form-name as xs:string? := (xdmp:get-request-field("form")[1]);
declare variable $uri as xs:string? := form:getVariable('uri')[1];  (: xml uri :)
declare variable $page as xs:string? := form:getVariable('page'); (: current page uri, if differnt from uri:)
declare variable $action as xs:string := form:getVariable('action'); (: edit, add, view :)
declare variable $options as xs:string? := form:getVariable('option')[1];
declare variable $following as xs:string* := form-functs:get-follower($currentUser, $id, $locale);
declare variable $formAction as xs:string := form:getVariable('formAction');
(: *********** :)
declare variable $history as element(hldse:history)? := history:get-history($id, $locale);

let $preview-url as xs:string? := core:build-url($uri, $locale, $uri)
let $form as element(ldse:formTemplate)? := form:getFormTemplate($form-name)
let $file as element()? := ( fbf:getForm(()), $fbf:empty-form )[1]
let $is-submission as xs:boolean := ldsemeta:is-submission($file) or form:getVariable("is-submission")
let $is-submitted as xs:boolean := ldsemeta:submission-submitted($file)
(:let $e := fn:error():)
let $status-display as xs:string? := ldsemeta:static-status($file)
let $has-permission as xs:boolean :=
    if($action = "edit")
    then ac:has-permission('ldse:edit-doc', $locale, $uri)
    	or ac:has-permission('ldse:edit-submission', $locale, $uri)

    else if($action = "add")
    then ac:has-permission('ldse:add-doc', $locale, $uri)
        or ac:has-permission('ldse:add-submission', $locale, $uri)

    else if($action = "view")
    then ac:has-permission("ldse:view-submission", $locale, $uri)

    else fn:false()

let $button-click as xs:string := 'ldse:preview'
let $has-publish-doc as xs:boolean := ac:has-permission('ldse:publish-doc', $locale, $uri)
let $has-unpublish-doc as xs:boolean := ac:has-permission('ldse:unpublish-doc', $locale, $uri)
let $referer as xs:string := form:getVariable("referer")
let $history-enabled as xs:boolean := $settings:history-enabled
let $versions-enabled as xs:boolean :=
	if($is-submission)
	then ldsemeta:submission-submitted($file)
		and settings:is-mode-versioned($core:mode)
	else settings:is-mode-versioned($core:mode)


(: ENRICH R&D :)
let $enrich-enabled as xs:boolean := $form/ldse:enrich = "true" and enrich:enrichable-lang($locale)
(: ENRICH R&D :)

let $form-title as xs:string? := xs:string($form/ldse:title)
let $doc-title as element(ldse:document-title)? := $form/ldse:document-title
let $title as xs:string? :=
    if ($doc-title/@show = "false") then (

    ) else if (fn:exists($doc-title)) then (
         fn:normalize-space(
            fn:string-join(
                for $n as item() in util:value($file, $doc-title)
                return fn:string($n)
            , ' ')
        )
    ) else (
        ldsemeta:get-document-title($file)
    )
let $actions as element(ldse:action)+ := ($settings:actions)
let $disabled-on-add as xs:string? :=
    if ($action = "add") then (
        "disabled"
    ) else ()
let $tooltip-on-add as attribute()? :=
    if ($action = "add") then (
        attribute data-tooltip {"This feature is not available when creating a document."}
    ) else ()

let $preview-right-url as xs:string := fn:replace($preview-url, "^(https?://).*?(/.*)$", fn:concat("$1", $settings:live-domain, "$2"))
let $form-json := core:transform-to-json($file, ('ldse:functions'))
return (
    if ($has-permission) then (
        core:template-apply(
            "Form Editor",
            "/form/form-editor",
            <page>
                <controller>formBuilder</controller>
                <head>
                    <link rel="stylesheet" type="text/css" media="all" href="{$settings:shared-prefix}/form/resources/styles/form.css" />
                    <link rel="stylesheet" href="{$settings:shared-prefix}/translation/resources/styles/calendar.css" />
                    {form:ouputCss($form)}
                    <link rel="stylesheet" type="text/css" href="{$settings:shared-prefix}/ice/resources/styles/binaryManager.css" />
                    <link rel="stylesheet" type="text/css" href="{$settings:shared-prefix}/resources/css/enrich.css" />

                    <link rel="stylesheet" type="text/css" media="all" href="{$settings:shared-prefix}/form/resources/scripts/flexslider/flexslider.css" />
                </head>
                <content>
                    <h2>{fn:string-join(($form-title,$title), ": ")} </h2>
                    <section id="options" class="ldse-section ldse-summary ldse-clearfix">
             			<header class="ldse-section--header">
             				<h2><a href="#d" class="ldse-icon-ko-tri-down">Options</a></h2>
             			</header>
             			<div class="ldse-section--body ldse-form">
             				<div class="ldse-rowFix ldse-makeCols">
             					<section id="content" class="ldse-block tile ldse-notification-container ldse-toggle-content depressed" data-group="#options" data-selector="#content-info">
             						<button class="ldse-button tile ldse-icon-edit above active">Content</button>
             						<span class="ldse-information">
    							         <span>{$lang}{if($country[. != ""]) then fn:concat("-", $country) else ()}</span>
    						        </span>
             					</section>
             					<section id="preview" class="ldse-block tile ldse-notification-container ldse-toggle-content disabled" data-group="#options" data-selector="#preview-info">
             						{$tooltip-on-add}
             						<button class="ldse-button tile ldse-icon-page above active" onclick="return Preview.tileClick();">Preview</button>
             						<span class="ldse-information">
    						        </span>
             					</section>
             					<section id="publishing" class="ldse-block tile ldse-notification-container ldse-toggle-content" data-group="#options" data-selector="#publishing-info">
             						<button class="ldse-button tile ldse-icon-calendar above">Publishing</button>
             						<span class="ldse-information">
    							         <span>{$status-display}</span>
    						        </span>
             					</section>
             					<section id="translations" class="ldse-block tile ldse-notification-container ldse-toggle-content disabled" data-group="#options" data-selector="#translation-info">
             						{$tooltip-on-add}
             						<button class="ldse-button tile ldse-icon-globe above">Translations</button>
             						<span class="ldse-information">
    							         <span></span>
    						        </span>
             					</section>
    							{if ($history-enabled) then (
             					<section id="workflow-comments" class="ldse-block tile ldse-notification-container ldse-toggle-content {$disabled-on-add}" data-click="getComments" data-id="{$id}" data-locale="{$locale}" data-group="#options" data-selector="#comments-section">
                                	{$tooltip-on-add}
                                	<button class="ldse-button tile ldse-icon-comments above">Comments</button>
             						<span class="ldse-information">
             						    <span class="ldse-comments-information">{fn:count($history/hldse:events/hldse:comment)}</span>
             					    </span>
                                </section>
                                ) else ()
                                }
             					{
             						correlation:build-correlation-button($id, $file)
                                }
                                {if ($history-enabled) then (
                   					<section id="history" class="ldse-block tile ldse-notification-container ldse-toggle-content {$disabled-on-add}" data-click="getHistory" data-id="{$id}" data-locale="{$locale}" data-group="#options" data-selector="#history-info">
                   						{$tooltip-on-add}
                   						<button class="ldse-button tile ldse-icon-history above">History</button>
	             						<span class="ldse-information">
	             						    <span class="ldse-history-information">{ fn:count($history/hldse:events/*) }</span>
	    						        </span>
                   					</section>
                   				) else (),
                   				if ($versions-enabled) then (
                                    version:build-versions-button($file, $id, $disabled-on-add, $tooltip-on-add)
                   				) else ()
                   				}

             				</div>
             			</div>
             		</section>
					<form class="ldse-section--body content-table ldse-form iceForm form-data" method="post" enctype="multipart/form-data" action="{$settings:shared-prefix}/form/create-form?lang={$lang}">
                  		<input type="hidden" id="is-submission" name="is-submission" value="{$is-submission}"/>
                  		<input type="hidden" id="is-submitted" value="{$is-submitted}"/>
                  		<input type="hidden" id="remove-publish-button" value="{fn:not(ac:has-permission("ldse:publish-doc", (), ()))}"/>
                  		<input type="hidden" id="isPageBuilder" value="{$form-name = "pageBuilder"}"/>
            		<section id="publishing-info" style="display:none;">
            			<section class="ldse-section ldse-summary ldse-clearfix">
             		     <input type="hidden" id="is-submitter" value="{$settings:is-submitter}" />
            				<header class="ldse-section--header">
            					<h2>Publishing</h2>
            				</header>
             			<section>
            				<div class="ldse-section--header">
            					<h2><a href="#d" class="ldse-icon-ko-tri-down">Document Info</a></h2>
            				</div>
             				<div class="ldse-section--body ldse-form">
             				   <div class="grid-50">
    								<dl>
    									<dt><span>URI:&nbsp;<span>{fn:string($file/ldse:ldse-meta/ldse:document/@uri)}</span></span></dt>
    								</dl>
    							</div>
             				    <div class="grid-50">
    								<dl>
    									<dt><span>Status:&nbsp;<span>{$status-display}</span></span></dt>
    								</dl>
    							</div>
             				    <div class="grid-50">
    								<dl>
    									<dt><span>ID:&nbsp;<span>{fn:string($file/ldse:ldse-meta/ldse:document/@id)}</span></span></dt>
    								</dl>
    								<dl>
    									<dt><span>File Name:&nbsp;<span>{util:file-name($file)}</span></span></dt>
    								</dl>
    								{
    								    if (fn:exists($file)) then (
        								    <dl>
                                                <dt><span>File Path:&nbsp;<span>{fn:replace(xdmp:node-uri($file),'/', '/&#8203;')}</span></span></dt>
                                            </dl>
                                        ) else ()
                                    }
    							</div>
             				    <div class="grid-50">
    								<dl>
    									<dt><span>Locale:&nbsp;<span>{fn:string($file/@locale)}</span></span></dt>
    								</dl>
    								<dl>
    									<dt><span>TGP:&nbsp;<span>{fn:string($file/ldse:ldse-meta/ldse:document/@tgp)}</span></span></dt>
    								</dl>
    							</div>
    							<div class="ldse-first"></div>
             				</div>
             			</section>
             			</section>
             		</section>
                    <section id="content-info" class="ldse-section ldse-summary ldse-clearfix">
                        <header class="ldse-section--header">
                            <h2>Content</h2>
                        </header>
                        <div class="ldse-section--body publishing-table ldse-form">
                            <input type="hidden" id="formLocale" name="formLocale" value="{$locale}" />
                            <input type="hidden" name="country" value="{$country}"/>
                            <input type="hidden" id="content-id" name="id" value="{$id}"/>
                            <input type="hidden" name="uri" value="{$uri}"/>
                            <input type="hidden" name="page" value="{$page}" />
                            <input type="hidden" id="formAction" name="action" value="{$action}" />
                            <input type="hidden" id="option" name="option" value="{$options}" />
                            <input type="hidden" name="referer" value="{$referer}" />
                            <input type="hidden" id="content-form-name" name="formName" value="{$form-name}" />
                            <input type="hidden" id="status" name="status" value="{$button-click}" />
                            <p><em>*</em> indicates required field</p>
                            <fieldset class="content-section">
                                <dl data-sequence="14" data-group="" class="">
                                    <dt class="label"><label for="dateline">Form Name*</label></dt>
                                    <dd><input type="text" class="xxxl required" title="Form Name" ng-model="form.name" name="formName"/></dd>
                                </dl>
                                <dl data-sequence="" data-group="" class=""><dd><input type="checkbox" title="Allow Schedule Publish" id="" ng-model="form._attributes.schedulePublish" name="schedule-publish"/><label for="schedule-publish">Allow Schedule Publish</label><br/></dd></dl>
                                <dl data-sequence="" data-group="" class=""><dd><input type="checkbox" title="Allow Schedule Unpublish" id="" ng-model="form._attributes.scheduleUnpublish" name="schedule-unpublish" /><label for="schedule-publish">Allow Schedule Unpublish</label><br/></dd></dl>
                                <dl data-sequence="" data-group="" class=""><dd><input type="checkbox" title="Workflow" id="" name="workflow" ng-model="form._attributes.workflow"/><label for="schedule-publish">Workflow</label><br/></dd></dl>
                                <dl data-sequence="" data-group="" class=""><dd><input type="checkbox" title="Show Document Title" id="" name="showDocTitle" ng-model="form._attributes.showDocTitle"/><label for="schedule-publish">Show Document Title</label><br/></dd></dl>
                                <dl data-sequence="14" data-group="" class="">
                                    <dt class="label"><label for="dateline">Document Title</label></dt>
                                    <dd><input type="text" class="xxxl" title="Document Title" name="docTitle" ng-model="form.documentTitle"/></dd>
                                </dl>
                                <dl data-sequence="14" data-group="" class="">
                                    <dt class="label"><label for="dateline">Folder*</label></dt>
                                    <dd><input type="text" class="xxxl required" title="Folder" name="folder" ng-model="form.folder"/></dd>
                                </dl>
                                <dl data-sequence="14" data-group="" class="">
                                    <dt class="label"><label for="dateline">File Prefix*</label></dt>
                                    <dd><input type="text" class="xxxl required" title="File Prefix" name="file-prefix" ng-model="form.filePrefix"/></dd>
                                </dl>
                                <dl data-sequence="14" data-group="" class="">
                                    <dt class="label"><label for="dateline">Root Element*</label></dt>
                                    <dd><input type="text" class="xxxl required" title="Root Element" name="root-element" ng-model="form.rootElement"/></dd>
                                </dl>
                                <section class="ldse-group ldse-section">
                                    <div class="ldse-section--header">
                                        <h2><a href="#d" class="ldse-icon-ko-tri-down ldse-group-header">Functions</a></h2>
                                    </div>
                                    <div class="ldse-section--body ldse-form">
                                        <dl data-sequence="18" data-group="functions" class="">
                                            <dt>
                                                <label><b>Functions</b></label>
                                            </dt>
                                            <dd>
                                                <ul class="sortable ui-sortable">
                                                    <li class="repeated-item" ng-repeat="function in form.functions">
                                                        <dl>
                                                            <input type="hidden" name="highlights-child" class="child" value="1"/>
                                                            <a href="#d" class="sprite delete ldse-icon-ko-remove ldse-icon bottom float-right">Delete</a>
                                                        </dl>
                                                        <fieldset class="table" style="">
                                                            <dl data-sequence="" data-group="functions" class="inline-block">
                                                                <dt class="label"><label for="functionName">Function Name (Include Namespace)</label></dt>
                                                                <dd><input type="text" class="xxxl" title="Function Name (Include Namespace)" name="functionName" ng-model="function.name" id="functionName"/></dd>
                                                            </dl>
                                                            <dl data-sequence="" data-group="functions" class="inline-block">
                                                                <dt class="label"><label for="functionNamespace">Function Namespace</label></dt>
                                                                <dd><input type="text" class="xxxl" title="Function Namespace (Include Namespace)" name="functionNamespace" ng-model="function.namespace" id="functionNamespace"/></dd>
                                                            </dl>
                                                            <dl data-sequence="" data-group="functions" class="inline-block">
                                                                <dt class="label"><label for="functionPath">Function Path</label></dt>
                                                                <dd><input type="text" class="xxxl" title="Function Path (Include Namespace)" name="functionPath" ng-model="function.path" id="functionPath"/></dd>
                                                            </dl>
                                                        </fieldset>
                                                    </li>
                                                </ul>
                                                <a href="#d" class="sprite ldse-icon-ko-add ldse-add prefix" ng-click="add(form.functions);">Add </a>
                                            </dd>
                                        </dl>
                                    </div>
                                </section>
                                <section class="ldse-group ldse-section">
                                    <div class="ldse-section--header">
                                        <h2><a href="#d" class="ldse-icon-ko-tri-down ldse-group-header">Functions</a></h2>
                                    </div>
                                    <div class="ldse-section--body ldse-form">
                                        <dl data-sequence="18" data-group="" class="">
                                            <dt>
                                                <label><b>Form</b></label>
                                            </dt>
                                            <dd>
                                                <ul class="sortable ui-sortable">
                                                    <li class="repeated-item">
                                                        <dl>
                                                            <input type="hidden" name="highlights-child" class="child" value="1"/>
                                                            <a href="#d" class="sprite delete ldse-icon-ko-remove ldse-icon bottom float-right">Delete</a>
                                                        </dl>
                                                        <fieldset class="table" style="">
                                                            <dl data-sequence="18" data-group="" class="">
                                                                <dt><label>Type</label></dt>
                                                                <dd>
                                                                    <select type="select" title="Type" name="type" id="type">
                                                                        {form:buildDefaultSelector(())}
                                                                        {(:<option value="headquarters" selected="">Headquarters</option><option value="area">Area</option>:)}
                                                                    </select>
                                                                </dd>
                                                            </dl>
                                                            <dl data-sequence="" data-group="" class="inline-block">
                                                                <dt class="label"><label for="highlight-1">Highlight</label></dt>
                                                                <dd><input type="text" class="xxxl" title="Highlight" name="highlight-1" value="" id="highlight-1"/></dd>
                                                            </dl>
                                                        </fieldset>
                                                    </li>
                                                </ul>
                                                <a href="#d" class="sprite ldse-icon-ko-add ldse-add prefix">Add </a>
                                            </dd>
                                        </dl>
                                    </div>
                                </section>
                            </fieldset>
                        </div>
                    </section>
                    </form>
                    { if ($history-enabled) then (
                        history:build-history-section()
                    ) else () }
                    { if ($history-enabled) then (
                       history:build-comment-section($id, $locale, $uri)) else()}
                    { if ($versions-enabled) then (
                        version:build-versions-section($file)
                    ) else ()}
                </content>
                <scripts>
                	{
                		let $protocol as xs:string := xdmp:get-request-header("X-Forwarded-Scheme", "http")
                		return <script language="JavaScript" type="text/javascript" src="//{fn:replace($protocol, "^http(s)$", "$1")[. ne "http"]}admin.brightcove.com/js/BrightcoveExperiences.js"/>
                    }
                    <script type="text/javascript" src="{$settings:cdn-path}/scripts/jquery/plugins/validation/jquery.validate.1.8.1.min.js"/>
                    <script type="text/javascript" src="{$settings:cdn-path}/scripts/jquery/plugins/validation/additional-methods1.8.1.min.js"/>
            		{ice:get-ice-script()}
            		{ form:jsVariableMap() }
            		{ form:ouputJavascript($form) }
                    <script type="text/javascript">
                        var referer = {xdmp:to-json-string(fn:string($referer))};
                        var userFullName = {xdmp:to-json-string(ac:getPersonName())};
                        ICE.uri = {xdmp:to-json-string($uri)};
                        ICE.page = {xdmp:to-json-string($page)};
                        var form = {$form-json};

                        var versify = "";
                        $(function(){{
                            ICE.setupForm();
                        }});
                    </script>
                    <script type="text/javascript" src="{$settings:shared-prefix}/resources/scripts/angularjs/angular.min.js"></script>
                    <script type="text/javascript" src="{$settings:shared-prefix}/resources/scripts/angularjs/angular-sanitize.min.js"></script>
                    <script type="text/javascript" src="{$settings:shared-prefix}/resources/scripts/angularjs/ldsp-ui-directives.js"></script>
                    <script type="text/javascript" src="{$settings:shared-prefix}/form/resources/scripts/app.js" />
{(:                    <script type="text/javascript" src="{$settings:shared-prefix}/form/resources/scripts/form.js" />:)}
                    <script type="text/javascript" src="{$settings:shared-prefix}/form/resources/scripts/form-editor.js" />
                    <script type="text/javascript" src="{$settings:shared-prefix}/form/resources/scripts/content.js" />
                    <script type="text/javascript" src="{$settings:shared-prefix}/binary/resources/scripts/burce.js" />
                    {
                    	correlation:scripts()
                    }
                    { if ($history-enabled) then (
                        history:build-history-scripts()
                    ) else () }
                    { if ($versions-enabled) then (
                        version:build-versions-scripts($id)
                    ) else ()}
                    <script type="text/javascript" src="{$settings:shared-prefix}/form/resources/scripts/flexslider/jquery.flexslider-min.js" />
                    <script type="text/javascript" src="{$settings:shared-prefix}/form/resources/scripts/chosen.jquery.min.js">&nbsp;</script>
                </scripts>
                <button-groups>
    				<button-group>
    					<button ng-click="save()" id="action-cancel" class="ldse-button ldse-responsive-button primary ldse-icon-save">Save</button>
    				</button-group>
    				<button-group>
    					<button onclick="promptChanges(); return false;" id="action-cancel" class="ldse-icon-x">Done</button>
    				</button-group>
    			</button-groups>
                <preview-eye>{$preview-url}</preview-eye>
                <options>
                </options>
            </page>
        )
    ) else (
        let $errorMsg as xs:string:="Sorry, you don't have permission to view this page."
        let $errorTitle as xs:string:= "Error!"
        return xdmp:redirect-response(fn:concat($settings:shared-prefix,"/shared/lds-edit/error?errorMsg=",$errorMsg,"&amp;errorTitle=",$errorTitle))
    )
)
