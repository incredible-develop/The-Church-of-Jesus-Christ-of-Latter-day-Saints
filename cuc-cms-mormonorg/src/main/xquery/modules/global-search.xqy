xquery version "1.0-ml";

module namespace gs = "http://lds.org/code/shared/lds-edit/global-search";

import module namespace mem = "http://lds.org/code/shared/common/memory-update" at "/shared/common/util/inMemoryUpdate.xqy";

(: LDS-EDIT Imports :)
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "utility-functions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "ldse-core.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "ldse-settings.xqy";
import module namespace convert = "http://lds.org/code/shared/lds-edit/ldse-meta-convert" at "ldse-meta-convert.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare option xdmp:mapping "true";

declare variable $trace-key as xs:string := "ldse-global-search";

declare variable $service-url as xs:string? := util:get-service-url("searchAdminService");

declare function gs:add($file as element()) as item()* {
    if ($service-url != "") then (
        let $lang as xs:string := $file/@locale
        let $searchUri as xs:string := fn:concat($service-url, "/add?lang=", $lang, "&amp;referrer=", $core:site)
        let $file as element() := gs:replace-uri($file)
        let $debug as item()* := xdmp:trace($trace-key,fn:concat("gs:add: $searchUri=", $searchUri))
        let $options as element() :=
            <options xmlns="xdmp:http">
                <headers>
                    <content-type>text/plain</content-type>
                </headers>
                <data>{gs:prepare-for-search($file)}</data>
            </options>
        let $success as item()* := (
            try {
                util:http-post($searchUri,$options)/searchAdmin
            } catch ($e) {
                <results>
                    <result>Error</result>
                    <message>HTTP Post Failed :'(</message>
                    <messageDetail>View Trace Log For Details!</messageDetail>
                    {xdmp:trace($trace-key,$e)}
                </results>
                
                
            }
        )
        let $debug as item()* := xdmp:trace($trace-key,fn:concat("gs:add:",xdmp:elapsed-time()))
        return (
            if ($success/result eq "Error") then (
                xdmp:trace($trace-key,fn:concat("gs:add:", xs:string($success/message)," - ", xs:string($success/messageDetail)))
            ) else ()
        )
    ) else ()
};

declare function gs:remove($file as element()) as item()* {
    if ($service-url != "") then (
        let $lang as xs:string := $file/@locale
        let $id as xs:string := convert:get-id($file)
        let $searchUri as xs:string := fn:concat($service-url, "/remove?lang=", $lang, "&amp;referrer=", $core:site,"&amp;id=",$id)
        let $debug as item()* := xdmp:trace($trace-key,fn:concat("gs:remove: $searchUri=",$searchUri))
        let $options as element() :=
            <options xmlns="xdmp:http">
                <headers>
                    <content-type>text/plain</content-type>
                </headers>
            </options>
        let $success as item()* := (
            try {
                util:http-post($searchUri,$options)/searchAdmin
            } catch ($e) {
                <results>
                    <result>Error</result>
                    <message>HTTP Post Failed :'(</message>
                    <messageDetail>View Trace Log For Details!</messageDetail>
                    {xdmp:trace($trace-key,$e)}
                </results>
            }
        )
        let $debug as item()* := xdmp:trace($trace-key,fn:concat("gs:remove:",xdmp:elapsed-time()))
        return (
            if ($success/result eq "Error") then (
                xdmp:trace($trace-key,fn:concat("gs:remove:",xs:string($success/message)," - ",xs:string($success/messageDetail)))
            ) else ()
        )
    ) else ()
};

(:This unquotes the XML, removes the pre tags that have brackets and a quote 
 with a regular expression, making it > 4x faster than an in-memory replace:)
declare function gs:prepare-for-search($file as element()) as xs:string {
    fn:replace(xdmp:quote($file),"<pre[^>]*?>[^<]*?(\[[^<:]*:[^<]*\][\s\S]*?)+</pre>","")
};

declare function gs:replace-uri($file as element()) as element() {
    let $searchDomain as xs:string? := $settings:search-domain
    let $newUri as attribute()? :=
        if ($searchDomain ne '') then (
            attribute uri {
                fn:concat($searchDomain, $file/@uri, util:split-locale-param($file/@locale))
            }
        ) else ()
    return (
        if (fn:exists($newUri)) then (
            mem:node-replace($file/@uri, $newUri)
        ) else ($file)
    )
};
