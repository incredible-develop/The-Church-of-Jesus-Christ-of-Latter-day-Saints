xquery version "1.0-ml";

(: File should be saved at "/custom/lds-edit/ldse-core.xqy" :)
module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core";

import module namespace site = "http://lds.org/code/shared/lds-edit/custom/ldse-site-core" at "/custom/lds-edit/ldse-site-core.xqy";

(: LDS-EDIT :)
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "ldse-settings.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "ldse-meta.xqy";
import module namespace history = "http://lds.org/code/shared/lds-edit/history/history" at "../history/history.xqy";
import module namespace version = "http://lds.org/code/lds-edit/versions" at "versions-functions.xqy";
import module namespace correlation = "http://lds.org/code/shared/lds-edit/correlation" at "../correlation/modules/correlation-functions.xqy";
import module namespace default = "http://lds.org/code/shared/lds-edit/ldse-default-core" at "ldse-default-core.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare option xdmp:mapping "true";

declare variable $site as xs:string := site:get-site-name();
declare variable $ldse-settings as element(ldse:ldse-settings) := core:get-ldse-settings(fn:false());

declare function core:get-ldse-settings($for-update as xs:boolean) as element(ldse:ldse-settings) {
    site:get-ldse-settings($for-update)
};

declare variable $environmentConfig as element(environment) := site:get-environmentConfig(); 
declare function core:get-environmentConfig() as element(environment) {
    site:get-environmentConfig()
};

declare variable $siteProperties as element(siteProperties)? := site:get-siteProperties(); 
declare function core:get-siteProperties() as element(siteProperties)? {
   site:get-siteProperties()
};

declare function core:get-siteProperties($context) as element(siteProperties)? {
    site:get-siteProperties($context)
};

declare function core:get-mode($port) as xs:string {
	site:get-mode($port)
};

(:
    ****************************************************************
    1. All default functions should only be called by the site core.
    
    ****************************************************************
:)
(:
    Read
    Collection or directory or both ie Filter-Query
    save opts
    Update / Save / Delete
    different directory/databases, maintain permission/collections

    is/has - boolean
    get - query
    build/create - new
    set - please no???
:)

declare variable $mode as xs:string := core:get-mode(); (: Sub-environment :)
declare variable $task-port as xs:integer := core:get-task-port();
declare variable $port as xs:integer? := (xdmp:get-request-port(), $task-port)[1];

declare function core:set-mode($new-mode as xs:string) as empty-sequence() {
    xdmp:set($mode, $new-mode)
};

declare function core:set-port($new-port as xs:integer) as empty-sequence() {
    xdmp:set($port, $new-port)
};
declare function core:get-port() as xs:integer {
    $port
};

(: preview, published :)
declare function core:get-mode() as xs:string {
    settings:get-mode($port)
};

(: get-mode-root() :)
    declare function core:get-mode-root() as xs:string {
        settings:get-mode-root($mode)
    };
    declare function core:get-mode-root($mode as xs:string) as xs:string {
        settings:get-mode-root($mode)
    };

(: is-ldse-enabled() :)
    declare function core:is-ldse-enabled() as xs:boolean {
        settings:is-ldse-enabled($mode)
    };
    declare function core:is-ldse-enabled($mode as xs:string) as xs:boolean {
        settings:is-ldse-enabled($mode)
    };

(: get-front-end-host() :)
    declare function core:get-front-end-host() as xs:string? {
        settings:get-front-end-host($mode)
    };
    declare function core:get-front-end-host($mode as xs:string) as xs:string? {
        settings:get-front-end-host($mode)
    };
    
(: get-site-root() :)    
    declare function core:get-site-root() as xs:string {
        site:get-site-root($mode)
    };
    declare function core:get-site-root($mode as xs:string) as xs:string {
        site:get-site-root($mode)
    };

declare function core:get-display-uri($uri as xs:string) as xs:string {
    site:get-display-uri($uri)
};

declare function core:get-ldspub-cdn-uri($uri as xs:string) as xs:string {
    default:get-ldspub-cdn-uri($uri)
};

declare function core:build-db-path(
    $uri as xs:string?, 
    $locale as xs:string?, 
    $id as xs:string?, 
    $file as element()?
) as xs:string {
   site:build-db-path($uri, $locale, $id, $file, ())
};

