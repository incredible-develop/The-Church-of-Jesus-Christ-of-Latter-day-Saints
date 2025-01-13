xquery version "1.0-ml";

import module namespace resource = "http://lds.org/code/shared/lds-edit/fast-i18n" at "../../../../rice/modules/fast-i18n.xqy";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../../../modules/utility-functions.xqy";
import module namespace ice = "http://lds.org/code/shared/lds-edit/iceFunction" at "../../../modules/iceFunctions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../../../modules/ldse-core.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../../../modules/access-control-functions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../../../modules/ldse-settings.xqy";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";

declare namespace xhtml = "http://www.w3.org/1999/xhtml";
declare option xdmp:mapping "true";
declare variable $host as xs:string := $util:host;

declare variable $country as xs:string? := util:escape-chars(xdmp:get-request-field("country", ""));
declare variable $preLocale as xs:string := util:escape-chars(xdmp:get-request-field("locale", "eng"));
declare variable $locale as xs:string := if ($country ne '') then (fn:concat($preLocale,'-',$country)) else ($preLocale);

declare variable $bundles as xs:string* := xdmp:get-request-field("bundle", "");
declare variable $keys as xs:string* := xdmp:get-request-field("key", "");
declare variable $newValues as xs:string* := xdmp:get-request-field("newValue", "");
declare variable $currentPage as xs:string := xdmp:get-request-field("currentPage", "");
declare variable $currentUri as xs:string := xdmp:get-request-field("currentUri", "");

declare variable $custom-page as element(custom-page)? := ice:get-custom-page($currentUri, $locale);

declare variable $redirectParams as xs:string? :=  
    if ( core:get-all-langs() eq $preLocale or util:get-country-locales() eq $locale) then (
        util:split-locale-param($locale)
    ) else (
        fn:concat("?lang=eng&amp;clang=", 
            $preLocale,
            if ($country ne '') then ( fn:concat("&amp;country=",$country)) else ()
        )
    );

if (ac:has-permission("ldse:edit-rice", $locale, $currentPage)) then (
    let $insertEdit as item()* := 
        (: Are there the same number of bundles, keys, and values? :)
        if ((fn:count($bundles) = fn:count($keys)) and (fn:count($bundles) = fn:count($newValues))) then (
            for $count as xs:integer in (1 to fn:count($bundles))
            return
                if ($bundles[$count] ne "" and $keys[$count] ne "" and $newValues[$count] ne "") then (
                    let $options as element() := 
                        <options xmlns="xdmp:tidy">
                            <newline>LF</newline>
                            <clean>true</clean>
                            <wrap>0</wrap>
                            <hide-comments>true</hide-comments>
                        </options>
                    let $value as item()* := fn:subsequence($newValues,$count, 1)
                    let $value as item()* := 
                        if (fn:matches($value , '.*?<param .*index="[0-9]*".*/>.*?'))
                        then ( util:unquote($value) )
                        else ( xdmp:tidy($value , $options)/xhtml:html/xhtml:body/node() )
                    (: If the value is text, remove the \n at the beginning and end :)
                    let $value as item()* := 
                        for $val as item() in $value
                        return (
                            typeswitch ($value)
                            case text() return functx:trim($val)
                            case xs:string return functx:trim($val)
                            default return $val
                        )
                    return (
                        if ($bundles[$count] eq "custom-page") then (
                            resource:insert-edit-page-resource($locale, $custom-page, $currentUri, $keys[$count], $value)
                        ) else (
                            resource:insert-edit-resource-bundle($locale, fn:concat($bundles[$count], ":", $keys[$count]), $value)
                        )
                    )                    
                ) else ()
        ) else ()
    
    return '{"data":"success", "message":"saved successfully"}'
) else (
        let $errorMsg as xs:string:="Sorry, You don't have permission" 
        let $errorTitle as xs:string:= "Access Denied!"
        return fn:concat('{"data":"error", "message":"', $errorMsg ,'"}')
    )
