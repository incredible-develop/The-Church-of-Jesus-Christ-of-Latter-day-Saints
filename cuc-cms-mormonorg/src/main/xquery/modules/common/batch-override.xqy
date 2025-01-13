xquery version "1.0-ml";

module namespace batch = "http://lds.org/code/common/process/batch-processing-custom";

import module namespace util = "http://lds.org/code/shared/common/util" at "/shared/common/util/util.xqy";

declare namespace qm = "http://marklogic.com/xdmp/query-meters";
declare namespace ss = "http://marklogic.com/xdmp/status/server";

(:~ The default options for batch processing :)
declare variable $DEFAULT_OPTIONS as element(batch:options) :=
    <options xmlns="http://lds.org/code/common/process/batch-processing-custom">
        <type>spawn</type>
        <apply-type>same-transaction</apply-type>
        <script>/modules/common/processBatch-override.xqy</script>
        <chunk-size>200</chunk-size>
        <batch-size>10000</batch-size>
        <database>{ xdmp:database-name(xdmp:database()) }</database>
        <modules>
        { 
            if (xdmp:modules-database() eq 0) then
                "file system"
            else
                xdmp:database-name(xdmp:modules-database())
        }
        </modules>
        <root>{ xdmp:modules-root() }</root>
        <user>{ xdmp:get-current-user() }</user>
        <meters>false</meters>
        <pass-options>false</pass-options>
        <pass-documents>false</pass-documents>
    </options>;

(:~
    Initiates the batch processing.  This function will use the supplied options
    to determine how many tasks to spawn to the Task Server.  As the processing
    engine is processing the supplied URIs it will call the supplied function
    against each of those URIs.
    
    @param $files A sequence of URIs to process in batches
    @param $processor The function to use to process each URI
    @param $options The batch processing options
:)
declare function batch:initiate(
    $files as xs:string*,
    $names as xs:string*,
    $directory as xs:string,
    $processor as xdmp:function,
    $options as element(batch:options)?
) as element(batch:batch-results)? {
    let $options := util:mergeOptions($DEFAULT_OPTIONS, $options)
    let $requestId as xs:unsignedLong? := 
        if ($options/batch:id gt 0) then
            $options/batch:id
        else 
            xdmp:request()
    let $total := fn:count($files)
    let $waitForResults as xs:boolean := xs:boolean(($options/batch:result, "false")[1])    
    let $chunkSize := xs:integer($options/batch:chunk-size)
    let $batchNumber as xs:integer? := $options/batch:batch-number
    let $batchChunks as xs:integer? := $options/batch:batch-chunks
    let $chunks :=
        if ($total gt $chunkSize) then
            fn:ceiling($total div $chunkSize)
        else 
            1
    
    let $debug := (
        xdmp:trace("batch-info", fn:concat("######## Starting batch processing (", $requestId, ") ########")),
        xdmp:trace("batch-info", "    #### Process parameters:"),
        xdmp:trace("batch-info", fn:concat("      ## Number of items: ", $total)),
        xdmp:trace("batch-info", fn:concat("      ## Number or chunks: ", $chunks)),
        if (fn:exists($batchNumber)) then (
            xdmp:trace("batch-info", fn:concat("      ## Batch set number: ", $batchNumber)),     
            xdmp:trace("batch-info", fn:concat("      ## Total number of batch sets: ", $batchChunks))   
        ) else (),
        xdmp:trace("batch-info", fn:concat("      ## Processor function: ", xdmp:quote($processor))),             
        xdmp:trace("batch-debug", "#### Batch options:"),
        for $option in $options/element()
        return
            xdmp:trace("batch-debug", fn:concat(fn:local-name($option), ": ", fn:string-join($option/text()|$option/@*,' ')))     
    ) 
    
    let $save := batch:saveProcessingInfo($files, $processor, $options)
    
    (: Process each chunk in a separate trasaction to avoid memory problems :)          
    let $results as item()* := ( 
        if ($total gt 0) then (    
            for $chunk at $index in 1 to $chunks
            let $begin := (($chunk - 1) * $chunkSize) + 1
            let $end := 
                if ($chunk * $chunkSize gt $total) then 
                    $total
                else
                    $chunk * $chunkSize       
            let $debug := 
                xdmp:trace(
                    "batch-info", 
                    fn:concat(
                        "    #### Initiating batch for items [", $begin, " to ", $end, "]",
                        if (fn:exists($batchChunks)) then
                            " for batch set"
                        else (),
                        if (fn:exists($batchNumber)) then
                            fn:concat(" ", $batchNumber, "/", $batchChunks)
                        else (),
                        " (", $requestId, ") ####" 
                    )
                ) 
            let $processData := 
                element process-data {
                    element id { $requestId },
                    element chunk { $index },
                    element chunks { $chunks },
                    element chunkSize { $chunkSize },
                    element total { $total }
                }        
            return
                batch:spawn($processData, $files[$begin to $end], $names[$begin to $end], $directory, $processor, $options)                    
        ) else ()
    )       
    let $debug := (
        xdmp:trace("batch-info", fn:concat("######## Batch processing initialization complete (", $requestId, ") ########")),
        if ($options/batch:meters eq "true") then
            let $qm as element(qm:query-meters) := xdmp:query-meters()
            return (
                xdmp:trace("batch-info", fn:concat("    - elapsed: ", xdmp:elapsed-time(), "; etc hits: ", $qm/qm:expanded-tree-cache-hits, "; etc misses: ", $qm/qm:expanded-tree-cache-misses, "; ctc hits: ", $qm/qm:compressed-tree-cache-hits, "; ctc misses: ", $qm/qm:compressed-tree-cache-misses, "; list hits: ", $qm/qm:list-cache-hits, "; list misses: ", $qm/qm:list-cache-misses)),
                for $host as element(qm:host) in $qm/qm:hosts/qm:host
                return
                    xdmp:trace("batch-info", fn:concat("    - ", $host/qm:host-name, ": ", $host/qm:round-trip-count, "/", $host/qm:round-trip-time))
            )
        else ()        
    )
    return 
        if ($waitForResults) then (
            (: 
                - If ML version < 5 then do a loop and sleep between each iteratio?  
                - Check for the estimate the number of batch-result files in the database with the current batch id?  
                - When the number equals the total then stop the loop, return the files and delete them?
                - Store the files in a directory with the batch id in the current database so we can do a directory-delete?
            :)
            <batch-results xmlns="http://lds.org/code/shared/common/process/batch-processing">{
                attribute id { $requestId },
                attribute processed { fn:count($results) },
                attribute failed { fn:count($results[@status eq "failure"]) },
                attribute elapsed { xdmp:elapsed-time() },
                $results
            }</batch-results>
        ) else ()
        
};


