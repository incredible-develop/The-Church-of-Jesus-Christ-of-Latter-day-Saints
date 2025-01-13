xquery version "1.0-ml";

module namespace cf = "http://lds.org/code/cogito/modules/cogito-functions";

import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at '../../modules/ldse-settings.xqy';
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at '../../modules/utility-functions.xqy';
import module namespace mem = "http://lds.org/code/shared/common/memory-update" at "/shared/common/util/inMemoryUpdate.xqy";
import module namespace df = "http://lds.org/code/shared/lds-edit/dynamicForms" at '../../ice/modules/dynamicForms.xqy';
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at '../../modules/ldse-core.xqy';

declare namespace ldse = 'http://lds.org/code/lds-edit';

declare function cf:query-cogito(
    $scheme as element(ldse:cogito-scheme)?
) as object-node() {
    let $results := 
        util:http-get($settings:cogito-url || '/tags?properties=true',
            <options xmlns="xdmp:http">
                <headers>
                    <accept>application/json</accept>
                </headers>
            </options>
        )[2]
    let $results := 
        object-node {
            'name': 'all',
            'total': fn:string($results/total),
            'offset': fn:string($results/offset),
            'limit': fn:string($results/limit),
            'tags': array-node { $results/tags }
        }
    return (
        $results
    )
};

declare function cf:update-cogito-tags(
    $type as xs:string?
) {
(:    let $schemes as element(ldse:cogito-scheme)* := $settings:cogito-schemes
    let $results as element(descriptorResult)? := cf:query-cogito($schemes):)
    let $tags := cf:query-cogito(())
    let $save := cf:save-results($tags, $type)
    return ()
};

declare function cf:save-results(
    $result as object-node(),
    $type as xs:string?
) as empty-sequence() {
    let $existing as object-node()? := cf:get-existing-cogito-scheme-tags('all')
    let $initialize :=
        if ( $type = 'init' ) then (
            cf:initialize($result/tags, $type)
        ) else (
            cf:diff-tags($result, $existing), cf:diff-for-deleted-tags($existing, $result)
        )
    let $db-path as xs:string := 
        if ( fn:exists($existing) ) then (
            $existing/xdmp:node-uri(.)
        ) else ( '/published/cms/content/english/cogito/scheme-' || 'all'|| '.json' )
    return xdmp:document-insert($db-path, $result)
};

declare function cf:initialize(
    $tag as object-node(),
    $type as xs:string
) {
    cf:push-to-queue($tag, $type)
};

declare function cf:get-existing-cogito-scheme-tags(
    $scheme as xs:string
) as object-node()? {
    cts:search(fn:collection(),
        cts:and-query((
            cts:json-property-value-query('name', $scheme, 'exact')
        ))
    )/node()
};

declare function cf:diff-for-deleted-tags(
    $tags as object-node()*,
    $response-tags as object-node()
) {
    for $tag as object-node() in $tags/tags
    let $event as xs:string? := cf:delete-diff-tag($tag, $response-tags)
    where fn:exists($event) and fn:not($event = '')
    return  (
        cf:push-to-queue($tag, $event)
    )
};

declare function cf:diff-tags(
    $tags as object-node()*,
    $saved-tags as object-node()?
) {
    for $tag as object-node() in $tags/tags
    let $event as xs:string? := 
        if ( fn:empty($saved-tags) ) then (
            'add'    
        ) else ( cf:diff-tag($tag, $saved-tags) )
    where fn:exists($event) and fn:not($event = '')
    return (
        cf:push-to-queue($tag, $event)
    )
};

declare function cf:delete-diff-tag(
    $tag as object-node(),
    $response-tags as object-node()*
) as xs:string? {
    let $response-tag := $response-tags/tags[id = $tag/id]
    where fn:empty($response-tag)
    return 'delete'
};

declare function cf:diff-tag(
    $tag as object-node(),
    $saved-tags as object-node()*
) as xs:string? {
    let $saved-tag := $saved-tags/tags[id = $tag/id]
    let $test := fn:count($tag/properties)
    let $debug := xdmp:log($tag)
    let $changed-props as xs:boolean := fn:count($tag/properties) != fn:count($saved-tag/properties)
    let $scheme-update as xs:boolean := 
        ( if ( fn:not($changed-props) ) then (
            ( for $scheme in $saved-tag/properties[name = 'inScheme']
            let $scheme-change := 
                if ( $tag/properties[name = 'inScheme']/value = $scheme/value ) then (
                ) else ( fn:true() )
            return $scheme-change )[1]
        ) else ( fn:false() ), fn:false() )[1]
    where fn:not($saved-tag/label = $tag/label) or $changed-props or $scheme-update
    return 'update'
};

declare function cf:push-to-queue(
    $object as object-node(),
    $event as xs:string
) {
    xdmp:spawn-function(function() { let $port := core:set-port(10090) return df:push-to-emx('tag', $object, $event) })
};
