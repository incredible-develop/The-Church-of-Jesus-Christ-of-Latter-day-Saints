xquery version "1.0-ml";

import module namespace form = "http://lds.org/code/shared/lds-edit/dynamicForms" at "/ice/modules/dynamicForms.xqy";
import module namespace ice = "http://lds.org/code/shared/lds-edit/iceFunction" at "/ice/modules/iceFunctions.xqy";
import module namespace json = "http://marklogic.com/json" at "/modules/fasterjson.xqy";
import module namespace document = "http://lds.org/code/shared/common/document/document-functions" at "/shared/common/document/documentFunctions.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "/modules/utility-functions.xqy";
import module namespace regis-functions = "http://lds.org/code/register/regis-functions" at "/register/registration/modules/functions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "/modules/ldse-settings.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "/modules/ldse-core.xqy";
import module namespace create-site = "http://lds.org/code/services/lds-publisher/create-site" at "/setup/modules/create-site.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";

(: Forces this transaction to be an update transaction :)
declare option xdmp:update "true";
declare option xdmp:mapping "false";

declare variable $locale as xs:string := form:getVariable('locale');
declare variable $id as xs:string? := form:getVariable('id');
declare variable $formName as xs:string := form:getVariable('form');
declare variable $action as xs:string := form:getVariable('action'); (: edit, add :)
declare variable $status as xs:string := form:getVariable('status');
declare variable $site as xs:string := form:getVariable('site');
declare variable $submit as xs:string := xdmp:get-request-field("value");
declare variable $isEditor as xs:boolean := fn:true();
declare variable $site-name as xs:string := xdmp:get-request-field("site");
declare variable $old-site-name as xs:string := xdmp:get-request-field("old-site-name");
declare variable $display-name as xs:string := xdmp:get-request-field("display-name");
declare variable $shared-prefix as xs:string? := fn:concat('/', $site);
declare variable $site-production-url as xs:string? := xdmp:get-request-field("site-production-url");
declare variable $preview-production-url as xs:string? := xdmp:get-request-field("preview-production-url");
declare variable $pri-contact-name as xs:string := xdmp:get-request-field("primaryName");
declare variable $pri-contact-username as xs:string := xdmp:get-request-field("pri-contact-username");
declare variable $pri-contact-email as xs:string? := xdmp:get-request-field("primaryEmail");
declare variable $sec-contact-name as xs:string? := xdmp:get-request-field("secondaryName");
declare variable $sec-contact-username as xs:string? := xdmp:get-request-field("sec-contact-username");
declare variable $sec-contact-email as xs:string? := xdmp:get-request-field("secondaryEmail");
declare variable $translation as xs:string? := xdmp:get-request-field("translation-services");
declare variable $post-zip as xs:string? := xdmp:get-request-field("post-zip");
declare variable $read-write-user as xs:string? := xdmp:get-request-field("adminName");
declare variable $read-write-user-pass as xs:string? := xdmp:get-request-field("adminPass");
declare variable $read-only-user as xs:string? := xdmp:get-request-field("devName");
declare variable $read-only-user-pass as xs:string? := xdmp:get-request-field("devPass");
declare variable $database as xs:string? := xdmp:get-request-field('database')[. != ''];
declare variable $user as xs:string? := ac:getUserName();
declare variable $name as xs:string? := ac:getPersonName();
declare variable $email as xs:string? := ac:getPersonEmail();

xdmp:set-response-content-type("text/json"),
let $form as element(ldse:formTemplate) := form:getFormTemplate($formName)
let $file as element()? := form:getRootFile($form)
let $buildMap as empty-sequence() := form:buildParamMap()
let $http-prefix as xs:string := "^(http://)"
let $messages as xs:string? := "Site Saved"
let $sites as element(registration)* :=
    cts:search(/registration,
            core:get-filter-query()
    )
let $new-site-name as xs:boolean? :=
    if ( fn:not($site-name = $old-site-name) ) then (
        for $site as xs:string in $sites[@id != $id]/basic-data/site
        where $site = $site-name
        return (
            fn:true()
        )
    ) else ( fn:false() )
