xquery version "1.0-ml";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../../../modules/utility-functions.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../../../modules/access-control-functions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../../../modules/ldse-core.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../../../modules/ldse-settings.xqy";

declare boundary-space preserve;
declare namespace ldse = "http://lds.org/code/lds-edit";
declare option xdmp:mapping "true";

declare variable $lang as xs:string := util:escape-chars(xdmp:get-request-field("lang", "eng"));
declare variable $country as xs:string? := util:escape-chars(xdmp:get-request-field("country", ""));
declare variable $locale as xs:string := if ($country ne '') then (fn:concat($lang, '-', $country)) else ($lang);

if (ac:has-permission('ldse:edit-doc', "", "")) then (
    let $templates as element(formTemplate)* := cts:search(/formTemplate[@teaserSwitchable eq 'true'], core:get-filter-query())
    let $buttons as element(p)* :=
        for $template as element(formTemplate) in $templates
        return (
            <p><button id="{$template/@name}Button" newFormType="{xs:string($template/@name)}" class="changeForm">Change to {xs:string($template/title)}</button></p>
        )
    return $buttons
) else (
     let $errorMsg as xs:string:="Sorry, You don't have permission" 
     let $errorTitle as xs:string:= "Access Denied!"
     return xdmp:redirect-response(fn:concat($settings:shared-prefix,"/error?errorMsg=",$errorMsg,"&amp;errorTitle=",$errorTitle))
)
