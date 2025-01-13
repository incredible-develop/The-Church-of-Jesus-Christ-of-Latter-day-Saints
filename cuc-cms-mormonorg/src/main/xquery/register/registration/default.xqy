xquery version "1.0-ml";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../modules/utility-functions.xqy";
import module namespace template = "http://lds.org/shared/lds-edit/template" at "../../modules/template.xqy";
import module namespace tw = "http://lds.org/code/shared/lds-edit/translation-workflow" at "../../translation/modules/translation-workflow.xqy";
import module namespace json = "http://marklogic.com/json" at "../../modules/fasterjson.xqy";
import module namespace document = "http://lds.org/code/shared/common/document/document-functions" at "/shared/common/document/documentFunctions.xqy";
import module namespace regis-functions = "http://lds.org/code/register/regis-functions" at "modules/functions.xqy";
import module namespace form = "http://lds.org/code/shared/lds-edit/dynamicForms" at "../../ice/modules/dynamicForms.xqy";
import module namespace formValidatorFunctions = "http://lds.org/code/shared/lds-edit/formValidatorFunctions" at "../../ice/form-validator/modules/formValidatorFunctions.xqy";
import module namespace ice = "http://lds.org/code/shared/lds-edit/iceFunction" at "../../ice/modules/iceFunctions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../modules/ldse-settings.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../modules/ldse-core.xqy";
import module namespace security = "http://lds.org/code/shared/common/security/security-functions" at "/shared/common/security/securityFunctions.xqy";

declare namespace search = "http://marklogic.com/appservices/search";
declare namespace ldse = "http://lds.org/code/lds-edit";

declare option xdmp:output "method = html";
declare option xdmp:mapping "true";

(: MAIN PARAMS :)
declare variable $lang as xs:string := 'eng';
declare variable $country as xs:string? := form:getVariable('country');
declare variable $locale as xs:string? := form:getVariable('locale');
declare variable $id as xs:string? := form:getVariable('id');
declare variable $uri as xs:string := '/';  (: xml uri :)
declare variable $page as xs:string := '/'; (: current page uri, if differnt from uri:)
declare variable $action as xs:string? := form:getVariable('action'); (: edit, add :)
declare variable $options as element() := <variables><form>registration</form></variables>; (: edit, add :)
declare variable $form-name as xs:string := $options/form;
declare variable $cdn-path as xs:string? := $settings:cdn-path;
declare variable $environment as xs:string := $settings:environment;
declare variable $current-user as xs:string := form:getVariable('user');
declare variable $new-server as element(siteProperties) := (
    cts:search(/siteProperties,
            core:get-filter-query()
    )
);
(: *********** :)
let $params as item()* := form:buildParamMap()
let $preview-server as element(environment)* := (
    cts:search(/siteProperties/preview-servers/environment,
            core:get-filter-query()
    )
)
let $option as xs:string? := ice:csv-variables($options)
let $form as element(ldse:formTemplate)? := form:getFormTemplate($form-name)
let $file as element()? := form:getRootFile($form)
let $site-name as xs:string? := $file/basic-data/site-name
let $username as xs:string? := $file/services/read-write-username
let $services-checkbox as xs:string? := $file/services-checkbox
let $translation-checkbox as xs:string? := $file/translation-checkbox
let $this-page as xs:string := '/registration/default'
let $save-button as xs:string := (
    if (fn:not($file)) then (
        "Register"
    ) else ("Save")
)
let $title as xs:string := "Registration"
let $environment as xs:string := $settings:environment
let $server as xs:string := $new-server/lds-services-servers/environment[@name = $environment]
let $rest-port as xs:string := fn:normalize-space($new-server/lds-services-rest-port)
let $admin-port as xs:string := fn:normalize-space($new-server/lds-services-admin-port)
let $user as element()? := $file/basic-data

