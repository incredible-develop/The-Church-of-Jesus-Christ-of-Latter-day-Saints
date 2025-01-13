xquery version "1.0-ml";

module namespace fast  = "http://lds.org/code/shared/lds-edit/fast-i18n";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../modules/utility-functions.xqy";

import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../modules/ldse-core.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../modules/ldse-settings.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../modules/access-control-functions.xqy";
import module namespace memUpdate = "http://lds.org/code/shared/common/memory-update" at "/shared/common/util/inMemoryUpdate.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "../../modules/ldse-meta.xqy";
import module namespace json = "http://marklogic.com/json" at "../../modules/fasterjson.xqy";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";

(: 
   Requires a range index on prop:last-modified
   May require an amp for get-server-field / set-server-field
:)
declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace xhtml = "http://www.w3.org/1999/xhtml";

declare option xdmp:mapping "true";

declare variable $DEPRECATED as empty-sequence() := util:deprecated(());
declare variable $FAST-KEY as xs:string := 'ldse:fast-i18n';
declare variable $FAST-MAP as map:map :=  util:get-server-field($FAST-KEY, map:map());
declare variable $REQUEST-CACHE as map:map := map:map();

declare variable $OLD as xs:dateTime := xs:dateTime(xs:date("1700-01-01"));
declare variable $seo-title-key as xs:string := xdmp:get-request-field("seo-title-key", "");
declare variable $MODE as xs:string := $core:mode;

declare variable $DEFAULT-LOCALE as xs:string := ($settings:default-locale, "eng")[1];
declare variable $ROOTS as xs:QName* := (xs:QName('resource-bundle'),xs:QName('resources'));
declare variable $ACCESSED-HIDDEN-STRINGS-KEY as xs:string := "fast-i8n-accessed-strings";

declare private function fast:load-map(
    $mode as xs:string,
    $locale as xs:string, 
    $lang-key as xs:string,
    $time-key as xs:string,
    $new-timestamp as xs:dateTime
) as empty-sequence() {
    let $country-lang as xs:string? := fn:substring-before($locale, '-')
    let $default as map:map? := if ($country-lang != "") then ( fast:get-locale-map($mode, $country-lang) ) else ()
    let $map as map:map := map:map(
                    <map:map xmlns:map="http://marklogic.com/xdmp/map" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema">{
                        fast:get-map-entries($default), (: Load Default Language first :)
                        fast:find-map-entries($locale) 
                    }</map:map>
                )
    let $put as empty-sequence() := map:put($FAST-MAP, $lang-key, $map)
    let $put as empty-sequence() := map:put($FAST-MAP, $time-key, $new-timestamp)
    let $set as item()* := util:set-server-field($FAST-KEY, $FAST-MAP)
    return ()
};

declare function fast:find-map-entries(
    $locale as xs:string
) as element(map:entry)* {
    let $docs as element()* :=
        cts:search(/(resources|resource-bundle),
            cts:and-query((
                core:get-filter-query(),
                cts:or-query((
                    cts:element-attribute-value-query( $ROOTS, xs:QName('xml:lang'), $locale, "unstemmed"),
                    cts:element-attribute-range-query(xs:QName('ldse:document'), xs:QName('locale'), '=', $locale, "collation=http://marklogic.com/collation/"),
                    cts:element-value-query(xs:QName('locale'), $locale, "unstemmed")
                ))
            )),
            "unfiltered"
        )
    (: Loop over docs convert if not in map form :)
    for $doc as element() in $docs
    order by $doc/@level ascending, $doc/@sequence ascending
    return (   
        if ( fn:exists($doc/map:map) ) then (
            $doc/map:map/map:entry
        ) else (
            fast:convert-bundles($doc, $locale)
        )
    )
};

(: Returns map:entry xml from a map:map :)
declare function fast:get-map-entries($map as map:map) as element(map:entry)* {
    element map { $map }/map:map/map:entry
};

(: Returns the newest timestamp for the desired language :)
declare function fast:get-timestamp(
    $locale as xs:string,
    $time-key as xs:string
) as xs:dateTime {
    let $timestamp as xs:dateTime? := map:get($REQUEST-CACHE, $time-key)
    return (
        if ( fn:exists($timestamp) ) then (
            $timestamp
        ) else (
            let $timestamp as xs:dateTime? := (
                    cts:element-values(
                        xs:QName('prop:last-modified'),
                        (),
                        ("properties", "descending", "limit=1"),
                        cts:document-fragment-query(
                            cts:and-query((
                                core:get-filter-query(),
                                cts:or-query((
                                    cts:element-attribute-value-query( $ROOTS, xs:QName('xml:lang'), ((:$DEFAULT-LOCALE,:) $locale), "unstemmed"),
                                    cts:element-query( $ROOTS, cts:element-attribute-range-query(xs:QName('ldse:document'), xs:QName('locale'), '=', ((:$DEFAULT-LOCALE, :)$locale), "collation=http://marklogic.com/collation/")
                                    ),
                                    cts:element-value-query(xs:QName('locale'), ((:$DEFAULT-LOCALE, :) $locale), "unstemmed")
                                ))
                            ))
                        )
                   ), 
                   $OLD
               )[1]
            return (
                $timestamp,
                map:put($REQUEST-CACHE, $time-key, $timestamp)
            )
        )
    )
};

declare function fast:get-locale-map(
    $mode as xs:string, 
    $locale as xs:string
) as map:map? {
    let $lang-key as xs:string := fn:concat($mode, $locale)
    let $time-key as xs:string := fn:concat($lang-key, '/timestamp')
    let $current-timestamp as xs:dateTime? := map:get($FAST-MAP, $time-key)
    let $new-timestamp as xs:dateTime? := fast:get-timestamp($locale, $time-key)
    let $load as empty-sequence() :=
        if ($current-timestamp != $new-timestamp or fn:empty($current-timestamp)) then (
            fast:load-map($mode, $locale, $lang-key, $time-key, $new-timestamp)
        ) else ()
    return map:get($FAST-MAP, $lang-key)
};

