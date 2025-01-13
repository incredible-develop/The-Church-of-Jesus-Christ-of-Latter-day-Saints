xquery version "1.0-ml";

import module namespace task = "http://lds.org/code/shared/lds-edit/task-functions" at "../pharaoh/modules/taskFunctions.xqy";
import module namespace cc = "http://lds.org/code/shared/lds-edit/clear-cache-functions" at "../clear-cache/modules/clear-cache-functions.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "../modules/ldse-meta.xqy";

import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../modules/ldse-core.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../modules/ldse-settings.xqy";

declare option xdmp:mapping "true";
(: 
    DEPRECATED TASK 
    should use /pharoah/actions-task.xqy
:)
declare variable $task-id as xs:string external;
declare variable $mode as xs:string external;
declare variable $port as xs:integer? external;
declare variable $site as xs:string external;

if ($task-id ne '' and $mode ne '') then (
    let $set as empty-sequence() := core:set-mode($mode)
    let $set as empty-sequence() := core:set-port($port)
    let $scheduledTasks as element(scheduled-task)* := task:getQueuedTaskById($task-id)
    
    let $publish := 
        $scheduledTasks/(
            let $currentTask as element(scheduled-task) := .
            let $task-id as xs:string := $currentTask/@id
            let $task-name as xs:string := $currentTask/task-name
            let $id as xs:string := $currentTask/task-data/file-id
            let $locale as xs:string := $currentTask/task-data/file-locale
            let $user as xs:string := $currentTask/task-data/ice-user
            let $set-user as empty-sequence():= ldsemeta:set-user($user, "")
            let $file as element()? := ldsemeta:get-file-by($id, $locale, (), ())
            let $schedule-publish-date as xs:dateTime? := ldsemeta:get-schedule-publish($file)/@dateTime
            let $schedule-unpublish-date as xs:dateTime? := ldsemeta:get-schedule-unpublish($file)/@dateTime
            return (
                if ( fn:exists($file) ) then (
                    let $action as element()? := 
                        if ($task-name eq "ice-publish") then (
                            if ( fn:exists($schedule-publish-date) ) then (
                                core:preform-action-and-update("ldse:publish", $file)
                            ) else ()
                        ) else if ($task-name eq "ice-unpublish") then (
                            if ( fn:exists($schedule-unpublish-date) ) then (
                                core:preform-action-and-update("ldse:unpublish", $file)
                            ) else ()
                        ) else ()
                    let $uris as element(uris) := element uris { element uri {xs:string($currentTask/task-data/file-uri)} }
                    let $clearCache as item()* := 
                        if ( fn:not($action eq fn:false()) ) then (
                            cc:clearCache($uris, $site, $locale, (),$user)
                        ) else ()
                    return (
                        if ( fn:exists($action) ) then (
                            task:deleteTask($currentTask),
                            xdmp:trace('pharaoh',fn:concat("Task ", $task-name, ": ", $task-id))
                        ) else if ( ($task-name eq "ice-publish" and fn:empty($schedule-publish-date) ) or
                               ($task-name eq "ice-unpublish" and fn:empty($schedule-unpublish-date) ) ) then (
                            task:deleteTask($currentTask),
                            xdmp:trace('pharaoh',fn:concat("Task ", $task-name, ": ", $task-id))
                        ) else (
                            task:taskFailed($currentTask),
                            xdmp:trace('pharaoh',fn:concat("Task FAILED: ", $task-id))
                        )   
                    )
                ) else (
                    (: delete task if the file is not found :)
                    task:deleteTask($currentTask),
                    xdmp:trace('pharaoh',fn:concat("Task Deleted: ", $task-id, " File Not Found"))
                )
            )
        )
    return ()
) else ()
