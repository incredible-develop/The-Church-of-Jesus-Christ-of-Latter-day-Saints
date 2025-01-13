xquery version "1.0-ml";

module namespace enrich = "http://lds.org/code/shared/lds-edit/enrich";

import module namespace mem = "http://lds.org/code/shared/common/memory-update" at "/shared/common/util/inMemoryUpdate.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "../modules/ldse-meta.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../modules/utility-functions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../modules/ldse-settings.xqy";
import module namespace fj = "http://marklogic.com/json" at "../modules/fasterjson.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../modules/ldse-core.xqy";
import module namespace document = "http://lds.org/code/shared/lds-edit/document-functions" at "../modules/document-functions.xqy";

(: ENRICH R&D:)

declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace html = "http://www.w3.org/1999/html";
declare namespace xhtml = "http://www.w3.org/1999/xhtml";
declare namespace zip = "xdmp:zip";

declare option xdmp:mapping "true";

declare variable $enrich-server as xs:string := $settings:enrich-server;

declare function enrich:get-enrich-data($file as element(), $update as xs:boolean) as element(enrich) {
    let $threshold as xs:double := xs:double(0.05)
    let $iterations as xs:int := 50
    let $payload as xs:string :=
        xdmp:quote(
            <enrich>
                <file>{$file}</file>
                {(: <text xml:lang="{$lang}">{$text}</text> :) }
                <threshold>{$threshold}</threshold>
                <iterations>{$iterations}</iterations>
                <remove-stop-words>true</remove-stop-words>
                <remove-noise-words>true</remove-noise-words>
            </enrich>
        )
    let $url as xs:string := fn:concat( $enrich-server, '/v1/enrich')  
    let $response as item()* := 
        try {
            util:http-post($url,
             <options xmlns="xdmp:http">
               <data>{$payload}</data>
               <headers>
                 <content-type>text/xml</content-type>
               </headers>
             </options>)
         } catch ($e) {
            
            xdmp:log("ERROR: failed to post to enrich server.")
         }
         
    let $response-data as item()? := $response[2]/*  
    let $ldse-meta as element(ldse:ldse-meta) := ldsemeta:get-ldse-meta($file)
    let $current-enrich as element(ldse:enrich)? := $ldse-meta/ldse:enrich
    
    let $enrich as element(enrich) := 
        typeswitch ($response-data)
        case element(enrich) return (
            let $updated as element(enrich) := update-enrich($current-enrich, $response-data)   
            let $save as item()* := 
                if ($update) then (
                    let $children as item()* := $updated/* except $updated/text
                    let $ldse-enrich as element(ldse:enrich) := 
                        <enrich xmlns="http://lds.org/code/lds-edit">{
                            util:renamespace($children, "http://lds.org/code/lds-edit")
                        }</enrich>
                    return (
                        if ( fn:exists($current-enrich) ) then (
                             document:document-replace($current-enrich, $ldse-enrich)
                        ) else (
                            let $new-mata as element(ldse:ldse-meta) := mem:node-insert-child(util:clone($ldse-meta), $ldse-enrich)
                            return (
                                document:document-replace($ldse-meta, $new-mata)
                            )
                        )
                    )
                ) else ()
            return (
                $updated
            )
        )
        default return (
            xdmp:log("ERROR: didn't get desired response from enrich server."),
            xdmp:log($url),
            xdmp:log($response),
            (util:renamespace($current-enrich, ""), <enrich></enrich>)[1]
        ) 
    return (
        $enrich 
    )   
};

declare function enrich:update-enrich($current-enrich as element()?, $new-enrich as element(enrich) ) as element(enrich) {
    let $term-active-map as map:map := map:map()
    let $puts as empty-sequence() := 
        for $t as element() in $current-enrich/*:terms/*
        return (
            map:put($term-active-map, xs:string($t), xs:string($t/@active))
        )
    let $entity-active-map as map:map := map:map()
    let $puts as empty-sequence() := 
        for $e as element() in $current-enrich/*:entities/*
        return (
            map:put($entity-active-map, xs:string($e), xs:string($e/@active))
        )
    let $related-active-map as map:map:= map:map()
    let $puts as empty-sequence() := 
        for $m as element() in $current-enrich/ldse:related/*
        return (
            map:put($related-active-map, fn:concat($m/@url, $m/@title), xs:string($m/@active))
        )
    return (
        <enrich>
            { $new-enrich/text }
            <terms>{
                for $new-term as element() in $new-enrich/terms/term[ 1 to 25]
                let $is-active as item() := (map:get($term-active-map,$new-term), fn:true())[1]
                return (
                    element term {
                        $new-term/@* except $new-term/@active,
                        attribute active {$is-active},
                        $new-term/node()
                    } 
                )
            }</terms>
            <entities>{
                for $new-entity as element() in $new-enrich/entities/*
                let $is-active as item() := (map:get($entity-active-map,$new-entity), fn:true())[1]
                return (
                    element { fn:node-name($new-entity) } {
                        $new-entity/@* except $new-entity/@active,
                        attribute active {$is-active},
                        $new-entity/node()
                    }
                )
            }</entities>
            <related>{
                for $new-match as element() in $new-enrich/related/match
                let $is-active as item() := (map:get($related-active-map, fn:concat($new-match/@url, $new-match/@title)), fn:false())[1]
                return (
                    element match {
                        $new-match/@* except $new-match/@active,
                        attribute active {$is-active},
                        $new-match/node()
                    }
                )
            }</related>
            { $new-enrich/phrases, $new-enrich/concepts  }
        </enrich>
    )
};


declare function enrich:update-actives(
    $enrich as element(ldse:enrich), 
    $keyword-indexes as xs:int*, 
    $org-indexes as xs:int*, 
    $role-indexes as xs:int*,
    $location-indexes as xs:int*,  
    $person-indexes as xs:int*, 
    $related-indexes as xs:int*
) as element(ldse:enrich) {
        <enrich xmlns="http://lds.org/code/lds-edit">
            <terms>{
                for $term as element(ldse:term) at $i in $enrich/ldse:terms/ldse:term
                let $is-active as xs:boolean := $i = $keyword-indexes 
                return (
                    element term {
                        $term/@* except $term/@active,
                        attribute active {$is-active},
                        $term/node()
                    } 
                )
            }</terms>
            <entities>{
                for $org as element(ldse:organization-entity) at $i in $enrich/ldse:entities/ldse:organization-entity
                let $is-active as xs:boolean :=  $i = $org-indexes 
                return (
                    element organization-entity {
                        $org/@* except $org/@active,
                        attribute active {$is-active},
                        $org/node()
                    }
                ),
                for $person as element(ldse:person-entity) at $i in $enrich/ldse:entities/ldse:person-entity
                let $is-active as xs:boolean :=  $i = $person-indexes 
                return (
                    element person-entity {
                        $person/@* except $person/@active,
                        attribute active {$is-active},
                        $person/node()
                    }
                ),
                for $role as element(ldse:role-entity) at $i in $enrich/ldse:entities/ldse:role-entity
                let $is-active as xs:boolean :=  $i = $role-indexes 
                return (
                    element role-entity {
                        $role/@* except $role/@active,
                        attribute active {$is-active},
                        $role/node()
                    }
                ),
                for $location as element(ldse:location-entity) at $i in $enrich/ldse:entities/ldse:location-entity
                let $is-active as xs:boolean :=  $i = $location-indexes 
                return (
                    element location-entity {
                        $location/@* except $location/@active,
                        attribute active {$is-active},
                        $location/node()
                    }
                )
            }</entities>
            <related>{
                for $match as element(ldse:match) at $i in $enrich/ldse:related/ldse:match
                let $is-active as xs:boolean := $i = $related-indexes
                return (
                    element match {
                        $match/@* except $match/@active,
                        attribute active {$is-active},
                        $match/node()
                    }
                )
            }</related>
            { $enrich/ldse:phrases, $enrich/ldse:concepts }
        </enrich>
};

declare function enrich:sync-needed() as xs:boolean {
    let $service-revision as xs:unsignedInt? := enrich:get-service-revision()
    
    let $current-revision as xs:unsignedInt := enrich:get-revision()
    return (
        xdmp:trace('enrich', fn:concat("Sites revision: ", $current-revision)),
        fn:exists($service-revision) and $service-revision = $current-revision
    )
};

declare function enrich:get-service-revision() as xs:unsignedInt? {
    let $url as xs:string := fn:concat( $enrich-server, '/v1/revision') 
    let $trace as item()* :=  xdmp:trace('enrich', fn:concat("Posting to: ", $url))
    let $response as item()* := 
        try {
            util:http-get($url,
             <options xmlns="xdmp:http">
               <timeout>2</timeout>
               <headers>
                 <content-type>text/xml</content-type>
               </headers>
             </options>)
         } catch ($e) {
            xdmp:trace('enrich', "ERROR: failed to get enrich service revision")
         }
     return (
        if ( $response[2] castable as xs:unsignedInt ) then (
            xs:unsignedInt($response[2]),
            xdmp:trace('enrich', fn:concat("Service revision: ", $response[2]))
        ) else (
            xdmp:trace('enrich', $response)
        )
     )
};

declare function enrich:get-revision() as xs:unsignedInt {
    (
        cts:element-values(xs:QName('enrich:revision'), (), ("any","descending", "limit=1"), core:get-filter-query() ),
        0
    )[1]
};

declare function enrich:get-uris-by-hash($hashes as xs:string*) as map:map {
    cts:uris("/", ("any", "map"),
        cts:and-query((
               cts:directory-query('/enrich/content/meta/', 'infinity'),
               cts:properties-query( cts:element-value-query(xs:QName('enrich:hash'), $hashes, 'exact') )
        ))
    )
};


declare function enrich:sync-meta-data() as item()* {
    let $meta-hash-map as map:map := cts:element-values(xs:QName('enrich:hash'), (), ("any","map"), core:get-filter-query() )
    
    let $payload as xs:string := xdmp:quote( <map>{ $meta-hash-map }</map> )
    let $url as xs:string := fn:concat( $enrich-server, '/v1/meta-data-sync')  
    
    let $trace as item()* := xdmp:trace('enrich', fn:concat('Posting to: ', $url) )
    
    let $response as item()* := 
        try {
            util:http-post($url,
             <options xmlns="xdmp:http">
               <data>{$payload}</data>
               <headers>
                 <content-type>application/octet-stream</content-type>
               </headers>
               <format xmlns="xdmp:document-get">binary</format>
             </options>)
         } catch ($e) {             
            xdmp:log("ERROR: failed to post to enrich server.")
         }
    
    let $zip as binary()? := 
        typeswitch ($response[2]/node())
        case binary() return ( $response[2]/node() )
        default return ()
        
    let $options as element() := <options xmlns="xdmp:zip-get"><format>xml</format></options>
    let $manifest as element(zip:parts)* := 
        try { 
            xdmp:zip-manifest($zip)
        } catch ($e) {
            ()
        }
    
    return (
        if ( fn:exists($manifest) ) then (
            let $trace as item()* := xdmp:trace('enrich', 'Extracting Zip' )
            let $zip-info as xs:string := "ZIP-INFO/manifest-map.xml"

            let $manifest-xml as element(manifest-map) := xdmp:zip-get($zip,  $zip-info, $options)/*[1]
            let $manifest-map as map:map := map:map($manifest-xml/map:map)
            
            let $hashes-item as item()* := map:get($manifest-map, 'hashes')
            let $hashes as map:map := 
                typeswitch ( $hashes-item )
                case element(map:map) return map:map($hashes-item)
                default return ( $hashes-item )
                
            let $revisions-item as item()* := map:get($manifest-map, 'revisions')
            let $revisions as map:map := 
                typeswitch ( $revisions-item )
                case element(map:map) return map:map($revisions-item)
                default return ( $revisions-item )
                                
            let $deletes as xs:string* := map:get($manifest-map,'deletes')
            
            let $saved-map as map:map := map:map()
            
            let $extract as item()* :=
                for $part as element(zip:part) in $manifest/zip:part
                let $uri as xs:string := xs:string($part)
                where fn:not( $uri = $zip-info )
                return (
                    let $file as element() := xdmp:zip-get($zip, $uri, $options)/*[1]
                    let $new-file as element() := util:renamespace($file, "http://lds.org/code/shared/lds-edit/enrich")
                    let $id as xs:string := xdmp:diacritic-less($new-file/@key)
                    let $lang as xs:string := $new-file/@xml:lang
                    let $db-path as xs:string := core:build-db-path((), $lang, $id, $new-file, ())
                    
                    let $hash as item() := map:get($hashes, $uri)
                    let $revision as item() := map:get($revisions,$uri)
                    let $sets as item()* := (
                        xdmp:document-set-property($db-path, <revision xmlns="http://lds.org/code/shared/lds-edit/enrich">{ $revision }</revision>),
                        xdmp:document-set-property($db-path, <hash xmlns="http://lds.org/code/shared/lds-edit/enrich">{ $hash }</hash>)
                    )
                    
                    let $save as item()* := core:save-file($db-path, $new-file, ())
                    return (
                        xdmp:trace('enrich', fn:concat('Saved: ', $db-path)), 
                        map:put($saved-map,$db-path,$db-path)
                    )
                )
            
            let $delete-map as map:map :=  enrich:get-uris-by-hash($deletes) - $saved-map
                
            let $delete-uris as xs:string* := map:keys($delete-map)
            
            let $delete as item()* := 
                if (fn:exists($delete-uris)) then (
                    xdmp:document-delete($delete-uris),
                    for $uri as xs:string in $delete-uris
                    return (
                        xdmp:trace('enrich', fn:concat('Removed: ', $uri))
                    )
                ) else ()
                
            return (
                xdmp:trace('enrich', 'Sync Complete' ),
                "finished extracting zip"
            )
        ) else ( 
            xdmp:trace('enrich', 'Failed to recieve zip' ),
            "no-zip"
        )
    )
    
     
};


declare function enrich:enrichable-lang($locale as xs:string) as xs:boolean {
    let $lang as xs:string := util:get-lang-from-locale($locale)
    return (
        $lang = "eng" or
        xdmp:estimate(
            cts:search(/enrich:languages,
                cts:and-query((
                    core:get-filter-query(),
                    cts:element-value-query(xs:QName('enrich:lang'), $lang, 'exact')    
                ))
            )
        ) > 0
    )
};

declare variable $word-query-options as xs:string* := (
    "case-insensitive",
    "diacritic-insensitive",
    "punctuation-insensitive",
    "whitespace-insensitive",
    "unwildcarded"
);

declare variable $meta-cache as map:map := map:map();

declare variable $has-url as cts:query := cts:element-query(xs:QName('enrich:url'), cts:and-query(()));

declare function enrich:get-meta-data($type as xs:string, $term as xs:string, $lang as xs:string) as element()? {
    let $key as xs:string := fn:concat($type, ':', $term)
    let $data as item()? := map:get($meta-cache,$key)
    let $word-query-options as xs:string* := ( $word-query-options , fn:concat( 'lang=', $lang ) )
    where fn:not( $data = "false" )
    return (
        if ( fn:exists($data) ) then (
            $data
        ) else (
            let $found as element()? :=
                if ($type = "keyword") then (
                    cts:search(/enrich:keyword,
                        cts:and-query((
                            cts:element-word-query(xs:QName('enrich:name'), $term, $word-query-options),
                            $has-url
                        ))
                    )[1]
                ) else if ( $type = "organization" ) then (
                    cts:search(/enrich:organization,
                        cts:and-query((
                            cts:element-value-query(xs:QName('enrich:name'), $term, $word-query-options),
                            $has-url
                        ))
                    )[1]
                ) else if ( $type = "person" ) then (
                    cts:search(/enrich:person,
                        cts:and-query((
                            cts:element-value-query(xs:QName('enrich:name'), $term, $word-query-options),
                            $has-url
                        ))
                    )[1]
                ) else if ( $type = "role" ) then (
                    cts:search(/enrich:role,
                        cts:and-query((
                            cts:element-value-query(xs:QName('enrich:name'), $term, $word-query-options),
                            $has-url
                        ))
                    )[1]
                ) else if ( $type = "location" ) then (
                    cts:search(/enrich:location,
                        cts:and-query((
                            cts:element-value-query(xs:QName('enrich:name'), $term, $word-query-options),
                            $has-url
                        ))
                    )[1]
                ) else ()
            return (
                $found,
                map:put($meta-cache, $key, ($found, 'false')[1])
            )
        )
    )
};

declare function enrich:mark-up-text($node as node()*, $enrich as element(ldse:enrich)?, $lang as xs:string) as item()* {
    if ( fn:exists($enrich) ) then (
        let $limit as xs:int := enrich:link-limit($lang)
        let $items-to-mark as element()* := (
            for $keyword as xs:string in $enrich/ldse:terms/ldse:term[@active = "true"]
            where fn:empty( map:get($marked-cache, $keyword) )
            return (  enrich:get-meta-data('keyword', $keyword, $lang) ),
            for $organization as xs:string in $enrich/ldse:entities/ldse:organization-entity[@active = "true"]
            where fn:empty( map:get($marked-cache, $organization) )
            return ( enrich:get-meta-data('organization', $organization, $lang) ),
            for $role as xs:string in $enrich/ldse:entities/ldse:role-entity[@active = "true"]
            where fn:empty( map:get($marked-cache, $role) )
            return ( enrich:get-meta-data('role', $role, $lang) ),
            for $person as xs:string in $enrich/ldse:entities/ldse:person-entity[@active = "true"]
            where fn:empty( map:get($marked-cache, $person) )
            return ( enrich:get-meta-data('person', $person, $lang) ),
            for $location as xs:string in $enrich/ldse:entities/ldse:location-entity[@active = "true"]
            where fn:empty( map:get($marked-cache, $location) )
            return ( enrich:get-meta-data('location', $location, $lang) )
        )            
        let $ordered as element()* :=
            for $item as element() in $items-to-mark
            order by fn:string-length( $item/enrich:name ) descending
            return $item
        return (
            if ( fn:exists($ordered) ) then (
                enrich:mark-items($node, $lang, $ordered, $limit)
            ) else ( $node )
        )
    ) else ( $node )
};

declare variable $marked-cache as map:map := map:map();

declare function enrich:link-limit($lang as xs:string) as xs:int {
    let $languages as element(enrich:languages)* :=
        cts:search(/enrich:languages,
            cts:and-query((
                core:get-filter-query(),
                cts:element-value-query(xs:QName('enrich:lang'), $lang, 'exact')
            ))
        )
    let $links as xs:string* := $languages/enrich:lang[. = $lang and fn:exists(@links)]/@links[ fn:not( . = "") ]
    let $limit as xs:int := xs:int( ($links,  4)[1] )
    return $limit
};

declare function enrich:mark-items($node as node()*, $lang as xs:string, $items as element()*, $limit as xs:int) as item()* {
    if ( fn:exists( $items ) ) then (
        let $item as element() := $items[1]
        let $word-query-options as xs:string* := ( $word-query-options , fn:concat( 'lang=', $lang ) )
        let $term as xs:string := $item/enrich:name
        let $marked-node as item()* := 
            cts:highlight(
                $node,
                cts:word-query($term, $word-query-options),
                if ( fn:empty($cts:node/ancestor-or-self::*:a) and fn:count($cts:node/(ancestor-or-self::*:p|ancestor-or-self::*:div)[fn:last()]//*:a) < $limit ) then (
                    typeswitch ($item)
                    case element(enrich:keyword) return (
                            <a href="{$item/enrich:url}" class="no-link-style ldse-enrich-link">{ $cts:text }</a>
                    )
                    default return (
                        <span itemscope="">
                           { $item/@itemType }
                           <a itemprop="url" href="{$item/enrich:url}" class="no-link-style ldse-enrich-link"><span itemprop="name">{ $cts:text }</span></a>
                        </span>
                    ),
                    map:put($marked-cache, $term, fn:true()),
                    xdmp:set($cts:action,"skip")                    
                ) else ( $cts:text )
            )
        return (
            enrich:mark-items($marked-node, $lang, fn:subsequence($items, 2), $limit)
        )
    ) else ( $node  )
};
