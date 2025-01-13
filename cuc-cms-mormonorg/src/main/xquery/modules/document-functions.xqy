xquery version "1.0-ml";
(: File should be saved at "/custom/lds-edit/ldse-core.xqy" :)

module namespace document = "http://lds.org/code/shared/lds-edit/document-functions";

import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace mem = "http://lds.org/code/shared/common/memory-update" at "/shared/common/util/inMemoryUpdate.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare option xdmp:mapping "true";

declare variable $update-map as map:map := map:map();

declare function document:is-not-updated($uri as xs:string) as xs:boolean {
    fn:not(document:is-updated($uri))
};

declare function document:is-updated($uri as xs:string) as xs:boolean {
    map:get($update-map, $uri) or fn:false()
};

declare function document:updated($uri as xs:string) as empty-sequence() {
    map:put($update-map, $uri, fn:true())
};

(: 
    Note: You cannot lock and unlock a uri in the same transaction.  The unlock will throw 
    a NOTLOCKED exception.  In order to get around that, the lock and unlock calls must 
    be inside their own transactions.  To do this, the lock (and modification of the file) 
    should be wrapped with in an eval and then the unlock should be wrapped in a separate 
    eval.
    If you don't want to use evals, a workaround is to set a timeout on the lock (e.g. 5 seconds 
    in the code below) and simply let the timeout expire to unlock a file. 
:)
declare function document:lock($nodes as node()*, $lockMessage as xs:string) as xs:boolean* {
    for $node as node() in $nodes
    let $uri as xs:string? := xdmp:node-uri($node)
    where $uri != ''
    return (
        try {
            if ( xdmp:document-locks($uri) ) then (
                fn:false()
            ) else (
                xdmp:lock-acquire(
                    $uri,
                    "exclusive",
                    "0",
                    $lockMessage,
                    xs:unsignedLong(5)
                ),
                fn:true()
            )
        } catch ($exception) {
            let $debug as item()* := xdmp:trace("documentLock", fn:concat("Error locking uri: ", $uri))
            let $debug as item()* := xdmp:trace("documentLock", $exception)
            return fn:false()
        }
    )
};

declare function unlock($nodes as node()*) as xs:boolean* {
    for $node as node() in $nodes
    let $uri as xs:string? := xdmp:node-uri($node)
    where $uri != ''
    return (
        try {
            xdmp:lock-release($uri),
            fn:true()
        } catch ($exception) {
            let $debug as item()* := xdmp:trace("documentLock", fn:concat("Error unlocking uri: ", $uri))
            let $debug as item()* := xdmp:trace("documentLock", $exception)
            return fn:false()
        }
    )
};

declare function document:document-replace(
    $existing as element()*, 
    $new as element()*
) as item() {
    let $uri as xs:string := xdmp:node-uri($existing)
    let $node as item() := mem:node-replace($existing, $new)
    let $node as item() :=
        typeswitch($node)
        case document-node() return $node/*
        default return $node
    let $save as item()* := document:document-insert($uri, $node, xdmp:document-get-collections($uri))
    return (
        $node,
        document:updated($uri)
    )
};

declare function document:document-insert(
    $uri as xs:string, 
    $doc as item()
) as item()* {
    document:document-insert($uri, $doc, xdmp:document-get-collections($uri), (), () )
};

declare function document:document-insert(
    $uri as xs:string, 
    $doc as item(), 
    $collections as xs:string*
) as item()* {
    document:document-insert($uri, $doc, $collections, (), () )
};

declare function document:document-insert(
    $uri as xs:string, 
    $doc as item(), 
    $collections as xs:string*, 
    $permissions as element(sec:permission)*,
    $quality as xs:int?
) as item()* {
    let $clean-uri as xs:string := document:clean-uri($uri)
    let $collections as xs:string* := if ( fn:empty($collections) ) then ( xdmp:default-collections() ) else ( $collections )
    (: Permissions required so + is the strong type :)
    let $permissions as element(sec:permission)* := (document:get-permissions($clean-uri), $permissions)
    
   
    return (
        xdmp:document-insert($clean-uri, $doc, $permissions, $collections, $quality),
        document:updated($clean-uri)
    )
};


(:~
    Deletes a document from the database.
    @param $uri The uri of the document to delete.
~:)
declare function document:document-delete($uri as xs:string) as xs:boolean {
    if ( cts:uris($uri, ('limit=1')) = $uri ) then (
        xdmp:document-delete($uri),
        document:updated($uri),
        fn:true()
    ) else (
        fn:false()
    )
};


declare function document:clean-uri(
    $uri as xs:string
) as xs:string? {
    fn:replace($uri, '[/\\]+', '/')
};

(:~ 
    For the given document path, finds the permissions that exist in the path (if document exists then the
    permissions of the document, if not the permissions of the nearest parent directory that exists).
    @param $uri The uri of the document 
    @return element(sec:permission)*
~:)
declare function document:get-permissions($uri as xs:string) as element(sec:permission)* {
    let $uri as xs:string? := document:find-permissions-uri($uri)
    where $uri != ""
    return (
        xdmp:document-get-permissions( $uri )
    )
};

declare function document:find-permissions-uri($uri as xs:string) as xs:string? {
    if ( fn:not($uri eq ("", "/")) ) then (
        if ( cts:uris($uri, ('limit=1')) = $uri ) then (
            $uri
        ) else (
            document:find-permissions-uri(fn:replace($uri, '^(.*)/.+$', '$1/'))
        )
    ) else ()
};