xquery version "1.0-ml";

module namespace brightcove = "http://lds.org/code/shared/lds-edit/brightcove/brightcove-service";

import module namespace mem = "http://lds.org/code/shared/common/memory-update" at "/shared/common/util/inMemoryUpdate.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../modules/utility-functions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../modules/ldse-settings.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../modules/ldse-core.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "../modules/ldse-meta.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace bldse = "http://lds.org/code/lds-edit/brightcove";
declare namespace http = "xdmp:http";

declare option xdmp:mapping "true";

declare variable $player-id-xpath as element() := $settings:brightcove-settings/ldse:player-id-element-xpath;
declare variable $video-id-xpath as element() := $settings:brightcove-settings/ldse:video-id-element-xpath;
declare variable $player-key-xpath as element() := $settings:brightcove-settings/ldse:player-key-element-xpath;

declare function brightcove:get-unix-timestamp($time as xs:dateTime, $duration as xs:int) as xs:unsignedLong? {
    let $now as xs:dateTime := fn:adjust-dateTime-to-timezone($time, xs:dayTimeDuration('PT0H')) + xs:dayTimeDuration(fn:concat('PT0H', $duration, 'S'))
    return fn:round(($now - xs:dateTime("1970-01-01T00:00:00-00:00")) div xs:dayTimeDuration('PT1S'))
};

declare function brightcove:substring-before-last-match ($arg as xs:string?, $regex as xs:string) as xs:string? {
   fn:replace($arg, fn:concat('^(.*)',$regex,'.*'),'$1', "m")
};
 
declare function brightcove:get-brightcove-videos(
    $newXml as element(), 
    $locale as xs:string, 
    $player-id as xs:string, 
    $video-id as xs:string
) as item() {
    let $host as xs:string := $settings:brightcove-server
    let $iso as xs:string := $locale
    let $url as xs:string := fn:concat("/api/videoPlayers/translatedPlayer/1/", $video-id, "/", $iso, "/", $player-id)
    let $now as xs:dateTime := fn:current-dateTime()
    let $x-auth-user as xs:string := $settings:brightcove-user
    let $api-key as xs:string := $settings:brightcove-key
    let $x-auth-expires as xs:unsignedLong? := brightcove:get-unix-timestamp($now, 30)
    let $x-auth-key as xs:string := xdmp:md5(fn:concat($api-key, xdmp:md5(fn:concat($url, $x-auth-user, $api-key, $x-auth-expires))))
    let $headers as element() := 
        <headers xmlns="xdmp:http">
            <X-Auth-User>{$x-auth-user}</X-Auth-User>
            <X-Auth-Expires>{$x-auth-expires}</X-Auth-Expires>
            <X-Auth-Key>{$x-auth-key}</X-Auth-Key> 
        </headers>
    let $data as item()* :=
        util:http-get(fn:concat($host, $url),
            <options xmlns="xdmp:http">
                {$headers}
            </options>
        )
    let $result-code as xs:string := $data[1]/http:code/xs:string(.)
    
    return
        <result>
            <host>{$host}</host>
            <url>{$url}</url>
            <date-time>{$now}</date-time>
            <api-key>{$api-key}</api-key>
            {$headers}
            <request>{$data[2]}</request>
            <code>{$result-code}</code>
        </result>
};