(:
    <options>
        <folder></folder>
        <file-prefix></file-prefix>
    </options>
:)
declare function core:build-db-path(
    $uri as xs:string?, 
    $locale as xs:string?, 
    $id as xs:string?, 
    $file as element()?, 
    $options as element(options)?
) as xs:string {
    site:build-db-path($uri, $locale, $id, $file, $options)
};

declare function core:convert-db-path(
    $mode as xs:string, (: draft, preview, published :)
    $path as xs:string
) as xs:string {
    site:convert-db-path($mode, $path)
};

declare function core:preform-action-and-update(
    $action as xs:string,
    $file as element()
) as item()* {
    core:preform-action-and-update($action, $file, ())
};

declare function core:preform-action-and-update(
    $action as xs:string,
    $file as element(),
    $options as element(options)?
) as item()* {
    let $db-path as xs:string? := xdmp:node-uri($file)
    let $db-path as xs:string := 
        if (fn:empty($db-path) or $db-path = "") then (
            core:build-db-path(
                ldsemeta:get-document-uri($file),
                ldsemeta:get-document-locale($file),
                ldsemeta:get-document-id($file),
                $file,
                ()
            )
        ) else ( $db-path ) 
    let $save as item()* := core:update-file($action, $db-path, $file, $file, $options)
    return (
        $file
    )
};

declare function core:action-transform(
    $action as xs:string,
    $file as element()
) as element() {
    if ($action = "ldse:publish") then (
        site:publish-transform($action, $file)
    ) else if ($action = "ldse:unpublish") then (
        site:unpublish-transform($action, $file)
    ) else if ($action = "ldse:remove") then (
        site:remove-transform($action, $file)
    ) else if ($action = "ldse:delete") then (
        site:delete-transform($action, $file)
    ) else (
        site:action-transform($action, $file)
    )
};

declare function core:update-search(
    $search as element(ldse:search),
    $doc-uri as xs:string, 
    $file as element(), 
    $orig-file as element()?
) as item()* {
    site:update-search($search, $doc-uri, $file, $orig-file)
};

declare function core:update-file(
    $action as xs:string, 
    $doc-uri as xs:string, 
    $file as element()
) as empty-sequence() {
    core:update-file($action, $doc-uri, $file, (), ())
};

(:~ 
    update-file will either call save-file or delete-file or both
    @param $action - ("ldse:preview", "ldse:publish", "ldse:publish-all", "ldse:remove-from-page", "ldse:delete", "ldse:unpublish" ...)
    @param $doc-uri - is the location to update the file
    @param $file - is the xml to be updated that has any needed meta updates
    @param $orig-file - is the orignal file if exists
    return item()*
~:)
declare function core:update-file(
    $action as xs:string, 
    $doc-uri as xs:string, 
    $file as element(), 
    $orig-file as element()?
) as empty-sequence() {
    site:update-file($action, $doc-uri, $file, $orig-file, ())
};

declare function core:update-file(
    $action as xs:string, 
    $doc-uri as xs:string, 
    $file as element(), 
    $orig-file as element()?,
    $options as element(options)?
) as empty-sequence() {
    site:update-file($action, $doc-uri, $file, $orig-file, $options)
};

declare function core:document-replace(
    $existing as element()*, 
    $new as element()*
) as empty-sequence() {
    let $doc as item() := site:document-replace($existing, $new)
    return (
        history:update($doc, $mode),
        version:save($mode, $doc, xdmp:node-uri($existing))
    )
};