(:~
    @param $locale for the resource
    @param $key of the need resource
    
    @return the value for the given locale in the current Mode,  defaulting to the $settings:default-locale value
~:)
declare function fast:get-value(
    $locale as xs:string,
    $key as xs:string
) as item()* {
    fast:get-value($MODE, $locale, $key)
};

declare function fast:get-uncached-value(
    $bundle-name as xs:string?,
    $locale as xs:string?,
    $template-id as xs:string?,
    $bundle-key as xs:string?
) as element()? {
    let $bundle as element()? := 
        cts:search(/(resources|resource-bundle),
            cts:and-query((
                core:get-filter-query(),
                cts:element-value-query(xs:QName('name'), $bundle-name, 'exact'),
                cts:or-query((
                    cts:element-attribute-value-query( $ROOTS, xs:QName('xml:lang'), $locale, "unstemmed"),
                    cts:element-attribute-range-query(xs:QName('ldse:document'), xs:QName('locale'), '=', $locale, "collation=http://marklogic.com/collation/"),
                    cts:element-value-query(xs:QName('locale'), $locale, "unstemmed")
                ))
            )),
            "unfiltered"
        )
    let $key as xs:string? := 
        if ( fn:exists($template-id[. != '']) ) then (
            $template-id || '-' || $bundle-key
        ) else ( $bundle-key )
    let $entry as element(entry)? := $bundle/properties/entry[@key = $key]
    return $entry/value
};
(:~
    @param $mode from which to get the resource
    @param $locale for the resource
    @param $key of the need resource
    
    @return the value for the given locale in give Mode,  defaulting to the $settings:default-locale value
~:)
declare function fast:get-value(
    $mode as xs:string, 
    $locale as xs:string,
    $key as xs:string
) as item()* {
    map:get( fast:get-locale-map($mode, $locale), $key )
};

(: CONVERSION FUNCTIONS :)
declare function fast:convert-bundles(
    $doc as element(), 
    $locale as xs:string
) as element(map:entry)* {
    let $tempMap as map:map := map:map()
    let $_ :=
        let $bundle as xs:string? := $doc/name
        for $entry as element() in $doc/(properties/entry | resource)
        let $key as xs:string := 
            if ($bundle != '') then (
                fn:concat($bundle, ":", $entry/@key)
            ) else (
                $entry/@key
            )
        where $key
        return (
            map:put($tempMap, $key, $entry/value/node())
        )
    return (
        fast:get-map-entries($tempMap)
    )
};


(:~
    @param $locale for the resource
    @param $key of the resource
    
    @return if lds edit is enabled and the user has permissions, html for editing the string. Othewise just the string. Executed in the current mode.
~:)
declare function fast:get-string-ice(
    $locale as xs:string, 
    $key as xs:string
) as item()* {
    fast:get-string-ice($locale, $key, $MODE)        
};

declare function fast:get-string-ice-json(
    $locale as xs:string, 
    $key as xs:string
) as item()* {
    fast:get-string-ice-json($locale, $key, $MODE)        
};
(:~
    @param $locale for the resource
    @param $key of the resource
    @param $mode in which to find the resource
    
    @return if lds edit is enabled and the user has permissions, html for editing the string. Othewise just the string.
~:)
declare function fast:get-string-ice(
    $locale as xs:string, 
    $key as xs:string, 
    $mode as xs:string
) as item()* {
    let $string as item()* := get-value($mode, $locale, $key)
    let $default as item()* := if (fn:empty($string)) then ( fast:get-value($mode, $DEFAULT-LOCALE, $key) ) else ($string)
    return if (ac:has-permission("ldse:edit-rice", $locale, ())) 
        then fast:add-edit-resource-link($mode, $locale, $key, $string)
        else $default
};

declare function fast:get-string-ice-json(
    $locale as xs:string, 
    $key as xs:string, 
    $mode as xs:string
) as item()* {
    let $string as item()* := get-value($mode, $locale, $key)
    let $default as item()* := if (fn:empty($string)) then ( fast:get-value($mode, $DEFAULT-LOCALE, $key) ) else ($string)
    return if (ac:has-permission("ldse:edit-rice", $locale, ())) 
        then fast:add-edit-resource-link-json($mode, $locale, $key, $string)
        else $default
};

(:~
    @param $locale for the resource
    @param $key of the resource
    
    @return if lds edit is enabled and the user has permissions, html for editing the string. Othewise just the string. Executed in the current Mode
~:)
declare function fast:get-string-ice-hidden(
    $locale as xs:string, 
    $key as xs:string
) as item()* {
    fast:get-string-ice-hidden($locale, $key, $MODE)
};

(:~
    @param $locale for the resource
    @param $key of the resource
    @param $mode in which to find the resource
    
    @return if lds edit is enabled and the user has permissions, add resource to the list of accessed hidden resources. Othewise just the string.
~:)
declare function fast:get-string-ice-hidden(
    $locale as xs:string, 
    $key as xs:string, 
    $mode as xs:string
) as item()* {
    let $string as item()* := 
        for $value as item() in fast:get-value($mode, $locale, $key)
        return (
            if ( fn:exists($value) and fn:not(fn:normalize-space(xdmp:quote($value)) = '') ) then ( $value ) else ()
        )
    let $default as item()* := if (fn:empty($string)) then ( fast:get-value($mode, $DEFAULT-LOCALE, $key) ) else ($string)
    return 
        if (ac:has-permission("ldse:edit-rice", $locale, ())) then (
            let $used as item()* := map:get($REQUEST-CACHE, $ACCESSED-HIDDEN-STRINGS-KEY)
            let $values as item()* := ($used[. != $key], $key)
            let $put as empty-sequence() := map:put($REQUEST-CACHE, $ACCESSED-HIDDEN-STRINGS-KEY, $values)
            return if (fn:empty($string)) then (fn:concat("?", $key, "?")) else ($string)
        ) else ( $default )
};