declare function brightcove:get-brightcove-video-status(
    $new-xml as element(),
    $locale as xs:string,
    $xml-player-id as element()*,
    $xml-video-id as element()*,
    $xml-player-key as element()*, 
    $eng-player-id as element()*, 
    $eng-video-id as element()*,
    $eng-player-key as element()*
) as element() {
   if ( fn:exists($xml-player-id) and fn:exists($xml-video-id) ) then (
        let $player-id as element()? := $xml-player-id[1]
        let $parent as element() := $player-id/..
        let $player-path as xs:string? := xdmp:path($player-id)
        
        let $video-id as element()? := $xml-video-id[.. is  $parent]
        let $player-key as element()? := $xml-player-key[.. is  $parent]
        let $player-id-eng as element()? := $eng-player-id[xdmp:path(.) = $player-path]
        let $parent-eng as element()? := $player-id/..
        let $video-id-eng as element()? := $eng-video-id[.. is  $parent]
        let $player-key-eng as element()? := $eng-player-key[.. is  $parent]

        let $new-xml as element() := brightcove:preform-update($new-xml, $locale, $player-id, $video-id, $player-key, $player-id-eng, $video-id-eng, $player-key-eng)
        
        return (
            brightcove:get-brightcove-video-status(
                $new-xml, 
                $locale, 
                $xml-player-id except $player-id, 
                $xml-video-id except $video-id, 
                $xml-player-key except $player-key,
                $eng-player-id except $player-id-eng, 
                $eng-video-id except $video-id-eng,
                $eng-player-key except $player-key-eng 
            )
        )
    ) else (
        $new-xml
    )
};

declare function brightcove:preform-update(
    $new-xml as element(),
    $locale as xs:string,
    $xml-player-id as element(),
    $xml-video-id as element(),
    $xml-player-key as element(), 
    $eng-player-id as element()?, 
    $eng-video-id as element()?,
    $eng-player-key as element()?
) as element() {
    let $player-id as xs:string? := 
        if ( fn:not($xml-player-id = "") ) then (
            xs:string($xml-player-id)
        ) else (
            xs:string($eng-player-id)
        )
    let $video-id as xs:string? := 
        if ( fn:not($xml-video-id = "") ) then (
            xs:string($xml-video-id)
        ) else (
            xs:string($eng-video-id)
        )
    let $player-key as xs:string? := 
        if ( fn:not($xml-player-key = "") ) then (
            xs:string($xml-player-key)
        ) else (
            xs:string($eng-player-key)
        )
    let $data as item() := brightcove:get-brightcove-videos($new-xml, $locale, $player-id, $video-id)
    let $result-code as xs:string := $data/code/xs:string(.)
    let $json as xs:string := 
        fn:concat('{',
          fn:replace(brightcove:substring-before-last-match(fn:substring-after($data/request/xs:string(.), '{'), '\}'), "&#13;|0&#13;", ""),
          
       '}')
    let $from-json as item()* := xdmp:from-json($json)
    let $new-xml as element() := 
        if ($result-code = "200") then (
            let $brightcove-xml as element()* := util:map-xml($from-json)
            let $player-id as xs:string? := ($brightcove-xml[2]/playerid, $player-id)[1]
            let $player-key as xs:string? := ($brightcove-xml[2]/playerkey, $player-key)[1]
            let $success as xs:boolean := 
                if ( fn:contains($brightcove-xml[2]/errors/xs:string(.), 'never') or (fn:exists($brightcove-xml[2]/playerid) and fn:exists($brightcove-xml[2]/playerkey)) ) then (
                    fn:true()
                ) else ( fn:false() )
            let $video-id as xs:string := $brightcove-xml[1]/id
            let $xml as element() := brightcove:update-player-fields($new-xml, $player-id, $player-key, $video-id, $xml-player-id, $xml-player-key, $xml-video-id)
            let $xml as element() := brightcove:update-ldsemeta-brightcove($xml, $result-code, $success)
            let $brightcove-xml as item()* := brightcove:build-extra-elements($brightcove-xml, $locale, $player-id, $player-key, $video-id)
            return $xml
        ) else (
            let $xml as element() := brightcove:update-player-fields($new-xml, $player-id, $player-key, $video-id, $xml-player-id, $xml-player-key, $xml-video-id)
            return 
                brightcove:update-ldsemeta-brightcove($xml, $result-code, ())
        )
    return $new-xml
};