declare function batch:spawn(
    $processData as element(process-data),
    $files as xs:string*,
    $names as xs:string*,
    $directory as xs:string,
    $processor as xdmp:function,
    $options as element(batch:options)?
) as item()* {
    let $batchNumber as xs:integer? := $options/batch:batch-number
    let $script as xs:string? := $options/batch:script
    let $database as xs:string? := $options/batch:database
    let $modules as xs:string? := $options/batch:modules
    let $root as xs:string? := $options/batch:root
    let $user as xs:string? := $options/batch:user
    let $type as xs:string? := $options/batch:type
    let $transactionMode as xs:string? := $options/batch:transaction-mode
    let $forestId as xs:unsignedLong? := $options/batch:forest-id
    let $waitForResults as xs:boolean := xs:boolean(($options/batch:result, "false")[1])    
    let $params := (
        xs:QName("processData"), $processData,
        xs:QName("files"), batch:paramUris($files),
        xs:QName("names"), batch:paramNames($names),
        xs:QName("directory"), batch:directory($directory),
        xs:QName("processor"), $processor,
        xs:QName("options"), $options
    )
    let $options := 
        <options xmlns="xdmp:eval">     
            <database>{ 
                if ($forestId gt 0) then
                    $forestId
                else
                    xdmp:database($database) 
            }</database>
            <modules>
            {
                if ($modules eq "file system") then
                    0
                else                 
                    xdmp:database($modules) 
            }
            </modules>
            <root>{ $root }</root>
            <user-id>{ xdmp:user($user) }</user-id>
            {
                (: Make sure a valid mode is passed :)
                if ($transactionMode = ("query", "auto", "update") and $type eq "invoke" and xdmp:version() ge "5.0") then
                    <transaction-mode>{ $transactionMode }</transaction-mode>
                else (
                    (: Don't have a default mode - just in case it may break something :)
                )
            }
            {
                (: Make sure a valid mode is passed :)
                if ($waitForResults and $type eq "spawn" and xdmp:version() ge "5.0" and fn:empty($batchNumber)) then (
                    <result>{ fn:true() }</result>
                ) else (
                    (: Don't have a default mode - just in case it may break something :)
                )
            }
        </options>
    let $result as item()* :=         
        if ($type eq "invoke") then
            xdmp:invoke($script, $params, $options)
        else
            xdmp:spawn($script, $params, $options)
    return
        $result
};

declare function batch:paramUris($files as xs:string*) as element(batch:files) {
    element batch:files {
        for $file in $files
        return
            element batch:file {
                $file
            }
    }
};

declare function batch:paramNames($names as xs:string*) as element(batch:names) {
    element batch:names {
        for $name in $names
        return
            element batch:name {
                $name
            }
    }
};

declare function batch:directory($directory as xs:string) as element(batch:directory) {
    element batch:directory {
        $directory
    }
};

declare function batch:saveProcessingInfo($uris as xs:string*, $processor as xdmp:function, $options as element(batch:options)?) as empty-sequence() {
    let $infoUri := fn:data($options/batch:info/@uri)
    return
        if ($infoUri) then
            let $processInfo :=
                element batch-processing-info {
                    attribute process-time { fn:current-dateTime() },
                    element document-count { fn:count($uris) },
                    element processor { $processor },
                    element additional-info { $options/batch:info/node() },
                    element documents-to-process {
                        for $uri in $uris
                        return
                            element document {
                                attribute uri { $uri }
                            }                
                    }
                }
            return
                xdmp:document-insert(fn:concat($infoUri, "batch-processing-info.xml"), $processInfo)
        else ()
};