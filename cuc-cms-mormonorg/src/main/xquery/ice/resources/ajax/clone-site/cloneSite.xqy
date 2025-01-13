xquery version "1.0-ml";

module namespace cloneSite = "http://lds.org/code/shared/lds-edit/cloneSite";

import module namespace sp = "http://lds.org/code/modules/site-properties" at "/modules/site-properties.xqy";
import module namespace copy = "http://lds.org/code/shared/lds-edit/copy-functions" at "/ice/modules/copyFunctions.xqy";
import module namespace rice = "http://lds.org/code/shared/lds-edit/riceFunctions" at "/string-manager/modules/stringFunctions.xqy";
import module namespace cloneFunctions = "http://lds.org/code/shared/lds-edit/clone-functions" at "/ice/resources/ajax/clone-page/cloneFunctions.xqy";
import module namespace af = "http://lds.org/code/lds-edit/content-admin/admin-functions" at "/content-admin/modules/functions.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";

declare option xdmp:mapping "true";

declare function cloneSite:cloneSite ($fromSite as xs:string, $fromLang as xs:string, $toSite as xs:string, $toLang as xs:string, $resources as xs:string*, $uris as xs:string*) {
    cloneSite:cloneSite ($fromSite, $fromLang, $toSite, $toLang, $resources, $uris, ())
};

declare function cloneSite:cloneSite ($fromSite as xs:string, $fromLang as xs:string, $toSite as xs:string, $toLang as xs:string, $resources as xs:string*, $uris as xs:string*, $tag as xs:string?) {

    let $fromSiteProperty as element(siteProperties) := sp:get-site-properties($fromSite)
    let $fromSitePrefix as xs:string := $fromSiteProperty/site-context/fn:string()
    let $toSiteProperty as element(siteProperties) := sp:get-site-properties($toSite)
    let $toSitePrefix as xs:string := $toSiteProperty/site-context/fn:string()
    let $folder as xs:string := fn:lower-case(cts:search(/languages/language, cts:element-attribute-value-query(xs:QName('language'), xs:QName('key'), $toLang, 'exact'))/englishName)
    let $excludeBundles as xs:string* :=
        ('country-codes','comeuntochrist-cookies', 'page-sub-level-1','page-sub-level-2','sub-languages', 'footer-config', 'legal-links', 'global-configurations', 'precisely-countries', 'autocomplete-config', 'site-performance-config')
    let $bundles as xs:string* :=
        if ($resources eq 'all') then
            rice:getBundles((), $fromLang, $fromSite)/name
        else if ($resources) then
            rice:getBundles($resources, $fromLang, $fromSite)/name
        else ()
    let $copyResources as item()* :=
        for $resource in $bundles
        return if (rice:getBundles($resource, $toLang, $toSite) or $resource eq $excludeBundles) then
                    $resource||' already exists'
               else
                    let $copy := (copy:copy-bundles-from-lang-to-other-langs($resource, $fromSite, $toSite, $fromLang, $toLang, $folder, 'preview'),
                                  copy:copy-bundles-from-lang-to-other-langs($resource, $fromSite, $toSite, $fromLang, $toLang, $folder, 'published'))
                    return $resource||' cloned'

    let $copyPages as xs:string* :=
        for $page in
            cts:search(/custom-page,
                cts:and-query((
                    cts:directory-query('/preview/', 'infinity'),
                    cts:element-value-query(xs:QName('ldse:site-context'), $fromSite, 'exact'),
                    cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), $fromLang, 'exact'),
                    if ($uris eq 'all') then
                        ()
                    else
                        cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('uri'), $uris, 'exact')
                )))
        let $fromUri :=
            if ($fromSitePrefix eq '/') then
                $page/@uri
            else fn:substring-after($page/@uri, $fromSitePrefix)
        let $toUri :=
            if ($toSitePrefix eq '/') then
                $fromUri
            else $toSitePrefix||$fromUri

        let $exists :=
            for $i in cts:search(/custom-page,
                cts:and-query((
                    cts:directory-query('/preview/', 'infinity'),
                    cts:element-value-query(xs:QName('ldse:site-context'), $toSite, 'exact'),
                    cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), $toLang, 'exact'),
                    cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('uri'), $toUri, 'exact')
                )))
            return if (($i/ldse:ldse-meta/ldse:form-options/ldse:site-context)[1]/fn:string() eq $toSite) then
                     $i
                   else ()
        let $suffix := ($tag, fn:format-dateTime(fn:current-dateTime(),"[Y0001][M01][D01]-[h][m][s]"))[1]
        let $result := if ($exists) then
                            let $newUri := $toUri||'-cloned/'||$suffix
                            return (cloneFunctions:copyFilesByUri($fromLang, $fromSite, $toLang, $toSite,$page/@uri, $newUri, fn:false(), $page/@id, $toSitePrefix, 'no'), 'cloned')
                       else (cloneFunctions:copyFilesByUri($fromLang, $fromSite, $toLang, $toSite,$page/@uri, $toUri, fn:false(), $page/@id, $toSitePrefix, 'no'), 'cloned')

        return $page/@uri||','||$toUri||','||$result
    return ($copyResources, $copyPages)

};

