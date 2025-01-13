xquery version "1.0-ml";

import module namespace enrich = "http://lds.org/code/shared/lds-edit/enrich" at "enrich-functions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../modules/ldse-core.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../modules/ldse-settings.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../modules/utility-functions.xqy";

declare option xdmp:mapping "true";

let $key as xs:string := fn:concat('EnrichSync-', $core:site)
let $now as xs:dateTime := fn:current-dateTime()
let $max-runtime as xs:int := 10    (: Minutes :)

let $mode as xs:string? := settings:get-warehouse-mode()
let $set-mode as item()* := core:set-mode($mode)
let $port as xs:int := xs:int(settings:get-mode-port($mode))
let $set-port as item()* := core:set-port($port)

let $last-run as xs:dateTime? := util:get-server-field($key)
let $running as xs:boolean := fn:exists($last-run) and fn:round((xs:dateTime($now) - $last-run) div xs:dayTimeDuration('PT1M')) < $max-runtime
let $trace as item()* := 
    if ($running) then (
        xdmp:trace("enrich", "Enrich Sync Task already running")
    ) else ()
where fn:not($running)
return (
    let $start as item()* := util:set-server-field($key, $now)
    return (
        if ( enrich:sync-needed() ) then (
            let $sync as item()*  := enrich:sync-meta-data()
            return (
                $sync,
                util:set-server-field($key, ())
            )
        ) else (
            "Nothing to Sync",
            xdmp:trace("enrich","Nothing to Sync"),
            util:set-server-field($key, ())
        )
    )
)