declare function brightcove:update-player-fields(
    $new-xml as element(), 
    $player-id as xs:string, 
    $player-key as xs:string, 
    $video-id as xs:string, 
    $xml-player-id as element(), 
    $xml-player-key as element(), 
    $xml-video-id as element()
) as element() {
    let $new-player-id as element() := element { fn:node-name($xml-player-id) } { $xml-player-id/@*, xs:string($player-id) }
    let $new-player-key as element() := element { fn:node-name($xml-player-key) } { $xml-player-key/@*, $player-key }
    let $new-video-id as element() := element { fn:node-name($xml-video-id) } { $xml-video-id/@*, xs:string($video-id) }

    let $player-id-path as xs:string := fn:replace(xdmp:path($xml-player-id), '^/[^/]+', '')
    let $xml-player-id as element() := brightcove:get-node($new-xml, $player-id-path)
    let $player-key-path as xs:string := fn:replace(xdmp:path($xml-player-key), '^/[^/]+', '')
    let $xml-player-key as element() := brightcove:get-node($new-xml, $player-key-path)
    let $video-id-path as xs:string := fn:replace(xdmp:path($xml-video-id), '^/[^/]+', '')
    let $xml-video-id as element() := brightcove:get-node($new-xml, $video-id-path)
    
    let $new-xml as element() := 
        util:get-root(
            mem:advanced-operation((
                "replace", $xml-player-id, $mem:start-mod-qname, $new-player-id, $mem:end-mod-qname,
                "replace", $xml-video-id, $mem:start-mod-qname, $new-video-id, $mem:end-mod-qname,
                "replace", $xml-player-key, $mem:start-mod-qname, $new-player-key, $mem:end-mod-qname
            ))
        )
    return $new-xml
};

declare function brightcove:get-node($xml as element(), $path as xs:string) {
    typeswitch($xml)
    case element() return (
        let $item := util:unpath($xml, $path)
        return (
            if ( fn:exists($item) ) then ( 
                $item
            ) else (
                let $path := fn:concat("/", fn:local-name($xml), $path)
                where fn:exists($path) and fn:not($path = "")
                return (
                    util:unpath($xml, $path)
                )
            )
                
        )
    )
    default return ()
};

declare function brightcove:update-ldsemeta-brightcove($new-xml as element(), $result-code as xs:string, $success as xs:boolean?) as element() {
    let $ldse-meta as element(ldse:ldse-meta)? := $new-xml/ldse:ldse-meta    
    let $new-xml as element() :=
        if ( xs:dateTime($ldse-meta/ldse:last-modified/@date) = fn:current-dateTime() and $ldse-meta/ldse:brightcove-service/@status = "retry" ) then (
            (: Document already updated this transaction :)
            $new-xml
        ) else if ( fn:exists($ldse-meta/ldse:brightcove-service) and $result-code eq "200" and fn:exists($success) ) then (
            util:get-root(mem:node-replace($ldse-meta/ldse:brightcove-service/@status, attribute status { "success" }))
        ) else if ( fn:empty($ldse-meta/ldse:brightcove-service) and $result-code eq "200" and fn:exists($success) ) then (
            util:get-root(mem:insert-child($ldse-meta, <brightcove-service xmlns="http://lds.org/code/lds-edit" status="success" />))
        ) else if ( fn:exists($ldse-meta/ldse:brightcove-service) ) then (
            util:get-root(mem:node-replace($ldse-meta/ldse:brightcove-service/@status, attribute status { "retry" }))
        ) else ( 
            util:get-root(mem:insert-child($ldse-meta, <brightcove-service xmlns="http://lds.org/code/lds-edit" status="retry" />))
        )
    return $new-xml 
};

declare function brightcove:build-extra-elements($brightcove-xml as element()*, $locale as xs:string, $player-id as xs:string, $player-key as xs:string, $video-id as xs:string) as item()* {
    let $xml as element(bldse:brightcove-details) := 
        <brightcove-details xmlns="http://lds.org/code/lds-edit/brightcove" player-id="{$player-id}" player-key="{$player-key}" video-id="{$video-id}" locale="{$locale}">
            {$brightcove-xml}
        </brightcove-details>
    let $db-path as xs:string := core:build-db-path((), $locale, (), $xml, <options><player-id>{$player-id}</player-id><video-id>{$video-id}</video-id></options>)
    return core:save-file($db-path, $xml, ())
};