(:~
    @param $locale for the resource
    @param $key of the resource
    @string $string the display string 
    
    @return html segment formatted for editing strings via RICE
~:)
(: TODO: Change RICE.editResource to not use a bundle, instead just use the locale and key :)
declare function fast:add-edit-resource-link($locale as xs:string, $key as xs:string, $string as item()*) as element(span) {
    fast:add-edit-resource-link($MODE, $locale, $key, $string)
};

declare function fast:add-edit-resource-link($mode as xs:string, $locale as xs:string, $key as xs:string, $string as item()*) as element(span) {
    let $bundle as xs:string := fn:substring-before($key, ":")
    let $key as xs:string := if ($bundle = "") then $key else fn:substring-after($key, ":")
    let $string as item()* := if (fn:empty($string)) then (fn:concat("?", $key, "?")) else ($string)
    return ( 
        <span class="resourceIce" id="{fn:concat('resourceIce-', $key)}">
            {$string}
            {
	            if($mode = 'preview') then
                    <a class="edit-resource" href="#d" onclick="RICE.editResource({xdmp:to-json-string($locale)}, {xdmp:to-json-string($bundle)}, {xdmp:to-json-string($key)}); return false;">
                        <img title="Edit Text" border="0" src="{$settings:cdn-path}/lds-edit/images/plus_hover.png"/>
                    </a>
                else ()
            }
        </span>
    )
};

declare function fast:add-edit-resource-link-json($locale as xs:string, $key as xs:string, $string as item()*) as element(span) {
    fast:add-edit-resource-link-json($MODE, $locale, $key, $string)
};

declare function fast:add-edit-resource-link-json($mode as xs:string, $locale as xs:string, $key as xs:string, $string as item()*) {
    let $bundle as xs:string := fn:substring-before($key, ":")
    let $key as xs:string := if ($bundle = "") then $key else fn:substring-after($key, ":")
    let $string as item()* := if (fn:empty($string)) then (fn:concat("?", $key, "?")) else ($string)
    return ( 
        json:obj((
            json:escapedKeyValue("locale", $locale),
            json:escapedKeyValue("bundle", $bundle),
            json:escapedKeyValue("key", $key),
            json:escapedKeyValue("cdnPath", $settings:cdn-path),
            json:escapedKeyValue("string", $string),
            json:escapedKeyValue("id", fn:concat('resourceIce-', $key))
        ))
(:        <span class="resourceIce" id="{fn:concat('resourceIce-', $key)}">
            {$string}
            <a class="edit-resource" href="#d" onclick="RICE.editResource({xdmp:to-json-string($locale)}, {xdmp:to-json-string($bundle)}, {xdmp:to-json-string($key)}); return false;">
                <img title="Edit Text" border="0" src="{$settings:cdn-path}/lds-edit/images/plus_hover.png"/>
            </a>
        </span>:)
    )
};

declare function fast:get-string-ipe(
    $locale as xs:string, 
    $key as xs:string
) as item()* {
    fast:get-string-ipe($locale, $key, $MODE)
};

declare function fast:get-string-ipe(
    $locale as xs:string, 
    $key as xs:string, 
    $mode as xs:string
) as item()* {
    let $string as item()* := get-value($mode, $locale, $key)
    let $default as item()* := if (fn:empty($string)) then ( fast:get-value($mode, $DEFAULT-LOCALE, $key) ) else ($string)
    let $bundle as xs:string := fn:substring-before($key, ":")
    let $sub-key as xs:string := if ($bundle = "") then $key else fn:substring-after($key, ":")
    return 
        if (ac:has-permission("ldse:edit-rice", $locale, ())) then (
            <span class="resourceIce html5editable" data-country="" data-lang="eng" data-locale="{$locale}" data-currentPage="/" data-currentUri="/" data-bundle="{$bundle}" data-key="{$sub-key}">
                {if (fn:empty($string)) then (fn:concat("?", $key, "?")) else ($string)}
            </span>
        ) else ($default)
};

(:~
    @param $locale for the resource
    @param $key of the resource
    @string $string the display string 
    
    @return a map of all the hidden resources that have been accessed up to this point in the request
~:)
(: TODO: Change RICE js to not use a bundle, instead just use the key :)
declare function fast:get-hidden-resources() as map:map? {
    let $map as map:map := map:map()
    
    let $keys as item()* := map:get($REQUEST-CACHE, $ACCESSED-HIDDEN-STRINGS-KEY)
    
    let $resources as element(resource)* := 
        for $key as item() in $keys
        let $bundle as xs:string? := fn:substring-before($key, ":")
        let $sub-key as xs:string? := if ($bundle = "") then $key else fn:substring-after($key, ":")
        return 
            <resource array="true">
                <bundle>{$bundle}</bundle>
                <key>{$sub-key}</key>
            </resource>
   let $_ as empty-sequence() := map:put($map, "list", $resources)
   return $map
};


(: ********************************************************************
    START Functions for Resource strings held in the page file
   ******************************************************************** :)
declare function fast:get-page-string-text($custom-page as element(), $key as xs:string) as item()* {
    let $string as item()* := fn:string-join($custom-page/resources/entry[@key = $key]/value/text(), ' ')
    return fast:get-page-default-for-empty($string, $key)
};

declare function fast:get-page-string-value($custom-page as element(), $key as xs:string) as item()* {
    let $string as item()* := $custom-page/resources/entry[@key = $key]/value/node()
    return fast:get-page-default-for-empty($string, $key)
};

declare function fast:get-page-default-for-empty($string as item()*, $key as xs:string) as item()* {
    if (core:is-ldse-enabled()) then (
        if (fn:empty($string) or $string = "") then (fn:concat("?", $key, "?")) else ($string)
    ) else (
        if (fn:empty($string) or $string = "") then "" else ($string)
    )
};

