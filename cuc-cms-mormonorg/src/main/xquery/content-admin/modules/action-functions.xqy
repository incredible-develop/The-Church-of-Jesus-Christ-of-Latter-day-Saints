xquery version "1.0-ml";

module namespace act = "http://lds.org/code/shared/lds-edit/content-admin/action-functions";

import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "../../modules/ldse-meta.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../modules/ldse-core.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../modules/ldse-settings.xqy";
import module namespace fj = "http://marklogic.com/json" at "../../modules/fasterjson.xqy";
import module namespace action = "http://lds.org/code/shared/lds-edit/action-functions" at "../../ice/modules/action-functions.xqy";
import module namespace cc = "http://lds.org/code/shared/lds-edit/clear-cache-functions" at "../../clear-cache/modules/clear-cache-functions.xqy";
import module namespace af = "http://lds.org/code/lds-edit/content-admin/admin-functions" at "functions.xqy";
declare namespace ldse = "http://lds.org/code/lds-edit";

declare function act:perform-action(
    $action as xs:string,
    $uri as xs:string,
    $locale as xs:string,
    $name as xs:string,
    $folder as xs:string,
    $html-id as xs:string,
    $id as xs:string,
    $get-children as xs:boolean,
    $site as xs:string?
) as item()* {
    let $file as element() := ldsemeta:get-file-by-id($id)

    let $content-ids as xs:string* := if ($action eq 'ldse:delete') then
                                            fn:distinct-values(af:findAllFilesUsedByPageSettings($id, $locale))
                                      else fn:distinct-values($file/content/element())
    let $children-ids as xs:string* := for $content-id in $content-ids
                                        let $compFile as element()* := ldsemeta:get-file-by-id($content-id)
                                        where $content-id ne $id
                                        return if ($action eq 'ldse:delete') then
                                                    if ($compFile/ldse:ldse-meta/ldse:document/@uri/fn:string() eq $uri) then
                                                         $content-id
                                                    else ()
                                               else $content-id
    let $update-children := if ($action eq 'ldse:delete') then
                                ()
                            else
                                act:update-children($children-ids, $action, $locale)
    let $process as item()* := action:perform-action($action, $uri, $locale, $name, $folder, $html-id, ($id, $children-ids), $get-children, $site)
    let $uris as element(uris) := element uris { element uri {$uri} }
    let $clearCache as item()* :=  if ($action eq ('ldse:publish', 'ldse:unpublish', 'ldse:publish-all')) then
        cc:clearCache($uris, $site, $locale, ())
    else ()

    return $process
};

declare function act:update-children(
    $ids as xs:string*,
    $action as xs:string,
    $locale as xs:string
) {
    if ( $action != 'ldse:delete' ) then (
        for $id as xs:string in $ids
        let $file as element() := ldsemeta:get-file-by-id($id)
        return (
            act:update-items($file, $action, $locale)
        )
    ) else ()
};

declare function act:update-items(
    $file as element()?,
    $action as xs:string,
    $locale as xs:string
) {
    for $item as xs:string in $file//@is-reference/../fn:string()
    let $child-file as element()? := ldsemeta:get-file-by-id($item)
    return (
        if ( fn:exists($child-file) ) then (
            let $update-children := act:update-items($child-file, $action, $locale)
            return core:preform-action-and-update($action, $child-file)
        ) else ()
    )
};

declare function act:update-child-components(
    $ids as xs:string*,
    $action as xs:string,
    $locale as xs:string
) {
    if ( $action != 'ldse:delete' ) then (
        for $id as xs:string in $ids
        let $file as element() := ldsemeta:get-file-by-id($id)
        return (
            if ( fn:exists($file) ) then (
                let $update-children := act:update-items($file, $action, $locale)
                return core:preform-action-and-update($action, $file)
            ) else ()
        )
    ) else ()
};