declare function cloneSite:updatePageLink ($fromSite as xs:string, $fromLang as xs:string, $toSite as xs:string, $toLang as xs:string, $resources as xs:string*, $uris as xs:string*) {
    let $fromSiteProperty as element(siteProperties) := sp:get-site-properties($fromSite)
    let $fromSitePrefix as xs:string := $fromSiteProperty/site-context/fn:string()
    let $toSiteProperty as element(siteProperties) := sp:get-site-properties($toSite)
    let $toSitePrefix as xs:string := $toSiteProperty/site-context/fn:string()
    let $pages :=
        for $page in
            cts:search(/custom-page,
                cts:and-query((
                    cts:directory-query('/preview/', 'infinity'),
                    cts:element-value-query(xs:QName('ldse:site-context'), $toSite, 'exact'),
                    cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), $toLang, 'exact'),
                    if ($uris eq 'all') then
                        ()
                    else
                        cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('uri'), $uris, 'exact')
                )))
        return af:findAllFilesUsedByPageSettings($page/@id, $toLang)
    let $allLinks :=
          cts:search(fn:collection(),
            cts:and-query((
                cts:directory-query('/preview/', 'infinity'),
                cts:element-value-query(xs:QName('ldse:site-context'), $toSite, 'exact'),
                cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('id'), $pages, 'exact')
            )) )//*[@pagelinkid eq 'true' and fn:string-length(.) > 0]
    return
        for $link in $allLinks
            let $fromPage :=
                cts:search(/custom-page,
                    cts:and-query((
                        cts:directory-query('/preview/', 'infinity'),
                        cts:element-value-query(xs:QName('ldse:site-context'), $fromSite, 'exact'),
                        cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('id'), $link||'-'||$fromLang, 'exact')
                    )) )
            let $fromUri :=
                if ($fromSitePrefix eq '/') then
                    $fromPage/@uri
                else fn:substring-after($fromPage/@uri, $fromSitePrefix)
            let $toUri :=
                if ($toSitePrefix eq '/') then
                    $fromUri
                else $toSitePrefix||$fromUri
            let $newLinkId :=
                cts:search(/custom-page,
                    cts:and-query((
                        cts:directory-query('/preview/', 'infinity'),
                        cts:element-value-query(xs:QName('ldse:site-context'), $toSite, 'exact'),
                        cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('uri'), $toUri, 'exact')
                    )) )
            let $log := $link/fn:base-uri()||','||$link||','||$fromUri||','||fn:substring-before($newLinkId/@id, '-')||','||$newLinkId/@uri
            return if ($newLinkId) then
                       (xdmp:node-replace($link/text(), text{fn:substring-before($newLinkId/@id, '-')}),
                        $log||' replaced')
                   else $log||' replacement not found'

};
