xquery version "1.0-ml";

module namespace file-query = "http://lds.org/code/shared/lds-edit/file-query";

import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../modules/ldse-core.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "../../modules/ldse-meta.xqy";
import module namespace mem = "http://lds.org/code/shared/common/memory-update" at "/shared/common/util/inMemoryUpdate.xqy";
declare namespace ldse = "http://lds.org/code/lds-edit";

declare function file-query:get-options($options as xs:string?) as xs:string* {
    for $option as xs:string in fn:tokenize($options, ',')
    return $option
};
declare function file-query:get-content-file( (:10:)
    $id as xs:string?,
    $uri as xs:string?,
    $lang as xs:string?,
    $options as xs:string?,
    $root-element as xs:string?,
    $directory as xs:string?,
    $category as xs:string?,
    $site as xs:string?,
    $type as xs:string?,
    $onlyMain as xs:string?
) as element()* {
    let $option as xs:string* := if ( fn:exists($options) ) then ( file-query:get-options($options) ) else ()
    let $file as element()* := file-query:get-file($id, $uri, $lang, $option, $root-element, $directory, $category, $site,$type, $onlyMain)
    let $files as element()* := ( file-query:get-reference-files($file,$lang,$option,$directory,$site) )

    return (
        $files
    )
};
declare function file-query:get-content-file( (:9:)
    $id as xs:string?,
    $uri as xs:string?,
    $lang as xs:string?,
    $options as xs:string?,
    $root-element as xs:string?,
    $directory as xs:string?,
    $category as xs:string?,
    $site as xs:string?,
    $type as xs:string?
) as element()* {
    file-query:get-content-file($id, $uri, $lang, $options, $root-element, $directory, $category, $site, $type, ())
};
declare function file-query:get-content-file( (:8:)
    $id as xs:string?,
    $uri as xs:string?,
    $lang as xs:string?,
    $options as xs:string?,
    $root-element as xs:string?,
    $directory as xs:string?,
    $category as xs:string?,
    $site as xs:string?
) as element()* {
    file-query:get-content-file($id, $uri, $lang, $options, $root-element, $directory, $category, $site, (), ())
};
declare function file-query:get-file( (:8:)
    $id as xs:string?,
    $uri as xs:string?,
    $lang as xs:string?,
    $option as xs:string*,
    $root-element as xs:string?,
    $directory as xs:string?,
    $category as xs:string?,
    $site as xs:string?
) as element()* {
    file-query:get-file($id, $uri, $lang, $option, $root-element, $directory, $category, $site, (), () )
};
declare function file-query:get-file( (:9:)
    $id as xs:string?,
    $uri as xs:string?,
    $lang as xs:string?,
    $option as xs:string*,
    $root-element as xs:string?,
    $directory as xs:string?,
    $category as xs:string?,
    $site as xs:string?,
    $type as xs:string?
) as element()* {
    file-query:get-file($id, $uri, $lang, $option, $root-element, $directory, $category, $site, $type, () )
};
declare function file-query:get-file( (:10:)
    $id as xs:string?,
    $uri as xs:string?,
    $lang as xs:string?,
    $option as xs:string*,
    $root-element as xs:string?,
    $directory as xs:string?,
    $category as xs:string?,
    $site as xs:string?,
    $type as xs:string?,
    $onlyMain as xs:string?
) as element()* {
    cts:search(/*,
        cts:and-query((
            if ( fn:exists($directory) ) then (
                cts:directory-query($directory, 'infinity')
            ) else (
                core:get-filter-query()
            ),
            if ( fn:exists($id) ) then (
                file-query:get-value-query($root-element, 'id', $id)
            ) else (),
            if ( fn:exists($uri) ) then (
                file-query:get-value-query($root-element, 'uri', $uri)
            ) else (),
             if ( fn:exists($type) ) then (
                file-query:get-value-query($root-element, 'type', $type)
            ) else (),
            if ( fn:exists($lang) ) then (
                cts:or-query((
                    file-query:get-value-query($root-element, 'locale', $lang),
                    file-query:get-value-query($root-element, 'lang', $lang)
                ))
            ) else (),
            if ( fn:exists($option) ) then (
                for $each-option as xs:string in $option
                let $qname as xs:string := fn:tokenize($each-option, ":")[1]
                let $val as xs:string := fn:tokenize($each-option, ":")[2]
                return (
                    file-query:get-value-query($root-element, $qname, $val)
                )
            ) else (),
            if ( fn:exists($category) ) then (
                file-query:get-value-query('category', 'name', $category)
            ) else (),
            if ( fn:exists($site) ) then (
                cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('site'), $site, 'exact')
            ) else (),
            if ( $onlyMain eq 'true' ) then (
                cts:or-query((
                    file-query:get-value-query('ldswebml', 'main', $onlyMain),
                    (:If the document doesn't contain a main attribute, it shouldn't be filtered out.:)
                    cts:not-query((file-query:get-value-query('ldswebml', 'main', 'false')))
                ))
            ) else ()
        ))
    )
};

declare function file-query:get-value-query($root-element as xs:string?, $qname as xs:string, $value as xs:string) {
    if ( fn:exists($root-element) and fn:not($root-element = '') ) then (
        cts:element-attribute-value-query(xs:QName($root-element), xs:QName($qname), $value, 'exact')
    ) else (
        cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName($qname), $value, 'exact')
    )
};

declare function file-query:get-reference-files(
    $files as element()*,
    $lang as xs:string?,
    $option as xs:string*,
    $directory as xs:string?,
    $site as xs:string?
    ) {
    for $file as element() in $files

        let $ids as element()* := $file/content/item
        let $child-ids as element()* := $file//element()[@fetch-data = "true"]

        let $generated-file as element() := if($child-ids) then (
            let $processed-files as element()* := fn:map(function($child-id){
                    let $childFile as element()?:= file-query:get-file($child-id, (), $lang, $option,(), $directory,(), $site,())
                    let $ref-files as element()* := file-query:get-reference-files($childFile,$lang,$option,$directory,$site)
                    let $new-child as element() := element {fn:node-name($child-id)} { 
                        $ref-files/@*[fn:local-name(.) ne 'type'],
                        attribute type {'array'},
                        $ref-files/*
                    }
                    return $new-child
                },$child-ids)

            return mem:congruent-replace($child-ids,$processed-files)/node()
        )
        else ($file)

        let $oldIDBasedFiles as element()* :=
            for $id as xs:string in $ids
            return file-query:get-file($id, (), $lang, $option,(), $directory,(), $site, () )

    return ($generated-file,$oldIDBasedFiles)
};