declare function fast:get-page-string-ice($locale as xs:string, $custom-page as element(), $key as xs:string) as item()* {
    let $string as item()* := fast:get-page-string-value($custom-page, $key)
    return if (ac:has-permission("ldse:edit-rice", $locale, ()) and core:is-ldse-enabled()) 
        then fast:add-edit-resource-link($locale, fn:concat("custom-page:", $key), $string)
        else $string
};

declare function fast:get-page-string-ice-hidden($locale as xs:string, $custom-page as element(), $key as xs:string) as item()* {
    let $string as item()* := fast:get-page-string-value($custom-page, $key)
    let $cache as empty-sequence() := if (ac:has-permission("ldse:edit-rice", $locale, ()) and core:is-ldse-enabled()) 
        then (
            let $new-key as xs:string := fn:concat("custom-page:", $key)
            let $used as item()* := map:get($REQUEST-CACHE, $ACCESSED-HIDDEN-STRINGS-KEY)
            let $values as item()* := ($used[. != $new-key], $new-key)
            let $put as empty-sequence() := map:put($REQUEST-CACHE, $ACCESSED-HIDDEN-STRINGS-KEY, $values)
            return ()
        )
        else ()
    return $string
};

(: creates custom-page if needed and added resources node :)
declare function fast:prepare-page-for-resources($lang as xs:string, $uri as xs:string, $custom-page as element()?) as item()* {
    if (core:is-ldse-enabled()) then (
        if (fn:exists($custom-page)) then (
            xdmp:node-insert-child($custom-page, <resources> </resources>)
        ) else (
            let $site as xs:string := $core:site
            let $langInEnglish as xs:string? := util:get-full-language-name-by-locale($lang)
            let $localePath as xs:string := fn:lower-case(if ($langInEnglish != '') then ($langInEnglish) else (fn:concat("country-sites/", $lang)))
            let $dbUrl as xs:string := if (fn:ends-with($uri,"/")) then (fn:concat($uri,"landing")) else ($uri)
            let $dbPath as xs:string := fn:concat($site, "/content/", $localePath, if ($site and $site ne 'ldsorg') then (fn:concat('/', $site)) else (), $dbUrl, "/")
            let $db-path as xs:string := core:build-db-path($dbUrl, $lang, "page", $custom-page, ())
            let $newPage as element(custom-page) :=
                <custom-page uri="{$uri}" locale="{$lang}" status="preview" id="{util:generate-unique-id($lang)}">
                    <resources></resources>
                </custom-page>
            return (
                core:save-file(core:get-mode(), $db-path, $newPage, ())
            )
        )
    ) else ()
};

declare function fast:insert-edit-page-resource(
    $lang as xs:string, 
    $custom-page as element(), 
    $uri as xs:string, 
    $key as xs:string, 
    $text as xs:string
) as item()* {
    let $string as xs:string? := $custom-page/resources/entry[@key = $key]
    return  if (fn:exists($string)) then (
        fast:edit-page-resource($lang, $custom-page, $uri, $key, $text)
    ) else (
        fast:insert-page-resource($lang, $custom-page, $uri, $key, $text)
    )
};

declare function fast:insert-page-resource($lang as xs:string, $custom-page as element(), $uri as xs:string, $key as xs:string, $text as item()*) as item()* {
    let $to-add as element(entry) := <entry key="{$key}" status="edited" translation="ready"><value>{$text}</value></entry>
    let $custom-page as item()* := 
        if ( fn:exists($custom-page) ) 
        then ($custom-page) 
        else cts:search(/custom-page[@uri eq $uri and @locale eq $lang], core:get-filter-query())
    let $resource-node as element(resources)? := $custom-page/resources
    return (
        if (fn:empty($custom-page)) then (
            (: no custom-page :)
        ) else if (fn:empty($resource-node)) then (
            (: create resources node :)
            xdmp:node-insert-child($custom-page, <resources>{$to-add}</resources>),fn:true()
        ) else (
            (: insert new string :)
            xdmp:node-insert-child($resource-node, $to-add),fn:true()
        )
    )
};

declare function fast:edit-page-resource($lang as xs:string, $custom-page as element(), $uri as xs:string, $key as xs:string, $text as item()*) as item()*{
    let $current-node as element(entry)? := $custom-page/resources/entry[@key = $key]
    let $value as element(value) := element value { $text }
    return (
        if (fn:not(fn:deep-equal($current-node/value, $value))) then (
            let $entry as element(entry) :=
                element entry {
                    attribute key {$key},
                    attribute status {'edited'},
                    if ($lang eq 'eng') then (
                        attribute translation {'ready'}
                    ) else (),
                    $value
                }
            return (xdmp:node-replace($current-node, $entry),fn:true())
         ) else ()
    )
};

(: ********************************************************************
    END of Functions for Resource strings held in the page file
   ******************************************************************** :)
   
declare function fast:insert-edit-resource-bundle($locale as xs:string, $keys as xs:string*, $values as item()*) as item()*
{
    let $key as xs:string := $keys[1]
    let $bundle-name as xs:string := fn:substring-before($key, ":")
    let $sub-key as xs:string := if ($bundle-name = "") then $key else fn:substring-after($key, ":")
    let $bundle as element()* :=
        cts:search(/(resources|resource-bundle),
            cts:and-query((
                core:get-filter-query(),
                cts:or-query((
                    cts:element-attribute-value-query( $ROOTS, xs:QName('xml:lang'), $locale, "unstemmed"),
                    cts:element-attribute-range-query(xs:QName('ldse:document'), xs:QName('locale'), '=', $locale, "collation=http://marklogic.com/collation/"),
                    cts:element-value-query(xs:QName('locale'), $locale, "unstemmed")
                ))
            )),
            "unfiltered"
        )
    let $bundle as item()* := if (fn:exists($bundle[name = $bundle-name])) then $bundle[name = $bundle-name] else $bundle
    let $new-ldsemeta as element(ldse:ldse-meta) := ldsemeta:get-meta($bundle)
    let $new-bundle as element() := fast:edit-add-resources($locale, $bundle, $keys, $values, 1)
    return (
        core:document-replace($bundle, $new-bundle)
    )
};

