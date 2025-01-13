xquery version "1.0-ml";

module namespace bp = 'http://lds.org/code/cms/modules/bulk-publishing';

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "/modules/utility-functions.xqy";
import module namespace json = "http://lds.org/code/shared/common/json/json-functions" at "/shared/common/json/jsonFunctions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "/modules/ldse-settings.xqy";
import module namespace df = 'http://lds.org/code/shared/lds-edit/dynamicForms' at '/ice/modules/dynamicForms.xqy';
import module namespace sp = "http://lds.org/code/modules/site-properties" at '/modules/site-properties.xqy';
import module namespace rw = "http://lds.org/code/shared/lds-edit/rewrite-functions" at '/ice/modules/rewrite-functions.xqy';
import module namespace cf = "http://lds.org/code/lds-edit/content-admin/content-functions" at '/content-admin/modules/content-functions.xqy';
import module namespace security = "http://lds.org/code/shared/common/security/security-functions" at "/shared/common/security/securityFunctions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at '/modules/ldse-core.xqy';
import module namespace document = "http://lds.org/code/shared/lds-edit/document-functions" at '/modules/document-functions.xqy';
import module namespace mem = "http://lds.org/code/shared/common/memory-update" at "/shared/common/util/inMemoryUpdate.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";

declare variable $currentUser as xs:string := ac:getUserName();

declare function bp:get-facet-values(
    $xml as element()*
) as xs:string* {
    for $item in $xml/link/href
    return (
        util:substring-after-last($item, '/')
    )
};

declare function bp:query-content-api(
    $url-params as xs:string?
) as element()* {
    let $results :=
        util:http-get('https://core-api.app.lds.org/api/v1/' || $url-params,
            <options xmlns="xdmp:http">
                <headers>
                    <content-type>application/xml</content-type>
                </headers>
            </options>
        )
    let $xml as element() := util:map-xml($results[2])
    return $xml
};

