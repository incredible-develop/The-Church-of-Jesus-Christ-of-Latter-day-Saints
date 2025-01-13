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
import module namespace form-functs = "http://lds.org/code/shared/lds-edit/form/form-functions" at "modules/form-functions.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "/modules/ldse-meta.xqy";
import module namespace version = "http://lds.org/code/lds-edit/versions" at "/modules/versions-functions.xqy";
import module namespace correlation = "http://lds.org/code/shared/lds-edit/correlation" at "/correlation/modules/correlation-functions.xqy";
import module namespace enrich = "http://lds.org/code/shared/lds-edit/enrich" at "/enrich/enrich-functions.xqy";
import module namespace site = "http://lds.org/code/shared/lds-edit/custom/ldse-site-core" at "/custom/lds-edit/ldse-site-core.xqy";
import module namespace sp = "http://lds.org/code/modules/site-properties" at '/modules/site-properties.xqy';
import module namespace okta = 'http://lds.org/code/cms/modules/okta-library' at "/modules/okta-library.xqy";

declare namespace search = "http://marklogic.com/appservices/search";
declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace cldse = "http://lds.org/code/lds-edit/correlation";
declare namespace hldse = "http://lds.org/code/lds-edit/history";
declare namespace its = "http://www.w3.org/2005/11/its";

declare option xdmp:output "method = html";
declare option xdmp:mapping "true";

(: MAIN PARAMS :)
declare variable $lang as xs:string := form:getVariable('lang');
declare variable $country as xs:string? := form:getVariable('country');
declare variable $locale as xs:string := form:getVariable('locale');   (: lang or lang-country :)
declare variable $id as xs:string? := form:getVariable('id');
declare variable $form-name as xs:string? := (form:getVariable('form'), xdmp:get-request-field("form"))[1];
declare variable $uri as xs:string? := form:getVariable('uri');  (: xml uri :)
declare variable $page as xs:string? := form:getVariable('page'); (: current page uri, if differnt from uri:)
declare variable $action as xs:string := form:getVariable('action'); (: edit, add, view :)
declare variable $options as xs:string? := form:getVariable('option')[1];
declare variable $site as xs:string? := form:getVariable('currSite')[. != ''];
(: *********** :)
declare variable $history as element(hldse:history)? := history:get-history($id, $locale);
declare variable $childID as xs:string? := xdmp:get-request-field("childID")[1];
declare variable $parentID as xs:string* := fn:tokenize(xdmp:get-request-field("parentID")[1],'_');
declare variable $pubHubReferer as xs:string? := xdmp:get-request-field("pubHubReferer")[1];
declare variable $wrapper-id as xs:string? := xdmp:get-request-field('wrapper-id')[. != ''][1];

let $login := okta:okta-login()
let $currentUser as xs:string? := ac:getUserName()
let $following as xs:string* := form-functs:get-follower($currentUser, $id, $locale)
let $site-properties := sp:get-site-properties($site)
let $site-props-url as xs:string? := $site-properties/urls/url[@env = 'preview'][. != '']
let $preview-url as xs:string? :=
    if ( fn:exists($site) and fn:exists($site-props-url) ) then (
        '//' || $site-props-url || $uri || '?lang=' || $lang
    ) else ( core:build-url($uri, $locale, ()) )
let $form as element(ldse:formTemplate)? := form:getFormTemplate($form-name)
let $file as element()? := form:getRootFile($form)
let $is-submission as xs:boolean := ldsemeta:is-submission($file) or form:getVariable("is-submission")
let $is-submitted as xs:boolean := ldsemeta:submission-submitted($file)
let $status-display as xs:string? := ldsemeta:static-status($file)
let $has-permission as xs:boolean :=
    ( if ( $action = "edit" ) then (
        ac:has-permission('ldse:edit-doc', $locale, $uri, $site)
    	or ac:has-permission('ldse:edit-submission', $locale, $uri, $site)
    ) else if ( $action = "add" ) then (
        ac:has-permission('ldse:add-doc', $locale, $uri, $site)
        or ac:has-permission('ldse:add-submission', $locale, $uri, $site)
    ) else if ( $action = "view" ) then (
        ac:has-permission("ldse:view-submission", $locale, $uri, $site)
    ) else ( fn:false() ) )
    and ( fn:exists($site) or $form/@requires-site = 'false' )