let $errors as xs:string* := (
    if ($new-site-name) then (
        json:obj((
            json:keyValue("name", "site"),
            json:keyValue("text", "Site Already Exists")
        ))
    ) else (),
    if ($site-name = "") then (
        json:obj((
            json:keyValue("name", "site"),
            json:keyValue("text", "Field Required")
        ))
    ) else if (fn:exists($site-name[fn:not(fn:matches(., "^.[a-zA-Z0-9\-\._]+$", "i"))])) then (
        json:obj((
            json:keyValue("name", "site"),
            json:keyValue("text", "Invalid Character")
        ))
    ) else (),
    if ($display-name = "") then (
        json:obj((
            json:keyValue("name", "display-name"),
            json:keyValue("text", "Field Required")
        ))
    ) else (),
    if ($site-production-url = "" or $site-production-url eq " ") then (
        json:obj((
            json:keyValue("name", "site-production-url"),
            json:keyValue("text", "Field Required")
        ))
    ) else (),
    if ($preview-production-url eq "") then (
        json:obj((
            json:keyValue("name", "preview-production-url"),
            json:keyValue("text", "Field Required")
        ))
    ) else (),
    if ($pri-contact-name = "") then (
        json:obj((
            json:keyValue("name", "pri-contact-name"),
            json:keyValue("text", "Field Required")
        ))
    ) else (),
    if ($pri-contact-username = "") then (
        json:obj((
            json:keyValue("name", "pri-contact-username"),
            json:keyValue("text", "Field Required")
        ))
    ) else (),
    if ($pri-contact-email = "" or fn:exists($pri-contact-email[fn:not(fn:matches(., "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$", "i"))])) then (
        json:obj((
            json:keyValue("name", "pri-contact-email"),
            json:keyValue("text", "Field is Required and Must be Valid Email")
        ))
    ) else (),
    if (($sec-contact-name = "")) then (
        json:obj((
            json:keyValue("name", "sec-contact-name"),
            json:keyValue("text", "Field Required")
        ))
    ) else (),
    if ($sec-contact-username eq "") then (
        json:obj((
            json:keyValue("name", "sec-contact-username"),
            json:keyValue("text", "Field Required")
        ))
    ) else (),
    if ($sec-contact-email = "" or fn:exists($sec-contact-email[fn:not(fn:matches(., "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$", "i"))])) then (
        json:obj((
            json:keyValue("name", "sec-contact-email"),
            json:keyValue("text", "Field Required and Must be Valid Email")
        ))
    ) else (),
    if ($translation = "translation") then (
        if ($post-zip = "") then (
            json:obj((
                json:keyValue("name", "post-zip"),
                json:keyValue("text", "Field Required")
            ))
        ) else()
    ) else (),
    if ($read-write-user eq "") then (
        json:obj((
            json:keyValue("name", "adminName"),
            json:keyValue("text", "Field Required")
        ))
    ) else (),
    if ($read-write-user-pass eq "") then (
        json:obj((
            json:keyValue("name", "adminPass"),
            json:keyValue("text", "Field Required")
        ))
    ) else (),
    if ($read-only-user eq "") then (
        json:obj((
            json:keyValue("name", "devName"),
            json:keyValue("text", "Field Required")
        ))
    ) else (),
    if ($read-only-user eq $read-write-user) then (
        json:obj((
            json:keyValue("name", "adminName"),
            json:keyValue("text", "Cannot be the same as Read Only Username")
        )),
        json:obj((
            json:keyValue("name", "devName"),
            json:keyValue("text", "Cannot be the same as Read / Write Username")
        ))
    ) else (),
    if ($read-only-user-pass eq "") then (
        json:obj((
            json:keyValue("name", "devPass"),
            json:keyValue("text", "Field Required")
        ))
    ) else ()
)

return (
    if ( fn:empty($errors) and $submit eq "Register") then (
        let $do := (
            if ( $translation eq "translation" ) then (
                regis-functions:translation-post($site-name, $preview-production-url, $shared-prefix, $post-zip, $pri-contact-name, $pri-contact-email, $sec-contact-name, $sec-contact-email)
            ) else if ($translation eq "translation") then (
                regis-functions:translation-post($site-name, $preview-production-url, $shared-prefix, $post-zip, $pri-contact-name, $pri-contact-email, $sec-contact-name, $sec-contact-email)
            ) else (),
            create-site:register($user, $name, $email),
            regis-functions:save($isEditor, $status, $form, $file, $action, $locale, $messages),
            regis-functions:email-registration($site-name, $pri-contact-name, $pri-contact-email, $sec-contact-name, $sec-contact-email)
        )
        return (
            json:obj((
                json:keyObject("success", "true"),
                json:keyObject("error",
                        json:arr($errors)
                )
            )), xdmp:redirect-response($settings:shared-prefix || '/register')
        )
    ) else if (fn:empty($errors) and $submit eq "Save") then (
        let $do := (
            if ( $translation eq "translation" ) then (
                regis-functions:translation-post($site-name, $preview-production-url, $shared-prefix, $post-zip, $pri-contact-name, $pri-contact-email, $sec-contact-name, $sec-contact-email)
            ) else if ($translation eq "translation") then (
                regis-functions:translation-post($site-name, $preview-production-url, $shared-prefix, $post-zip, $pri-contact-name, $pri-contact-email, $sec-contact-name, $sec-contact-email)
            ) else (),
            create-site:register($user, $name, $email),
            regis-functions:save($isEditor, $status, $form, $file, $action, $locale, $messages)
        )
        return (
            json:obj((
                json:keyObject("success", "true"),
                json:keyObject("error",
                        json:arr($errors)
                )
            )), xdmp:redirect-response($settings:shared-prefix || '/register')
        )
    ) else (
        json:obj((
            json:keyObject("success", "false"),
            json:keyObject("error",
                    json:arr($errors)
            )
        ))
    )
)
