xquery version "1.0-ml";

import module namespace task = "http://lds.org/code/shared/lds-edit/task-functions" at "modules/taskFunctions.xqy";
import module namespace cc = "http://lds.org/code/shared/lds-edit/clear-cache-functions" at "../clear-cache/modules/clear-cache-functions.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "../modules/ldse-meta.xqy";
import module namespace correlation = "http://lds.org/code/shared/lds-edit/correlation" at "../correlation/modules/correlation-functions.xqy";
import module namespace func = "http://lds.org/code/shared/lds-edit/function-apply" at "../invoke/function-apply.xqy";
import module namespace sso = "http://lds.org/code/shared/common/sso/clientlib" at "/shared/common/security/clientlib.xqy";
import module namespace rw = "http://lds.org/code/shared/lds-edit/rewrite-functions" at "../ice/modules/rewrite-functions.xqy";
import module namespace action = "http://lds.org/code/shared/lds-edit/action-functions" at "../ice/modules/action-functions.xqy";


import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../modules/ldse-core.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../modules/ldse-settings.xqy";

declare namespace handle-correlation = "http://lds.org/code/shared/lds-edit/handle-correlation";

declare option xdmp:mapping "true";

declare variable $task-id as xs:string external;
declare variable $mode as xs:string external;
declare variable $port as xs:integer? external;
declare variable $site as xs:string external;

if ($task-id ne '' and $mode ne '') then (
    let $set as empty-sequence() := core:set-mode($mode)   
    let $set as empty-sequence() := core:set-port($port) 
    for $task as element(scheduled-task) in task:getQueuedTaskById($task-id)
    let $task-id as xs:string := $task/@id
    let $task-name as xs:string := $task/task-name
    let $action as xs:string := $task/task-data/action
    let $id as xs:string := $task/task-data/file-id
    let $locale as xs:string := $task/task-data/file-locale
    let $uri as xs:string  := $task/task-data/file-uri
    let $user as xs:string := $task/task-data/ice-user
    let $set-user as empty-sequence():= ldsemeta:set-user($user, "")
    
    let $set-cn as empty-sequence() := xdmp:set($sso:CN, $user)
    
    let $file as element()? := ldsemeta:get-file-by($id, $locale, (), ())
    let $schedule-publish-date as xs:dateTime? := ldsemeta:get-schedule-publish($file)/@dateTime
    let $schedule-unpublish-date as xs:dateTime? := ldsemeta:get-schedule-unpublish($file)/@dateTime
    let $uris as element(uris) := <uris><uri>{$uri}</uri></uris>
    let $success as xs:boolean :=
        try {
            if ($action eq "ldse:publish") then (
                if ( fn:exists($schedule-publish-date) ) then (
                    let $perform := action:perform-action($action, $uri, $locale, "", "", "", $id)
                    return fn:true()
                ) else (
                    fn:false()
                )
            ) else if ($action eq "ldse:unpublish") then (
                if ( fn:exists($schedule-unpublish-date) ) then (
                    let $perform := action:perform-action($action, $uri, $locale, "", "", "", $id)
                    return fn:true()
                ) else (
                    fn:false()
                )
            ) else ( fn:false() )
        } catch ($e) {
            fn:false(),
            xdmp:trace('pharaoh', $e)
        }
    return (
        if ($success) then (
            task:deleteTask($task),
            xdmp:trace('pharaoh',fn:concat("Task ", $task-name, ": ", $task-id)),
            cc:clearCache($uris, $site, $locale, (), $user)            
        ) else if ( fn:empty($file) ) then (
            (: delete task if the file is not found :)
            task:deleteTask($task),
            xdmp:trace('pharaoh',fn:concat("Task Deleted: ", $task-id, " File Not Found"))
        ) else if ( 
            ($action eq "ldse:publish" and fn:empty($schedule-publish-date)) or
            ($action eq "ldse:unpublish" and fn:empty($schedule-unpublish-date))
        ) then (
            (: delete task if the file is no longer scheduled :)
            task:deleteTask($task),
            xdmp:trace('pharaoh',fn:concat("File Not Scheduled: Deleting Task ", $task-name, ": ", $task-id))
        ) else (
            task:taskFailed($task)
        )
    )
) else ()