declare function brightcove:nightly-task($files as item()*) as item()* {
    for $file as item() in fn:doc($files)
    let $orig-file as element() := $file/*
    let $locale as xs:string? := $orig-file/ldse:ldse-meta/ldse:document/@locale
    let $id as xs:string? := ldsemeta:get-document-id($orig-file)
    let $orig-id as xs:string := fn:concat(fn:substring-before($id, "-"), "-eng")
    let $english-file as element()? := brightcove:get-english-video($orig-id)
    let $xml-player-id as element()+ := util:value($orig-file, $player-id-xpath)
    let $xml-video-id as element()+ := util:value($orig-file, $video-id-xpath)
    let $xml-player-key as element()+ := util:value($orig-file, $player-key-xpath)
    let $english-player-id as element()* := util:value($english-file, $player-id-xpath)
    let $english-video-id as element()* := util:value($english-file, $video-id-xpath)
    let $english-player-key as element()* := util:value($english-file, $player-key-xpath)
    return 
        if ( $locale = "eng" and fn:exists($xml-player-id) and fn:not($xml-player-id = "") and fn:exists($xml-video-id) and fn:not($xml-video-id = "") and fn:exists($xml-player-key) and fn:not($xml-player-key = "") ) then (
            let $new-file as element() := brightcove:get-brightcove-video-status($orig-file, $locale, $xml-player-id, $xml-video-id, $xml-player-key, (), (), ())
            let $db-path as xs:string := xdmp:node-uri($file)
            
            return 
                core:save-file($db-path, $new-file, $orig-file)
            
        ) else if ( fn:not($locale = "") and fn:exists($locale) and fn:exists($xml-player-id) and fn:not($xml-player-id = "") and fn:exists($xml-video-id) and fn:not($xml-video-id = "") and fn:exists($xml-player-key) and fn:not($xml-player-key = "") ) then (
            let $new-file as element()? := brightcove:get-brightcove-video-status($orig-file, $locale, $xml-player-id, $xml-video-id, $xml-player-key, $english-player-id, $english-video-id, $english-player-key)
            let $db-path as xs:string := xdmp:node-uri($file)
            
            return 
                core:save-file($db-path, $new-file, $orig-file)
        ) else (
            if ( fn:exists($english-player-id) and fn:not($english-player-id = "") and fn:exists($english-video-id) and fn:not($english-video-id = "") and fn:exists($english-player-key) and fn:not($english-player-key = "") ) then (
                let $new-file as element()? := brightcove:get-brightcove-video-status($orig-file, $locale, $xml-player-id, $xml-video-id, $xml-player-key, $english-player-id, $english-video-id, $english-player-key)
                let $db-path as xs:string := xdmp:node-uri($file)
                return 
                    core:save-file($db-path, $new-file, $orig-file)
            ) else (
                $file
            )
        )
};

declare function brightcove:get-english-video($id as xs:string) as element()? {
    cts:search(/*, 
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('id'), $id, "exact"),
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), 'eng', "exact")
        )),
        "unfiltered"
    )[1]
};

declare function brightcove:save-video-information(
    $id as xs:string, 
    $locale as xs:string
) as item()* {
    let $file as element()? := ldsemeta:get-file-by($id, $locale, (), ())
    where fn:exists($file)
    return (
        brightcove:nightly-task( xdmp:node-uri($file) )
    )
};

declare function brightcove:is-video($file as element()) as xs:boolean {
   fn:exists(util:value($file, $player-id-xpath)) and fn:exists(util:value($file, $video-id-xpath)) and fn:exists(util:value($file, $player-key-xpath))
};
