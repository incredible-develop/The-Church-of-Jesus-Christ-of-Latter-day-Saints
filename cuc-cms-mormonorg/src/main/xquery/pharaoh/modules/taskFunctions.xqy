xquery version "1.0-ml";

module namespace taskFunctions = "http://lds.org/code/shared/lds-edit/task-functions";

import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../modules/utility-functions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../modules/ldse-core.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../modules/ldse-settings.xqy";

declare namespace task = "http://marklogic.com/xdmp/group";
declare option xdmp:mapping "true";

declare variable $config as element(configuration) := getConfig();
declare variable $group as xs:unsignedLong := getGroup($config, "Default");

declare function getConfig() as element(configuration){
    admin:get-configuration()
};

declare function getGroup($configParam as element(configuration), $name as xs:string) as xs:unsignedLong {
    admin:group-get-id($configParam, $name)
};

declare function saveConfig($newConfig as element(configuration)) as empty-sequence() {
    admin:save-configuration($newConfig)
};

declare function getScheduledTasks() as element(task:scheduled-task)* {
    admin:group-get-scheduled-tasks($config, $group)
};

(:~  
    Used to create a new task.  If the task is for today it will schedule it.  Otherwise
    it will add it to a queue and the taskmaster will schedule it the night before. 
~:)
declare function newTask(
    $task-site as xs:string,
    $task-path as xs:string, 
    $task-root as xs:string, 
    $task-start as xs:dateTime, 
    $task-database as xs:unsignedLong,
    $task-modules as xs:unsignedLong,
    $task-user as xs:unsignedLong,
    $task-host as xs:unsignedLong?, 
    $task-data as element(task-data)?,
    $task-name as xs:string?,
    $task-id as xs:string) as xs:boolean? 
{
    xdmp:trace('pharaoh','New Task'),
    queueTask($task-site, $task-path, $task-root, $task-start, $task-database, $task-modules, $task-user, $task-host, $task-data, $task-name, $task-id),
    if (xs:date($task-start) eq fn:current-date()) then (
        scheduleTask($task-site, $task-path, $task-root, $task-start, $task-database, $task-modules, $task-user, $task-host)
    ) else ()
};

(:~  
    Queues task by inserting a xml doc containing the vital data to schedule the task at a future time.
    Also is able to store any other additional data you need.
    <task-date>
        Any Thing you want here
    </task-date>
~:)
declare function queueTask(
    $task-site as xs:string, 
    $task-path as xs:string, 
    $task-root as xs:string, 
    $task-start as xs:dateTime, 
    $task-database as xs:unsignedLong,
    $task-modules as xs:unsignedLong, 
    $task-user as xs:unsignedLong, 
    $task-host as xs:unsignedLong?, 
    $task-data as element(task-data)?, 
    $task-name as xs:string?, 
    $task-id as xs:string) as item()* 
{
    let $newTask as element(scheduled-task) :=
        element scheduled-task {
            attribute id {$task-id},
            attribute scheduled { 'false' },
            element task-name {$task-name},
            $task-data,
            element task-created { fn:current-dateTime() },
            element task-dateTime {$task-start},
            element task-path {$task-path},
            element task-root {$task-root},
            element task-database {$task-database},
            element task-modules {$task-modules},
            element task-user {$task-user},
            element task-host {$task-host},
            element task-site {$task-site}
        }

    let $existingTask as element(scheduled-task)? := getQueuedTaskById($task-id)
    
    let $dbPath as xs:string := 
        if (fn:exists($existingTask)) then (
            xdmp:node-uri($existingTask)
        ) else (
            core:build-db-path("", "", $task-id, $newTask, () )
        )
    let $trace as empty-sequence() := xdmp:trace('pharaoh', fn:concat('Queued Task ', $task-id, ' For: ', $task-start))
    return (
        core:save-file($dbPath, $newTask, () )
    )
    
};


(:~  
    Returns a queued task by id
~:)
declare function getQueuedTaskById($id as xs:string) as element(scheduled-task)? {
    cts:search(/scheduled-task,
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-value-query(xs:QName('scheduled-task'), xs:QName('id'), $id, 'exact')
        ))
    )
};

