xquery version "1.0-ml";

module namespace link = "http://lds.org/code/shared/lds-edit/link-checker-functions";

import module namespace json = "http://marklogic.com/json" at "../../modules/fasterjson.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../modules/utility-functions.xqy";

import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";

declare namespace xh = "xdmp:http";
declare option xdmp:mapping "true";
declare function link:validate($full-urls as xs:string*, $orgin-host as xs:string?, $live-host as xs:string?) as xs:string {
    json:obj(
        json:keyObject("results", 
            json:arr((
                for $full-url as xs:string in $full-urls
                let $parts as element(url-parts) := util:get-url-parts($full-url)
                let $domain as xs:string? := $parts/domain
                let $uri as xs:string? := fn:string-join(($parts/uri, $parts/params/ $parts/hash), '')
                let $code as xs:string? := link:get-response-code($domain, $uri)
                return (
                    json:obj((
                        json:keyEscapedValue("url", $full-url),
                        json:keyObject("code", $code)
                    ))
                )
            ))
        )
    )
};

declare function link:get-response-code($domain as xs:string, $uri as xs:string?) as xs:string? {
    link:get-response-code($domain, $uri, 0)
};

declare function link:get-response-code($domain as xs:string, $uri as xs:string?, $redirect-count as xs:int) as xs:string? {
    let $code as xs:string? := 

            let $response as item()* := 
                try {
                    xdmp:http-head(fn:concat("http://extproxy:80", $uri),
                     <options xmlns="xdmp:http">
                        <headers xmlns="xdmp:http">
                            <host>{$domain}</host>               
                        </headers>
                        <timeout>10</timeout>
                    </options>)
                } catch ($e) { () }
            let $code as xs:string? := $response/xh:code/xs:string(.)
            let $int as xs:int? := xs:int(($code, 1000)[1])
            return (
                if ($int > 300 and $int < 400) then (
                    let $location as xs:string? := $response/xh:headers/xh:location
                    let $parts as element(url-parts) := util:get-url-parts($location)
                    let $new-domain as xs:string? := ($parts/domain, $domain)[1]
                    let $new-uri as xs:string? := fn:string-join(($parts/uri, $parts/params/ $parts/hash), '')
                    return (
                        if (fn:contains(fn:lower-case($location), "signin") or fn:contains(fn:lower-case($location), "login")) then (
                            "200"
                        ) else if (fn:starts-with($location,'https')) then (
                            link:get-internal-response-code($location, $redirect-count + 1, $response/xh:headers/xh:set-cookie/fn:string(.))
                        ) else if ($redirect-count <= 5 and $location != "" ) then (
                            link:get-response-code($new-domain, $new-uri, $redirect-count + 1)
                        ) else (
                            "1000"
                        )
                    )
                ) else (
                    $code
                )
            ) 
    return (
        ($code, "1000")[1]
    )
};

declare function link:get-internal-response-code($url as xs:string, $redirect-count as xs:int, $cookies as xs:string*) as xs:string? {
        let $code as xs:string? := 
            let $response as item()* := 
                try {
                    xdmp:http-head($url,
                     <options xmlns="xdmp:http">
                        <timeout>10</timeout>
                        <headers>
                            {
                            for $cookie as xs:string in $cookies
                            return (
                                <Cookie>{$cookie}</Cookie>
                            )   
                        }</headers>
                    </options>)
                } catch ($e) { () }
            let $code as xs:string? := $response/xh:code/xs:string(.)
            let $int as xs:int? := xs:int(($code, 1000)[1])
            return (
                if ($int > 300 and $int < 400) then (
                    let $location as xs:string? := $response/xh:headers/xh:location
                    let $cookies as xs:string* := $response/xh:headers/xh:set-cookie/fn:string(.)
                    return (
                        if (fn:contains(fn:lower-case($location), "signin") or fn:contains(fn:lower-case($location), "login")) then (
                            "200"
                        ) else if ($redirect-count <= 5 and $location != "" ) then (
                            link:get-internal-response-code($location, $redirect-count + 1, $cookies)
                        ) else (
                            "1000"
                        )
                    )
                ) else (
                    $code
                )
            ) 
    return (
        ($code, "1000")[1]
    )
};

declare function link:get-host($full-url as xs:string) as xs:string {
    fn:replace($full-url, '((.[^/]+?://)?.[^/]+)(/.*)', '$1')
};

declare function link:get-uri($full-url as xs:string) as xs:string? {
  if ( fn:matches($full-url, '((http[s]?://)[^/\?#]+)(/.*)') ) then (
    fn:replace($full-url, '((http[s]?://)[^/\?#]+)(/.*)', '$3')
  ) else ( '/' )
};
