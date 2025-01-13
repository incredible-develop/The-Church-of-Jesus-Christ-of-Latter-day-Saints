xquery version "1.0-ml";

import module namespace form = "http://lds.org/code/shared/lds-edit/dynamicForms" at "/ice/modules/dynamicForms.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "/modules/ldse-settings.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";
import module namespace ice = "http://lds.org/code/shared/lds-edit/iceFunction" at "/ice/modules/iceFunctions.xqy";
import module namespace site = "http://lds.org/code/shared/lds-edit/custom/ldse-site-core" at "/custom/lds-edit/ldse-site-core.xqy";
import module namespace sp = "http://lds.org/code/modules/site-properties" at "/modules/site-properties.xqy";
import module namespace cloneFunctions = "http://lds.org/code/shared/lds-edit/clone-functions" at "/ice/resources/ajax/clone-page/cloneFunctions.xqy";
import module namespace mem-op = "http://lds.org/code/shared/common/memory-update" at "/shared/common/util/inMemoryUpdate.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare option xdmp:output "method = html";
declare option xdmp:mapping "true";


(: MAIN PARAMS :)
declare variable $lang as xs:string := form:getVariable('lang');
declare variable $country as xs:string? := form:getVariable('country');
declare variable $locale as xs:string := form:getVariable('locale');   (: lang or lang-country :)
declare variable $id as xs:string? := form:getVariable('id');
declare variable $formName as xs:string := form:getVariable('form');
declare variable $uri as xs:string := form:getVariable('uri');  (: xml uri :)
declare variable $page as xs:string := form:getVariable('page'); (: current page uri, if differnt from uri:)
declare variable $action as xs:string := form:getVariable('action'); (: edit, add :)
declare variable $options as xs:string := form:getVariable('option'); (: edit, add :)
(: *********** :)

declare variable $is-ixf-modal as xs:boolean := xdmp:get-request-field('ixf') = "true";
declare variable $clone-requested as xs:string? := xdmp:get-request-field("clone");
declare variable $site as xs:string? := xdmp:get-request-field("site");

let $buildMap as empty-sequence() := form:buildParamMap()
let $_form as element(ldse:formTemplate)? := form:getFormTemplate($formName)
let $form as element(ldse:formTemplate)? := site:add-standardized-fields-to-iceform($_form)
let $_file as element()? := form:getRootFile($form)
let $has-permission as xs:boolean :=
    if ($action = "edit") then (
        ac:has-permission('ldse:edit-doc', $locale, $uri)
    ) else if ($action = "add") then (
        ac:has-permission('ldse:add-doc', $locale, $uri)
    ) else ( fn:false() )

let $has-publish-doc as xs:boolean := ac:has-permission('ldse:publish-doc', $locale, $uri)
let $has-unpublish-doc as xs:boolean := ac:has-permission('ldse:unpublish-doc', $locale, $uri)
let $component-id as xs:string? :=
    	if ( $clone-requested ) then (
    	   "new"
    	) else ( $id)
let $component-action as xs:string? :=
    if ( $clone-requested ) then (
       "add"
    ) else ( $action)

let $cloneChildComponent as xs:boolean := ($clone-requested eq 'true' and ($_file//element()[@is-reference eq 'true']/fn:string()))
let $site-prefix := sp:get-site-properties($site)/site-context/fn:string()
let $file :=  if ($cloneChildComponent) then
                  cloneFunctions:updateChildRefs($_file, $locale, $site, $locale, $site, $_file//ldse:document/@uri/fn:string(), $uri, fn:false(), $site-prefix, 'false')
              else $_file
let $file := if (xs:string(fn:node-name($file))) then $file else $file/node()
let $children := $file//*[@is-reference eq 'true']/..
let $clone-id as xs:string? := ac:getUserName()||current-dateTime()
let $create-doc := if ($clone-requested and ($children)) then
                        let $data := <cloneDoc cloneId="{$clone-id}" formName="{$formName}" component-id="{$id}">
                                        {mem-op:node-delete($file/ldse:ldse-meta)}
                                     </cloneDoc>
                        return xdmp:document-insert('/preview/cms/content/temp/clonedoc-'||$clone-id||'.xml', $data)
                    else ()
let $form-action := if ($clone-requested and ($children)) then
                        $settings:shared-prefix||'/ice/save?lang='||$lang||'&amp;cloneId='||$clone-id||'&amp;site='||$site
                    else $settings:shared-prefix||'/ice/save?lang='||$lang
return (
    if ($has-permission) then (
        xdmp:set-response-content-type( "text/html" ),
        <div id="ice-dialog" title="{xs:string($form/ldse:title)}">
            {form:jsVariableMap(fn:false())}
            {$form/ldse:css/node()}
        <section class="ldse-section ldse-summary cf">
         	{ if ( fn:not($is-ixf-modal) ) then (
             	<header class="ldse-section--header">
             		<h2>{xs:string($form/ldse:title)}</h2>
             	</header>
         	  ) else ()
         	}
            <div  class="iceForm ldse-form padding-sm ldse-section--body">
                <form action="{$form-action}" method="post" enctype="multipart/form-data" class="ldse-form iceForm">
                    <input type="hidden" id="formLocale" name="formLocale" value="{$locale}" />
                    <input type="hidden" name="country" value="{$country}" />
                    <input type="hidden" name="id" value="{$component-id}" />
                    <input type="hidden" name="uri" value="{$uri}" />
                    <input type="hidden" name="page" value="{$page}" />
                    <input type="hidden" name="action" value="{$component-action}" />
                    <input type="hidden" name="option" value="{$options}" />
                    <input type="hidden" name="updateCustomPage" value="false" />
                    <fieldset class="margin-bottom-sm float-left">{
                        form:groupInputs($form, form:buildForm($form/ldse:structure/*, $file, ()), fn:true())
                    }</fieldset>
                    {
                        if ($form/@right-sash eq 'true') then (
                            <fieldset class="margin-bottom-sm float-right">
                                <dl>
                                    <dt>
                                        <label for="status">Status</label>
                                    </dt>
                                    <dd>
                                        <select name="status" id="status">
                                            <option value="ldse:preview">Preview</option>
                                            <option value="ldse:publish">Publish</option>
                                            <option value="ldse:unpublish">Unpublish</option>
                                            <option value="ldse:delete">Delete</option>
                                        </select>
                                    </dd>
                                </dl>
                                {form:buildWorkFlowCheckboxes($file, $form, $locale)}
                                {
                                  if ($form/@schedule-publish eq 'true' and $has-publish-doc) then (
                                    form:buildFuturePublish($file, $form, $locale)
                                  ) else (),
                                  if ($form/@schedule-unpublish eq 'true' and $has-unpublish-doc) then (
                                    form:buildFutureUnpublish($file, $form, $locale)
                                  ) else ()
                                }
                            </fieldset>
                        ) else ()
                   }
                   <div class="clear">
                        <input type="submit" class="ldse-button primary float-right text-sm ldse-icon-ko-save confirm" value="Save"/>
                        <input type="button" class="ldse-button float-left text-sm cancel closeForm" name="lds-publisher-cancel" value="Cancel"/>
                    </div>
                </form>
            </div>
        </section>
        { form:ouputJavascript($form) }
    </div>
    ) else ()
)
