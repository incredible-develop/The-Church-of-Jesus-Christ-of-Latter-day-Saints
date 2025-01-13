xquery version "1.0-ml";

import module namespace task = "http://lds.org/code/shared/lds-edit/task-functions" at "modules/taskFunctions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../modules/ldse-core.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../modules/ldse-settings.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../modules/utility-functions.xqy";

declare option xdmp:mapping "true";

let $key as xs:string := fn:concat('PharoahTask-', $core:site)
let $now as xs:dateTime := fn:current-dateTime()
let $max-runtime as xs:int := 10    (: Minutes :)

let $mode as item()* := settings:get-pharaoh-mode()
let $set-mode as item()* := core:set-mode( $mode )
let $set-port as item()* := core:set-port( settings:get-mode-port($mode) )

let $last-run as xs:dateTime? := util:get-server-field($key)
let $current-date as xs:dateTime := fn:current-dateTime()
let $running as xs:boolean := fn:exists($last-run) and fn:round((xs:dateTime($now) - $last-run) div xs:dayTimeDuration('PT1M')) < $max-runtime
let $trace as item()* := 
    if ($running) then (
        xdmp:trace("pharaoh", "Task already running")
    ) else ()
where fn:not($running)
return (
    let $start as item()* := util:set-server-field($key, $now)
    let $run as item()* := task:minTaskMaster()
    return (
        $run,
        util:set-server-field($key, ())
    )
)