(:~ 
    save-file will either call the  document:document-insert 
    @param $doc-uri - is the location to save the file
    @param $file - is the xml to be save that has any needed meta updates
    @param $orig-file - is the orignal file if exists
    return item()*
~:)
declare function core:save-file(
    $doc-uri as xs:string, 
    $file as item(), 
    $orig-file as element()?
) as item()* {
    core:save-file($mode, $doc-uri, $file, $orig-file, ())
};
(:~ 
    save-file will either call the  document:document-insert 
    @param $mode - ("draft", ""preview", "publish")
    @param $doc-uri - is the location to save the file
    @param $file - is the xml to be save that has any needed meta updates
    @param $orig-file - is the orignal file if exists
    return item()*
~:)
declare function core:save-file(
    $mode as xs:string, 
    $doc-uri as xs:string, 
    $file as item(), 
    $orig-file as element()?
) as item()* {
    core:save-file($mode, $doc-uri, $file, $orig-file, ())
};

declare function core:save-file(
    $mode as xs:string, 
    $doc-uri as xs:string, 
    $file as item(), 
    $orig-file as element()?,
    $options as element(options)?
) as item()* {
    version:save($mode, $file, $doc-uri),
    history:update($file, $mode),
    site:save-file($mode, $doc-uri, $file, $orig-file, $options)
};

(:~ 
    delete-file will either call the  document:document-delete 
    @param $doc-uri - is the location to delete the file
    @param $file - is the xml to be save that has any needed meta updates
    @param $orig-file - is the orignal file if exists
    return item()*
~:)
declare function core:delete-file(
    $doc-uri as xs:string, 
    $file as item(), 
    $orig-file as element()?
) as item()* {
    core:delete-file($mode, $doc-uri, $file, $orig-file)
};
(:~ 
    delete-file will either call the  document:document-delete 
    @param $mode - ("preview", "publish", "remove-from-page", "delete", "unpublish" ...)
    @param $doc-uri - is the location to delete the file
    @param $file - is the xml to be save that has any needed meta updates
    @param $orig-file - is the orignal file if exists
    return item()*
~:)
declare function core:delete-file(
    $p-mode as xs:string, 
    $doc-uri as xs:string, 
    $file as item(), 
    $orig-file as element()?
) as item()* {
    version:delete-all($p-mode, $file),
    history:update($file, $p-mode),
    site:delete-file($p-mode, $doc-uri, $file, $orig-file),
    if ( $p-mode = $mode ) then ( correlation:delete-file($file) ) else ()
};

declare function core:get-filter-query() as cts:query* {
   site:get-filter-query()
};

declare function core:get-ldse-roles() as element(ldse:roles)? {
    site:get-ldse-roles()
};

declare function core:get-contributor() as element(ldse:contributor)? {
    site:get-contributor()
};

declare function core:get-contributor($user as xs:string?) as element(ldse:contributor)? {
    site:get-contributor($user)
};

declare function core:get-all-locales() as xs:string* {
    site:get-all-locales()
};

declare function core:get-all-langs() as xs:string* {
    site:get-all-langs()
};

declare function core:validate-check($check as element(ldse:check), $map as map:map, $actual as item()) as xs:boolean{
    site:validate-check($check, $map, $actual)
};

declare function core:load-ice-map(
    $map as map:map,
    $locale as xs:string,
    $type as xs:string,
    $file as element()?,
    $current-page as xs:string,
    $options as element()* (: as element(options|defaults)+ :)
) as empty-sequence() {
    site:load-ice-map($map, $locale, $type, $file, $current-page, $options)
};

declare function core:get-contributor-name($user as xs:string) as xs:string {
    site:get-contributor-name($user)
};

declare function core:template-apply($title as xs:string, $pageUri as xs:string, $page as element(page)) as item()+ {
    site:template-apply($title, $pageUri, $page)
};

declare function core:history($doc as item(), $hist-doc as item()) as element()* {
    site:history($doc, $hist-doc)
};

(: 
   If this document is under version control it returns the maximum number of versions allowed 
   0 if the document is not under control
:)
declare function core:is-managed($doc as element()) as xs:int {
    site:is-managed($doc)
};

declare function core:build-url($url as xs:string, $locale as xs:string, $params as xs:string?) as xs:string? {
    site:build-url($url, $locale, $params)
};

declare function core:get-title($file as element()) as xs:string? {
    site:get-title($file)
};

declare function core:get-type($file as element()) as xs:string? {
    site:get-type($file)
};

declare function core:warehouse($uri as xs:string, $doc as element()) as xs:boolean {
    if (settings:is-moded-warehoused($core:mode)) then (
        site:warehouse($uri, $doc)
    ) else ( fn:false() )
};

declare function core:get-task-port() as xs:integer {
    site:get-task-port()
};

declare function core:get-live-domain($file as element()?, $locale as xs:string?) as xs:string {
    site:get-live-domain($file, $locale)
};

declare function core:get-domain($file as element()?, $locale as xs:string?) as xs:string {
    site:get-domain($file, $locale)
};

declare function core:updateUri($newFile as element(), $locale as xs:string, $origFile as element()?) as element() {
    site:updateUri($newFile, $locale, $origFile)
};

declare function core:transform-to-json($root as node(), $arrays as item()*) {
    site:transform-to-json($root, $arrays)
};