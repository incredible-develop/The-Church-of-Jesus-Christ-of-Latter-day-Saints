xquery version "1.0-ml";

module namespace fq = "http://lds.org/code/shared/lds-edit/file-queries";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../modules/utility-functions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../modules/ldse-core.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../modules/ldse-settings.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";

declare function fq:get-all-duplicate-files($directory as xs:string) as xs:string* {
    for $uri as xs:string in cts:uris("/", "any",
        cts:and-query((
            cts:directory-query($directory, 'infinity'),
            cts:element-query(xs:QName('ldse:ldse-meta'), cts:and-query(( () ))),
            cts:not-query(
                cts:directory-query(fn:concat(core:get-site-root(), "content/_configuration/"), "infinity") 
            )
        ))
    )
    where fn:ends-with($uri, ".xml")
    return (
        $uri
    )
};

declare function fq:find-file-by($id as xs:string?, $uri as xs:string?, $locale as xs:string?) as element()* {
    cts:search(/*,
        cts:and-query((
            if ( fn:exists($id) ) then (
                cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('id'), $id, 'exact')
            ) else (),
            if ( fn:exists($uri) ) then (
                cts:element-attribute-range-query(xs:QName('ldse:document'), xs:QName('uri'), '=', $uri, "collation=http://marklogic.com/collation/")
            ) else (),
            if ( fn:exists($locale) ) then (
                cts:element-attribute-range-query(xs:QName('ldse:document'), xs:QName('locale'), '=', $locale, "collation=http://marklogic.com/collation/")
            ) else ()
        ))
    )
};

declare function fq:get-saved-duplicates() as element(ldse:dup-files)* {
    cts:search(/ldse:dup-files,
        cts:and-query(( () ))
    )
};

declare function fq:get-files-from-service() {
    util:http-get(
        fn:concat("http://", $settings:file-server/fn:string(), ':10689/file-upload'),
        <options xmlns="xdmp:http"></options>
    )
};

declare function fq:query-for-file(
    $id as xs:string, 
    $locale as xs:string, 
    $uri as xs:string, 
    $directory as xs:string?, 
    $root-element as xs:string?, 
    $id-qname as xs:string?
) as element()* {
    fq:query-for-file($id, $locale, $uri, $directory, $root-element, $id-qname, ())
};

declare function fq:query-for-file(
    $id as xs:string, 
    $locale as xs:string, 
    $uri as xs:string, 
    $directory as xs:string?, 
    $root-element as xs:string?, 
    $id-qname as xs:string?,
    $mode as xs:string?
) as element()* {
    cts:search(/*,
        cts:and-query((
            if ( fn:exists($mode) ) then ( 
                cts:directory-query(fn:concat('/', $mode, '/'), 'infinity')
            ) else (),
            if ($id ne '') then (
                cts:or-query((
                    cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('id'), $id, 'exact'),
                    cts:element-attribute-value-query(xs:QName($root-element), xs:QName($id-qname), $id, 'exact')
                ))
            ) else (),
            if ($uri ne '') then (
                cts:or-query((
                    cts:element-attribute-range-query(xs:QName('ldse:document'), xs:QName('uri'), '=', $uri, "collation=http://marklogic.com/collation/"),
                    cts:element-attribute-value-query(xs:QName($root-element), xs:QName('uri'), $uri, 'exact')
                ))
            ) else (),
            if ($locale ne '') then (
                cts:or-query((
                    cts:element-attribute-range-query(xs:QName('ldse:document'), xs:QName('locale'), '=', $locale, "collation=http://marklogic.com/collation/"),
                    cts:element-attribute-value-query(xs:QName($root-element), xs:QName('locale'), $locale, 'exact')
                ))
            ) else ()
        ))
    )
};

declare function fq:query-pull-files() as element()* {
    cts:search(/query-file,
        cts:and-query(( () ))
    )
};

declare function fq:get-structure() as xs:string* {
    cts:uris('/', "any", cts:directory-query('/', '1') )
};

declare function fq:get-child-directories($directory as xs:string) as xs:string* {
    for $path as xs:string in cts:uris($directory, 'any', cts:directory-query($directory, '1'))
    where fn:count(util:contains($path, (".DS_Store", ".txt", "_configuration"))) = 0
    return $path
};