declare function bp:query-content-api-for-file(
    $url-params as xs:string?
) as element()* {
    util:http-get('https://core-api.app.lds.org/api/v1/' || $url-params,
        <options xmlns="xdmp:http">
            <headers>
                <content-type>application/xml</content-type>
            </headers>
        </options>
    )/*
};

declare function bp:update-facets-and-results(
    $selected as xs:string?,
    $site as xs:string?
) {
    let $url-params as xs:string := fn:replace($selected, ',', '/')
    let $results as element()* := bp:query-content-api($url-params)
    return (
        bp:get-facet-data($results, $url-params, $site)
    )
};

declare function bp:get-facet-data(
    $results as element()*,
    $uri as xs:string,
    $site as xs:string?
) {
    let $facets as xs:string* := bp:get-facet-values($results)
    let $site-properties as element(siteProperties) := sp:get-site-properties($site)
    let $json :=
        object-node {
            'facets': bp:get-facet-json($facets[fn:not(fn:ends-with(., '.xhtml'))]),
            'files': bp:get-file-json($facets[fn:ends-with(., '.xhtml')], $uri, $site-properties),
            'templates': bp:get-available-templates($site-properties)
        }
    return (
        xdmp:from-json($json)
    )
};

declare function bp:get-available-templates(
    $site-properties as element(siteProperties)
) {
    array-node {
        for $template as element(page) in $site-properties/admin-pages/nav/section/page[@template = ( 'lds-source', 'lesson', 'toc' )]
        order by $template ascending
        return (
            object-node {
                'template': fn:string($template/@template),
                'title': fn:string($template),
                'value': fn:string($template/@id)
            }
        )
    }
};

declare function bp:get-file-json(
    $file-names as xs:string*,
    $uri as xs:string,
    $site-properties as element(siteProperties)
) {
    if ( fn:exists($file-names) ) then (
        object-node {
            'files': array-node {
                for $file-name as xs:string in $file-names
                let $name as xs:string? := $file-name
                let $file as element()* := bp:query-content-api-for-file($uri || '/' || $file-name)
                let $data-aid as xs:string? := $file/@data-aid
                let $lang as xs:string := fn:substring-before($uri, '/')
                let $context as xs:string := fn:substring-before(fn:substring-after(fn:substring-after($uri, $lang), '/'), '/')
                let $new-uri as xs:string :=
                    if ( $site-properties/site-context = '/' || $context ) then (
                         '/' || fn:substring-after($uri, '/')
                    ) else ( $site-properties/site-context || '/' || fn:substring-after($uri, '/') )
                let $url as xs:string := $site-properties/site-context || '/' || fn:substring-after($uri, '/') || '/' || fn:substring-before($file-name, '.')
                let $existing as element()? := cf:get-content-with-uri($lang, $new-uri || '/' || fn:substring-before($file-name, '.'), ( 'preview', 'unpublish' ))
                let $publish as element()? := cf:get-content-with-uri($lang, $new-uri || '/' || fn:substring-before($file-name, '.'), 'publish')
                order by $name ascending
                return (
                    object-node {
                        'dataId': fn:string($data-aid),
                        'id': fn:string($file-name),
                        'value': fn:string($file-name),
                        'title': fn:string($file-name),
                        'newUri': $new-uri,
                        'checked': fn:false(),
                        'url': '//' || $site-properties/urls/url[@env = 'preview'] || $url,
                        'status': if ( fn:exists($publish) ) then ( 'published' ) else if ( fn:exists($existing) ) then ( $existing/@status/xs:string(.) ) else ( '' ),
                        'uri': fn:string($uri || '/' || $file-name)
                    }
                )
            }
        }
    ) else ( object-node {} )
};

declare function bp:get-facet-json(
    $facets as xs:string*
) {
    if ( fn:exists($facets) ) then (
        object-node {
            'options': array-node {
                if ( $facets castable as xs:int* ) then (
                    for $facet as xs:string in $facets
                    let $name as xs:string? := ( util:get-full-language-name-by-locale($facet), $facet )[1]
                    order by $name descending
                    return (
                        object-node {
                            'id': fn:string($facet),
                            'value': fn:string($facet),
                            'title': fn:string($name)
                        }
                    )
                ) else (
                    for $facet as xs:string in $facets
                    let $name as xs:string? := ( util:get-full-language-name-by-locale($facet), $facet )[1]
                    order by $name ascending
                    return (
                        object-node {
                            'id': fn:string($facet),
                            'value': fn:string($facet),
                            'title': fn:string($name)
                        }
                    )
                )
            }
        }
    ) else ( object-node {} )
};

declare function bp:update-uris(
    $selected as xs:string?,
    $site as xs:string,
    $status as xs:string?,
    $template as xs:string?,
    $data-aids as xs:string?
) {
    let $items as xs:string* := fn:tokenize($selected, ',')
    let $data-aids as xs:string* := fn:tokenize($data-aids, ',')
    let $site-properties as element(siteProperties) := sp:get-site-properties($site)
    let $lang as xs:string := fn:substring-before($items[1], '/')
    let $statuses := if ( $status = 'ldse:publish' ) then ( 'preview', 'publish' ) else ( 'preview' )
    let $page-id as xs:string* := $site-properties//page[@template = $template]/@id
    let $uris :=
        for $item as xs:string at $index in $items
        let $content-context as xs:string := '/' || fn:substring-before(fn:substring-after($item, '/'), '/')
        let $uri as xs:string :=
            if ( $site-properties/site-context = $content-context ) then (
                 '/' || fn:substring-before(fn:substring-after($item, '/'), '.')
            ) else ( $site-properties/site-context || '/' || fn:substring-before(fn:substring-after($item, '/'), '.') )
        let $document-uri as xs:string := '/' || fn:substring-before(fn:substring-after($item, '/'), '.')
        let $uri as xs:string :=
            if ( fn:ends-with($uri, '_manifest') ) then (
                fn:substring-before($uri, '/_manifest')
            ) else ( $uri )
        let $existing-page as element(custom-page)? := cf:get-content-by($uri, $lang, $site, 'pageBuilder')
        let $file-status as xs:string :=
            if ( $status = 'ldse:publish' ) then (
                'publish'
            ) else ( 'preview' )
        let $existing-file as element(titan-source)? := cf:get-content-by-status($existing-page/content/titan-source, 'preview', ())
        let $update-file as item()* :=
            if ( fn:exists($existing-file) and $status != 'ldse:preview' ) then (
                core:preform-action-and-update($status, $existing-file)
            ) else ()
        let $update-page as item()* :=
            if ( fn:exists($existing-page) and $status != 'ldse:preview' ) then (
                core:preform-action-and-update($status, $existing-page)
            ) else ()
        let $new-file as element(titan-source)? :=
            if ( fn:empty($existing-file) and $status = ( 'ldse:preview', 'ldse:publish' ) ) then (
                (let $is-published as xs:boolean := fn:count($statuses) > 1
                let $new-file as element(titan-source) := bp:get-new-file($uri, $lang, $site, 'preview', $is-published, $document-uri, $data-aids[$index])
                for $status as xs:string in $statuses
                let $file-uri as xs:string := core:build-db-path($uri, $lang, $new-file/@id, $new-file)
                let $updated-file as element(titan-source) := mem:node-replace($new-file/@status, attribute status { $status })
                let $updated-file as element(titan-source) := mem:node-replace($updated-file/ldse:ldse-meta/ldse:document/@status, attribute status { $status })
                let $new-db-path as xs:string :=
                    if ( $status = 'publish' ) then (
                        fn:replace($file-uri, 'preview', 'published')
                    ) else ( $file-uri )
                let $save := document:document-insert($new-db-path, $updated-file)
                return ( $new-file ))[1]
            ) else ()
        let $new-page as element(custom-page)? :=
            if ( fn:empty($existing-page) and $status = ( 'ldse:preview', 'ldse:publish' ) ) then (
                let $is-published as xs:boolean := fn:count($statuses) > 1
                let $new-page as element(custom-page) := bp:get-custom-page($uri, $lang, $site, $new-file[1]/@id, 'preview', $is-published, $page-id[1], $template)
                for $status as xs:string in $statuses
                let $updated-page as element(custom-page) := mem:node-replace($new-page/@status, attribute status { $status })
                let $updated-page as element(custom-page) := mem:node-replace($updated-page/ldse:ldse-meta/ldse:document/@status, attribute status { $status })
                let $page-uri as xs:string := core:build-db-path($uri, $lang, $new-page/@id, $new-page)
                let $new-db-path as xs:string :=
                    if ( $status = 'publish' ) then (
                        fn:replace($page-uri, 'preview', 'published')
                    ) else ( $page-uri )
                return document:document-insert($new-db-path, $updated-page)
            ) else ()
        return (
            fn:true()
        )
    return ( fn:false() )
};

declare function bp:get-new-file(
    $uri as xs:string,
    $lang as xs:string,
    $site as xs:string,
    $status as xs:string,
    $is-published as xs:boolean,
    $document-uri as xs:string,
    $data-aid as xs:string?
) as element(titan-source) {
    let $file-id as xs:string := util:generate-unique-id($lang)
    let $new-file as element(titan-source) :=
        <titan-source status="{ $status }" id="{ $file-id }" uri="{ $uri }" type="titan-source" locale="{ $lang }" xml:lang="{ $lang }" xmlns:its="http://www.w3.org/2005/11/its">
            <ldse-meta its:translate="no" xmlns="http://lds.org/code/lds-edit" xmlns:its="http://www.w3.org/2005/11/its">
                <document id="{ $file-id }" locale="{ $lang }" uri="{ $uri }" status="{ $status }" site="cms" source="chq" words="1" tgp="0.0035" env="{ $settings:environment }" title="" type="titan-source:titan-source"/>
                <created date="{ fn:current-dateTime() }" username="{ $currentUser }" userid=""/>
                <form-options its:translate="no">
                    <form>titan-source</form>
                    <location>titan-source</location>
                    <type>titan-source</type>
                    <site-context>{ $site }</site-context>
                    <page-type/>
                </form-options>
                { if ( $is-published ) then ( <publish-date date="{ fn:current-dateTime() }" username="{ $currentUser }" /> ) else () }
            </ldse-meta>
            <source its:translate="no" title="" uri="{ $document-uri }" lang="{ $lang }">{ $data-aid }</source>
        </titan-source>
    return $new-file
};

declare function bp:get-custom-page(
    $uri as xs:string,
    $lang as xs:string,
    $site as xs:string,
    $file-id as xs:string,
    $status as xs:string,
    $is-published as xs:boolean,
    $page-id as xs:string,
    $template as xs:string?
) as element(custom-page) {
    let $content-id as xs:string := util:generate-unique-id($lang)
    let $page as element(custom-page) :=
        <custom-page status="{ $status }" id="{ $content-id }" locale="{ $lang }" xml:lang="{ $lang }" uri="{ $uri }">
            <ldse-meta its:translate="no" xmlns="http://lds.org/code/lds-edit" xmlns:its="http://www.w3.org/2005/11/its">
                <document id="{ $content-id }" locale="{ $lang }" uri="{ $uri }" status="{ $status }" site="{ $core:site }" source="chq" words="13" tgp="0.0455" env="{ $settings:environment }" title="" type="custom-page"/>
                <created date="{ fn:current-dateTime() }" username="{ $currentUser }" userid=""/>
                <form-options its:translate="no">
                    <form>pageBuilder</form>
                    <templateId>{ $template }</templateId>
                    <templateUri/>
                    <current-page/>
                    <site>{ $site }</site>
                    <site-context>{ $site }</site-context>
                    <pageId>{ $page-id }</pageId>
                </form-options>
                { if ( $is-published ) then ( <publish-date date="{ fn:current-dateTime() }" username="{ $currentUser }" /> ) else () }
            </ldse-meta>
            <content its:translate="no" xmlns:its="http://www.w3.org/2005/11/its">
                <titan-source>{ $file-id }</titan-source>
            </content>
            <meta type="array"></meta>
            <title></title>
            <template-id>{ $template }</template-id>
            <uri-definition its:translate="no" xmlns:its="http://www.w3.org/2005/11/its">
                <site-context>{ $site }</site-context>
                <uri>{ $uri }</uri>
                <uri-path>{ $uri }</uri-path>
            </uri-definition>
        </custom-page>
    return $page
};
