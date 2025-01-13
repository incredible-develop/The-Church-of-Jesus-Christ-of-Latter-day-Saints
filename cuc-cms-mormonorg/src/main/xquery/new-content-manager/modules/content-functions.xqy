xquery version "1.0-ml";

module namespace content-functions = "http://lds.org/code/shared/lds-edit/new-content-manager/content-functions";

import module namespace security = "http://lds.org/code/shared/common/security/security-functions" at "/shared/common/security/securityFunctions.xqy";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../modules/utility-functions.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "../../modules/ldse-meta.xqy";

import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../modules/ldse-settings.xqy";

declare namespace xhtml = "http://www.w3.org/1999/xhtml";
declare namespace ldse = "http://lds.org/code/lds-edit";
declare option xdmp:mapping "true";

(: Returns link if visibility attribute is true :)
declare function getLinkVisibility($links as element(ldse:link)*, $linkName as xs:string?) as xs:boolean? {
      $links[@linkName = $linkName]/@visible = "true"
};

declare function buildCustomLink() as element(tr)?{
    for $link as element(ldse:link) in $settings:to-translation-custom-links
    return (
        <tr id="{$link/@id}">
            <td>
                <a href="{$link/@url}">{$link}</a>
            </td>
        </tr>
    )
};

declare function buildHomePageArchiveLink($teaser as element(), $uri as xs:string) as xs:string {
    if ($teaser/featuredDate castable as xs:dateTime) then (
        fn:concat($uri, '/',fn:year-from-dateTime($teaser/featuredDate), '/', fn:month-from-dateTime($teaser/featuredDate))
    ) else if ($teaser/publishDate castable as xs:dateTime) then (
        fn:concat($uri, '/',fn:year-from-dateTime($teaser/publishDate), '/', fn:month-from-dateTime($teaser/publishDate))
    ) else ($uri)
};

declare function truncate ($string as xs:string*, $words as xs:integer) as xs:string? {
    let $string as xs:string? := fn:normalize-space(fn:string-join($string, ' '))
    let $tokens as xs:string* := fn:tokenize($string, ' ')
    return (
        if (fn:count($tokens) > $words) then (
            fn:concat(fn:string-join(fn:subsequence($tokens, 1, $words), ' '),'...')
        ) else ($string)
    )
};

declare function getRootContext($uri as xs:string?) as xs:string? {
    if ($uri eq '/') then ('home-page') else ((fn:tokenize($uri, '/')[. ne ''])[1])
};

declare function getFileType($file as element()) as xs:string {
    let $nodeName as xs:string := fn:local-name($file)
    return (
        if ($nodeName eq 'ldswebml') then (
            xs:string($file/@type)
        ) else (
            $nodeName
        )
    )
};