(:~  
    Schedules at one time task to Marklogic's task server
    Returns true if the task was scheduled to the tasked server.
    number 1 reason it would return an empty is if the task was already scheduled.
~:)
declare function scheduleTask(
    $task-site as xs:string, 
    $task-path as xs:string, 
    $task-root as xs:string, 
    $task-start as xs:dateTime, 
    $task-database as xs:unsignedLong,
    $task-modules as xs:unsignedLong, 
    $task-user as xs:unsignedLong, 
    $task-host as xs:unsignedLong?) as xs:boolean? 
{
    let $newTask as element(task:scheduled-task) := admin:group-one-time-scheduled-task($task-path, $task-root, $task-start, $task-database, $task-modules, $task-user, $task-host)
    where fn:not(taskExists($newTask))
    return (
        let $trace as empty-sequence() := xdmp:trace('pharaoh', fn:concat('Scheduled Task ', $task-path, ' For: ', $task-start))   
        let $addTask as element(configuration) := admin:group-add-scheduled-task($config, $group, $newTask)
        let $save as empty-sequence() := saveConfig($addTask)
        return (fn:true())
    )
};

(:~  
    Returns true or false
    Checks if a identical task already exists in marklogics task server.
~:)
declare function taskExists($newTask as element(task:scheduled-task)) as xs:boolean {
    let $scheduledTasks as element(task:scheduled-task)* := getScheduledTasks()
    return (
        fn:exists(
            $scheduledTasks[
                task:task-start-date eq $newTask/task:task-start-date and
                task:task-start-time eq $newTask/task:task-start-time and
                task:task-type eq $newTask/task:task-type and
                task:task-path eq $newTask/task:task-path and
                task:task-root eq $newTask/task:task-root and
                task:task-database eq $newTask/task:task-database and
                task:task-modules eq $newTask/task:task-modules and
                task:task-user eq $newTask/task:task-user and
                task:task-host eq $newTask/task:task-host
            ]
        )
    )
};

(:~  
    Returns all tasks from the queue that are for tomorrow
    12:00AM to 11:59:59PM
~:)
declare function getTomorrowsTasks() as element(scheduled-task)* {
    let $tomorrowStart as xs:dateTime := xs:dateTime(fn:current-date() + xs:dayTimeDuration("P1D"))
    let $tomorrowEnd as xs:dateTime := xs:dateTime($tomorrowStart + xs:dayTimeDuration("PT24H"))
    return (
        cts:search(/scheduled-task[xs:dateTime(task-dateTime) < $tomorrowEnd and
                                   xs:dateTime(task-dateTime) >= $tomorrowStart],
            core:get-filter-query()
        )
    )
};

(:~  
    Executed by the nightly taskmaster
    schedules tomorrows tasks and deletes old tasks
~:)
declare function taskMaster() as empty-sequence() {
   let $tomorrowTasks as element(scheduled-task)* := getTomorrowsTasks()
   let $schedule as item()* := 
        for $task as element(scheduled-task) in $tomorrowTasks
        return (
            scheduleTask(
                xs:string($task/task-path),
                xs:string($task/task-root),
                xs:dateTime(xs:string($task/task-dateTime)),
                xs:string($task/task-database),
                xs:string($task/task-modules),
                xs:string($task/task-user),
                xs:string($task/task-host),
                xs:string($task/task-site)
            ),
            updateQueuedTask($task)
        )
   let $deleteOld as element(task:scheduled-task)* := deleteOldTasks()
   return ()
};

(:~  
    Returns all tasks scheduled now
~:)
declare function getNowTasks() as element(scheduled-task)* {
    let $now as xs:dateTime := roundMin(fn:current-dateTime())
    return (
        cts:search(/scheduled-task[xs:dateTime(task-dateTime) <= $now],
            cts:and-query((
                core:get-filter-query(),
                cts:not-query( cts:element-attribute-value-query(xs:QName('scheduled-task'), xs:QName('scheduled'), 'true', 'exact') )
            ))
        )
    )
};

(:~  
    Rounds down a dateTime to the nearest minute
~:)
declare function roundMin($dateTime as xs:dateTime) as xs:dateTime {
    $dateTime + xs:dayTimeDuration(fn:concat("-PT", fn:seconds-from-dateTime($dateTime), "S"))
};

