xquery version "1.0-ml";
(: File should be saved at "/custom/lds-edit/ldse-core.xqy" :)

module namespace default = "http://lds.org/code/shared/lds-edit/ldse-default-core";

import module namespace security = "http://lds.org/code/shared/common/security/security-functions" at "/shared/common/security/securityFunctions.xqy";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";

(: LDS-EDIT :)
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "/modules/ldse-core.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "/modules/ldse-settings.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "/modules/utility-functions.xqy";
import module namespace document = "http://lds.org/code/shared/lds-edit/document-functions" at "/modules/document-functions.xqy";
import module namespace function = "http://lds.org/code/shared/lds-edit/function-apply" at "/invoke/function-apply.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "/modules/ldse-meta.xqy";
import module namespace gs = "http://lds.org/code/shared/lds-edit/global-search" at "/modules/global-search.xqy";
import module namespace copy = "http://lds.org/code/shared/lds-edit/copy-functions" at "/ice/modules/copyFunctions.xqy";
import module namespace ice = "http://lds.org/code/shared/lds-edit/iceFunction" at "/ice/modules/iceFunctions.xqy";
import module namespace template = "http://lds.org/shared/lds-edit/template" at "/modules/template.xqy";
import module namespace translation = "http://lds.org/code/shared/lds-edit/translationFunctions" at "/translation/modules/translationFunctions.xqy";
import module namespace form = "http://lds.org/code/shared/lds-edit/dynamicForms" at "/ice/modules/dynamicForms.xqy";
import module namespace json = "http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";
import module namespace mem = "http://lds.org/code/shared/common/memory-update" at "/shared/common/util/inMemoryUpdate.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace oldse = "http://lds.org/code/lds-edit/omniture";
declare namespace hldse = "http://lds.org/code/lds-edit/history";
declare namespace vldse = "http://lds.org/code/lds-edit/versions";
declare namespace cldse = "http://lds.org/code/lds-edit/correlation";
declare namespace bldse = "http://lds.org/code/lds-edit/brightcove";
declare namespace lsldse = "http://lds.org/code/lds-edit/lang-sync";
declare namespace enrich = "http://lds.org/code/shared/lds-edit/enrich";
declare namespace its = "http://www.w3.org/2005/11/its";
declare namespace xhtml = "http://www.w3.org/1999/xhtml";

declare option xdmp:mapping "true";

(:
    ****************************************************************
    1. All default functions should only be called by the site core.
    2. Default Functions should not reference other default functions/variables
       Should call back to the core
    ****************************************************************
:)
declare variable $site as xs:string := $core:site;
declare variable $site-param as xs:string? := xdmp:get-request-field('site')[1];

