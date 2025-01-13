xquery version "1.0-ml";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../../../modules/utility-functions.xqy";
import module namespace ice = "http://lds.org/code/shared/lds-edit/iceFunction" at "../../../modules/iceFunctions.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "../../../../modules/ldse-meta.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../../../modules/ldse-core.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../../../modules/access-control-functions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../../../modules/ldse-settings.xqy";
import module namespace mem = "http://lds.org/code/shared/common/memory-update" at "/shared/common/util/inMemoryUpdate.xqy";

declare boundary-space preserve;
declare namespace ldse = "http://lds.org/code/lds-edit";
declare option xdmp:mapping "true";

declare variable $host as xs:string := $util:host;

declare variable $country as xs:string? := util:escape-chars(xdmp:get-request-field("country", ""));
declare variable $preLang as xs:string := util:escape-chars(xdmp:get-request-field("lang", "eng"));

declare variable $lang as xs:string := if ($country ne '') then (fn:concat($preLang,'-',$country)) else ($preLang);

declare variable $navName as xs:string := xdmp:get-request-field("navName", "eng");
declare variable $orginalName as xs:string := xdmp:get-request-field("orginalName", "");
declare variable $orginalSequence as xs:string := xdmp:get-request-field("orginalSequence", "");
declare variable $orginalLocation as xs:string := xdmp:get-request-field("orginalLocation", "");
declare variable $currentPage as xs:string := xdmp:get-request-field("currentPage", "");
            
declare variable $isCustom as xs:string := (xdmp:get-request-field("isCustom", "false")[. != ""], "false")[1];
declare variable $referencedChannel as xs:string? := if ($isCustom eq 'true') then (xdmp:get-request-field("referencedChannel", "")) else ();
declare variable $custom-page as element(custom-page)? := if ($isCustom eq 'true') then (ice:get-custom-page($currentPage, $lang)) else ();

declare variable $sectionSequence as xs:string := xdmp:get-request-field("sectionSequence", "");
declare variable $sectionName as xs:string := util:escape-chars(xdmp:get-request-field("sectionName", ""));
declare variable $sectionUrl as xs:string := util:escape-chars(xdmp:get-request-field("sectionUrl", ""));
declare variable $sectionAttrName as xs:string := util:sanitize-uri(util:escape-chars(xdmp:get-request-field("sectionAttrName", "")));

declare variable $channels as element(channels)? := 
    cts:search(/channels[@name eq $navName and @locale eq $lang],
        core:get-filter-query()
    );

declare function local:buildChannels($index as xs:string?) as element(channels)? {
    let $alwaysShow as xs:string? := xdmp:get-request-field(fn:concat("alwaysShow",$index))
    let $sequences as xs:string* := xdmp:get-request-field(fn:concat("sequence",$index))
    let $names as xs:string* := xdmp:get-request-field(fn:concat("name",$index))
    let $urls as xs:string* := xdmp:get-request-field(fn:concat("url",$index))
    let $attrNames as xs:string* := xdmp:get-request-field(fn:concat("attrName",$index))
    let $subs as xs:string* := xdmp:get-request-field(fn:concat("sub",$index))
    return (
        if (fn:exists($sequences) and fn:exists($names) and fn:count($sequences) eq fn:count($names)) then (
            element channels {
                if ($alwaysShow eq 'true') then (
                    attribute alwaysShow {'true'}
                ) else (),
                for $sequence as xs:string at $count in $sequences
                let $name as xs:string := $names[$count]
                let $url as xs:string := $urls[$count]
                let $attrName as xs:string := util:sanitize-uri($attrNames[$count])
                let $sub as xs:string := $subs[$count]
                where $name ne ''
                return (
                    <channel sequence="{$sequence}" name="{$attrName}">
                        <name>{$name}</name>
                        <url>{$url}</url>
                        { local:buildChannels($sub) }
                    </channel>
                )
            }           
        ) else ()
    )
};