(:~  
    Executed by the minutely taskmaster
    schedules now tasks
~:)
declare function minTaskMaster() as empty-sequence() {
   let $nowTasks as element(scheduled-task)* := getNowTasks()
   let $trace as empty-sequence() := xdmp:trace('pharaoh', 'Task Master Executed')  
   let $mode as xs:string := settings:get-pharaoh-mode()
   let $port as xs:integer? := settings:get-mode-port($mode)
   let $spawn as item()* := 
        for $task as element(scheduled-task) in $nowTasks
        let $path as xs:string := $task/task-path
        let $database as xs:string := $task/task-database
        let $modules as xs:string := $task/task-modules
        let $root as xs:string := $task/task-root
        let $user as xs:string := $task/task-user
        let $task-id as xs:string := $task/@id
        let $site as xs:string := $task/task-site
        let $trace as empty-sequence() := xdmp:trace('pharaoh', fn:concat('Spawned Task ', $task-id))  
        let $vars as item()* := (
            xs:QName('task-id'), $task-id, 
            xs:QName('mode'), $mode,
            xs:QName('port'), $port,
            xs:QName('site'), $site
        )
        let $mark-scheduled as item()* := updateQueuedTask($task)
        return (
            xdmp:spawn($path, $vars,
                <options xmlns="xdmp:eval">
                    <user-id>{$user}</user-id>
                </options>)
        )
   return ()
};

(:~  
    Updates the scheduled attribute on queued tasks marking them scheduled
~:)
declare function updateQueuedTask($task as element(scheduled-task)) as item()* {
    let $newTask as element(scheduled-task) :=
        element scheduled-task {
            $task/@*[fn:not(fn:local-name(.) eq 'scheduled')],
            attribute scheduled {'true'},
            $task/*
        }
    return (
        core:save-file(xdmp:node-uri($task), $newTask, () )
    )
};

(:~  
    Deletes a queued task
~:)
declare function deleteTask($task as element(scheduled-task)) as item()* {
    core:delete-file(xdmp:node-uri($task), $task, ())
};

(:~  
    Addes a task-failed element,
    If your task should call this function if it fails to preform the desired action.
~:)
declare function taskFailed($task as element(scheduled-task)) as item()* {
    let $newTask as element(scheduled-task) :=
        element scheduled-task {
            $task/@*[fn:not(fn:local-name(.) eq 'scheduled')],
            attribute scheduled {'false'},
            element task-failed {
                fn:current-dateTime()
            },
            $task/*
        }
    let $trace as empty-sequence() := xdmp:trace('pharaoh', fn:concat('Task FAILED: ', $task/@id))
    return (
        core:save-file(xdmp:node-uri($task), $newTask, () )
    )
};

(:~  
    Deletes the given scheduled tasks from marklogic's task server
~:)
declare function deleteTasks($tasks as element(task:scheduled-task)*) as empty-sequence() {
    saveConfig(admin:group-delete-scheduled-task($config, $group, $tasks))
};

(:~  
    Deletes all one time scheduled tasks from marklogics's task server
    Old is considered any task 5mins in the past or older.
~:)
declare function deleteOldTasks() as element(task:scheduled-task)* {
    let $scheduledTasks as element(task:scheduled-task)* := getScheduledTasks()
    let $curDate as xs:date := fn:current-date()
    let $curTime as xs:time := fn:current-time() + xs:dayTimeDuration("-PT5M")
    let $oldTasks as element(task:scheduled-task)* := 
        $scheduledTasks[
            task:task-start-date < $curDate or
            (
                task:task-start-date = $curDate and
                task:task-start-time <= $curTime
            ) and
            task:task-type eq "once"
         ]        
    let $delete as empty-sequence() := deleteTasks($oldTasks)
    return $oldTasks
};

declare function queue-action-task(
    $action as xs:string, (: ldse:publish, ldse:unpublish, ldse:delete ...:)
    $dateTime as xs:dateTime, 
    $file-id as xs:string, 
    $locale as xs:string,
    $uri as xs:string,
    $ice-user as xs:string) as item()* 
{
    let $task-path as xs:string := "/pharaoh/action-task.xqy"
    let $task-root as xs:string := xdmp:modules-root()
    let $task-start as xs:dateTime := $dateTime
    let $task-database as xs:unsignedLong := xdmp:database()
    let $task-modules as xs:unsignedLong := xdmp:modules-database()
    let $task-user as xs:integer := xdmp:user(xdmp:get-current-user())
    let $task-site as xs:string := $core:site
    let $task-host as xs:unsignedLong? := () (: admin:host-get-id($config, xdmp:host-name()) :)
    
    let $task-data as element(task-data) := 
            element task-data {
                element action {$action},
                element file-id {$file-id},
                element file-uri {$uri},
                element file-locale {$locale},
                element ice-user {$ice-user}
            }
    let $task-name as xs:string := fn:concat('scheduled-',$action)
    return (
        queueTask($task-site, $task-path, $task-root, $task-start, $task-database, $task-modules, $task-user, $task-host, $task-data, $task-name, fn:concat($action, '-',$file-id))
    )
};