declare function default:get-ldse-settings($for-update as xs:boolean) as element(ldse:ldse-settings) {
    if ($for-update) then (
        (for $setting as element(ldse:ldse-settings) in
            cts:search(/ldse:ldse-settings,
                cts:and-query((
                        cts:element-query(xs:QName('ldse:mode'), cts:and-query(())),
                        cts:element-attribute-value-query(xs:QName('ldse:ldse-settings'), xs:QName('application'), $site, 'exact')
                    ))
             )
        order by fn:exists($setting/ldse:modes/ldse:mode[ldse:port = fn:string($core:port)]) descending
        return ( $setting )
        )[1]
    ) else (
        let $server-key as xs:string := "ldse:ldse-settings"
        let $map as map:map := util:get-server-field($server-key, map:map())
        let $port as xs:string? := fn:string($core:port)
        let $database as xs:string? := xdmp:database-name(xdmp:database())
        let $file-key as xs:string? := fn:string-join(($site, $port, $database), ':')
        let $time-key as xs:string := fn:concat($file-key, ':timestamp')
        let $current-time as xs:dateTime? := map:get($map, $time-key)
        let $database-time as xs:dateTime? :=
            cts:element-values(
                xs:QName('prop:last-modified'),
                (),
                ("properties", "descending", "limit=1"),
                cts:document-fragment-query(
                    cts:and-query((
                        cts:element-query(xs:QName('ldse:mode'), cts:and-query(())),
                        cts:element-attribute-value-query(xs:QName('ldse:ldse-settings'), xs:QName('application'), $site, 'exact')
                    ))
                )
            )
        let $current-settings as element(ldse:ldse-settings)? := map:get($map, $file-key)
        let $ldse-settings as element(ldse:ldse-settings) :=
            if (fn:exists($current-settings) and $current-time = $database-time) then (
                $current-settings
            ) else (
                let $setting as element(ldse:ldse-settings) :=
                    (for $setting as element(ldse:ldse-settings) in
                        cts:search(/ldse:ldse-settings,
                            cts:and-query((
                                    cts:element-query(xs:QName('ldse:mode'), cts:and-query(())),
                                    cts:element-attribute-value-query(xs:QName('ldse:ldse-settings'), xs:QName('application'), $site, 'exact')
                                ))
                         )
                    order by fn:exists($setting/ldse:modes/ldse:mode[ldse:port = $port]) descending
                    return ( $setting )
                    )[1]
                 let $update-map as item()* := (
                    map:put($map, $file-key, <ldse-settings xmlns="http://lds.org/code/lds-edit">{$setting/@*, $setting/*}</ldse-settings>),
                    map:put($map, $time-key, $database-time)
                 )
                 return (
                    let $set as item()* := util:set-server-field($server-key, $map)
                    return (
                        $setting
                    )
                 )

            )
        return (
            $ldse-settings
        )
    )
};

declare function default:get-site-root($mode as xs:string) as xs:string {
    fn:concat(core:get-mode-root($mode), $site, '/')
};


declare function default:build-db-path(
    $uri as xs:string?,
    $locale as xs:string?,
    $id as xs:string?,
    $file as element()?,
    $options as element(options)?
) as xs:string {
    let $uri as xs:string? := if (fn:starts-with($uri, $settings:shared-prefix)) then (fn:substring-after($uri, $settings:shared-prefix)) else ($uri)
    let $lang-name as xs:string? := util:get-full-language-name-by-locale($locale)
    let $site-folder as xs:string? := $options/site-folder
    let $site-folder as xs:string? :=
        if ( fn:exists($site-folder) ) then (
            $site-folder || '/'
        ) else ()
    let $lang-folder as xs:string? :=
        if ( $options/use-lang-folder/fn:string() = "false" ) then (
            ""
        ) else if ( fn:contains($locale, '-') ) then (
            fn:concat('country-sites/',$locale)
        ) else if ( fn:exists($lang-name) ) then (
            fn:lower-case($lang-name)
        ) else (
            $locale
        )
    return (
        (: if the file already exists use the current path :)
        if ( fn:exists($file) and fn:not(xdmp:node-uri($file) = '') and fn:exists(xdmp:node-uri($file)) ) then (
            xdmp:node-uri($file)
        ) else (
            typeswitch ($file)
            case element(resources) return (
                util:clean-db-uri( fn:concat(core:get-site-root(), '/content/', $lang-folder, '/resources/', $id, '-resources.xml') )
            )
            case element(channels) return (
                util:clean-db-uri( fn:concat(core:get-site-root(), '/content/', $lang-folder, '/navigation/', ($lang-name,$locale)[1], '-', $id, '-navigation.xml') )
            )
            case element(scheduled-task) return (
                util:clean-db-uri( fn:concat(core:get-site-root(), '/pharaoh/task-', $id, '.xml') )
            )
            case element(ldse:report) return (
                if ($file/@type = "from-translation") then (
                     util:clean-db-uri( fn:concat(core:get-site-root(),'/content/lds-edit/from-translation/', $options/folder, '/', $id,'-report.xml') )
                ) else ()
            )
            case element(rewriteRules) return (
                util:clean-db-uri( fn:concat(core:get-site-root(),'/content/_configuration/rewrite-rules/rewrite-rules-',$locale,'.xml') )
            )
            case element(redirectRules) return (
                util:clean-db-uri( fn:concat(core:get-site-root(),'/content/_configuration/redirect-rules/redirect-rules-',$locale,'.xml') )
            )
            case element(ldse:translation-history) return (
                util:clean-db-uri( fn:concat(core:get-site-root(), "/content/lds-edit/translation", $uri, "/", $id, ".xml") )
            )
            case element(ldse:clear-cache-log-entry) return (
                util:clean-db-uri( fn:concat(core:get-site-root(), "/content/lds-edit/cache-clearing/", $options/folder, "/", $id, ".xml") )
            )
            case element(ldse:contributor) return (
                util:clean-db-uri( fn:concat(core:get-site-root(), '/content/_configuration/ice/content-contributors/', $id, '.xml') )
            )
            case element(ldse:bc-folder) return (
                 util:clean-db-uri( fn:concat(core:get-site-root(), '/content/lds-edit/bc/', $uri,'-folder.xml') )
            )
            case element(binary-content) return (
                util:clean-db-uri(  fn:concat(core:get-site-root(), "/content/lds-edit/bc/", $options/folder, '/', $id, ".xml") )
            )
            case element(ldse:seo-data) return (
                util:clean-db-uri( fn:concat(core:get-site-root(), '/content/lds-edit/seo-moz-data/',$options/path,'.xml') )
            )
            case element(generated-report) return (
                util:clean-db-uri( fn:concat(core:get-site-root(), '/content/lds-edit/generated-report/',$options/path, '/', $id, '.xml') )
            )
            case element(hldse:history) return (
                util:clean-db-uri( fn:concat(core:get-site-root(), '/content/lds-edit/history/', $lang-folder, "/", $uri, "/", $options/file-prefix[. != ""]/fn:concat(., "-"), $id, '.xml') )
            )
            case element(lsldse:lang-sync) return (
                util:clean-db-uri( fn:concat(core:get-site-root(), '/content/lds-edit/lang-sync/', $lang-folder, "/", $uri, "/", 'lang-sync-', $id, '.xml') )
            )
            case element(lang-sync) return (
                util:clean-db-uri( fn:concat(core:get-site-root(), '/content/lds-edit/lang-sync/', $lang-folder, "/", $uri, "/", 'lang-sync-', $id, '.xml') )
            )
            case element(vldse:version) return (
                 util:clean-db-uri( fn:concat(core:get-site-root(), '/content/lds-edit/versions/', $lang-folder, "/", $uri, "/", $id, '.xml') )
            )
            case element(bldse:brightcove-details) return (
                 util:clean-db-uri( fn:concat(core:get-site-root(), '/content/lds-edit/brightcove/', $options/player-id, "/", $options/video-id, '.xml') )
            )
            case element(cldse:correlation) return (
                 util:clean-db-uri( fn:concat(core:get-site-root(), '/content/lds-edit/correlation/', $lang-folder, "/", $options/uri-prefix[fn:not(. = "")]/fn:concat(., "/"), $uri, "/", $options/file-prefix[. != ""]/fn:concat(., "-"), $id, '.xml') )
            )
            case element(ldse:warehouse-delete) return (
              util:clean-db-uri( fn:concat(core:get-site-root(), '/content/lds-edit/warehouse/pending-deletes/', $id, '.xml') )
            )
            case element(enrich:keyword) return (
              util:clean-db-uri( fn:concat(core:get-site-root(), '/content/lds-edit/enrich/', $locale, '/keywords/', $id, '.xml') )
            )
            case element(enrich:organization) return (
              util:clean-db-uri( fn:concat(core:get-site-root(), '/content/lds-edit/enrich/', $locale, '/organizations/', $id, '.xml') )
            )
            case element(enrich:person) return (
              util:clean-db-uri( fn:concat(core:get-site-root(), '/content/lds-edit/enrich/', $locale, '/people/', $id, '.xml') )
            )
            case element(enrich:role) return (
              util:clean-db-uri( fn:concat(core:get-site-root(), '/content/lds-edit/enrich/', $locale, '/roles/', $id, '.xml') )
            )
            case element(enrich:location) return (
              util:clean-db-uri( fn:concat(core:get-site-root(), '/content/lds-edit/enrich/', $locale, '/locations/', $id, '.xml') )
            )
            case element(enrich:languages) return (
              util:clean-db-uri( fn:concat(core:get-site-root(), '/content/lds-edit/enrich/', $id, '.xml') )
            )
            case element(category) return (
                util:clean-db-uri( fn:concat(core:get-site-root(), '/content/', fn:lower-case($lang-name), '/', $uri, '/', $id, '.xml') )
            )
            case element(sub-site) return (
                util:clean-db-uri( fn:concat(core:get-site-root(), '/content/_configuration/',  $options/folder, '/', $options/file-prefix, $id, '.xml') )
            )
            default return (
                util:clean-db-uri( fn:concat(core:get-site-root(), '/content/', $site-folder, $lang-folder, '/', $uri, '/', $options/folder, '/', $options/file-prefix, $id, '.xml') )
            )
        )
    )
};

declare function default:convert-db-path(
    $target-mode as xs:string, (: preview or publish :)
    $path as xs:string
) as xs:string {
    if ($core:mode = $target-mode) then (
        $path
    ) else (
        let $relative-path as xs:string := fn:replace($path, fn:concat('^(', core:get-mode-root(), ')'), '')
        return (
            util:clean-db-uri(fn:concat(settings:get-mode-root($target-mode), $relative-path))
        )
    )
};

(:~
    Takes the URI and converts it to the appropriate BC URI.
    @param $uri The URI in the database of the image
    @return the correct URI to display the image
~:)
declare function default:get-display-uri(
    $uri as xs:string
) as xs:string {
    let $relativeUri as xs:string := if (fn:starts-with($uri, "/")) then ( fn:substring-after($uri, "/") ) else ( $uri )
    return (
        if ($uri = "") then (
            ""
        ) else if (fn:matches($uri, '^https?://') ) then (
            $uri
        ) else if (fn:contains($uri, '/bc/')) then (
            (: if it already contains bc, then just use the uri :)
            $uri
         ) else if ($settings:shared-prefix ne '') then (
             (: if we can identify which site it is, use the site :)
             fn:concat($settings:shared-prefix,'/bc/', $relativeUri)
         ) else (
             (: if no site, then use the ldsorg bc :)
             fn:concat("/bc/content/", $relativeUri)
         )
    )
};

(:~
    Takes the URI and converts it to the appropriate CDN URI.
    @param $uri The URI of the resource without the publisher cdn
    @return the correct URI to display the CDN resource
~:)
declare function default:get-ldspub-cdn-uri(
    $uri as xs:string
) as xs:string {
    (: remove beginning '/' if present :)
    let $uri as xs:string := fn:replace($uri, '^/+', '')
    return (
        $settings:cdn-ldspub-path || util:clean-db-uri(fn:concat('/', $site, '/', $uri))
    )
};

(:
    look into caching with variable the directory, need one more funciton with no params
:)
declare variable $directory-query as cts:query := default:get-filter-query();

declare function default:get-filter-query() as cts:query* {
    let $directories as xs:string+ := (
        core:get-site-root(),
        if ( $settings:manage-shared ) then (
            fn:concat( settings:get-mode-root($core:mode), "shared/")
        ) else ()
    )
    return (
        cts:directory-query($directories, 'infinity')
    )
};

declare function default:get-filter-query(
    $collections as xs:string*
) as cts:query* {
    if ( fn:exists($collections) ) then (
        cts:and-query((
            $directory-query,
            cts:collection-query($collections)
        ))
    ) else (
        $directory-query
    )
};

declare function default:action-transform(
    $action as xs:string,
    $file as element()
) as element() {
    default:action-transform($action, $file, ())
};

declare function default:action-transform(
    $action as xs:string,
    $file as element(),
    $status as xs:string?
) as element() {
    let $status as xs:string := ( $status, settings:get-action-meta-status($action) )[1]
    let $locale as xs:string := ldsemeta:get-document-locale($file)
    let $id as xs:string := ldsemeta:get-document-id($file)
    return (
        element { fn:node-name($file) } {
            attribute status { $status },
            $file/@* except $file/@status,
            ldsemeta:get-meta($file, $id, $locale, (), $status, $action),
            $file/* except $file/ldse:ldse-meta
        }
    )
};

declare function default:update-file(
    $action as xs:string,
    $doc-uri as xs:string,
    $file as element(),
    $orig-file as element()?,
    $options as element(options)?
) as empty-sequence() {
    let $action-xml as element(ldse:action) := settings:get-action($action)
    let $debug := xdmp:log($file)
    let $debug := xdmp:log($orig-file)
    let $new-file := if ( fn:exists($file/ldse:ldse-meta/ldse:translation-event) ) then ( mem:node-delete($file/ldse:ldse-meta/ldse:translation-event) ) else ( $file )
    let $new-file := if ( fn:exists($new-file/ldse:ldse-meta/ldse:last-modified) ) then ( mem:node-delete($new-file/ldse:ldse-meta/ldse:last-modified) ) else ( $new-file )
    let $new-file := if ( fn:exists($new-file/ldse:ldse-meta/ldse:sensitive) ) then ( mem:node-delete($new-file/ldse:ldse-meta/ldse:sensitive) ) else ( $new-file )
    let $new-orig-file := if ( fn:exists($orig-file/ldse:ldse-meta/ldse:translation-event) ) then ( mem:node-delete($orig-file/ldse:ldse-meta/ldse:translation-event)/* ) else ( $orig-file )
    let $new-orig-file := if ( fn:exists($new-orig-file/ldse:ldse-meta/ldse:last-modified) ) then ( mem:node-delete($new-orig-file/ldse:ldse-meta/ldse:last-modified)/* ) else ( $new-orig-file )
    let $new-orig-file := if ( fn:exists($new-orig-file/ldse:ldse-meta/ldse:sensitive) ) then ( mem:node-delete($new-orig-file/ldse:ldse-meta/ldse:sensitive)/* ) else ( $new-orig-file )
    let $files-are-equal as xs:boolean := fn:deep-equal($new-orig-file, $new-file)

    (:let $debug := if ( fn:not(fn:local-name($orig-file) = 'custom-page' ) ) then ( xdmp:log($orig-file/ldse:ldse-meta/ldse:last-modified) ) else ()
    let $e := if ( fn:not(fn:local-name($orig-file) = 'custom-page' ) ) then ( fn:error() ) else ()
    let $e := if ( fn:not(fn:local-name($file) = 'custom-page' ) ) then ( fn:error() ) else ():)

    let $status-updated-file as element() :=
        if ( $files-are-equal ) then (
            $file
        ) else ( default:action-transform($action, $file) )
    let $saves as item()* :=
        for $mode as element(ldse:mode) in $action-xml/ldse:save/ldse:mode
        return (
            switch ( $mode/xs:string(.) )
            case 'preview' return (
                if ( fn:not(fn:local-name($file) = 'lang-sync') ) then (
                    let $status as xs:string :=
                        switch ( $action )
                        case 'ldse:unpublish' return 'unpublish'
                        default return 'preview'
                    let $status-updated-file as element() :=
                        if ( $files-are-equal ) then (
                            $file
                        ) else ( default:action-transform($action, $file, $status) )
                    return core:save-file($mode, core:convert-db-path($mode, $doc-uri), $status-updated-file, $orig-file, $options)
                ) else ( core:save-file($mode, core:convert-db-path($mode, $doc-uri), $file, $orig-file, $options) )
            )
            case 'publish' return core:save-file($mode, core:convert-db-path($mode, $doc-uri), $status-updated-file, $orig-file, $options)
            default return core:save-file($mode, core:convert-db-path($mode, $doc-uri), $status-updated-file, $orig-file, $options)
        )
    let $deletes as item()* :=
        for $mode as element(ldse:mode) in $action-xml/ldse:delete/ldse:mode
        return (
            core:delete-file($mode, core:convert-db-path($mode, $doc-uri), $file, $orig-file)
        )

    let $country-send as item()* :=
        if ($action-xml/ldse:country = "send" and fn:node-name($file) = xs:QName('resources')) then (
            function:spawn(xdmp:function(xs:QName('copy:copy-resource-file-to-countries')), $core:mode, ($orig-file,$file)[1])
        ) else if ($action-xml/ldse:country = "send") then (
            function:spawn(xdmp:function(xs:QName('copy:send-to-country')), $core:mode, ($orig-file,$file)[1], ldsemeta:get-document-locale(($orig-file,$file)[1]))
        ) else ()
    let $search as item()* :=
        if ( fn:exists($action-xml/ldse:search) ) then (
            core:update-search($action-xml/ldse:search, $doc-uri, $file, $orig-file)
        ) else ()
   return ()
};

declare function default:publish-transform(
    $action as xs:string,
    $file as element()
) as element() {
    let $status as xs:string := settings:get-action-meta-status($action)
    let $locale as xs:string := ldsemeta:get-document-locale($file)
    let $id as xs:string := ldsemeta:get-document-id($file)
    return (
        typeswitch ($file)
        case element(custom-page) return (
            element custom-page {
                attribute status {$status},
                $file/@* except $file/@status,
                ldsemeta:get-meta($file, $id, $locale, (), $status),
                $file/* except $file/(ldse:ldse-meta|resources|channel),
                if ( fn:exists($file/resources) ) then (
                    element resources {
                        for $entry as element(entry) in $file/resources/entry
                        return (
                            element entry {
                                $entry/@* except $file/@status,
                                $entry/*
                            }
                        )
                    }
                ) else (),
                $file/channel
            }
        )
        case element(resources) return (
            let $name as xs:string := $file/name
            let $application as xs:string := $file/application
            let $ldse-meta as element(ldse:ldse-meta) := ldsemeta:get-meta($file, fn:concat($name, '-', $locale), $locale, (), $status)
            let $ldse-meta as element(ldse:ldse-meta) :=
                if ($locale eq "eng") then (
                    ldsemeta:translation-mark-ready($ldse-meta)
                ) else (
                    ldsemeta:translation-mark-complete($ldse-meta)
                )
            return (
                <resources locale="{$file/@locale}" status="{ $status }">{
                    <name its:translate="no">{ $name }</name>,
                    <application its:translate="no">{ $application }</application>,
                    $ldse-meta,
                    $file/*[fn:not( self::properties | self::ldse:ldse-meta | self::name | self::application )],
                    element properties {
                        for $entry as element(entry) in $file/properties/entry
                        return (
                            element entry {
                                $entry/@*[fn:local-name(.) != 'status'],
                                $entry/node()
                            }
                        )
                    }
                }</resources>
            )
        )
        case element (channels) return (
            let $name as xs:string := $file/@name
            let $transStatus as xs:string? := if ($file/@translation eq ('preview', 'ready')) then ('ready') else ()
            let $ldse-meta as element(ldse:ldse-meta) := ldsemeta:get-meta($file, fn:concat($name, '-', $locale), $locale, (), $status)
            let $ldse-meta as element(ldse:ldse-meta) :=
                if ($locale eq "eng") then (
                    ldsemeta:translation-mark-ready($ldse-meta)
                ) else (
                    ldsemeta:translation-mark-complete($ldse-meta)
                )
            return (
                element channels {
                    attribute status { $status },
                    attribute translation {$transStatus},
                    $file/@*[ fn:not(fn:node-name(.) = (xs:QName('status'), xs:QName('translation')) )],
                    $ldse-meta,
                    $file/* except $file/ldse:ldse-meta
                }
            )
        )
        default return (
            element {fn:node-name($file)} {
                attribute status {$status},
                $file/@* except $file/@status,
                ldsemeta:get-meta($file, $id, $locale, (), $status),
                $file/* except $file/ldse:ldse-meta
            }
        )
    )
};

declare function default:unpublish-transform(
    $action as xs:string,
    $file as element()
) as element() {
    let $status as xs:string := settings:get-action-meta-status($action)
    let $locale as xs:string := ldsemeta:get-document-locale($file)
    let $id as xs:string := ldsemeta:get-document-id($file)
    return (
        element {fn:node-name($file)} {
            attribute status {$status},
            $file/@* except $file/@status,
            ldsemeta:get-meta($file, $id, $locale, (), $status),
            $file/* except $file/ldse:ldse-meta
        }
    )
};

declare function default:remove-transform(
    $action as xs:string,
    $file as element()
) as element() {
    let $status as xs:string := settings:get-action-meta-status($action)
    let $uri as xs:string := ldsemeta:get-document-uri($file)
    let $locale as xs:string := ldsemeta:get-document-locale($file)
    let $id as xs:string := ldsemeta:get-document-id($file)
    let $remove-refs as item()* :=
        try {
            ice:remove-reference-from-page($locale, $uri, $id)
        } catch ($e) {
            xdmp:trace("ldse-action", "Failed to Remove Custom-Page Refs"),
            xdmp:trace("ldse-action", $e)
        }
    return (
        element {fn:node-name($file)} {
            attribute status {$status},
            $file/@* except $file/(@status|@uri|@page),
            ldsemeta:get-meta($file, $id, $locale, (), $status),
            $file/* except $file/ldse:ldse-meta
        }
    )
};

declare function default:delete-transform(
    $action as xs:string,
    $file as element()
) as element() {
    let $status as xs:string := settings:get-action-meta-status($action)
    let $locale as xs:string := ldsemeta:get-document-locale($file)
    let $id as xs:string := ldsemeta:get-document-id($file)
    return (
        element {fn:node-name($file)} {
            attribute status {$status},
            $file/@* except $file/@status,
            ldsemeta:get-meta($file, $id, $locale, (), $status),
            $file/* except $file/ldse:ldse-meta
        }
    )
};

declare function default:update-search(
    $search as element(ldse:search),
    $doc-uri as xs:string,
    $file as element(),
    $orig-file as element()?
) as item()* {
    if (fn:local-name($file) eq 'ldswebml') then (
        if ($search = "send") then (
            gs:add($file)
        ) else if ($search = "remove") then (
            gs:remove($file)
        ) else ()
    ) else ()
};

declare function default:document-replace(
    $existing as element()*,
    $new as element()*
) as item() {
    document:document-replace($existing, $new)
};

declare function default:save-file(
    $mode as xs:string,
    $doc-uri as xs:string,
    $file as item(),
    $orig-file as element()?,
    $options as element(options)?
) as item()* {

    let $c as xs:string* := $options/collection/text()
    let $p as element(sec:permission)* := $options/sec:permission
    return (
        if ( function:invoke-required($mode) ) then (
            let $func as xdmp:function := xdmp:function(xs:QName("document:document-insert"))
            return (
                function:apply($func, $mode, $doc-uri, $file, $c, $p, ())
            )
        ) else (
            document:document-insert($doc-uri, $file, $c, $p, ())
        )
    )
};

declare function default:delete-file(
    $mode as xs:string,
    $doc-uri as xs:string,
    $file as item(),
    $orig-file as element()?
) as item()* {
    if ( function:invoke-required($mode) ) then (
        let $func as xdmp:function := xdmp:function(xs:QName("document:document-delete"))
        return (
            function:apply($func, $mode, $doc-uri)
        )
    ) else (
        document:document-delete($doc-uri)
    )
};

declare function default:get-ldse-roles() as element(ldse:roles)? {
    $settings:ldse-roles
};

declare function default:get-contributor() as element(ldse:contributor)? {
   default:get-contributor(())
};

declare function default:get-contributor($user as xs:string?) as element(ldse:contributor)? {
     if (core:is-ldse-enabled()) then (
         cts:search(/ldse:contributor,
             cts:and-query((
                 (: We do not want the core:get-filter-query() here :)
                 cts:directory-query(core:get-site-root(), 'infinity'),
                 cts:element-value-query( xs:QName('ldse:name'), ( $user, fn:lower-case(ac:getUserName()) )[1], ('unstemmed','case-insensitive'))
             ))
         )
     ) else ()
};

declare variable $all-locales as xs:string* := default:get-all-locales();
declare function default:get-all-locales() as xs:string* {
    default:get-supported-languages()/@key
};

declare variable $all-langs as xs:string* := default:get-all-langs();
declare function default:get-all-langs() as xs:string* {
    default:get-supported-languages()/@key
};

declare function default:get-supported-languages() as element(language)* {
    cts:search(/supportedLanguages,
        cts:and-query((
            core:get-filter-query(),
            if ( fn:exists($site-param) ) then (
                cts:element-attribute-value-query(xs:QName('supportedLanguages'), xs:QName('site'), $site-param, 'exact')
            ) else ()
        ))
    )/language
};

declare variable $all-locales-with-countries as xs:string* := default:get-all-locales-with-countries();
declare function default:get-all-locales-with-countries() as xs:string* {
    fn:distinct-values((
        $all-locales,
        util:get-country-locales()
    ))
};

declare variable $all-langs-with-counties as xs:string* := get-all-langs-with-countries();
declare function get-all-langs-with-countries() as xs:string*  {
    fn:distinct-values((
        $all-langs,
        util:get-country-sites()/language/@key
    ))
};

declare function default:get-contributor-name($user as xs:string) as xs:string {
    let $val as element(ldse:contributor)? :=
        cts:search(/ldse:contributor,
            cts:and-query((
                core:get-filter-query(),
                cts:element-value-query(xs:QName('ldse:name'), fn:lower-case($user), "case-insensitive")
            ))
        )[1]
    return (
        if (fn:empty($val/ldse:name/@display) or $val/ldse:name/@display = "") then (
            $user
        ) else (
            fn:string($val/ldse:name/@display)
        )
    )
};

declare function default:template-apply($title as xs:string, $pageUri as xs:string, $page as element(page)) as item()+ {
    template:apply($title, $pageUri, $page)
};

(:~
 : This function ensures that a URL has a language if required. It tries to do this while keeping the URL in tact and in roughly the same order of parameters as when the URL was called.
 :
 : @param $url The full url
 : @param $locale The language that we will add to the URL if no locale is found
 : @param $additional-params A string with additional params to add once the $locale is added to the URL
 : @param $shared-prefix The prefix of the site, $settings:shared-prefix if none is provided
 : @param $host The host, default $util:host if non provided
 : @param $exclude-lang-extensions A list of extensions that do not require a locale
 :
 : @return The full url with the locale added to the querystring in the first position
 :)
declare function default:build-url(
    $url as xs:string,
    $locale as xs:string,
    $additional-params as xs:string?
) as xs:string {
    default:build-url($url, $locale, $additional-params, $settings:shared-prefix, $util:host, $settings:exclude-lang-extensions)
};
declare function default:build-url(
    $url as xs:string,
    $locale as xs:string,
    $additional-params as xs:string?,
    $shared-prefix as xs:string?,
    $host as xs:string?,
    $exclude-lang-extensions as xs:string*
) as xs:string {
    if ( fn:starts-with($url, '//') ) then (
        $url
    ) else (
        let $url as xs:string :=
            if ( $shared-prefix != "" and fn:not(fn:matches($url, '^https?://')) and fn:not( fn:starts-with($url, $shared-prefix) ) and fn:not($settings:new-dynamic = "true") ) then (
                fn:concat($shared-prefix, $url)
            ) else ( $url )
        let $url-parts as element(url-parts) := util:get-url-parts($url)
        let $url-domain as xs:string? := fn:string-join(($url-parts/protocol[. != ""], $url-parts/domain[. != ""]), '://')[ . != ""]
        let $domain as xs:string? := ($url-domain, $host)[1]
        let $uri as xs:string? := $url-parts/uri[. != ""]
        (: tokenize on the ? or &amp; to allow get params separated
         : join together on &amp; those that are not blank
         : keep if the entire thing is not blank
         :)
        let $url-params as xs:string? := util:clean-url-params($url-parts/params[. != ""])
        let $additional-params as xs:string? := util:clean-url-params($additional-params)

        let $params as xs:string? := fn:string-join(($url-params, $additional-params), '&amp;')[. ne '']
        let $is-extension-to-exclude as xs:boolean* :=
            fn:map(
                function($ext) { fn:ends-with(fn:lower-case($url), $ext) },
                $exclude-lang-extensions
            )
        let $contains-lang as xs:boolean := fn:matches($params, '[&amp;]?lang=')

        let $url-params as xs:string? :=
            if ($contains-lang or $is-extension-to-exclude ) then (
                (: exclude all params, including locale :)
                fn:concat('?', $params)[. ne '?']
            ) else (
                fn:string-join((util:split-locale-param($locale), $params), '&amp;')
            )
        let $hash as xs:string? := $url-parts/hash
        return (
            fn:concat($domain, $uri, $url-params, $hash)
        )
    )
};

declare function default:get-title($doc as element()) as xs:string? {
    let $form-name as xs:string? := ldsemeta:get-form-options($doc)/form
    let $form as element(ldse:formTemplate)? := form:get-form($form-name)
    let $xpath as xs:string? := $form/ldse:document-title/xs:string(.)
    let $title as xs:string? :=
        if (fn:exists($xpath) and fn:not($xpath = "")) then (
            fn:normalize-space(
                fn:string-join(
                    for $n as item() in util:value($doc, $xpath)
                    return fn:string($n)
                , ' ')
            )
        ) else ( translation:getTitle($doc) )
    return $title
};

declare function default:get-type($doc as element()) as xs:string? {
    let $type as xs:string? := fn:local-name($doc)
    return
        if ($type = "ldswebml") then (
            $doc/@type
        ) else (
            fn:string-join( ($type, $doc/@type), ":")
        )
};

declare function default:warehouse($uri as xs:string, $doc as element()) as xs:boolean {
    typeswitch ($doc)
    case element(scheduled-task) return ( fn:false() )
    case element(ldse:report) return ( fn:false() )
    case element(rewriteRules) return ( fn:false() )
    case element(ldse:translation-history) return ( fn:false() )
    case element(ldse:clear-cache-log-entry) return ( fn:false() )
    case element(ldse:contributor) return ( fn:true() )
    case element(ldse:bc-folder) return ( fn:false() )
    case element(binary-content) return ( fn:false() )
    case element(ldse:seo-data) return ( fn:false() )
    case element(generated-report) return ( fn:false() )
    case element(hldse:history) return ( fn:true() )
    case element(vldse:version) return ( fn:true() )
    case element(bldse:brightcove-details) return ( fn:true() )
    case element(cldse:correlation) return ( fn:true() )
    case element(ldse:ldse-settings) return ( fn:true() )
    case element(ldse:warehouse-delete) return ( fn:false() )
    case element(enrich:keyword) return ( fn:false() )
    case element(enrich:organization) return ( fn:false() )
    case element(enrich:person) return ( fn:false() )
    case element(enrich:role) return ( fn:false() )
    case element(enrich:location) return ( fn:false() )
    case element(enrich:languages) return ( fn:false() )
    default return (
        fn:exists($doc/ldse:ldse-meta)
    )
};

declare function default:get-live-domain($file as element()?, $locale as xs:string?) as xs:string? {
    $settings:live-domain
};

declare function default:get-domain($file as element()?, $locale as xs:string?) as xs:string? {
    settings:get-mode-domain($core:mode)
};

declare function default:updateUri($newFile as element(), $locale as xs:string, $origFile as element()?) as element() {
    $newFile
};

declare function default:get-environmentConfig() as element(environment) {
    (cts:search(/environment, core:get-filter-query()), <environment/>)[1]
};

declare function default:get-siteProperties() as element(siteProperties)? {
    (cts:search(/siteProperties, core:get-filter-query()))[1]
};

declare function default:get-siteProperties($context) as element(siteProperties)? {
    (cts:search(/siteProperties, cts:directory-query($context, 'infinity')))[1]
};

declare function default:get-mode($port) as xs:string {
    settings:get-mode-default($port)
};

declare function default:build-default-json-config($arrays as item()*) {
    let $config := json:config("custom")
    let $arrays as xs:QName* :=
        for $array as xs:string in ( $settings:element-arrays, $arrays )
        return (
            xs:QName($array)
        )
    return (
        map:put($config, "array-element-names", $arrays),
        map:put($config, "text-value","_value"),
        map:put($config, "whitespace","ignore"),
        map:put($config, 'ignore-element-names', (xs:QName('meta'))),
        map:put($config, 'ignore-attribute-names', (xs:QName('its:translate'))),
        map:put($config, 'ignore-element-names', (xs:QName('ldse:ldse-meta'))),
        $config
    )
};

declare function default:transform-to-json($root as element(), $arrays as item()*) {
    let $ps as element()* := $root//node()[@type = "wysiwyg"]
    let $root-arrays as element()* := $root//node()[@type = 'array']
    let $root-arrays as xs:string* :=
        if ( fn:exists($root-arrays) ) then (
            for $root-array in $root-arrays
            return ( fn:local-name($root-array) )
        ) else ()
    let $root as element() := if ( fn:exists($ps) ) then ( util:quote-paras($root, $ps, 1) ) else ( $root )
    return (
        json:transform-to-json($root, default:build-default-json-config(( $arrays, $root-arrays )))
    )
};