if (ac:has-permission("ldse:edit-navigation", $lang, $currentPage)) then (
    
    let $orginalChannel as element(channel)? :=
        if ($isCustom eq 'true') then (
            $custom-page/channel
        ) else if ($orginalLocation ne '') then (
            $channels//channel[xdmp:path(.) eq $orginalLocation and @sequence eq $orginalSequence and @name eq $orginalName]
        ) else (
            $channels//channel[@sequence eq $orginalSequence and @name eq $orginalName]
        )
    

    let $newChannel as element(channel) :=
        element channel {
            if ($referencedChannel and $isCustom eq 'true') then (
                attribute reference {$referencedChannel}
            ) else (
                attribute sequence {$sectionSequence},
                attribute name {$sectionAttrName},
                if ($isCustom eq 'true') then (
                    attribute translation {"ready"}
                ) else (),
                element name {$sectionName},
                element url {$sectionUrl},
                local:buildChannels('')
            )
        }
    
        
    let $new-file as element() := 
        if ($isCustom eq 'true' and fn:exists($custom-page)) then (
            if ( fn:exists($orginalChannel) ) then (
                util:get-root(mem:node-replace($orginalChannel, $newChannel))
            ) else (
                util:get-root(mem:node-insert-child($custom-page, $newChannel))
            )
         ) else if ($isCustom ne 'true') then (
            if ( fn:exists($orginalChannel) ) then (
                util:get-root(mem:node-replace($orginalChannel, $newChannel))
            ) else (
                util:get-root(mem:node-insert-child($channels, $newChannel))
            )
         ) else (xdmp:redirect-response("/error.xqy"))
                 
    let $transStatus as attribute()? := 
        if ( fn:exists($orginalChannel) and fn:deep-equal($orginalChannel, $newChannel)) then () else (
            attribute translation {'ready'}
        )

    let $new-file as element() := 
        if ($isCustom eq 'false' and fn:exists($transStatus) and fn:exists($channels)) then (
            if ( fn:exists($new-file/@translation) ) then (
                util:get-root(mem:node-replace($new-file/@translation, $transStatus))
            ) else (
                util:get-root(mem:node-insert-child($new-file, $transStatus))
            )
        ) else (
          $new-file  
        )
    let $new-file as element() :=
        if ($isCustom eq 'true' and fn:exists($custom-page)) then (
            let $new-meta as element(ldse:ldse-meta) := ldsemeta:get-meta($custom-page)
            return (
                if (fn:exists($new-file/ldse:ldse-meta)) then (
                    util:get-root(mem:node-replace($new-file/ldse:ldse-meta, $new-meta))
                ) else (
                    util:get-root(mem:node-insert-child($new-file, $new-meta))
                )
            )
        ) else if ($isCustom eq 'false' and fn:exists($channels)) then (
            let $new-meta as element(ldse:ldse-meta) := ldsemeta:get-meta($channels)
            return (
                if (fn:exists($new-file/ldse:ldse-meta)) then (
                    util:get-root(mem:node-replace($new-file/ldse:ldse-meta, $new-meta))
                ) else (
                    util:get-root(mem:node-insert-child($new-file, $new-meta))
                )
            )
        ) else (
            $new-file
        )
    
   let $save as item()* := 
        if ($isCustom = "true" and fn:exists($custom-page)) then (
            core:save-file(xdmp:node-uri($custom-page), $new-file, $custom-page)
        ) else if ($isCustom eq 'false' and fn:exists($channels)) then (
            core:save-file(xdmp:node-uri($channels), $new-file, $channels)
        ) else (
            xdmp:redirect-response("/error.xqy") 
        )
    return (
        xdmp:redirect-response( core:build-url(xdmp:url-decode(xdmp:get-request-field('referer',$sectionUrl)), $lang, ()) )
    )
) else (
        let $errorMsg as xs:string:="Sorry, You don't have permission" 
        let $errorTitle as xs:string:= "Access Denied!"
        return xdmp:redirect-response(fn:concat($settings:shared-prefix,"/error?errorMsg=",$errorMsg,"&amp;errorTitle=",$errorTitle))
    )