let $button-click as xs:string := 'ldse:preview'
let $has-publish-doc as xs:boolean := ac:has-permission('ldse:publish-doc', $locale, $uri)
let $has-unpublish-doc as xs:boolean := ac:has-permission('ldse:unpublish-doc', $locale, $uri)
let $referer as xs:string := form:getVariable("referer")
let $preview-enabled as xs:boolean := $settings:preview-enabled
let $history-enabled as xs:boolean := $settings:history-enabled
let $versions-enabled as xs:boolean :=
	if($is-submission)
	then ldsemeta:submission-submitted($file)
		and settings:is-mode-versioned($core:mode)
	else settings:is-mode-versioned($core:mode)

let $wysiwygs as element(ldse:input)* := $form//ldse:input[@type = 'wysiwyg']
let $toolbars-used as xs:string* :=
    for $wysiwyg in $wysiwygs
    return (
        if ( fn:exists($wysiwyg/@toolbar) ) then (
            $wysiwyg/@toolbar
        ) else ( 'default' )
    )
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
let $instruction := ($form/ldse:instruction)
let $actions as element(ldse:action)+ := ($settings:actions)
let $disabled-on-add as xs:string? :=
    if ($action = "add") then (
        "disabled"
    ) else ()
let $tooltip-on-add as attribute()? :=
    if ($action = "add") then (
        attribute data-tooltip {"This feature is not available when creating a document."}
    ) else ()

let $domain-for-preview as xs:string? := ( $settings:app-domain, $settings:live-domain )[1]
let $preview-right-url as xs:string :=
    if ( fn:exists($site) and fn:exists($site-props-url) ) then (
        '//' || $site-props-url || $uri
    ) else ( fn:replace($preview-url, "^(https?://).*?(/.*)$", fn:concat("$1", $domain-for-preview, "$2")) )
let $follower as xs:boolean? :=
    for $follower as xs:string in $following
    where $follower = $currentUser
    return fn:true()

let $enrichment-keyword-count as xs:int := fn:count($file/ldse:ldse-meta/ldse:enrich/ldse:terms/ldse:term)
let $sensitive-page as xs:boolean? :=
    for $sensitive-uri as element(ldse:sensitive-uri) in $settings:sensitive-uris/ldse:sensitive-uri
    where $sensitive-uri = $uri
    return fn:true()
