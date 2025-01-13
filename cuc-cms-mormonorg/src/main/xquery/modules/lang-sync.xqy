xquery version "1.0-ml";

module namespace ls = "http://lds.org/code/shared/lds-edit/lang-sync";

import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "ldse-core.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "ldse-meta.xqy";

declare namespace lsldse = "http://lds.org/code/lds-edit/lang-sync";
declare namespace its = "http://www.w3.org/2005/11/its";

declare variable $update-id-map as map:map := map:map();
declare variable $deleted-map as map:map := map:map();
declare variable $index-map as map:map := map:map();

declare function ls:get-lang-sync($id as xs:string) as element()? {
    cts:search(/lsldse:lang-sync,
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-value-query(xs:QName('lsldse:lang-sync'), xs:QName("id"), $id, 'exact')
        )),
        "unfiltered"
    )
};

declare function ls:update-lang-sync(
    $file as element()?,
    $newXml as element(),
    $id as xs:string
) as item()* {
    ls:update-lang-sync($file, $newXml, $id, ())
};

declare function ls:update-lang-sync(
    $file as element()?,
    $newXml as element(),
    $id as xs:string,
    $translation-info as element()*
) as item()* {
    let $new-updates as xs:string* := ls:get-update-ids($newXml)
    where fn:exists($new-updates)
    return (
(:        let $build-deletes as empty-sequence() := ls:find-deleted-nodes($newXml, $file):)
        let $lang-sync as element(lsldse:lang-sync)? := ls:get-lang-sync($id)
        let $newest-lang-id as xs:int := ( ls:get-oldest-lang-update($lang-sync//lsldse:lang)[1], 0 )[1]
        let $latest-id as xs:int := ( $lang-sync/lsldse:updates[1]/@version-id/xs:int(.), 0 )[1]
        let $update-latest-id as xs:boolean := $latest-id <= $newest-lang-id
        let $newest-id as xs:int := if ( $update-latest-id ) then ( $newest-lang-id + 1 ) else ( $latest-id )
        let $new-lang-sync as element(lsldse:lang-sync) :=
            if ( fn:exists($lang-sync) ) then (
                element { fn:QName('http://lds.org/code/lds-edit/lang-sync', fn:local-name($lang-sync)) } {
                    $lang-sync/@*,
                    ls:build-updates-section($lang-sync, $newest-id, $new-updates, $update-latest-id),
                    ls:get-delete-nodes($newXml, $file, $newest-id, $lang-sync, $update-latest-id),
                    ls:get-index-update-nodes($newXml, $file, $newest-id, $lang-sync, $update-latest-id),
                    $lang-sync/lsldse:langs
                }
            ) else (
                ls:create-lang-sync($file, $newXml, $id, $new-updates)
            )
        let $uri as xs:string? := ldsemeta:get-document-uri($newXml)
        let $db-path as xs:string := core:build-db-path($uri, $newXml/@locale, $id, $new-lang-sync, ())
        return (
            core:update-file('ldse:preview', $db-path, $new-lang-sync, $lang-sync)
        )
    )
};

declare function ls:build-updates-section(
    $lang-sync as element(lsldse:lang-sync),
    $latest-id as xs:int,
    $new-updates as xs:string*,
    $update-latest-id as xs:boolean
) as element(lsldse:updates)* {
    if ( $update-latest-id ) then ( 
        element { fn:QName('http://lds.org/code/lds-edit/lang-sync', 'updates') } {
            attribute version-id { $latest-id },
            ls:get-new-file-updates($new-updates)
        }
    ) else (),
    for $update-section as element() at $i in ( $lang-sync/lsldse:updates, <updates/> )
    let $new-updates as element(lsldse:updates)? := 
        element { fn:QName('http://lds.org/code/lds-edit/lang-sync', 'updates') } {
            $update-section/@*,
            ls:get-new-file-updates(($update-section/node()/fn:string(), $new-updates))
        }
    where fn:exists($new-updates/node())
    order by $update-section/@version-id/xs:int(.) descending
    return (
        $new-updates
    )
};

declare function ls:update-map-ids(
    $lang-sync as element(lsldse:lang-sync)?
) as empty-sequence() {
    for $update as xs:string in $lang-sync//lsldse:updates[1]/node()
    return (
        map:put($update-id-map, $update, $update)
    )
};

declare function ls:create-lang-sync(
    $file as element()?,
    $newXml as element(),
    $id as xs:string,
    $new-updates as xs:string*
) as element() {
    <lang-sync xmlns="http://lds.org/code/lds-edit/lang-sync" id="{$id}">{
        <updates version-id="1" xmlns="http://lds.org/code/lds-edit/lang-sync"> {
            ls:get-new-file-updates($new-updates)
        }</updates>
    }</lang-sync>
};

declare function ls:get-new-file-updates(
    $update-ids as xs:string*
) as element(lsldse:update)* {
    for $update as xs:string in fn:distinct-values($update-ids)
    where fn:not($update = map:keys($update-id-map))
    return (
        <update xmlns="http://lds.org/code/lds-edit/lang-sync">{ $update }</update>,
        map:put($update-id-map, $update, $update)
    )
};

declare function ls:get-new-index-updates(
    $update-ids as xs:string*
) as element(lsldse:update-index)* {
    for $update as xs:string in fn:distinct-values($update-ids)
    where fn:not($update = map:keys($index-map))
    return (
        <update-index xmlns="http://lds.org/code/lds-edit/lang-sync">{ $update }</update-index>,
        map:put($index-map, $update, $update)
    )
};

declare function ls:get-new-deletes(
    $update-ids as xs:string*
) as element(lsldse:delete)* {
    for $update as xs:string in fn:distinct-values($update-ids)
    where fn:not($update = map:keys($deleted-map))
    return (
        <delete xmlns="http://lds.org/code/lds-edit/lang-sync">{ $update }</delete>,
        map:put($deleted-map, $update, $update)
    )
};

declare function ls:get-update-ids(
    $newXml as element()
) as xs:string* {
    $newXml//node()[@translation = "ready" and fn:not(@its:translate = "no")]/@data-id
};

declare function ls:get-lang-sync-langs($lang-sync as element()?) as element()* {
    $lang-sync/lsldse:langs/lsldse:lang
};

declare function ls:get-node-ids(
    $lang-sync as element()?,
    $update-id as xs:string
) as xs:string* {
    let $update-id as xs:int? := xs:int($update-id)
    let $update-nodes as element(lsldse:updates)* := 
        if ( fn:exists($update-id) ) then ( 
            $lang-sync/lsldse:updates[@version-id/xs:int(.) > $update-id]
        ) else ()
    return (
        $update-nodes/lsldse:update
    )
};

declare function ls:update-langs-in-lang-sync(
    $lang-sync as element(lsldse:lang-sync), 
    $languages as xs:string*
) as item()* {
    let $langs as element(lsldse:langs)? := $lang-sync/lsldse:langs
    let $updates as element(lsldse:updates)* := $lang-sync/lsldse:updates
    let $latest-update as xs:string := ( $updates[1]/@version-id, '1' )[1]
    let $not-sent as element(lsldse:lang)* := $langs/lsldse:lang[fn:not(. = $languages)]
    let $oldest-not-sent as xs:int? := ls:get-oldest-lang-update($not-sent)[fn:last()]
    let $new-sync as element(lsldse:lang-sync) :=
        <lang-sync xmlns="http://lds.org/code/lds-edit/lang-sync">{
            $lang-sync/@*,
            if ( fn:exists($oldest-not-sent) ) then ( ls:get-updates($updates, $oldest-not-sent) ) else (),
            ls:get-deletes($lang-sync/lsldse:deletes),
            <langs xmlns="http://lds.org/code/lds-edit/lang-sync">{
                for $language in $languages
                return (
                    <lang update-id="{$latest-update}" xmlns="http://lds.org/code/lds-edit/lang-sync">{$language}</lang>
                ),
                $not-sent
            }</langs>
        }</lang-sync>
        
    return (
        core:update-file('ldse:preview', xdmp:node-uri($lang-sync), $new-sync, $lang-sync)
    )
};

declare function ls:get-oldest-lang-update(
    $langs as element(lsldse:lang)*
) as xs:int* {
    for $lang as element() in $langs
    let $version-id as xs:int := $lang/@update-id/xs:int(.)
    order by $version-id descending
    return (
        $version-id
    )
};

declare function ls:get-updates(
    $updates as element(lsldse:updates)*,
    $oldest-lang as xs:int?
) as element(lsldse:updates)* {
    for $update as element() in $updates
    where $update/@version-id/xs:int(.) > $oldest-lang and fn:exists($update/node())
    return (
        <updates xmlns="http://lds.org/code/lds-edit/lang-sync">{
            $update/@*,
            $update/node()
        }</updates>
    )
};

declare function ls:get-deletes(
    $deletes as element(lsldse:deletes)*
) as element(lsldse:deletes)* {
    for $update as element() in $deletes
    where fn:exists($update/node())
    return (
        <deletes xmlns="http://lds.org/code/lds-edit/lang-sync">{
            $update/@*,
            $update/node()
        }</deletes>
    )
};

declare function ls:get-index-update-nodes(
    $newXml as element(),
    $origFile as element()?,
    $latest-id as xs:int,
    $lang-sync as element(lsldse:lang-sync)?,
    $update-latest-id as xs:boolean
) as element(lsldse:update-indexes)* {
    let $new-updates as xs:string* := ls:find-index-update-nodes($newXml)
    return (
        if ( $update-latest-id ) then ( 
            element { fn:QName('http://lds.org/code/lds-edit/lang-sync', 'update-indexes') } {
                attribute version-id { $latest-id },
                ls:get-new-index-updates($new-updates)
            }
        ) else (),
        for $index-node as element() in ( $lang-sync/lsldse:update-indexes, <update-indexes/> )
        let $new-updates as element(lsldse:update-indexes)? := 
            element { fn:QName('http://lds.org/code/lds-edit/lang-sync', 'update-indexes') } {
                $index-node/@*,
                if ( fn:empty($index-node/@version-id) ) then (
                    attribute version-id { $latest-id }
                ) else (),
                ls:get-new-index-updates(($index-node/node()/fn:string(), $new-updates))
            }
        where fn:exists($new-updates/node())
        order by $index-node/@version-id/xs:int(.) descending
        return (
            $new-updates 
        )
    )
};

declare function ls:get-delete-nodes(
    $newXml as element(),
    $origFile as element()?,
    $latest-id as xs:int,
    $lang-sync as element(lsldse:lang-sync)?,
    $update-latest-id as xs:boolean
) as element(lsldse:deletes)* {
    let $new-updates as xs:string* := ls:find-deleted-nodes($newXml, $origFile)
    return (
        if ( $update-latest-id ) then ( 
            element { fn:QName('http://lds.org/code/lds-edit/lang-sync', 'deletes') } {
                attribute version-id { $latest-id },
                ls:get-new-deletes($new-updates)
            }
        ) else (),
        for $index-node as element() in ( $lang-sync/lsldse:deletes, <deletes/> )
        let $new-updates as element(lsldse:deletes)? := 
            element { fn:QName('http://lds.org/code/lds-edit/lang-sync', 'deletes') } {
                $index-node/@*,
                if ( fn:empty($index-node/@version-id) ) then (
                    attribute version-id { $latest-id }
                ) else (),
                ls:get-new-deletes(($index-node/node()/fn:string(), $new-updates))
            }
        where fn:exists($new-updates/node())
        order by $index-node/@version-id/xs:int(.) descending
        return (
            $new-updates
        )
    )
};

declare function ls:find-deleted-nodes(
    $newXml as element(),
    $origFile as element()?
) as xs:string* {
    let $existing-ids as xs:string* := $newXml//node()/@data-id
    for $new-id as xs:string in $origFile//node()/@data-id
    where fn:not($new-id = $existing-ids)
    return (
        $new-id
    )
};

declare function ls:find-index-update-nodes(
    $newXml as element()
) as xs:string* {
    $newXml//node()[@update-index = 'true']/@data-id
}; 

declare function ls:get-update-index-ids(
    $lang-sync as element(lsldse:lang-sync)?,
    $update-id as xs:string
) as xs:string* {
    let $update-id as xs:int? := xs:int($update-id)
    let $update-nodes as element(lsldse:update-indexes)* := 
        if ( fn:exists($update-id) ) then ( 
            $lang-sync/lsldse:update-indexes[@version-id/xs:int(.) > $update-id]
        ) else ()
    return (
        $update-nodes/lsldse:update-index
    )
};

declare function ls:get-delete-ids(
    $id as xs:string,
    $lang as xs:string
) as xs:string* {
    let $id as xs:string :=
        if ( fn:ends-with($id, '-eng') ) then (
            $id
        ) else ( fn:substring-before($id, '-') || '-eng' )
    let $lang-sync as element(lsldse:lang-sync)? := ls:get-lang-sync($id)
    let $lang-version-id as xs:int? := $lang-sync/lsldse:langs/lsldse:lang[. = $lang]/@update-id/xs:int(.)
    
    return (
        $lang-sync/lsldse:deletes[@version-id/xs:int(.) >= $lang-version-id]/lsldse:delete
    )
};