declare function fast:edit-add-resources($lang as xs:string, $new-bundle as element(), $keys as xs:string*, $values as item()*, $index as xs:int) as element()? {
    let $new-bundle as element() := 
        let $key as xs:string := fn:substring-after($keys[1], ":")
        let $value as item()* := fn:subsequence($values, $index, 1)
        let $options as element() := 
            <options xmlns="xdmp:tidy">
                <newline>LF</newline>
                <clean>true</clean>
                <wrap>0</wrap>
                <hide-comments>true</hide-comments>
            </options>
                       
        let $value as item()* := if ( fn:string($value) eq "&nbsp;" ) then ( "" ) else ($value)
        let $current-nodes as element(entry)* := $new-bundle/properties/entry[@key = $key]
        let $current-node as element(entry)? :=  $current-nodes[1]
        let $value as item()* := 
            if ( fn:exists($value//param) ) then (
                $value/node()
            ) else (
                xdmp:quote(xdmp:tidy($value, $options)/xhtml:html/xhtml:body/node())
            )
        let $value as item()* := 
            for $val as item() in $value
            return (
                typeswitch ($val)
                case text() return functx:trim($val)
                case xs:string return functx:trim($val)
                default return $val
            )
        let $new-value as element(value) := element value { $value }
        let $new-entry := 
             if ( fn:not(fn:deep-equal($current-node/value, $new-value)) ) then
                    element entry {
                        attribute key {$key},
                        attribute status {'edited'},
                        if ($lang eq 'eng') then (
                            attribute translation {'ready'}
                        ) else (),
                        $new-value
                    }
            else if ( fn:empty($current-node) ) then <entry key="{$key}" status="edited" translation="ready">{$new-value}</entry>
            else ()
        let $new-bundle as element() := 
            if($new-entry) then  
                element { fn:node-name($new-bundle) } {
                    $new-bundle/@*,
                    element properties {
                        $new-entry,
                        $new-bundle/properties/entry except $new-bundle/properties/entry[@key = $key]
                    },
                    $new-bundle/node() except $new-bundle/properties
            }
            else $new-bundle
        return (
            if ( fn:count($keys) > 1 ) then (
                fast:edit-add-resources($lang, $new-bundle, $keys[2 to fn:last()], $values, $index + 1)
            ) else (
                $new-bundle
            )
        )
    return (
        $new-bundle
    )
};

declare function fast:insert-edit-resource-bundle($locale as xs:string, $keys as xs:string*, $texts as item()*, $new-bundle as element()) as item()* {
    if(fn:count($keys) > 0)
    then
        let $key as xs:string := $keys[1]
        let $text as item()* := $texts
        let $bundle-name as xs:string := fn:substring-before($key, ":")
        let $sub-key as xs:string := if ($bundle-name = "") then $key else fn:substring-after($key, ":")
        let $entry as item()* := ($new-bundle/map:map/map:entry[@key = $key], $new-bundle/(properties/entry|resource)[@key = $sub-key])
        let $new-entry as node() := fast:create-entry($new-bundle, if (fn:exists($new-bundle/map:map)) then $key else $sub-key, $locale, $text, $entry)
        
        let $new-bundle as element() :=
            if (fn:exists($entry))
            then
                if (fn:not(fn:deep-equal($entry/value, $new-entry/value)))
                then memUpdate:node-replace($entry, $new-entry)
                else $new-bundle
                
            else memUpdate:node-insert-child(($new-bundle/(properties|map:map))[1], $new-entry)
        
        return fast:insert-edit-resource-bundle($locale, $keys[2 to fn:last()], $texts[2 to fn:last()], $new-bundle)
    
    else $new-bundle
};

declare private function fast:create-entry($bundle as item()*, $key as xs:string, $locale as xs:string, $text as item()*, $entry as item()*) as item(){
    element 
        { xs:QName(if (fn:exists($bundle/map:map)) then "map:entry" else "entry") } 
        {
            attribute key {$key},
            attribute status {'edited'},
            if ($locale eq 'eng') then (
                attribute translation {'ready'},
                $entry/@* except $entry/(@key|@translation|@status)
            ) else (
                $entry/@* except $entry/(@key|@status)
            ),
            element value { $text },
            <versions>
            {
                if(fn:not($entry/value = $text))
                then
                    <value its:translate="no" xmlns:its="http://www.w3.org/2005/11/its">
                    {
                        attribute date {ldsemeta:get-last-modified-date($bundle)},
                        attribute user {ldsemeta:get-modifier($bundle)},
                        $entry/value/fn:string(.)
                    }
                    </value>
                
                else ()
            }
            {$entry/versions/value}
            </versions>
        }
};

(:~
    Takes the specified string at builds full urls for each
    anchor tag within the string.

    @param $string The string from the resource bundle
    @param $lang The locale of the requested site (eng, spa,...)
    @param $host The site host

    @return The string with fully qualified urls in the <a>
~:)
declare function fast:build-links-in-string($string as item()*, $lang as xs:string, $host as xs:string?) as item()* {
    let $originalString as element(string) := <string>{$string}</string>
    let $finalString as item()*  :=
        (: If this string should be editable inline... :)
        if ( fn:exists($originalString/span[@class="resourceIce"]) ) then (
            let $span as element(span)* := $originalString/span[@class="resourceIce"]
            return element span {
                attribute class { $span/@class },
                attribute id { $span/@id },
                for $x as node() in $span/node()
                return
                    typeswitch($x)
                    case text() return ($x)
                    case element() return (
                        if (fn:local-name($x) eq "a") then (
                            if ( fn:starts-with($x/@href, "#") ) then (
                                $x
                            ) else (
                                <a href="{util:build-full-url($host, fn:data($x/@href), $lang)}">{fn:string($x)}</a>
                            )
                        ) else ()
                    )
                    default return ()
            }
        (: Else, just process like normal :)
        ) else (
            for $x as node() in $originalString/node()
            return
                typeswitch($x)
                case text() return ($x)
                case element() return (
                    if (fn:local-name($x) eq "a") then (
                        <a href="{util:build-full-url($host, fn:data($x/@href), $lang)}">{fn:string($x)}</a>
                    ) else ()
                )
                default return ()
        )
    return $finalString
};

(:~
    Makes an entire resource bundle available via javascript.
    Pre-requisite: must include data.js on the page where this is used.

    @param $bundle The resource bundle

    @return The <script/> to make resource values available via javascript
~:)
declare function fast:bundle-to-javascript($bundle as xs:string) as element(script) {
    let $prefix as xs:string := fn:concat($bundle, ":")
    let $locale as xs:string := $util:locale
    let $bundle-map as map:map := fast:get-locale-map($MODE, $locale)
    (: Get all values in a bundle :)
    let $ldse-enabled as xs:boolean := core:is-ldse-enabled()
    let $strings as xs:string* :=
            for $key as xs:string in map:keys($bundle-map)[fn:starts-with(., $prefix)]
            let $resource as item()* := map:get($bundle-map, $key)
            let $string as xs:string? := fn:normalize-space(fn:string-join($resource[self::text()],' '))
            let $string as xs:string? := if (fn:empty($string) and $ldse-enabled) then (fn:concat("?", $key, "?")) else ($string)
            let $string as xs:string? := fn:replace($string, "\n", "")
            let $string as xs:string? := fn:replace($string, "'", "\\'")
            let $string as xs:string? := fn:normalize-space($string)
            let $key as xs:string := fn:substring-after($key, $prefix)
            return fn:concat("'", $key, "' : '", $string, "'")
    return (
        <script type="text/javascript">
            // All resources in bundle {$bundle}
            if (DATA) {{
                DATA.addResources(
                    {{
                        {fn:string-join($strings, ",")}
                    }}
                );
            }}
        </script>
    )
};

(:~
    Returns an entire resource bundle as a MarkLogic map
    @param $locale The resource locale
    @param $bundle The resource bundle
    @return map:map
~:)
declare function fast:get-bundle-map($locale as xs:string, $bundle as xs:string) as map:map {
    let $map as map:map := map:map()
    let $prefix as xs:string := fn:concat($bundle, ':')
    let $locale-map as map:map := fast:get-locale-map($MODE, $locale)
    let $puts as item()* :=
        for $key as xs:string in map:keys($locale-map)
        where fn:starts-with($key, $prefix)
        return (
            map:put($map, fn:substring-after($key, $prefix), map:get($locale-map, $key))
        )
    return (
        $map
    )
};

(:~
    Puts an entire resource bundle into the given resource map for editing via ICE.

    @param $bundle The resource bundle
    @param $resourceMap The map where the resources should be stored

    @return ""
~:)
declare function fast:get-bundle-ice($bundle as xs:string) as item()* {
    let $locale as xs:string := $util:locale
    (: Get all values in a bundle :)
    let $strings as item()* :=
        for $entry as element(entry) in cts:search(/resources[locale eq $locale and name eq $bundle],
                                core:get-filter-query(),
                                'unfiltered'
                            )/properties/entry
        let $key as xs:string := fn:data($entry/@key)
        return fast:get-string-ice($locale, $bundle, $key)
    return ""
};

declare function fast:get-bundle-ice-hidden($bundle as xs:string) as item()* {
    let $locale as xs:string := $util:locale
    (: Get all values in a bundle :)
    let $strings as item()* :=
        for $entry as element(entry) in cts:search(/resources[locale eq $locale and name eq $bundle],
                                core:get-filter-query(),
                                'unfiltered'
                            )/properties/entry
        let $key as xs:string := fn:data($entry/@key)
        return fast:get-string-ice-hidden($locale, $key)
    return ""
};


(: OLD RESOURCE API SUPPORT :)

declare function fast:getStringIce(
    $locale as xs:string, 
    $bundle-name as xs:string, 
    $key as xs:string, 
    $deprecated-context as xs:string
) as item()* {
   let $_ as item()* := $DEPRECATED
   let $new-key as xs:string := fn:concat($bundle-name, ':',$key)
   let $mode as xs:string := settings:get-mode-by-root($deprecated-context)
   
   return fast:get-string-ice($locale, $new-key, $mode)
};

(: DEPRECATED...use getStringIce(...) :)
declare function getString($lang as xs:string, $bundle as xs:string, $key as xs:string, $deprecated-context as xs:string?, $personId as xs:string?) as item()* {
    $DEPRECATED,
    getString($lang, $bundle, $key, $deprecated-context)
};

declare function getString($lang as xs:string, $bundle as xs:string, $key as xs:string, $deprecated-context as xs:string?) as item()* {
    let $_ as item()* := $DEPRECATED
    let $new-key as xs:string := fn:concat($bundle, ':',$key)
    let $mode as xs:string := $MODE
    
    let $string as item()* := fast:get-value($mode,$lang,$new-key)
    let $default as item()* := if (fn:empty($string)) then ( fast:get-value($mode, $DEFAULT-LOCALE, $key) ) else ($string)
    return if ( fn:empty($default) and core:is-ldse-enabled() ) then ( fn:concat("?", $key, "?") ) else ($default)
};

declare function getStringValue($lang as xs:string, $bundle as xs:string, $key as xs:string, $deprecated-context as xs:string?, $resourceMap as item()*) as item()* {
    $DEPRECATED,
    getStringValue($lang, $bundle, $key, $deprecated-context)
};

declare function getStringValue($lang as xs:string, $bundle as xs:string, $key as xs:string, $deprecated-context as xs:string?) as item()* {
    $DEPRECATED,
    getDefaultForEmpty(
        (getString($lang, $bundle, $key, $deprecated-context)),
        $lang, $bundle, $key, $deprecated-context)
};

declare function getStringText($lang as xs:string, $bundle as xs:string, $key as xs:string, $deprecated-context as xs:string?) as item()* {

    let $_ as item()* := $DEPRECATED
    let $new-key as xs:string := fn:concat($bundle, ':',$key)
    let $mode as xs:string := $MODE
        
    let $string as item()* := fast:get-value($mode,$lang,$new-key)/text()
    let $default as item()* := if (fn:empty($string)) then ( fast:get-value($mode, $DEFAULT-LOCALE, $key)/text() ) else ($string)
    return if ( fn:empty($default) and core:is-ldse-enabled()) then ( fn:concat("?", $key, "?") ) else ($default)
};


declare function getStringKeyForMonths($lang as xs:string, $bundle as xs:string, $value as item()*, $deprecated-context as xs:string) as item()* {    
    let $_ as item()* := $DEPRECATED
    let $mode as xs:string := $MODE
    let $map-entries as element(map:entry)* := fast:get-map-entries(fast:get-locale-map($mode, $lang))
    let $start as xs:string := fn:concat($bundle, ":month")
    let $string as element(map:entry)* := ($map-entries[fn:lower-case(xs:string(map:value)) = $value and fn:starts-with(@key, $start)]/@key)[1]
    return if (fn:empty($string) and core:is-ldse-enabled()) then (fn:concat("?", $value, "?")) else ($string)
};


declare function getDefaultForEmpty($string as item()*, $lang as xs:string, $bundle as xs:string, $key as xs:string, $deprecated-context as xs:string?) as item()* {
    $DEPRECATED,
    getDefaultForEmpty($string, $lang, $bundle, $key, $deprecated-context,
        if ($lang[2] != "") 
            then (getString($lang[2], $bundle, $key, $deprecated-context)) 
            else ()
    )
};

declare function getDefaultForEmpty($string as item()*, $lang as xs:string, $bundle as xs:string, $key as xs:string, $deprecated-context as xs:string?, $default-string as item()*) as item()* {
    let $_ as item()* := $DEPRECATED
    return (
        if (core:is-ldse-enabled()) then (
            if ( fn:empty($string) ) then (
                fn:concat("?", $key, "?")
            ) else ( $string ) 
        ) else (
            if ( fn:empty($string) ) then (
                getString($DEFAULT-LOCALE, $bundle, $key, $deprecated-context)
            ) else ( $string )
        )
    )
};

declare function getStringIce($lang as xs:string, $bundle as xs:string, $key as xs:string, $deprecated-context as xs:string?, $resourceMap as item()*) as item()* {   
    let $_ as item()* := $DEPRECATED
    let $new-key as xs:string := fn:concat($bundle, ':',$key)
    let $mode as xs:string := settings:get-mode-by-root($deprecated-context)
    
    return if (fn:empty($resourceMap) or fn:not($resourceMap instance of map:map)) 
        then fast:get-string-ice($lang, $new-key)
        else fast:get-string-ice-hidden($lang, $new-key, $mode) 
};

declare function getStringIce($lang as xs:string, $bundle as xs:string, $key as xs:string, $deprecated-context as xs:string?, $resourceMap as item()*, $string as item()*) as item()* {
    let $_ as item()* := $DEPRECATED
    let $new-key as xs:string := fn:concat($bundle, ':',$key)
    let $mode as xs:string := settings:get-mode-by-root($deprecated-context)
    
    return if (fn:empty($resourceMap) or fn:not($resourceMap instance of map:map)) 
        then fast:get-string-ice($lang, $new-key)
        else fast:get-string-ice-hidden($lang, $new-key, $mode)      
};

(: ********************************************************************
    START Functions for Resource strings held in the page file
   ******************************************************************** :)
declare function getPageStringText($lang as xs:string, $custom-page as element(custom-page)*, $key as xs:string, $deprecated-context as xs:string?) as item()* {
    $DEPRECATED,
    fast:get-page-string-text($custom-page,$key)
};

declare function getPageStringValue($lang as xs:string, $custom-page as element(custom-page)*, $key as xs:string, $deprecated-context as xs:string?) as item()* {
    $DEPRECATED,
    fast:get-page-string-value($custom-page,$key)
};

declare function getPageDefaultForEmpty($string as item()* , $key as xs:string, $deprecated-context as xs:string?) as item()* {
    $DEPRECATED,
    fast:get-page-default-for-empty($string,$key)
};

declare function getPageStringIce($lang as xs:string, $custom-page as element(custom-page)*, $key as xs:string, $deprecated-context as xs:string?) as item()*{
    $DEPRECATED,
    fast:get-page-string-ice($lang,$custom-page,$key)
};

declare function getPageStringIce($lang as xs:string, $custom-page as element(custom-page)*, $key as xs:string, $deprecated-context as xs:string?, $resourceMap as item()*) as item()* {
    $DEPRECATED,
    if (fn:empty($resourceMap) or fn:not($resourceMap instance of map:map)) 
        then fast:get-page-string-ice($lang,$custom-page,$key)
        else fast:get-page-string-ice-hidden($lang,$custom-page,$key)
};

declare function preparePageForResources($lang as xs:string, $uri as xs:string, $custom-page as element(custom-page)*) as item()* {
    $DEPRECATED,
    fast:prepare-page-for-resources($lang,$uri,$custom-page)
};

declare function insertEditPageResource($deprecated-context as xs:string?, $lang as xs:string, $custom-page as element(custom-page)*, $uri as xs:string, $key as xs:string, $text as item()*) as item()* {
    $DEPRECATED,
    fast:insert-edit-page-resource($lang,$custom-page,$uri,$key,$text)
};

declare function insertPageResource($deprecated-context as xs:string?, $lang as xs:string, $custom-page as element(custom-page)*, $uri as xs:string, $key as xs:string, $text as item()*) as item()* {
    $DEPRECATED,
    fast:insert-page-resource($lang,$custom-page,$uri,$key,$text)
};

declare function editPageResource($deprecated-context as xs:string?, $lang as xs:string, $custom-page as element(custom-page)*, $uri as xs:string, $key as xs:string, $newText as item()*) as item()* {
    $DEPRECATED,
    fast:edit-page-resource($lang,$custom-page,$uri,$key,$newText)
};

(: ********************************************************************
    END of Functions for Resource strings held in the page file
   ******************************************************************** :)


(:  __________________________________________________________
 ::
 :: Substitutes a param element in the string with an index attribute
 :: equal to the passed-in index with the item in the args sequence
 :: at the same index. Then recursively calls itself with
 :: this new string and with an index incremented by 1 until there
 :: is either no item in the args sequence with that index or
 :: there is no param element with an index attribute equal to
 :: the passed-in index.
 :: An example string:
 :: <entry key="results"><param index="1"/>-<param index="2"/> of <param index="3"/> results</entry>
 :: NOTES: The param elements' index attributes do not need to appear in
 :: order in the string, so the following is okay:
 :: <entry key="results"><param index="2"/>-<param index="1"/> of <param index="3"/> results</entry>
 :: However, the order of the items in the sequence must match
 :: up with the index attribute. So for the first example the
 :: args might be (1, 10, 31) but for the second example the
 :: args would need to be (10, 1, 31).
 :: This function should not be called directly, use getParamString.
 :: Embedded html tags will be preserved.
 ::  ___________________________________________________________
:)
declare function getParameterizedString($str as item()*, $args as item()*, $index as item()*) as node()*{
  if (fn:empty($args[$index]) or fn:empty($str//param[@index = $index]))
  then ($str)
  else (getParameterizedString(
          memUpdate:node-replace($str//param[@index=$index], $args[$index]/node()),
          $args, $index + 1)
       )
};


(:  __________________________________________________________
 ::
 :: Finds the string for the given locale, bundle and key. Then
 :: converts all items in the args sequence to nodes and calls
 :: getParameterizedString to substitute args into the parameters
 :: in the string.
 ::  ___________________________________________________________
:)
declare function getParamString($lang as item()*, $deprecated-context as item()*, $key as item()*, $bundle as item()*, $args as item()*) as node()*{
    fast:get-param-string-ice($lang, fn:concat($bundle, ":", $key), $args)
};

declare function getParamString($lang as item()*, $deprecated-context as item()*, $key as item()*, $bundle as item()*, $args as item()*, $resourceMap as item()*) as node()*{
    fast:get-param-string-ice-hidden($lang, fn:concat($bundle, ":", $key), $args)
};

declare function get-param-string($lang as item()*, $key as item()*, $args as item()*) as node()*{
    let $str as element(string) := <string>{get-value($MODE, $lang, $key)}</string>
    let $argList as element(param)* :=
        for $arg as item() in $args
        return <param>{$arg}</param>
    return getParameterizedString($str, $argList, 1)/node()
    (:using node() returns everything inside the string element:)
};

declare function get-param-string-ice($lang as item()*, $key as item()*, $args as item()*) as node()*{
    let $str as element(string) := <string>{fast:get-string-ice($lang, $key, $MODE)}</string>
    let $argList as element(param)* :=
        for $arg as item() in $args
        return <param>{$arg}</param>
    return getParameterizedString($str, $argList, 1)/node()
    (:using node() returns everything inside the string element:)
};

declare function get-param-string-ice-hidden($lang as item()*, $key as item()*, $args as item()*) as node()*{
    let $str as element(string) := <string>{fast:get-string-ice-hidden($lang, $key, $MODE)}</string>
    let $argList as element(param)* :=
        for $arg as item() in $args
        return <param>{$arg}</param>
    return getParameterizedString($str, $argList, 1)/node()
    (:using node() returns everything inside the string element:)
};

declare function insertEditResourceBundle($deprecated-context as item()*, $lang as item()*, $bundle as item()*, $key as item()*, $text as item()*) as item()* {
    $DEPRECATED,
    fast:insert-edit-resource-bundle($lang, fn:concat($bundle, ":", $key), $text)
};

declare function insertResourceBundle($deprecated-context as item()*, $lang as item()*, $bundle as item()*, $key as item()*, $text as item()*) as item()* {
    $DEPRECATED,
    (:fast:insert-resource-bundle($lang,$bundle,$key,$text):)
    fast:insert-edit-resource-bundle($lang, fn:concat($bundle, ":", $key), $text)
};

declare function editResourceBundle($deprecated-context as item()*, $lang as item()*, $bundle as item()*, $key as item()*, $text as item()*) as item()* {
    $DEPRECATED,
    (:fast:edit-resource-bundle($lang,$bundle,$key,$text):)
    fast:insert-edit-resource-bundle($lang, fn:concat($bundle, ":", $key), $text)
};


(:~
    Takes the specified string at builds full urls for each
    anchor tag within the string.

    @param $string The string from the resource bundle
    @param $lang The locale of the requested site (eng, spa,...)
    @param $deprecated-context The execution context (preview or published)
    @param $host The site host

    @return The string with fully qualified urls in the <a>
~:)
declare function buildLinksInString($string as item()*, $lang as item()*, $deprecated-context as item()*, $host as item()*) as item()* {
    $DEPRECATED,
    fast:build-links-in-string($string,$lang,$host)
};

declare function bundleToJavascript($bundle as item()*) as item()* {
    $DEPRECATED,
    fast:bundle-to-javascript($bundle)
};

declare function getBundleIce($bundle as item()*, $resourceMap as item()*) as item()* {
    $DEPRECATED,
    if (fn:empty($resourceMap) or fn:not($resourceMap instance of map:map)) 
        then fast:get-bundle-ice($bundle)
        else fast:get-bundle-ice-hidden($bundle)
};
(: END OLD RESOURCE API SUPPORT :)