let $sensitive-page as xs:boolean := $sensitive-page or form:getVariable("sensitive-page")
let $sensitive-element as element(ldse:sensitive)? := if ( $file ) then ( ldsemeta:get-sensitive($file) ) else ()
let $approved-date as xs:string? := $sensitive-element/@approval-date
let $approved as xs:string? := $sensitive-element/@approval-requested
let $approval-sent as xs:string? := $sensitive-element/@approval-sent
let $needs-approval as xs:string? := $sensitive-element/@needs-approval
let $sensitive as xs:string? := $sensitive-element/@status
let $stakeholder as xs:string? := $sensitive-element/@stakeholder
return (
    if ($has-permission) then (
        core:template-apply(
            "Content Editor",
            "/form",
            <page>
                <head>
                    <link rel="stylesheet" type="text/css" media="all" href="{$settings:shared-prefix}/form/resources/styles/form.css" />
                    <link rel="stylesheet" href="{$settings:shared-prefix}/translation/resources/styles/calendar.css" />
                    <link rel="stylesheet" href="{$settings:shared-prefix}/translation/resources/styles/chosen.min.css" />
                    {form:ouputCss($form)}
                    <link rel="stylesheet" type="text/css" href="{$settings:shared-prefix}/ice/resources/styles/binaryManager.css" />
                    <link rel="stylesheet" type="text/css" href="{$settings:shared-prefix}/resources/css/enrich.css" />
                    <link rel="stylesheet" type="text/css" href="{$settings:shared-prefix}/resources/css/search-modal.css" />

                    <link rel="stylesheet" type="text/css" media="all" href="{$settings:shared-prefix}/form/resources/scripts/flexslider/flexslider.css" />
                </head>
                <content>
                    {
                        if ( ( $sensitive = "yes" or ($settings:is-submitter and $is-submitted) or fn:exists(correlation:build-status-info-section($file)) ) and $settings:has-sensitive = 'true' ) then (
                            form-functs:get-stakeholders($file, $sensitive, $settings:is-submitter, $is-submitted)
                        ) else ()
					}
                    <h2>{fn:string-join(($form-title,$title), ": ")} {if ( fn:not($action = 'add') ) then ( <span class="ldse-follow-content"><a href="#d" onclick="followContent(this, '{$currentUser}'); return false;" data-id="{$id}" data-locale="{$locale}"><span class="{if ( $follower ) then ( "ldse-icon ldse-icon-flag ldse-following-content" ) else ("ldse-icon ldse-icon-flag")}" /></a>&nbsp;<span class="ldse-follow-text">Follow This Content</span></span>) else ()}     </h2>
                    <section id="options" class="ldse-section ldse-summary ldse-clearfix">
             			<header class="ldse-section--header">
             				<h2><a href="#d" class="ldse-icon-ko-tri-down">Options</a></h2>
             			</header>
             			<div class="ldse-section--body ldse-form">
             				<div class="ldse-rowFix ldse-makeCols">
             					<section id="content" class="ldse-block tile ldse-notification-container ldse-toggle-content depressed" data-group="#options" data-selector="#content-info">
             						<button class="ldse-button tile ldse-icon-edit above active">Content</button>
             						<span class="ldse-information">
    							         <span>{ $lang }{ if ( $country[. != ""] ) then fn:concat( "-", $country ) else () }</span>
    						        </span>
             					</section>
								{
    								if ( $preview-enabled ) then (
                     					<section id="preview" class="ldse-block tile ldse-notification-container ldse-toggle-content {$disabled-on-add}" data-group="#options" data-selector="#preview-info">
                     						{$tooltip-on-add}
                     						<button class="ldse-button tile ldse-icon-page above active" onclick="return Preview.tileClick();">Preview</button>
                     						<span class="ldse-information">
            						        </span>
                     					</section>
    								) else ()
								}
             					<section id="publishing" class="ldse-block tile ldse-notification-container ldse-toggle-content" data-group="#options" data-selector="#publishing-info">
             						<button class="ldse-button tile ldse-icon-calendar above">Publishing</button>
             						<span class="ldse-information">
    							         <span>{$status-display}</span>
    						        </span>
             					</section>
             					<section id="translations" class="ldse-block tile ldse-notification-container ldse-toggle-content {$disabled-on-add}" data-group="#options" data-selector="#translation-info">
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
                   				{
                       				(: ENRICH R&D :)
                   				if ($enrich-enabled) then (
                       				     <section id="enrich" class="ldse-block tile ldse-notification-container ldse-toggle-content {$disabled-on-add}" data-click="getEnrich" data-group="#options" data-selector="#enrich-info" data-id="{$id}" data-locale="{$locale}">
                                            {$tooltip-on-add}
                                            <button class="ldse-button tile ldse-icon-tag above">Enrich</button>
		             						<span class="ldse-information">{
		             						   if(fn:exists($file/ldse:ldse-meta/ldse:enrich))
		             						   then
		             						   		if($enrichment-keyword-count > 0)
		             						   		then fn:concat($enrichment-keyword-count, " Keywords")
		             						   		else "Not Enriched"
		             						   else ()
		    						        }</span>
                                        </section>
                      				) else ()
                       				(: ENRICH R&D :)
                   				}

             				</div>
             			</div>
             		</section>
					<form class="ldse-section--body content-table ldse-form iceForm form-data" method="post" enctype="multipart/form-data" action="{$settings:shared-prefix}/form/save?lang={$lang}">
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
             				<div class="ldse-section--body publishing-table ldse-form">
               					<p>
               					    {form:buildWorkFlowCheckboxes($file, $form, $locale)}
               					</p>
                                {
                                    if ( $form/@schedule-publish eq 'true' and $has-publish-doc ) then (
                                        form:buildFuturePublish($file, $form, $locale)
                                    ) else (),
                                    if ( $form/@schedule-unpublish eq 'true' and $has-unpublish-doc ) then (
                                        form:buildFutureUnpublish($file, $form, $locale)
                                    ) else ()
                                }
             				</div>
             			<section>
            				<div class="ldse-section--header">
            					<h2><a href="#d" class="ldse-icon-ko-tri-down">Document Info</a></h2>
            				</div>
             				<div class="ldse-section--body ldse-form">
             				   <div class="grid-50">
    								<dl>
    									<dt><span>Ldse-meta URI:&nbsp;<span>{fn:string($file/ldse:ldse-meta/ldse:document/@uri)}</span></span></dt>
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
             				   <div class="grid-50">
    								<dl>
    									<dt><span>Root URI:&nbsp;<span>{fn:string($file/@uri)}</span></span></dt>
    								</dl>
    							</div>
    							<div class="ldse-first"></div>
             				</div>
             			</section>
             			</section>
             		</section>
                    <section id="content-info" class="ldse-section ldse-summary ldse-clearfix" sensitive="{$settings:has-sensitive}">
                        <header class="ldse-section--header">
                            <h2>Content</h2>
                        </header>
                        <div class="ldse-section--body publishing-table ldse-form">
                            <input type="hidden" id="formLocale" name="formLocale" value="{$locale}" />
                            <input type="hidden" name="country" value="{$country}"/>
                            <input type="hidden" id="content-id" name="id" value="{$id}"/>
                            <input type="hidden" name="uri" value="{$uri}"/>
                            <input type="hidden" name="form" id="form" value="{$form-name}"/>
                            <input type="hidden" name="page" value="{$page}" />
                            <input type="hidden" id="formAction" name="action" value="{$action}" />
                            <input type="hidden" id="option" name="option" value="{$options}" />
                            <input type="hidden" name="referer" value="{$referer}" />
                            <input type="hidden" id="content-form-name" name="formName" value="{$form-name}" />
                            <input type="hidden" id="status" name="status" value="{$button-click}" />
                            <input type="hidden" id="approval-sent" value="{$approval-sent}"/>
                            <input type="hidden" id="site" name="site" value="{ $site }"/>
                            { if ( fn:exists($wrapper-id) ) then ( <input type="hidden" id="wrapper-id" name="wrapper-id" value="{ $wrapper-id }"/> ) else () }
                            <p><em>*</em> indicates required field</p>
                            { if ($instruction) then <div id="instruction"><p><strong>Instruction</strong></p>{$instruction}</div> else ()}
                            <fieldset class="content-section">
                                {
                                    if ( $settings:has-sensitive = 'true' ) then (
                                        <dl><dt><label>Contains Sensitive Information?</label>&nbsp;<em>*</em></dt>
                                            <select seq="0" class="ldse-sensitive-content required" title="Sensitive Content?" options="" name="sensitive">
                                                <option value="yes">{if ( $sensitive = "yes" or ( $sensitive-page and $sensitive = "yes" ) ) then ( attribute selected { "selected" } ) else () } Yes</option>
                                                <option value="no">{if ( fn:not($sensitive = "yes") and fn:not($sensitive-page) ) then ( attribute selected { "selected" } ) else if ( fn:not($sensitive-page) and fn:empty($sensitive) ) then ( attribute selected { "selected" } ) else if ( $sensitive = "no" ) then ( attribute selected { "selected" } ) else () } No</option>
                                            </select>
                                        </dl>,
                                        <dl class="ldse-stakeholder-item" style="{if ( fn:not($sensitive = "yes") ) then ( "display:none;" ) else ()}">
                                            <dt><label>Primary Stakeholder / Approver</label>&nbsp;<em>*</em></dt>
                                            <select seq="0" class="ldse-sensitive-stakeholder required" ng-model="stakeholder" title="Stakeholder" options="" name="stakeholder">
                                                <option value="">Please Select</option>
                                                {form-functs:builds-stakeholder-select($stakeholder)}
                                            </select>
                                        </dl>,
                                        <dl class="ldse-stakeholder-item" style="{if ( fn:not($sensitive = "yes") ) then ( "display:none;" ) else ()}">
                                            <dt><label>Other Stakeholders</label></dt>
                                            <select input="select" seq="0" class="ldse-other-sensitive-stakeholder ldse-multi-select" title="Stakeholder" options="" name="other-stakeholders">
                                                {form-functs:builds-other-stakeholder-select($stakeholder, $file)}
                                            </select>
                                        </dl>
                                    ) else (),
                                    site:get-form-inputs($form, $file)
                               }
                            </fieldset>
                        </div>
                    </section>
                    <section id="preview-info" style="display:none;">
	                    <section class="ldse-section ldse-summary ldse-clearfix">
	                        <header class="ldse-section--header">
	                            <h2>Preview</h2>
		                        <div id="preview-comparison">
		                        	<dl>
		                        		<dd>
					    					<input type="checkbox" id="comparison-preview" onclick="Preview.toggle();"/>
					    					<label for="comparison-preview">Comparison View</label>
		                        		</dd>
		                        	</dl>
		                        </div>
	                        </header>
	                        <div id="preview-body" class="ldse-section--body ldse-form clearfix">
								<section id="preview-haschanges" class="ldse-section ldse-summary ldse-info-banner warning">
									<div class="ldse-section--body">
										<span class="ldse-icon-ko-warning ldse-icon ldse-info-banner-icon">Warning</span>
										<h3>Unsaved Changes</h3>
										<div>
											Preview will not reflect recent changes until you have clicked the 'Save' button.
										</div>
									</div>
								</section>
                                <div id="preview-left" class="ldse-preview-window">
                                    <section class="ldse-section ldse-summary ldse-info-banner warning ldse-preview-compare-msg">
                                        <div class="ldse-section--body">
                                            <span class="ldse-icon-ko-warning ldse-icon ldse-info-banner-icon">Warning</span>
                                            <h3>Comparison View</h3>
                                        <div>
                                        The selected devices are too wide to show next to each other. Scroll down the page to see the other device.
                                    </div></div></section>
	                        		<div>
	                        			<input type="hidden" id="preview-url" value="{$preview-right-url}"/>
		                        		<input type="text" class="preview-url xxxl" value="{$preview-right-url}"/>
		                        		<button class="ldse-button preview-go" onclick="Preview.go(this); return false;">Go</button>
                                        <br />
                                        <br />

                                        <div class="flexslider ldse-device-list ldse-device-type" data-iframe="ldse-preview-iframe1">

                                        </div>

                                        <div class="preview-orientation" data-iframe="ldse-preview-iframe1">
                                            <button data-value="portrait" class="ldse-button tile above active ldse-preview-portrait">Portrait</button>
                                            <button data-value="landscape" class="ldse-button tile above ldse-preview-landscape">Landscape</button>
                                        </div>


		                        	</div>
                                    <div class="ldse-device-info">
                                        Width:
                                        <span class="ldse-device-width">
                                        </span>&nbsp;
                                        Height:
                                        <span class="ldse-device-height">
                                        </span>
                                    </div>
                                    <div class="preview-iframe-container ldse-preview-iframe1">
                                        <iframe class="ldse-preview-iframe1" src="" onload="try {{ $('#preview-left .preview-url').val(this.contentWindow.location);}} catch(e) {{ }}"/>
                                    </div>

	                        	</div>
	                        	<div id="preview-right" class="ldse-preview-window">
	                        		<div>
		                        		<input type="text" class="preview-url xxxl" value="{$preview-url}"/>
		                        		<button class="ldse-button preview-go" onclick="Preview.go(this); return false;">Go</button>
                                        <br />
                                        <br />

                                        <div class="flexslider ldse-device-list ldse-device-type" data-iframe="ldse-preview-iframe2" data-orientation="ldse-device-orientation2">

                                        </div>

                                        <div class="preview-orientation" data-iframe="ldse-preview-iframe1">
                                            <button data-value="portrait" class="ldse-button tile above active ldse-preview-portrait">Portrait</button>
                                            <button data-value="landscape" class="ldse-button tile above ldse-preview-landscape">Landscape</button>
                                        </div>


                                    </div>
                                    <div class="ldse-device-info">
                                        Width:
                                        <span class="ldse-device-width">
                                        </span>&nbsp;
                                        Height:
                                        <span class="ldse-device-height">
                                        </span>
                                    </div>
		                        	<div class="preview-iframe-container ldse-preview-iframe2">
		                        		<iframe class="ldse-preview-iframe2" src="" onload="try {{ $('#preview-left .preview-url').val(this.contentWindow.location);}} catch(e) {{ }}"/>
		                        	</div>
	                        	</div>
	                        </div>
	                    </section>
                    </section>
                    {
                    	if( fn:exists($file) and $settings:correlation-enabled)
                    	then correlation:build-correlation-section(correlation:get-values-map())
                    	else
    				<section id="correlation" style="display:none;">
    					<input type="hidden" name="correlation-save" value="false"/>
    				</section>
                    }
                    {
                        (: ENRICH R&D :)
                        if ($enrich-enabled) then (
                            <section id="enrich-info" class="ldse-enrich-form" style="display:none;">
                                <section class="ldse-section ldse-summary ldse-clearfix">
                                    <header class="ldse-section--header">
                                        <h2>Enrich</h2>
                                    </header>
                                    <div class="ldse-section--body ldse-form">
                                       Enriching please wait...
                                    </div>
                                </section>
                            </section>
                        ) else ()
                    }
                    </form>
                    { if ($history-enabled) then (
                        history:build-history-section()
                    ) else () }
                    { if ($history-enabled) then (
                       history:build-comment-section($id, $locale, $uri)) else()}
                    { if ($versions-enabled) then (
                        version:build-versions-section($file)
                    ) else ()}
             		<section id="translation-info" style="display:none;">
            			<section class="ldse-section ldse-summary ldse-clearfix">
            				<header class="ldse-section--header">
            					<h2>Translations</h2>
            				</header>
            				<form>
                              	<div class="ldse-clearfix">
                      				<div class="ldse-table-buttons">
                      				    <button id="translation-action-edit" href="{$settings:shared-prefix}/form?lang={$lang}&amp;country={$country}&amp;site={ $site }" onclick="editFile(); return false;" class="ldse-button ldse-responsive-button ldse-icon-edit secondary ldse-show-single">Edit</button>
                      					<button id="translation-action-delete" onclick="actionButtons(this); return false;" class="ldse-button ldse-responsive-button destructive ldse-icon-trash ldse-show-mult" data-action="ldse:delete" style="display:none">Delete</button>
                      					<button id="translation-action-unpublish" onclick="actionButtons(this); return false;" class="ldse-button ldse-responsive-button destructive ldse-icon-clock ldse-show-mult" data-action="ldse:schedule-unpublish" style="display:none">Schedule Unpublish</button>
                      					<button id="translation-action-unpublish" onclick="actionButtons(this); return false;" class="ldse-button ldse-responsive-button destructive ldse-icon-unpublish ldse-show-mult" data-action="ldse:unpublish" style="display:none">Unpublish</button>
                      					<button id="translation-action-publish" onclick="actionButtons(this); return false;" class="ldse-button ldse-responsive-button secondary ldse-icon-clock ldse-show-mult" data-action="ldse:schedule-publish" style="display:none">Schedule Publish</button>
                      					<button id="translation-action-publish" onclick="actionButtons(this); return false;" class="ldse-button ldse-responsive-button secondary ldse-icon-send ldse-show-mult" data-action="ldse:publish" style="display:none">Publish</button>
                      				</div>
                      			</div>
                         			<table id="detail-table" class="ldse-table ldse-fullbleed">
                					<thead>
                						<tr>
                							<th>
                								<span class="ldse-option box-only">
                								{
											        if ( ac:has-permission("ldse:translation-checkbox", $locale, $uri) ) then (
											        	<input type="checkbox" name="" value="" id="box-all"/>,
	                									<label for="box-all"></label>
	                								) else ()
												}
                								</span>
                							</th>
                							<th></th>
                							<th class="sorts" data-name="status"><a href="#d" onclick="sortColumn(this)">Status</a></th>
                							<th class="sorts hide-small" data-name="title"><a href="#d" onclick="sortColumn(this)">Title</a></th>
                							<th class="sorts" data-name="locale"><a href="#d" onclick="sortColumn(this)">Locale</a></th>
                							<th class="sorts" data-name="dateReturned"><a href="#d" onclick="sortColumn(this)">Returned Date</a></th>
                							<th class="sorts hide-large" data-name="dateSent"><a href="#d" onclick="sortColumn(this)">Sent Date</a></th>
                							<th class="sorts hide-med" data-name="component"><a href="#d" onclick="sortColumn(this)">Component ID</a></th>
                							<th class="sorts hide-large" data-name="filename"><a href="#d" onclick="sortColumn(this)">File Name</a></th>
                						</tr>
                					</thead>
                					<tbody id="detail-table-body">
                					</tbody>
                				</table>
                			</form>
             			</section>
             		</section>
             		<section class="ldse-section ldse-modal large" id="titanModal" style="display:none; z-index:99999;">
                        <div id="inline-search">
                            <header class="ldse-section--header">
                                <h2>Search Titan Assets</h2>
                            </header>
                            <section class="ldse-section ldse-clearfix ldse-collection-page">
                                <div class="ldse-section--body">
                                    <titan-search></titan-search>
                                </div>
                            </section>
                        </div>
             		</section>
					<section id="scheduling-modal" style="display:none;" class="ldse-section ldse-modal">
						<div class="confirmation">
							<div id="scheduling-variables" style="display:none;"></div>
							<header class="ldse-section--header">
								<h2>Schedule <span class="schedule-label"></span></h2>
							</header>
							<div class="ldse-section--body publishing-table ldse-form">
								<dl>
									<dt>Future <span class="schedule-label"></span> Date</dt>
									<dd>
										<input name="futureDateModal" id="futureDateModal" class="hasDatePicker datePicker lg" value="{fn:format-dateTime(fn:current-dateTime(), "[Y0001]-[M01]-[D01]", "en", (), ())}" placeholder="YYYY-MM-DD"><b class="ldse-icon-calendar" onclick="$('#futureDateModal').focus();"></b></input>
									</dd>
								</dl>
								<dl>
									<dt>
										<label for="futureHourModal">Military Time (Hour Minute)</label>
									</dt>
									<dd class="schedule-time">
										<select name="futureHourModal" id="futureHourModal">
											{
												for $h as xs:integer in 0 to 23
												let $value as xs:string :=
													if($h < 10)
													then fn:concat("0", $h)
													else xs:string($h)

												return
													element option {
														attribute value {$value},
														$value
													}
											}
										</select>
										<select name="futureMinModal" id="futureMinModal">
											{
												for $m as xs:integer in 0 to 59
												let $value as xs:string :=
													if($m < 10)
													then fn:concat("0", $m)
													else xs:string($m)

												return
													element option {
														attribute value {$value},
														$value
													}
											}
										</select>
									</dd>
								</dl>
								<dl id="schedule-error">
									<dd class="error">
										<label>Not a valid future date and time.<br/>Server time is <span id="pretty-date"></span></label>
									</dd>
								</dl>
								<dl>
									<dd>
										<button id="scheduling-modal-cancel" class="ldse-button ldse-icon-ko-x" style="float: right;" onclick="cancelSchedulingModal(); return false;">Cancel</button>
										<button id="scheduling-modal-save" class="ldse-button primary ldse-icon-save" style="float: right;" onclick="saveSchedulingModal(); return false;">Save</button>
									</dd>
								</dl>
							</div>
						</div>
					</section>
                </content>

                <scripts>
                	{
                		let $protocol as xs:string := xdmp:get-request-header("X-Forwarded-Scheme", "http")
                		return <script language="JavaScript" type="text/javascript" src="//{fn:replace($protocol, "^http(s)$", "$1")[. ne "http"]}admin.brightcove.com/js/BrightcoveExperiences.js">&nbsp;</script>
                    }
                    <script type="text/javascript" src="{$settings:shared-prefix}/resources/scripts/angularjs/angular-1.5.min.js"></script>
                    <script type="text/javascript" src="{$settings:cdn-path}/scripts/jquery/plugins/validation/jquery.validate.1.8.1.min.js">&nbsp;</script>
                    <script type="text/javascript" src="{$settings:cdn-path}/scripts/jquery/plugins/validation/additional-methods1.8.1.min.js">&nbsp;</script>
            		{ice:get-ice-script($toolbars-used)}
            		{ form:jsVariableMap() }
            		{ form:ouputJavascript($form) }
                    <script type="text/javascript">
                        var referer = {xdmp:to-json-string(fn:string($referer))};
                        var userFullName = {xdmp:to-json-string(ac:getPersonName())};
                        ICE.uri = {xdmp:to-json-string($uri)};
                        ICE.page = {xdmp:to-json-string($page)};
                        ICE.resource = {{}};
                        ICE.resource.searchUrl = {xdmp:to-json-string($site-properties/content-endpoints/api-endpoint/url/xs:string(.))};
                        var approvalSent = {xdmp:to-json-string($approval-sent)};
                        var needsApproval = {xdmp:to-json-string($needs-approval)};
                        var sensitive = {xdmp:to-json-string($settings:has-sensitive)};
                        var childID = {xdmp:to-json-string($childID)};
                        var newDynamic = {xdmp:to-json-string($settings:new-dynamic)};
                        var sharedPrefx = { xdmp:to-json-string($settings:shared-prefix) };
                        $(function(){{
                            ICE.setupForm();
                        }});
                        var versify = {xdmp:to-json-string($settings:versification)};
                        var parentID = {xdmp:to-json-string($parentID)};
                        var pubHubReferer = {xdmp:to-json-string(fn:string(($pubHubReferer,$referer)[1]))};
                        var collection = {xdmp:to-json-string($form/ldse:collections/ldse:collection/fn:string())};
                        var site = { xdmp:to-json-string($site) };
                    </script>
                    <script type="text/javascript" src="{$settings:shared-prefix}/form/resources/scripts/form.js">&nbsp;</script>
                    <script type="text/javascript" src="{$settings:shared-prefix}/form/resources/scripts/titanSearch.js">&nbsp;</script>
                    <script type="text/javascript" src="{$settings:shared-prefix}/form/resources/scripts/titanResults.js">&nbsp;</script>
                    <script type="text/javascript" src="{$settings:shared-prefix}/form/resources/scripts/pagination.js">&nbsp;</script>
                    <script type="text/javascript" src="{$settings:shared-prefix}/form/resources/scripts/titanCollectionItems.js">&nbsp;</script>
{(:                    <script type="text/javascript" src="{$settings:shared-prefix}/form/resources/scripts/collection-wrapper.js">&nbsp;</script>:)}
                    <script type="text/javascript" src="{$settings:shared-prefix}/form/resources/scripts/content.js">&nbsp;</script>
                    <script type="text/javascript" src="{$settings:shared-prefix}/binary/resources/scripts/burce.js">&nbsp;</script>
                    {
                    	correlation:scripts()
                    }
                    { if ($history-enabled) then (
                        history:build-history-scripts()
                    ) else () }
                    { if ($versions-enabled) then (
                        version:build-versions-scripts($id)
                    ) else ()}
                    <script type="text/javascript" src="{$settings:shared-prefix}/form/resources/scripts/flexslider/jquery.flexslider-min.js">&nbsp;</script>
                    <script type="text/javascript" src="{$settings:shared-prefix}/form/resources/scripts/preview.js">&nbsp;</script>
                    <script type="text/javascript" src="{$settings:shared-prefix}/form/resources/scripts/chosen.jquery.min.js">&nbsp;</script>
                </scripts>
				{
					form:build-action-groups($form)
				}
                {   (:In the new dynamic use, show the preview button only for main top level forms. Not children since the URI's might be wrong:)
                    if($settings:new-dynamic eq "true" and $parentID ne '')
                    then ()
                    else ( <preview-eye>{$preview-right-url}</preview-eye>)
                }
                <options>
                </options>
            </page>
        )
    ) else (
        template:error-access-denied("Error!", "Sorry, you don't have permission to view this page.")
    )
)