return (
    template:apply(
        $title,
        $this-page,
        <page>
            <head>
                <link rel="stylesheet" href="{$settings:shared-prefix}/register/registration/resources/styles/registration.css"></link>
            </head>
            <content>
                <section  id="basic-info" class="ldse-section ldse-summary cf">
                    <header class="ldse-section--header">
                        <h2>Site Registration</h2>
                    </header>
                    <form class="ldse-section--body registration-table iceForm ldse-form" method="post" action="{$settings:shared-prefix}/register/registration/modules/save?lang={$lang}">
                        <input type="hidden" id="formLocale" name="formLocale" value="{$locale}" />
                        <input type="hidden" name="country" value="{$country}" />
                        <input type="hidden" name="id" value="{$id}" />
                        <input type="hidden" name="uri" value="{$uri}" />
                        <input type="hidden" name="page" value="{$page}" />
                        <input type="hidden" name="option" value="{$option}" />
                        <input type="hidden" class="save-button" name="value" value="{$save-button}" />
                        <input type="hidden" name="old-site-name" value="{$site-name}" />
                        <input type="hidden" name="admin-port" value="{$admin-port}" />
                        <p><em>*</em>indicates required field</p>
                        <div class="registration-sections">
                            <div class="registration-section1">
                                {
                                    for $node as element() in form:buildForm($form/ldse:structure/ldse:registration/ldse:basic-data/*, $file, ())
                                    order by if ($node/@data-sequence castable as xs:double) then (xs:double($node/@data-sequence)) else (9999)
                                    return (
                                        $node
                                    )
                                }
                            </div>
                            <div class="registration-section2">
                                <div class="ldse-option box-only registration-section-heading">
                                    {form:buildForm($form/ldse:structure/ldse:registration/ldse:translation-checkbox, $file, ())}
                                </div>
                                <div class="translation-fields">
                                    {
                                        for $node as element() in form:buildForm($form/ldse:structure/ldse:registration/ldse:translation, $file, ())
                                        order by if ($node/@data-sequence castable as xs:double) then (xs:double($node/@data-sequence)) else (9999)
                                        return (
                                            $node
                                        )
                                    }
                                </div>
                            </div>
                        </div>
                    </form>
                </section>
            </content>
            <scripts>
                <script src="{$settings:shared-prefix}/register/registration/resources/scripts/registration.js" type="text/javascript">&nbsp;</script>
                <script type="text/javascript" src="{$cdn-path}/scripts/ui/1.8.11/jquery-ui.min.js" />
                <script type="text/javascript" src="{$cdn-path}/lds-edit/scripts/jquery.form.js">&nbsp;</script>
                <script type="text/javascript" src="{$settings:cdn-path}/scripts/jquery/plugins/validation/jquery.validate.1.8.1.min.js"/>
                <script type="text/javascript" src="{$settings:cdn-path}/scripts/jquery/plugins/validation/additional-methods1.8.1.min.js"/>
                {ice:get-ice-script()}
                <script type="text/javascript">
                    ICE.setupForm();
                    var server = "{fn:concat('http://', $server)}";
                    var port = "{$rest-port}";
                </script>
            </scripts>
            <button-groups>
                {
                    if (fn:not($file) or $file/ldse:ldse-meta/ldse:created[@username = $current-user] or fn:lower-case(xs:string($user/primary-contact/username)) = fn:lower-case($current-user) or fn:lower-case(xs:string($user/secondary-contact/username)) = fn:lower-case($current-user) ) then (
                        <button-group>
                            <button onclick="submitForm('form'); return false;" icon=" ldse-icon-save" id="action-save" class="primary">{$save-button}</button>
                        </button-group>
                    ) else ()
                }
                <button-group>
                    <button onclick="window.location.href = '{$settings:shared-prefix}/register?lang={$locale}'" icon=" ldse-icon-x" id="action-cancel" class="">Done</button>
                </button-group>
            </button-groups>
            <options>
                <ldse-logo-image-class>xl</ldse-logo-image-class>
            </options>
        </page>
    )
)