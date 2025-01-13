(:-------------------------------------------------------------------------------------------------------------------------------------:
     Copyright 2015 Intellectual Reserve, Inc.  All rights reserved.  This notice may not be removed.
 :-------------------------------------------------------------------------------------------------------------------------------------:)
xquery version "1.0-ml";

(: setup the namespace for this module :)
module namespace cache-control = "http://lds.org/code/modules/cache-control-functions";

import module namespace sp = "http://lds.org/code/modules/site-properties" at "../modules/site-properties.xqy";

(:~
    Adds the cache header and sets the max-age based off of site properties

    @param $context The execution context (preview or published)

    @return empty sequence
:)
declare function cache-control:addCacheHeader(
    $params-in as map:map?
) {
    let $requestUrl := xdmp:get-request-url()
    let $site := map:get($params-in, 'site')
    let $host := map:get($params-in, 'host')
    let $caching := if ($site) then
                        (sp:get-site-properties($site))[1]/caching
                    else
                        sp:get-site-properties-by($host)/caching
    let $maxAge as xs:string? := ($caching/cacheMaxAge)[1]
    let $tempCacheTime := $caching/tempCacheUrls/@time
    let $tempCacheUrls := $caching/tempCacheUrls

    (: if the url has ?url, then we are using a template and need to use this url, else use the real url :)
    let $requestUrl as xs:string := if (fn:contains($requestUrl, "?url=")) then (fn:substring-after(fn:substring-before($requestUrl,"&amp;"), "?url=")) else (fn:substring-before($requestUrl, ".xqy"))
    let $requestUrl as xs:string := if (fn:contains($requestUrl, "default")) then (fn:substring-before($requestUrl, "default")) else ($requestUrl)

    let $max :=  if ($tempCacheUrls[cacheUrl eq $requestUrl]) then ($tempCacheTime) else (if ($maxAge) then ($maxAge) else ("21600"))
    return (
        if (fn:empty($maxAge) or $max eq "0") then (
            cache-control:addNoCacheHeader()
        ) else (
            xdmp:add-response-header("Cache-Control", fn:concat("max-age=",  $max))
        )
    )
};

(:~
    Adds the no cache headers

    @return empty sequence
:)
declare function cache-control:addNoCacheHeader() {
    xdmp:add-response-header("Pragma", "no-cache"),
    xdmp:add-response-header("Cache-Control", "no-cache")
};
