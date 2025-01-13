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
declare variable $distinct-bundles as xs:string* := fn:distinct-values($bundles);
declare variable $keys as xs:string* := xdmp:get-request-field("key", "");
declare variable $newValues as xs:string* := xdmp:get-request-field("newValue", "");
declare variable $currentPage as xs:string := xdmp:get-request-field("currentPage", "");
declare variable $currentUri as xs:string := xdmp:get-request-field("currentUri", "");
declare variable $seo-title-key as xs:string := xdmp:get-request-field("seo-title-key", "");

declare variable $custom-page as element(custom-page)? := ice:get-custom-page($currentUri, $locale);
declare variable $referer as xs:string? := xdmp:get-request-header('referer');

declare variable $clangParam as xs:string? :=  
    if ( fn:not(core:get-all-langs() = $preLocale) and $country = "" and fn:not(fn:contains($preLocale, '-')) ) then (
        fn:concat("&amp;clang=", $preLocale)
    ) else ();
    
declare variable $redirectLocale as xs:string? := if ( $clangParam != "" ) then ("eng") else ( $locale );

if (ac:has-permission("ldse:edit-rice", $locale, $currentPage)
	or (
		$currentPage = "/form"
		and ac:has-permission("ldse:edit-rice-contentEditor", (), ())
	)
) then (
	let $map as map:map := map:map()
	
    let $insertEdit as item()* := 
        (: Are there the same number of bundles, keys, and values? :)
        if ((fn:count($bundles) = fn:count($keys)) and (fn:count($bundles) = fn:count($newValues))) then (
            for $count as xs:integer in (1 to fn:count($bundles))
            let $bundle as xs:string? := fn:subsequence($bundles, $count, 1)
            let $key as xs:string? := fn:subsequence($keys, $count, 1)
            let $value as xs:string? := fn:subsequence($newValues,$count, 1)
            return
                if ($bundle ne "" and $key ne "" and $value ne "") then (
                    let $options as element() := 
                        <options xmlns="xdmp:tidy">
                            <newline>LF</newline>
                            <clean>true</clean>
                            <wrap>0</wrap>
                            <hide-comments>true</hide-comments>
                        </options>
                    let $value as item()* := fn:subsequence($newValues,$count, 1)
                    let $value as item()* := 
                        if (fn:matches($value , '.*?<param .*index="[0-9]*".*/>.*?')) then ( 
                            util:unquote($value)
                        ) else ( xdmp:quote(xdmp:tidy($value, $options)/xhtml:html/xhtml:body/node()) )
                    (: If the value is text, remove the \n at the beginning and end :)
                    let $value as item()* := 
                        for $val as item() in $value
                        return (
                            typeswitch ($val)
                            case text() return functx:trim($val)
                            case xs:string return functx:trim($val)
                            default return $val
                        )
                    let $value as element() := <val>{$value}</val>
                    return
	                    map:put($map, fn:concat($bundle, ":", $key), $value)
                    (:(
                        if ($bundle eq "custom-page") then (
                            resource:insert-edit-page-resource($locale, $custom-page, $currentUri, $key, $value)
                        ) else (
                            resource:insert-edit-resource-bundle($locale, fn:concat($bundle, ":", $key), $value)
                        )
                    ) :)                   
                ) else ()
        ) else ()
		
    let $_ as item()* :=
    	for $bundle-name as xs:string in $distinct-bundles
	    let $all-keys as xs:string* := map:keys($map)[fn:starts-with(., $bundle-name)]
	    let $keys := $all-keys[. != $seo-title-key]
	    let $values as item()* :=
	    	for $key as xs:string in $keys
	    	return map:get($map, $key)
    	return
			if ($bundle-name = "custom-page") then (
                for $key as xs:string at $index in $keys
                let $key := fn:substring-after($key, ":")
                let $value as xs:string := fn:subsequence($values, $index, 1)
                return resource:insert-edit-page-resource($locale, $custom-page, $currentUri, $key, $value)
            ) else resource:insert-edit-resource-bundle($locale, $keys, $values)

    
    return
    	if($currentPage = "/form")
    	then ()
    	else xdmp:redirect-response( $referer )
) else (
        let $errorMsg as xs:string:="Sorry, You don't have permission" 
        let $errorTitle as xs:string:= "Access Denied!"
        return xdmp:redirect-response(fn:concat($settings:shared-prefix,"/error?errorMsg=",$errorMsg,"&amp;errorTitle=",$errorTitle))
    )
