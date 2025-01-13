xquery version "1.0-ml";

module namespace ice = "http://lds.org/code/shared/lds-edit/iceFunction";

import module namespace mem = "http://lds.org/code/shared/common/memory-update" at "/shared/common/util/inMemoryUpdate.xqy";
import module namespace json = "http://lds.org/code/shared/common/json/json-functions" at "/shared/common/json/jsonFunctions.xqy";
import module namespace form = "http://lds.org/code/shared/lds-edit/dynamicForms" at "/ice/modules/dynamicForms.xqy";
import module namespace tw = "http://lds.org/code/shared/lds-edit/translation-workflow" at "/translation/modules/translation-workflow.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "/modules/ldse-meta.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "/modules/ldse-core.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "/modules/ldse-settings.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "/modules/utility-functions.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";
import module namespace fast = "http://lds.org/code/shared/lds-edit/fast-i18n" at "/rice/modules/fast-i18n.xqy";
import module namespace fjson = "http://marklogic.com/json" at "/modules/fasterjson.xqy";
import module namespace rice = "http://lds.org/code/shared/lds-edit/riceFunctions" at "/string-manager/modules/stringFunctions.xqy";
import module namespace document = "http://lds.org/code/shared/lds-edit/document-functions" at "/modules/document-functions.xqy";
import module namespace sp = "http://lds.org/code/modules/site-properties" at '/modules/site-properties.xqy';

declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace xhtml = "http://www.w3.org/1999/xhtml";
declare namespace its = "http://www.w3.org/2005/11/its";
declare namespace asr = "http://www.w3.org/2009/xpath-functions/analyze-string";
declare option xdmp:mapping "true";

declare variable $DEPRECATED as empty-sequence() := util:deprecated(());

declare variable $publish-types as map:map := map:map();
declare variable $dynamic-items as map:map := map:map();

declare variable $domain as xs:string := fn:substring-after($util:host, "://");
declare variable $full-preview-host as xs:string? := fn:concat("//" ,settings:get-mode-domain("preview"), $settings:shared-prefix);
declare variable $is-user as xs:boolean := ac:is-user();
declare variable $add-ice-defaults as element()* := util:strip-namespaces($settings:add-ice-defaults);
declare variable $site as xs:string? := xdmp:get-request-field('site');
declare variable $template-id as xs:string? := util:escape-chars(xdmp:get-request-field('id'))[. != ""];

(: This is for shortcutting component building (builds component and content at same time) :)
declare function ice:build-component-pieces($locale as xs:string, $current-page as xs:string, $options as element(options)?) {
    let $prefix as xs:string? := $options/prefix
    let $location as xs:string? := $options/variables/location
    let $component-pieces as xs:string? := $options/variables/components
    let $parent as xs:string? := $options/variables/parent
    let $vars as xs:string := ice:csv-variables($options/variables)
    return (
        <links xmlns="http://lds.org/code/lds-edit">
            {
                for $option as xs:string at $i in fn:tokenize($component-pieces, '\|')
                let $type as xs:string := util:substring-after-last($option, '/')
                return (
                    <link sequence="70" name="ldse:add-component-piece" custom-call="false">
                        <checks>
                            <check op="permission">ldse:add-doc</check>
                            <or>
                                <check op="=" val="true">#only-clone</check>
                                <and>
                                    <check op="!=" val="true">#only-edit</check>
                                    <or>
                                        <check op="!=" val="true">#only-one</check>
                                        <check op="empty">$file</check>
                                    </or>
                                </and>
                            </or>
                        </checks>
                        <a onclick="ICE.createComponent(this); return false;" data-post.locale="{$locale}" data-post.parent-id="{$parent}" data-post.location="{$location}" data-post.country="{util:get-country-from-locale($locale)}" data-post.content-type="{$option}" data-post.uri="{$current-page}" data-post.page="{$current-page}" data-post.option="{$vars}" class="ldse-icon-ko-add" i18n="ldse.edit.{$type}">Add {$type}</a>
                    </link>
                )
            }
        </links>
    )
};

declare function ice:get-merged-options(
    $options as element(options)?
) as element()+ {
    $options, $add-ice-defaults
};

declare function ice:add-ice(
    $locale as xs:string,
    $type as xs:string,
    $xmlFile as element()?,
    $current-page as xs:string,
    $options as element(options)?
) as item()* {
    if ( $is-user ) then (
        let $file as element()? := fn:root($xmlFile)/*[1]
        let $file as element()? := if ( fn:local-name($file) = 'ldse-meta' ) then ( fn:root($xmlFile) ) else ( $file )
        let $type as xs:string := fn:replace($type, "&apos;|&quot;", "")
        let $addType as empty-sequence() := if ($type ne 'sub-channel') then ( ice:add-dynamic-item($type, ldsemeta:get-document-id($file)) ) else ()
        let $component-links as element()? := if ( fn:exists($options) and fn:lower-case($type) = "component" ) then ( <options>{build-component-pieces($locale, $current-page, $options)}</options> ) else ( <options/> )
        let $show-links-apis := fn:starts-with($xmlFile/ldse:ldse-meta/ldse:form-options/ldse:templateId/fn:string(), 'mo-')
        let $is-published := ($xmlFile/ldse:ldse-meta/ldse:publish-date/@date/fn:string())
        let $merged-options as element()+ := ( $options, $add-ice-defaults ) (: as  element(options|defaults)+ :)
        let $_merged-links as element(link)* := ( $merged-options[1]/links/link, $merged-options[2]/links/link )
        let $site := if ($xmlFile) then ($xmlFile/ldse:ldse-meta/ldse:form-options/ldse:site-context)[1]/fn:string() else ()
        let $authRequired as element()? := ac:authRequired($site)
        let $consolidated-host as xs:string? :=
			for $i in  sp:get-consolidation-info($site, 'publish')
            return $i/@host||$i/@prefix
        let $consolidated as xs:boolean :=
            if (fn:exists($consolidated-host)) then
                if ($site) then
                    sp:get-site-properties($site)/consolidation-status/fn:string() eq 'consolidated'
                 else fn:false()
            else fn:false()
        let $_merged-links as element(link)* := if ($show-links-apis) then
                                                  $_merged-links
                                                else for $i in $_merged-links
                                                     let $link-api := $i/@link-api eq 'true'
                                                     where not($link-api)
                                                     return $i
        let $_merged-links as element(link)* := if ($is-published) then
                                                    $_merged-links
                                               else for $i in $_merged-links
                                                    let $published-only := $i/@published-only eq 'true'
                                                    where not($published-only)
                                                    return $i
        let $_merged-links as element(link)* := if ($consolidated)  then
                                                    $_merged-links
                                               else for $i in $_merged-links
                                                    let $consolidated := $i/@consolidated eq 'true'
                                                    where not($consolidated)
                                                    return $i
        let $merged-links as element(link)* := if (not($authRequired))  then
                                                     $_merged-links
                                                else for $i in $_merged-links
                                                    let $no-auth-only := $i/@no-auth-only eq 'true'
                                                    where not($no-auth-only)
                                                    return $i
        let $map as map:map := load-map(map:map(), $locale, $type, $xmlFile, $current-page, $merged-options)
        let $var-site-context := fn:tokenize(map:get($map, '$site-context'), ',')
        let $region := for $i in $var-site-context
                       where fn:matches($i, '^region=')
                       return fn:substring-after($i, 'region=')
        let $can-duplicate-component :=
            if ($template-id eq 'mo-universal-template') then
                fn:true()
            else
                if ($type) then
                    for $i in cts:search(/template, cts:element-attribute-value-query(xs:QName('template'), xs:QName('id'), $template-id, 'exact'))
                    return not(fn:exists($i/region[@id eq $region]//*[fn:name(.) eq $type and @only-one eq 'true']))
                else fn:false()
        let $updateMap := map:put($map, '#can-duplicate-component', <duplidate-component>{$can-duplicate-component}</duplidate-component>)
        let $li as element(li)* :=
            let $default-links as element(li)* :=
                for $link-name as xs:string at $index in (fn:distinct-values($merged-links/@name))
                let $link as element(ldse:link)? := settings:get-ice-link-by-name($link-name)
                where ($merged-links[@name = $link-name])[1] = "true" and is-link-valid($link, $map)
                order by $link/@sequence/xs:integer(.), $index
                return (
                    <li>{
                        if ($index = 1) then (attribute class {"ldse-first-menu-item"}) else (),
                        ice:xml-variable-replace(util:strip-namespaces($link/ldse:a), $map)
                    }</li>
                )
            let $other-links as element(li)* :=
                for $link-name as element(ldse:link) at $index in $component-links/ldse:links/ldse:link
                where is-link-valid($link-name, $map)
                return (
                    <li>{ ice:xml-variable-replace(util:strip-namespaces($link-name/ldse:a), $map) }</li>
                )
            return (
                ($default-links[1], $other-links, $default-links[2 to fn:last()])
            )
        where fn:exists($li)
        return (
            let $file-id as xs:string? := map:get($map, '$file-id')
            let $is-published as xs:boolean := map:get($map, '$is-published') = "true"
            let $published-date as xs:dateTime? := if ( $is-published ) then (ldsemeta:get-publish-date($file)/@date) else ()
            let $modified-date as xs:dateTime? := ldsemeta:get-last-modified($file)/@date
            let $is-modified as xs:boolean := ( fn:exists($published-date) and fn:exists($modified-date) and ($modified-date > $published-date) )
            let $future-publish-date as xs:dateTime? := ldsemeta:get-schedule-publish($file)/@dateTime
            let $future-publish as xs:boolean := ( fn:exists($future-publish-date) and $future-publish-date > fn:current-dateTime() )
            let $is-ajax as xs:boolean := map:get($map, '#ajax') = "true"
            let $is-only-clone as xs:boolean := map:get($map, '#only-clone') = "true"
            let $wrapper-class as xs:string? := if ($is-ajax) then ("ajax") else ()
            let $unpublish := ldsemeta:get-unpublish-date($file)
            let $is-unpublished as xs:boolean := fn:exists(ldsemeta:get-unpublish-date($file))
            let $isdraft as xs:boolean := (fn:not($is-published) and  fn:not($is-unpublished))
            let $correlation-approved as xs:boolean := if($type ne "sub-channel") then fn:not($file) or ldsemeta:correlation-can-publish($file) else fn:true()
            let $correlation-class as xs:string? := if(fn:not($correlation-approved)) then "correlation-not-approved" else ()
            let $document-title as xs:string := (ldsemeta:get-document-title($file)[. ne ""], "Item with no Title")[1]
            let $doc-title-attr as attribute() := attribute data-correlation-document-title {$document-title}
            let $component as xs:string? := ldsemeta:get-document-type($file)
            let $status as element(status) := ice:get-status($file, $map, $type)[1]
            let $source as xs:string? := map:get($map, '$source')
            return (
                <ice-div class="{fn:concat("ice-", fn:lower-case(fn:replace($type, ' ', '-')))}">
                    <div class="ldse-ice-menu-container { $status/@class} {$wrapper-class} {$correlation-class} {$file-id}">
                        {if($correlation-class) then $doc-title-attr else ()}
                        <a href="#" class="ldse-ice-status">{
                            if ($source != "chq") then (
                                <span>{$source}</span>
                            ) else ("&nbsp;")
                        }</a>
                        <ul class="ldse-menu">
                            <li class="ldse-status-item"><span>{$status/node()}</span></li>
                            {$li}
                            {addIceCustomOptions($locale, $type, $xmlFile, $current-page, $options)}
                        </ul>
                        { if ($is-ajax) then (
                            <script type="text/javascript">
                                $(document).ready(function() {{addIceEvents(true);}});
                                {
                                    if ( fn:exists(map:get($map, "$form")) ) then (
                                        fn:concat("ACT.addDynamicItem('", $type, "', ['", $file-id,"']);")
                                    ) else (
                                        fn:concat("ACT.addItem('", $type, "');")
                                    )}
                            </script>
                        ) else ()}
                    </div>
                </ice-div>
            )

        )
    ) else ()
};

declare function ice:get-status(
    $file as element()?,
    $map as map:map,
    $type as xs:string?
) as element(status)* {
    let $file-id as xs:string? := map:get($map, '$file-id')
    let $is-published as xs:boolean := map:get($map, '$is-published') = "true"
    let $published-date as xs:dateTime? := if ( $is-published ) then ( ldsemeta:get-publish-date($file)/@date ) else ()
    let $modified-date as xs:dateTime? := ldsemeta:get-last-modified($file)/@date
    let $is-modified as xs:boolean := ( fn:exists($published-date) and fn:exists($modified-date) and ($modified-date > $published-date) )
    let $future-publish-date as xs:dateTime? := ldsemeta:get-schedule-publish($file)/@dateTime
    let $future-publish as xs:boolean := ( fn:exists($future-publish-date) and $future-publish-date > fn:current-dateTime() )
    let $is-ajax as xs:boolean := map:get($map, '#ajax') = "true"
    let $is-only-clone as xs:boolean := map:get($map, '#only-clone') = "true"
    let $wrapper-class as xs:string? := if ($is-ajax) then ("ajax") else ()
    let $unpublish := ldsemeta:get-unpublish-date($file)
    let $is-unpublished as xs:boolean := fn:exists(ldsemeta:get-unpublish-date($file))
    let $isdraft as xs:boolean := (fn:not($is-published) and  fn:not($is-unpublished))
    let $correlation-approved as xs:boolean := if($type ne "sub-channel") then fn:not($file) or ldsemeta:correlation-can-publish($file) else fn:true()
    let $correlation-class as xs:string? := if(fn:not($correlation-approved)) then "correlation-not-approved" else ()
    let $document-title as xs:string := (ldsemeta:get-document-title($file)[. ne ""], "Item with no Title")[1]
    let $doc-title-attr as attribute() := attribute data-correlation-document-title {$document-title}
    let $component as xs:string? := ldsemeta:get-document-type($file)
    let $source as xs:string? := map:get($map, '$source')
    return (
        if ($is-only-clone) then (
            <status class="">Empty</status>
        ) else if ( $component = "component" and $future-publish ) then (
            <status class="ldse-status-scheduled-component">Scheduled</status>
        ) else if ( $component = "component" and $is-modified ) then (
            <status class="ldse-status-modified-component">Modified</status>
        ) else if ( $component = "component" and $is-published ) then (
            <status class="ldse-status-published-component">Published</status>
        ) else if ( $component = "component" and $is-unpublished ) then (
            <status class="ldse-status-unpublished-component">Unpublished</status>
        ) else if ( $component = "component" and $isdraft and fn:exists($file) ) then (
            <status class="ldse-status-not-published-component">Draft</status>
        ) else if ( $type = "component" ) then (
            <status class="ldse-status-component">Empty</status>
        ) else if ( $future-publish ) then (
            <status class="ldse-status-scheduled">Scheduled</status>
        ) else if ($is-modified) then (
            <status class="ldse-status-modified">Modified</status>
        ) else if ($is-published) then (
            <status class="ldse-status-published">Published</status>
        ) else if ($is-unpublished) then (
            <status class="ldse-status-unpublished">Unpublished</status>
        ) else if($isdraft and fn:exists($file)) then (
            <status class="ldse-status-not-published">Draft</status>
        ) else (),
        <status class="">Empty</status>
    )
};

declare function addIceCustomOptions($locale as xs:string, $type as xs:string, $xmlFile as element()?, $currentPage as xs:string, $options as element(options)?) as element(li)* {
    let $passed-functions as element(custom-option)* := $options/custom-option
    let $passed-function-names as xs:string* := $passed-functions/@name
    let $custom-functions as element(ldse:custom-option)* := $settings:ldse-settings/ldse:add-ice/ldse:custom-option[@name eq $passed-function-names or @global eq "true"]
    return (
        for $custom-function as element(ldse:custom-option) in $custom-functions
        let $name as xs:string := $custom-function/@name
        let $namespace as xs:string := $custom-function/@namespace
        let $path as xs:string := $custom-function/@path
        let $function as xdmp:function := xdmp:function(fn:QName($namespace, $name), $path)
        where fn:not( $passed-functions[@name eq $name] eq "false" )
        order by fn:number($custom-function/@seq)
        return (
            xdmp:apply($function, core:get-mode-root(), $locale, $type, $xmlFile, $currentPage, $options)
        )
    )
};


declare function ice:add-gear(
    $current-page as xs:string,
    $lang as xs:string,
    $is-template as xs:boolean,
    $options as element(options)?
) as item()* {
    ice:add-gear($current-page, $lang, (), $is-template, $options)
};

declare function ice:add-gear-links(
    $current-page as xs:string,
    $lang as xs:string,
    $hidden-resources as map:map?,
    $is-template as xs:boolean,
    $options as element(options)?
) as item()* {
    let $captured-hidden as map:map? := fast:get-hidden-resources()
    let $add as item()* :=
        for $key as xs:string in map:keys($hidden-resources)
        return map:put($captured-hidden, $key, map:get($hidden-resources, $key))
    let $hidden-resources as map:map? := $captured-hidden

    let $merged-options as element()+ := ($options, $add-gear-defaults ) (: as  element(options|defaults)+ :)
    let $merged-links as element(link)* := for $actions as element(links) in ($merged-options[1]/links, $merged-options[2]/links) return $actions/link
    let $custom-page as element(custom-page)? := if ($is-template) then (ice:get-custom-page($current-page, $lang, fn:false())) else ()
    let $map as map:map := load-gear-map(map:map(), $lang, $current-page, $hidden-resources, $is-template, $merged-options, $custom-page)
    let $is-published as xs:boolean := ldsemeta:is-published($custom-page)
    let $published-date as xs:dateTime? := if ( $is-published ) then (ldsemeta:get-publish-date($custom-page)/@date) else ()
    let $modified-date as xs:dateTime? := ldsemeta:get-last-modified($custom-page)/@date
    let $is-modified as xs:boolean := ( fn:exists($published-date) and fn:exists($modified-date) and ($modified-date > $published-date) )
    let $status-class as xs:string? :=
        if ($is-modified) then ('ldse-status-modified')
        else if ($is-published) then ('ldse-status-published')
        else ('ldse-status-not-published')
    let $menu-items :=
        <publisherPreviewMenu>
            {
                if ( $is-template and fn:exists($custom-page) ) then (
                    <links>
                        <text>{
                            if ($is-modified) then ('Modified')
                            else if ($is-published) then ('Published')
                            else ('Not Published')
                        }</text>
                    </links>
                ) else (),

                for $link-name as xs:string at $index in fn:distinct-values($merged-links/@name)
                let $link as element(ldse:link)? := settings:get-gear-link-by-name($link-name)
                where ($merged-links[@name = $link-name])[1] = "true" and is-link-valid($link, $map)
                order by $link/@sequence/xs:integer(.), $index
                return (
                    <links>{ice:xml-variable-replace(util:strip-namespaces($link/ldse:a), $map)}</links>
                ),

                addGearCustomOptions($current-page, $lang, $hidden-resources, $is-template, $options),
                <links><a class="ldse-icon-home" href="{fn:concat($settings:shared-prefix,'', util:split-locale-param($lang))}">LDS Publisher Home</a></links>
            }
        </publisherPreviewMenu>
    where $is-user
    return (
        core:transform-to-json($menu-items, ("links"))
    )
};

declare variable $add-gear-defaults as element()*:= util:strip-namespaces($settings:add-gear-defaults);
declare function ice:add-gear(
    $current-page as xs:string,
    $lang as xs:string,
    $hidden-resources as map:map?,
    $is-template as xs:boolean,
    $options as element(options)?
) as item()* {
    let $captured-hidden as map:map? := fast:get-hidden-resources()
    let $add as item()* :=
        for $key as xs:string in map:keys($hidden-resources)
        return map:put($captured-hidden, $key, map:get($hidden-resources, $key))
    let $hidden-resources as map:map? := $captured-hidden

    let $merged-options as element()+ := ($options, $add-gear-defaults ) (: as  element(options|defaults)+ :)
    let $merged-links as element(link)* := for $actions as element(links) in ($merged-options[1]/links, $merged-options[2]/links) return $actions/link
    let $custom-page as element(custom-page)? := if ($is-template) then (ice:get-custom-page($current-page, $lang, fn:false())) else ()
    let $map as map:map := load-gear-map(map:map(), $lang, $current-page, $hidden-resources, $is-template, $merged-options, $custom-page)

    let $is-published as xs:boolean := ldsemeta:is-published($custom-page)
    let $published-date as xs:dateTime? := if ( $is-published ) then (ldsemeta:get-publish-date($custom-page)/@date) else ()
    let $modified-date as xs:dateTime? := ldsemeta:get-last-modified($custom-page)/@date
    let $is-modified as xs:boolean := ( fn:exists($published-date) and fn:exists($modified-date) and ($modified-date > $published-date) )
    let $status-class as xs:string? :=
        if ($is-modified) then ('ldse-status-modified')
        else if ($is-published) then ('ldse-status-published')
        else ('ldse-status-not-published')
    where $is-user
    return (
        <div id="ice-overlay-header">
            <div id="unsupported-browser" style="display: none;">
                LDS Edit is not supported in Internet Explorer.
                <span class="notify-close">
                    <a title="dismiss this notification">×</a>
                </span>
            </div>
        </div>,
        <div id="ldse-toolbar-container" class="ldse-toolbar-container front">
            <div id="ldse-toolbar" class="ldse-toolbar">
                <div class="ldse-toolbar-item ldse-main-menu {$status-class}">
                    <p class="ldse-toolbar-logo ldse-dropdownMenu-trigger">
                        <span class="ldse-icon-list-2 ldse-icon">Main Menu</span>
                        <span class="ldse-brand">
                            <span class="ldse-logo-text-last">LDS</span>
                            <span class="ldse-logo-text-first"> PUBLISHER</span>
                        </span>
                        <span class="ldse-site-name">{$settings:display-name}</span>
                    </p>
                    <nav class="ldse-nav">
                        <ul class="ldse-menu">
                            {  if ( $is-template and fn:exists($custom-page) ) then (
                                <li class="ldse-status-item">
                                    <span>{
                                        if ($is-modified) then ('Modified')
                                        else if ($is-published) then ('Published')
                                        else ('Not Published')
                                    }</span>
                                </li>
                            ) else ()
                            }
                            {
                                for $link-name as xs:string at $index in fn:distinct-values($merged-links/@name)
                                let $link as element(ldse:link)? := settings:get-gear-link-by-name($link-name)
                                where ($merged-links[@name = $link-name])[1] = "true" and is-link-valid($link, $map)
                                order by $link/@sequence/xs:integer(.), $index
                                return <li>{ice:xml-variable-replace(util:strip-namespaces($link/ldse:a), $map)}</li>
                            }
                            { addGearCustomOptions($current-page, $lang, $hidden-resources, $is-template, $options) }
                            { <li><a class="ldse-icon-home" href="{fn:concat($settings:shared-prefix, '', util:split-locale-param($lang), '&amp;site=', xdmp:get-request-field('site'))}">LDS Publisher Home</a></li> }
                        </ul>
                    </nav>
                </div>
                <div id="ldse-toolbar-buttons" class="ldse-toolbar-buttons">
                </div>
            </div>
            { if ( $settings:toolbar-settings/ldse:toolbar-toggle/@enabled = 'true') then (
                <div id="ldse-toolbar-toggle" class="ldse-toolbar-item ldse-toolbar-toggle">
                    <span class="ldse-icon-close-menu ldse-icon">Toggle Toolbar</span>
                </div>
            ) else () }
        </div>,
        if (map:count($publish-types) > 0 or map:count($dynamic-items) > 0 ) then (
            let $addResource as empty-sequence() := map:put($publish-types, 'resource', 'resource')
            let $items as xs:string* :=
                for $key as xs:string in map:keys($publish-types)
                return fn:concat('"', $key, '"')
            let $dynamicItems as xs:string* :=
                for $key as xs:string in map:keys($dynamic-items)
                let $array as xs:string* := (
                    for $item as xs:string in map:get($dynamic-items, $key)
                    return ( fn:concat('"', $item, '"'))
                )
                return (
                    fn:concat('{name:"', $key, '", ids:[', fn:string-join($array , ','), ']}')
                )
            let $actions as xs:string* :=
                for $action as element(ldse:action) in $settings:actions
                return ( fn:concat('"',$action/@name,'":"', $action/@title, '"') )
            return (
                <script type="text/javascript">
                    {fn:concat('ACT.addItems([', fn:string-join($items, ','), ']);')}
                    {fn:concat('ACT.addDynamicItems([',fn:string-join($dynamicItems, ','), ']);')}
                    {fn:concat('ACT.IS_TEMPLATE = ', $is-template, ';')}
                    {fn:concat('ACT.ACTIONS = {', fn:string-join($actions, ','), '};')}
                    {if (fn:exists($options/settings/toggle-carousel)) then ('ICE.carouselCheck();') else ()}
                </script>
            )
        ) else (),
        if ( fn:exists($merged-options/settings/clear-url) ) then (
            <script type="text/javascript">{ fn:concat('ACT.addClearUrl(', fjson:arrq($merged-options/settings/clear-url), ');') }</script>
        ) else (),
        if (fn:empty($hidden-resources)) then () else (
            let $list as item()* := map:get($hidden-resources, "list")
            let $resources as xs:string := json:serialize(<resources>{$list}</resources>)
            return
                if (fn:empty($list)) then () else (
                    <script type="text/javascript">
                        {fn:concat("RICE.HIDE_TITLE = '", xs:string($options/seo-title/hide-seo-title), "';")}
                        {fn:concat('RICE.SEO_TITLE = "', fn:normalize-space(xs:string($options/seo-title/seo-title-value)), '";')}
                        {fn:concat("RICE.HIDDEN_RESOURCES = ", $resources, ";")}
                        {fn:concat("RICE.CURRENT_URI = '", $current-page, "';")}
                    </script>
                )
        )
    )
};

declare function ice:get-simplified-menu(
    $current-page as xs:string,
    $editThisPageId as xs:string?,
    $lang as xs:string,
    $hidden-resources as map:map?,
    $is-template as xs:boolean,
    $options as element(options)?
) as item()* {
    let $captured-hidden as map:map? := fast:get-hidden-resources()
    let $add as item()* :=
        for $key as xs:string in map:keys($hidden-resources)
        return map:put($captured-hidden, $key, map:get($hidden-resources, $key))
    let $hidden-resources as map:map? := $captured-hidden

    let $merged-options as element()+ := ($options, $add-gear-defaults ) (: as  element(options|defaults)+ :)
    let $merged-links as element(link)* := for $actions as element(links) in ($merged-options[1]/links, $merged-options[2]/links) return $actions/link
    let $custom-page as element(custom-page)? := if ($is-template) then (ice:get-custom-page($current-page, $lang, fn:false())) else ()
    let $map as map:map := load-gear-map(map:map(), $lang, $current-page, $hidden-resources, $is-template, $merged-options, $custom-page)

    let $is-published as xs:boolean := ldsemeta:is-published($custom-page)
    let $published-date as xs:dateTime? := if ( $is-published ) then (ldsemeta:get-publish-date($custom-page)/@date) else ()
    let $modified-date as xs:dateTime? := ldsemeta:get-last-modified($custom-page)/@date
    let $is-modified as xs:boolean := ( fn:exists($published-date) and fn:exists($modified-date) and ($modified-date > $published-date) )
    let $status-class as xs:string? :=
        if ($is-modified) then ('ldse-status-modified')
        else if ($is-published) then ('ldse-status-published')
        else ('ldse-status-not-published')
    return (
        <div id="ice-overlay-header">
            <div id="unsupported-browser" style="display: none;">
                LDS Edit is not supported in Internet Explorer.
                <span class="notify-close">
                    <a title="dismiss this notification">x</a>
                </span>
            </div>
        </div>,
        <div id="ldse-toolbar-container" class="ldse-toolbar-container front">
            <div id="ldse-toolbar" class="ldse-toolbar">
                <div class="ldse-toolbar-item ldse-main-menu {$status-class}">
                    <p class="ldse-toolbar-logo ldse-dropdownMenu-trigger">
                        <span class="ldse-icon-list-2 ldse-icon">Main Menu</span>
                        <span class="ldse-brand">
                            <span class="ldse-logo-text-last">LDS</span>
                            <span class="ldse-logo-text-first"> PUBLISHER</span>
                        </span>
                        <span class="ldse-site-name">{$settings:display-name}</span>
                    </p>
                    <nav class="ldse-nav">
                        <ul class="ldse-menu">
                            {  if ( $is-template and fn:exists($custom-page) ) then (
                                <li class="ldse-status-item">
                                    <span>{
                                        if ($is-modified) then ('Modified')
                                        else if ($is-published) then ('Published')
                                        else ('Not Published')
                                    }</span>
                                </li>
                            ) else ()
                            }
                            {
                                for $link-name as xs:string at $index in fn:distinct-values($merged-links/@name)
                                let $link as element(ldse:link)? := settings:get-gear-link-by-name($link-name)
                                where ($merged-links[@name = $link-name])[1] = "true"
                                (:and is-link-valid($link, $map):)
                                order by $link/@sequence/xs:integer(.), $index
                                return <li>{ice:xml-variable-replace(util:strip-namespaces($link/ldse:a), $map)}</li>
                            }
                            { <li><a class="ldse-icon-home" href="{fn:concat($full-preview-host,'', util:split-locale-param($lang))}">LDS Publisher Home</a></li> }
                        </ul>
                    </nav>
                </div>
                <div id="ldse-toolbar-buttons" class="ldse-toolbar-buttons">
                    {
                        if($editThisPageId)
                        then(
                            <button id="ldse-ice-toggle" class="ldse-button ldse-responsive-button ldse-icon-edit" onclick="window.location='{fn:concat($full-preview-host,'/form',util:split-locale-param($lang),'&amp;id=',$editThisPageId)}'">Edit This Page</button>
                        )
                        else()
                    }
                </div>
            </div>
            <div id="ldse-toolbar-toggle" class="ldse-toolbar-item ldse-toolbar-toggle">
                <span class="ldse-icon-close-menu ldse-icon">Toggle Toolbar</span>
            </div>
        </div>
    )
};

declare function ice:xml-variable-replace($link as node(), $variables as map:map) as node() {
    util:strip-namespaces(
            ice:tidy(
                    fn:string-join(
                            for $node as node() in util:strip-namespaces(fn:analyze-string(xdmp:quote($link), '\{([\$#].+?)\}')/node())
                            return (
                                typeswitch ($node)
                                    case element(match) return (
                                        let $pre-key as xs:string := fn:string($node/group)
                                        let $key as xs:string := fn:replace($pre-key, "(.*?)/.*$", "$1")
                                        let $xpath as xs:string? := fn:substring-after($pre-key, '/')[. != $pre-key]
                                        return if ($xpath != "") then (
                                            map:get($variables, $key)/xdmp:value($xpath)
                                        ) else (
                                            map:get($variables, $key)
                                        )
                                    )
                                    default return ( fn:string($node) )
                            )
                            , "")
            )
    )
};

declare function ice:is-link-valid(
        $link as element(ldse:link)?,
        $map as map:map
) as xs:boolean {
    fn:exists($link) and
            (
                fn:empty($link/ldse:checks/*) or
                        ice:validate-checks(<ldse:and>{$link/ldse:checks/*}</ldse:and>, $map)
            )
};

declare function ice:validate-checks(
    $node as element(),
    $map as map:map
) as xs:boolean {
    typeswitch($node)
        case element(ldse:check) return ice:validate-check($node, $map)
        case element(ldse:not) return fn:not( ice:validate-checks($node/node(), $map) )
        case element(ldse:or) return some $n as element() in $node/* satisfies ice:validate-checks($n, $map)
        case element(ldse:and) return every $n as element() in $node/* satisfies ice:validate-checks($n, $map)
        default return (fn:false())
};

declare function ice:validate-check(
    $check as element(ldse:check),
    $map as map:map
) as xs:boolean {
    let $pre-key as xs:string := fn:string($check)
    let $key as xs:string := fn:replace($pre-key, "(.*?)/.*$", "$1") (: fn:tokenize("test", "/")[1] or fn:replace($pre-key, "(.*?)/.*$", "$1")  :)(:(fn:substring-before($pre-key, '/')[. != ""], $pre-key)[1]:)
    let $xpath as xs:string? := fn:substring-after($pre-key, '/')[. != $pre-key]
    let $value as xs:string? := ($check/@val, "true")[1]
    let $actual as item()* :=
        if ($xpath != "")
        then map:get($map, $key)/xdmp:value($xpath)
        else map:get($map, $key)

    let $file as element()? := map:get($map, "$file")
    let $uri as xs:string? := ldsemeta:get-document-uri($file)
    let $sensitive-page as xs:boolean? :=
        for $sensitive-uri as element(ldse:sensitive-uri) in $settings:sensitive-uris/ldse:sensitive-uri
        return (
            if ( $sensitive-uri = $uri ) then (
                fn:true()
            ) else (
                fn:false()
            )
        )

    return (
        if ( $check/@op = "=" ) then (
            $value = $actual
        ) else if ( $check/@op = "!=" ) then (
            $value != $actual
        ) else if ( $check/@op = "exists" ) then (
            fn:exists($actual)
        ) else if ( $check/@op = "empty" ) then (
            fn:empty($actual)
        ) else if ( $check/@op = "action" ) then (
            ac:is-action-allowed($pre-key, map:get($map,'$locale'), map:get($map, '$current-page'), $map)
        ) else if ( $check/@op = "permission" ) then (
            ac:has-permission($pre-key, map:get($map,'$locale'), map:get($map, '$current-page'))
        ) else if ( $check/@op = "translation" ) then (
            let $step as xs:string? := $check/@step
            let $action as xs:string? := $check/@action
            let $file as element()? := map:get($map,"$file")
            return fn:exists($file) and tw:file-needs-action($step, $action, $file)
        ) else if ( $check/@op = "correlationcanpublish" ) then (
            let $file as element()? := map:get($map, "$file")
            return (
                if ( fn:exists($file) ) then (
                    ldsemeta:correlation-can-publish($file)
                ) else ( fn:true() )
            )
        ) else if ( $check/@op = ">" ) then (
            $value > $actual
        ) else if ( $check/@op = ">=" ) then (
            $value >= $actual
        ) else if ( $check/@op = "<" ) then (
            $value < $actual
        ) else if ( $check/@op = "<=" ) then (
            $value <= $actual
        ) else if ( $check/@op = "is-submission" )  then (
            ldsemeta:is-submission($actual)
            or xs:boolean((map:get($map, "$is-submission"), "false")[1])
        ) else if ( $check/@op = "user-created-file" ) then (
            ldsemeta:user-created-file($actual)
        ) else if ( $check/@op = "submission-submitted" ) then (
            ldsemeta:submission-submitted($actual)
        ) else if ( $check/@op = "is-published" ) then (
            ldsemeta:is-published($actual)
        ) else if($check/@op = "has-translated-files") then (
            fn:count(ldsemeta:get-translated-files(ldsemeta:get-document-id($actual))) > 0
        ) else if($check/@op = "has-syncable-elements") then (
            fn:exists($actual//ldse:structure//*[@its:translate = "no" and @sync = "true"])
        ) else if ( $check/@op = "is-sensitive" ) then (
            fn:not(ldsemeta:is-not-sensitive($file)) or ( fn:exists($sensitive-page) and $sensitive-page and fn:not(ldsemeta:is-not-sensitive($file)) )
        ) else if ( $check/@op = "approved" ) then (
            ldsemeta:is-approved($file)
        ) else ( core:validate-check($check, $map, $actual) )
    )
};

declare function ice:load-gear-map(
    $map as map:map,
    $locale as xs:string,
    $current-page as xs:string,
    $hidden-resources as map:map?,
    $is-template as xs:boolean,
    $options as element()*, (: as element(options|defaults)+ :)
    $custom-page as element(custom-page)?
) as map:map {
    let $_ as item()* := (
        ice:load-map($map, $locale, "", (), $current-page, $options),
        map:put($map,'$is-template', xs:string($is-template)),
        map:put($map,'$hidden-resources',$hidden-resources),
        map:put($map, "$custom-page", $custom-page)
    )
    return $map
};

declare function ice:load-map(
    $map as map:map,
    $locale as xs:string,
    $type as xs:string,
    $file as element()?,
    $current-page as xs:string,
    $options as element()* (: as element(options|defaults)+ :)
) as map:map {
    let $root as element()? := util:get-root($file)
    let $root as element()? :=
        if ( fn:name($root) = 'search:response' ) then (
            $file
        ) else ( $root )
    let $_ as item()* := (
        for $option as element() in fn:reverse($options)
        return (
            for $var as element() in $option/variables/*
            return (
                map:put($map, fn:concat('$',fn:local-name($var)), $var)
            ),
            for $setting as element() in $option/settings/*
            return (
                map:put($map, fn:concat('#',fn:local-name($setting)), $setting)
            )
        ),
        map:put($map,'$shared-prefix', $settings:shared-prefix),
        map:put($map,'$host', $settings:host),
        map:put($map,'$locale',$locale),
        map:put($map,'$lang',util:get-lang-from-locale($locale)),
        map:put($map,'$country',util:get-country-from-locale($locale)),
        map:put($map,'$type',$type),
        map:put($map,'$file', $root),
        map:put($map,'$node', $file),
        map:put($map,'$current-page', $current-page),
        map:put($map, "$submission-string", if(fn:not(ldsemeta:submission-submitted($file))) then " Submission" else ()),
        let $file-locale as xs:string? := ldsemeta:get-document-locale($root)
        let $file-country as xs:string? := util:get-country-from-locale($file-locale)
        let $file-id as xs:string? := ldsemeta:get-document-id($root)
        let $publish-type as xs:string := $type
        let $source as xs:string? := ldsemeta:get-document-source($root)
        let $source as xs:string := if ($source ne '') then ($source) else if ($file-country ne '') then ($file-country) else ('chq')
        let $chq-protected as xs:string := xs:string( $source = 'chq' and $file-country != '' )
        let $chq-only as xs:string := xs:string( $source = 'chq' and fn:not($file-country != '') )
        let $is-published as xs:string := xs:string( ldsemeta:is-published($root) )
        let $csv-variables as xs:string? := ice:csv-variables(util:merge(($options/variables)[1], ($options/variables)[2]))
        let $file-root as xs:string? := fn:name($root)
        return (
            if ($file-root = "teaser") then (
                let $teaser-type as item()* := ($root/@type[. ne ''], map:get($map,'$teaser-type'), map:get($map,'$type'))[1]
                let $teaser-location as item()* := ($root/@location[. ne ''], map:get($map,'$teaser-location'), map:get($map,'$location'))[1]
                return (
                    map:put($map, '$teaser-type', $teaser-type),
                    map:put($map, '$teaser-location', $teaser-location)
                )
            ) else (),
            map:put($map, '$file-root', $file-root),
            map:put($map, '$file-locale', $file-locale),
            map:put($map, '$file-country', $file-country),
            map:put($map, '$site', xdmp:get-request-field('site')),
            map:put($map, '$file-id', $file-id),
            map:put($map, '$publish-type', $publish-type),
            map:put($map, '$source', $source),
            map:put($map, '$chq-protected', $chq-protected),
            map:put($map, '#chq-only', $chq-only),
            map:put($map, '$is-published', $is-published),
            map:put($map, '$csv-variables', $csv-variables),
            map:put($map, '#ldse-settings', $settings:ldse-settings)
        )
    )
    return $map
};

declare function ice:csv-variables($variables as element()) as xs:string? {
    fn:encode-for-uri(fn:string-join(
            (for $var as element() in $variables/*
            let $name as xs:string := fn:local-name($var)
            where $name != "custom-option"
            order by if ($name = 'form') then (1) else (2)
            return fn:concat($name,':',xs:string($var))),
            ','
    ))
};

(:
    TODO
    Decide on this host variable,   believe it needs to hold the front-end host for the site
:)
declare function ice:getIceScripts($deprecated-context as xs:string?) as element()* {
    $DEPRECATED,
    ice:get-ice-script()
};

declare function ice:get-ice-script() as element()* {
    <script type="text/javascript">
        var sharedPrefix = {xdmp:to-json-string($settings:shared-prefix)};
        var frontEndHost = {xdmp:to-json-string(core:get-front-end-host())};
        var host = {xdmp:to-json-string($util:host)};
        var cdnPath = {xdmp:to-json-string($settings:cdn-path)};
        var locale = {xdmp:to-json-string($util:locale)};
        var serverTimeZone = { fn:hours-from-duration(fn:timezone-from-dateTime(fn:current-dateTime()))  };
        var clientTimeZone = - new Date().getTimezoneOffset()/60;
    </script>,
    <script type="text/javascript" src="{$settings:cdn-path}/scripts/jquery/plugins/cookie/jquery.cookie.20110127.min.js">&nbsp;</script>,
    <script type="text/javascript" src="{$settings:cdn-path}/scripts/ui/{$settings:jquery-ui}/jquery-ui.min.js">&nbsp;</script>,
    <script type="text/javascript" src="{$settings:cdn-path}/scripts/jquery/plugins/fileupload/5.6/jquery.fileupload.js">&nbsp;</script>,
    <script type="text/javascript" src="{$settings:cdn-ldspub-path}/lds-edit/scripts/{$settings:ckeditor-version}/ckeditor.js">&nbsp;</script>,
    <script type="text/javascript" src="{$settings:cdn-ldspub-path}/lds-edit/scripts/{$settings:ckeditor-version}/adapters/jquery.js">&nbsp;</script>,
    <script type="text/javascript" src="{$settings:cdn-ldspub-path}/lds-edit/scripts/jquery.form.js">&nbsp;</script>,
    <script type="text/javascript" src="{$settings:shared-prefix}/ice/resources/script/ice.js">&nbsp;</script>,
    ice:outputCkeditorSettings()
};

declare function ice:get-scripts() as element()* {
    <script type="text/javascript">
        var sharedPrefix = {xdmp:to-json-string($settings:shared-prefix)};
        var frontEndHost = {xdmp:to-json-string(core:get-front-end-host())};
        var host = {xdmp:to-json-string($util:host)};
        var cdnPath = {xdmp:to-json-string($settings:cdn-path)};
        var locale = {xdmp:to-json-string($util:locale)};
        var serverTimeZone = { fn:hours-from-duration(fn:timezone-from-dateTime(fn:current-dateTime()))  };
        var clientTimeZone = - new Date().getTimezoneOffset()/60;
    </script>,
    <script type="text/javascript" src="{$settings:cdn-path}/scripts/jquery/plugins/cookie/jquery.cookie.20110127.min.js">&nbsp;</script>,
    <script type="text/javascript" src="{$settings:cdn-path}/scripts/ui/{$settings:jquery-ui}/jquery-ui.min.js">&nbsp;</script>,
    <script type="text/javascript" src="{$settings:cdn-path}/scripts/jquery/plugins/fileupload/5.6/jquery.fileupload.js">&nbsp;</script>,
    <script type="text/javascript" src="{$settings:shared-prefix}/ice/resources/script/ice.js">&nbsp;</script>
};

declare function ice:get-ice-script(
    $toolbars-used as xs:string*
) as element()* {
    <script type="text/javascript">
        var sharedPrefix = {xdmp:to-json-string($settings:shared-prefix)};
        var frontEndHost = {xdmp:to-json-string(core:get-front-end-host())};
        var host = {xdmp:to-json-string($util:host)};
        var cdnPath = {xdmp:to-json-string($settings:cdn-path)};
        var locale = {xdmp:to-json-string($util:locale)};
        var serverTimeZone = { fn:hours-from-duration(fn:timezone-from-dateTime(fn:current-dateTime()))  };
        var clientTimeZone = - new Date().getTimezoneOffset()/60;
    </script>,
    <script type="text/javascript" src="{$settings:cdn-path}/scripts/jquery/plugins/cookie/jquery.cookie.20110127.min.js">&nbsp;</script>,
    <script type="text/javascript" src="{$settings:cdn-path}/scripts/ui/{$settings:jquery-ui}/jquery-ui.min.js">&nbsp;</script>,
    <script type="text/javascript" src="{$settings:cdn-path}/scripts/jquery/plugins/fileupload/5.6/jquery.fileupload.js">&nbsp;</script>,
    <script type="text/javascript" src="{$settings:cdn-ldspub-path}/lds-edit/scripts/{$settings:ckeditor-version}/ckeditor.js">&nbsp;</script>,
    <script type="text/javascript" src="{$settings:cdn-ldspub-path}/lds-edit/scripts/{$settings:ckeditor-version}/adapters/jquery.js">&nbsp;</script>,
    <script type="text/javascript" src="{$settings:cdn-ldspub-path}/lds-edit/scripts/jquery.form.js">&nbsp;</script>,
    <script type="text/javascript" src="{$settings:shared-prefix}/ice/resources/script/ice.js">&nbsp;</script>,
    ice:outputCkeditorSettings($toolbars-used)
};

declare function ice:getCkeditorSettings() as element(ldse:ldse-ckeditor)* {
    let $settings as element(ldse:ldse-ckeditor)* :=
        cts:search(/ldse:ldse-ckeditor,
            core:get-filter-query()
        )
    for $setting as element(ldse:ldse-ckeditor) in $settings
    return (
        if ( fn:not($setting/ldse:events/ldse:event[@name = 'dialogDefinition']) ) then (
            element {fn:node-name($setting)} {
                $setting/(@*|node() except $setting/ldse:events),
                <events xmlns="http://lds.org/code/lds-edit">
                    {$setting/ldse:events/ldse:event}
                    <event xmlns="http://lds.org/code/lds-edit" name="dialogDefinition">
                        // Take the dialog name and its definition from the event data.
                        var dialogName = ev.data.name;
                        var dialogDefinition = ev.data.definition;

                        // Check if the definition is from the dialog we're
                        // interested in (the 'link' dialog).
                        if ( dialogName == 'link' )
                        {{
                        // Remove the 'Target' and 'Advanced' tabs from the 'Link' dialog.
                        dialogDefinition.removeContents( 'target' );
                        dialogDefinition.removeContents( 'advanced' );
                        dialogDefinition.removeContents( 'upload' );

                        // Get a reference to the 'Link Info' tab.
                        var infoTab = dialogDefinition.getContents( 'info' );

                        // Remove unnecessary widgets from the 'Link Info' tab.
                        infoTab.remove( 'browse');
                        }}
                    </event>
                </events>
            }
        ) else ( $setting )
    )
};

declare function ice:getCkeditorSettings(
    $toolbars-used as xs:string*
) as element(ldse:ldse-ckeditor)* {
    let $settings as element(ldse:ldse-ckeditor)* :=
        cts:search(/ldse:ldse-ckeditor,
            core:get-filter-query()
        )
    for $setting as element(ldse:ldse-ckeditor) in $settings
    where $setting/@name = $toolbars-used or ( fn:empty($setting/@name) and 'default' = $toolbars-used )
    return (
        if ( fn:not($setting/ldse:events/ldse:event[@name = 'dialogDefinition']) ) then (
            element {fn:node-name($setting)} {
                $setting/(@*|node() except $setting/ldse:events),
                <events xmlns="http://lds.org/code/lds-edit">
                    {$setting/ldse:events/ldse:event}
                    <event xmlns="http://lds.org/code/lds-edit" name="dialogDefinition">
                        // Take the dialog name and its definition from the event data.
                        var dialogName = ev.data.name;
                        var dialogDefinition = ev.data.definition;

                        // Check if the definition is from the dialog we're
                        // interested in (the 'link' dialog).
                        if ( dialogName == 'link' )
                        {{
                        // Remove the 'Target' and 'Advanced' tabs from the 'Link' dialog.
                        dialogDefinition.removeContents( 'target' );
                        dialogDefinition.removeContents( 'advanced' );
                        dialogDefinition.removeContents( 'upload' );

                        // Get a reference to the 'Link Info' tab.
                        var infoTab = dialogDefinition.getContents( 'info' );

                        // Remove unnecessary widgets from the 'Link Info' tab.
                        infoTab.remove( 'browse');
                        }}
                    </event>
                </events>
            }
        ) else ( $setting )
    )
};

declare function ice:getPluginForm(
    $plugin as xs:string
) as xs:string? {
    let $ckeditor as element(ldse:ldse-ckeditor)* := ice:getCkeditorSettings()
    return (
        ($ckeditor/ldse:plugins/ldse:plugin[@form ne '' and . eq $plugin]/@form)[1]
    )
};

declare function ice:outputCkeditorSettings2() as element(script)? {
    let $ckeditor as element(ldse:ldse-ckeditor)? := ice:getCkeditorSettings()
    where fn:exists($ckeditor)
    return(
        <script type="text/javascript">{
            fn:concat('var CKEDITOR_SETTINGS = ', ice:jsonConfigSettings($ckeditor/ldse:config-settings), '; '),
            if ( fn:exists($ckeditor/ldse:styles) ) then (
                fn:concat('CKEDITOR_SETTINGS.stylesSet = ', ice:jsonStyles($ckeditor/ldse:styles), '; ')
            ) else (),
            if ( fn:exists($ckeditor/ldse:toolbar) ) then (
                for $toolbar as element(ldse:toolbar) in $ckeditor/ldse:toolbar
                let $name as xs:string := ( $toolbar/@name, "MyToolbar " )[1]
                return fn:concat('CKEDITOR_SETTINGS.toolbar_', $name, ' = ', ice:jsonToolbar($toolbar), '; ')
            ) else (),
            if ( fn:exists($ckeditor/ldse:plugins) ) then (
                fn:concat('CKEDITOR_SETTINGS.extraPlugins = ', ice:getExtraPlugins($ckeditor/ldse:plugins), '; ')
            ) else ()
        }</script>
    )
};

declare function ice:outputCkeditorSettings() as element(script)? {
    let $all-settings as element(ldse:ldse-ckeditor)* := ice:getCkeditorSettings()
    let $count as xs:int := fn:count($all-settings)
    return
        <script type="text/javascript">{
            "var CKEDITOR_SETTINGS = {};",
            fn:concat('CKEDITOR_SETTINGS.DEFAULT_SETTINGS_NAME = "', ($all-settings[@default = "true"]/@name, $all-settings/@name, "DefaultSettings")[1], '";'),
            for $ckeditor as element(ldse:ldse-ckeditor) in $all-settings
            let $settings as xs:string :=
                if ( $count = 1 ) then (
                    "CKEDITOR_SETTINGS"
                ) else ( fn:concat('CKEDITOR_SETTINGS["', ( $ckeditor/@name, "DefaultSettings" )[1], '"]') )
            where fn:exists($ckeditor)
            return (
                fn:concat($settings, ' = ', ice:jsonConfigSettings($ckeditor/ldse:config-settings), '; '),
                if ( fn:exists($ckeditor/ldse:styles) ) then (
                    fn:concat($settings, '.stylesSet = ', ice:jsonStyles($ckeditor/ldse:styles), '; ')
                ) else (),
                if ( fn:exists($ckeditor/ldse:toolbar) ) then (
                    for $toolbar as element(ldse:toolbar) in $ckeditor/ldse:toolbar
                    let $name as xs:string := ( $toolbar/@name, "MyToolbar ")[1]
                    return fn:concat($settings, '.toolbar_', $name, ' = ', ice:jsonToolbar($toolbar), '; ')
                ) else (),
                if ( fn:exists($ckeditor/ldse:plugins) ) then (
                    fn:concat($settings, '.extraPlugins = ', ice:getExtraPlugins($ckeditor/ldse:plugins), '; ')
                ) else (),
                if ( fn:exists($ckeditor/ldse:events) ) then (
                    ice:getEvents($ckeditor/ldse:events)
                ) else ()
            )

        }</script>
};

declare function ice:outputCkeditorSettings(
    $toolbars-used as xs:string*
) as element(script)? {
    let $all-settings as element(ldse:ldse-ckeditor)* := ice:getCkeditorSettings()
    let $count as xs:int := fn:count($all-settings)
    return
        <script type="text/javascript">{
            "var CKEDITOR_SETTINGS = {};",
            fn:concat('CKEDITOR_SETTINGS.DEFAULT_SETTINGS_NAME = "', ($all-settings[@default = "true"]/@name, $all-settings/@name, "DefaultSettings")[1], '";'),
            for $ckeditor as element(ldse:ldse-ckeditor) in $all-settings
            let $settings as xs:string :=
                if ( $count = 1 ) then (
                    "CKEDITOR_SETTINGS"
                ) else ( fn:concat('CKEDITOR_SETTINGS["', ( $ckeditor/@name, "DefaultSettings" )[1], '"]') )
            where fn:exists($ckeditor)
            return (
                fn:concat($settings, ' = ', ice:jsonConfigSettings($ckeditor/ldse:config-settings), '; '),
                if ( fn:exists($ckeditor/ldse:styles) ) then (
                    fn:concat($settings, '.stylesSet = ', ice:jsonStyles($ckeditor/ldse:styles), '; ')
                ) else (),
                if ( fn:exists($ckeditor/ldse:toolbar) ) then (
                    for $toolbar as element(ldse:toolbar) in $ckeditor/ldse:toolbar
                    let $name as xs:string := ( $toolbar/@name, "MyToolbar ")[1]
                    return fn:concat($settings, '.toolbar_', $name, ' = ', ice:jsonToolbar($toolbar), '; ')
                ) else (),
                if ( fn:exists($ckeditor/ldse:plugins) ) then (
                    fn:concat($settings, '.extraPlugins = ', ice:getExtraPlugins($ckeditor/ldse:plugins), '; ')
                ) else (),
                if ( fn:exists($ckeditor/ldse:events) ) then (
                    ice:getEvents($ckeditor/ldse:events)
                ) else ()
            )

        }</script>
};

declare function ice:getEvents($events as element(ldse:events)) as xs:string
{
    for $event as element(ldse:event) in $events/ldse:event
    return
        fn:concat(
                "CKEDITOR.on('",
                $event/@name/fn:string(.),
                "', function( ev ){",
                $event/fn:string(.),
                "});"
        )
};

declare function ice:jsonConfigSettings($config-settings as element(ldse:config-settings)) as xs:string {
    fn:concat('{', fn:string-join(ice:jsonconfigSetting($config-settings/*), ','), '}')
};

declare function ice:jsonconfigSetting($setting as element()) as xs:string {
    let $name as xs:string := fn:local-name($setting)
    let $value as xs:string := $setting
    let $value as xs:string :=
        if (fn:matches($value, "\{\$.*\}" )) then (
            form:evalVarsInSrc($value)
        ) else ($value)
    return (
        if ($value = ("true", "false") or fn:matches($value, "^'.*'$") or fn:matches($value, '^\d+$')  or fn:matches($value, '^\[.*\]$') or fn:matches($value, '^\{.*\}$') ) then (
            fn:concat('"', $name, '":',$value)
        ) else if ( fn:matches($value, '^".*"$') ) then (
            fjson:escapedKeyValue($name, fn:substring($value, 2, fn:string-length($value) - 2) )
        ) else (
            fjson:escapedKeyValue($name, $value)
        )
    (:fn:concat('"', $name, '":',$value):)
    )
};

(: JSON CKEDITOR STYLES :)
declare function ice:jsonStyles($styles as element(ldse:styles)) as xs:string {
    fn:concat('[', fn:string-join(ice:jsonStyle($styles/ldse:style), ','), ']')
};

declare function ice:jsonStyle($style as element(ldse:style)) as xs:string {
    fn:concat('{',
            '"name":"', $style/ldse:name, '",',
            '"element":"', $style/ldse:element, '",',
            if ( fn:exists($style/ldse:attributes/*) ) then (
                fn:concat('"attributes":{', fn:string-join( ice:jsonStyleAttributes($style/ldse:attributes/*), ','), '}')
            ) else (),
            '}')
};

declare function ice:jsonStyleAttributes($attr as element()) as xs:string {
    fn:concat('"', fn:local-name($attr), '":"', $attr, '"')
};
(: END OF JSON CKEDITOR STYLES :)

(: JSON CKEDITOR TOOLBAR :)
declare function ice:jsonToolbar($toolbar as element(ldse:toolbar)) as xs:string {
    fn:concat('[', fn:string-join(ice:jsonToolbarRow($toolbar/ldse:row), ",'/',"), ']')
};

declare function ice:jsonToolbarRow($toolbarRow as element(ldse:row)) as xs:string {
    fn:string-join( ice:jsonToolbarGroup($toolbarRow/ldse:group), ',')
};

declare function ice:jsonToolbarGroup($toolbarGroup as element(ldse:group)) as xs:string {
    fn:concat('[', fn:string-join(ice:jsonToolbarButton($toolbarGroup/*), ','), ']')
};

declare function ice:jsonToolbarButton($toolbarButton as element()) as xs:string? {
    let $name as xs:string := fn:local-name($toolbarButton)
    where validToolbarButton($toolbarButton)
    return (
        if ($name eq 'PIPE') then ( '"-"' ) else ( fn:concat('"', $name, '"') )
    )
};

(: NOTE
   ldse-ckeditor @role option on buttons its going to be converted to a @permission
 :)
declare function ice:validToolbarButton($toolbarButton as element()) as xs:boolean {
    if ( fn:exists($toolbarButton/@permission[. != ""]) ) then (
        ac:has-permission($toolbarButton/@permission, (), ())
    ) else ( fn:true() )
};
(: END OF JSON CKEDITOR TOOLBAR :)

declare function getExtraPlugins($plugins as element(ldse:plugins)) as xs:string {
    fn:concat('"', fn:string-join($plugins/ldse:plugin, ','), '"')
};

declare function add-type($type as xs:string) as empty-sequence() {
    map:put($publish-types, $type, $type)
};

declare function add-dynamic-item($type as xs:string, $id as xs:string) as empty-sequence() {
    map:put($dynamic-items, $type, ( map:get($dynamic-items, $type), $id) )
};

declare function getDynamicItems() as map:map {
    $dynamic-items
};

declare function getPublishTypes() as map:map {
    $publish-types
};



declare function ice:addDynamicItem($type as xs:string, $id as xs:string) as empty-sequence() {
    $DEPRECATED,
    ice:add-dynamic-item($type, $id)
};
(:~
    Controls when ICE is shown as well as the ICE dropdown options and onclicks for each option

    @param $deprecated-context the directory of the item
    @param $locale language area/country (ie: eng, spa-mx, etc.)
    @param $type the type of the item (ie: article, video, teaser, etc.)
    @param $xmlFile the xml file of the item
    @param $currentPage the uri to the page of the item
    @param $options a custom xml that determines different cases that need to be addressed when editing or adding items.

    Available options in the option xml:
    <options>
        <teaser-type>main</teaser-type>                Teaser type (feature, link, quote, tools, articleLink, list, ...)
        <teaser-location>sidebar</teaser-location>     Teaser Location (right-sash, carosel, inline, ...)
        <teaser-manager>text,summary</teaser-manager>  Adds teaser manager to the ice drop down for editing all teasers in that location. Pass
                                                            an optional list of nodes to show as text to the user. (Default: title,body)
        <only-one>true</only-one>                      When only one item is allowed
        <only-clone>true</only-clone>                  Used when $xmlFile is a default item used only to create real content
        <only-edit>true</only-edit>                    Used when the item is only editable (such as leftnav)
        <ajax>true</ajax>                              Set to true when ajaxed so we can set the onclick events again.
        <disable-remove>true</disable-remove>          Used to remove the remove-form-page option
        <disable-delete>true</disable-delete>          Used to remove the delete option
        <custom-nav>{$isCustom}</custom-nav>           Used for left nav
        <nav-name>ldsorg-navigation</nav-name>         Name of the root channels node
        <publish-languages>false</publish-languages> Remove the publish languages option
        <custom-option name="pre:someFunction">true|false</custom-option> Must be defined in ldse-settings
    </options>
~:)

declare function ice:addIce(
        $deprecated-context as xs:string?,
        $locale as xs:string,
        $type as xs:string,
        $xmlFile as element()?,
        $currentPage as xs:string,
        $options as element(options)?
) as element()? {
    let $settings-names as xs:QName* := (
        xs:QName('only-one'),xs:QName('only-clone'),xs:QName('only-edit'),xs:QName('ajax'), xs:QName('custom-option'), xs:QName('disable-remove'),
        xs:QName('disable-delete')
    )
    let $link-names as xs:QName* := ( xs:QName('publish-languages') )
    let $settings as element()* := $options/*[fn:node-name(.) = $settings-names]
    let $links as element()* := $options/*[fn:node-name(.) = $link-names]
    let $variables as element()* := $options/* except ($settings, $links)
    let $links as element()*:=
        <links>
            { if (fn:exists($options/publish-languages)) then ( <link name="ldse:publish-languages">true</link> ) else () }
            { if (fn:exists($options/teaser-manager)) then ( <link name="ldse:teaser-manager">true</link> ) else () }
            { if ($type eq 'sub-channel') then (
                <link name="ldse:edit-navigation">true</link>,
                <link name="ldse:edit-custom-navigation">true</link>,
                <link name="ldse:publish-navigation">true</link>,
                <link name="ldse:publish-jericho">true</link>
            ) else ()
            }
        </links>/node()
    return (
        $DEPRECATED,
        ice:add-ice($locale, $type, $xmlFile, $currentPage,
                <options>
                    <variables>{ $variables }</variables>
                    <links>{ $links }</links>
                    <settings>{ $settings }</settings>
                    { $options/custom-option }
                </options>
        )
    )
};

declare function addGear($deprecated-context as xs:string, $currentPage as xs:string, $lang as xs:string, $hiddenResources as map:map?) as item()* {
    $DEPRECATED,
    addGear($deprecated-context, $currentPage, $lang, $hiddenResources, fn:false())
};

declare function addGear($deprecated-context as xs:string, $currentPage as xs:string, $lang as xs:string, $hiddenResources as map:map?, $isTemplate as xs:boolean) as item()* {
    $DEPRECATED,
    addGear($deprecated-context, $currentPage, $lang, $hiddenResources, $isTemplate,
            <options>
                <publish-page/>
                <unpublish-page/>
                <publish-meta/>
                <page-settings/>
                <edit-hidden/>
                <new-page/>
                <clone-page/>
                { if ($isTemplate) then (
                    <change-template/>
                ) else () }
            </options>)
};

(:~
    Controls the LDS-EDIT gear
    @param $deprecated-context the directory of the item
    @param $currentPage the uri to the page of the item
    @param $lang language (ie: eng, spa, deu, etc.)
    @param $hiddenResources a map of all hidden strings
    @param $isTemplate boolean if the page uses a template or not
    @param $options a custom xml that determines when each option in the dropdown menu is displayed

    Available options in the option xml:
    <options>
        <publish-page/>         Show the publish page option
        <publish-meta/>         Show the publish meta link
        <unpublish-page/>       Show the unpublish page option
        <change-template/>      Show the change template option
        <add-poll/>             Show the add poll option
        <page-settings/>        Show the option for a form to change theme, width, and navigation
        <edit-hidden/>          Show the edit hidden resources option
        <new-page/>             Show the new page from template option
        <clone-page action="clone|move"/>           Show the clone page option
        <toggle-carousel>id or class of carousel</toggle-carousel>  Turn on and off carousel
    </options>
:)

(: TODO
    update addGear to have permissions for each actions
:)
declare function addGear($deprecated-context as xs:string?, $currentPage as xs:string, $lang as xs:string, $hiddenResources as map:map?, $isTemplate as xs:boolean, $options as element(options)?) as item()* {

    let $settings-names as xs:QName* := (
        xs:QName('clone-page'),
        xs:QName('toggle-carousel'),
        xs:QName('clear-url')
    )

    let $link-names as xs:QName* := (
        xs:QName('publish-page'),
        xs:QName('publish-meta'),
        xs:QName('unpublish-page'),
        xs:QName('change-template'),
        xs:QName('add-poll'),
        xs:QName('page-settings'),
        xs:QName('edit-hidden'),
        xs:QName('new-page')
    )

    let $settings as element()* := $options/*[fn:node-name(.) = $settings-names]
    let $links as element()* := $options/*[fn:node-name(.) = $link-names]
    let $variables as element()* := $options/* except ($settings, $links)
    let $links as element()*:=
        <links>
            <link name="ldse:gear-publish">{fn:exists($options/publish-page)}</link>
            <link name="ldse:gear-publish-meta">{fn:exists($options/publish-meta)}</link>
            <link name="ldse:gear-unpublish">{fn:exists($options/unpublish-page)}</link>
            <link name="ldse:gear-change-template">{fn:exists($options/change-template)}</link>
            <link name="ldse:gear-add-poll">{fn:exists($options/add-poll)}</link>
            <link name="ldse:gear-settings">{fn:exists($options/page-settings)}</link>
            <link name="ldse:gear-clone-page">{fn:exists($options/clone-page)}</link>
            <link name="ldse:gear-edit-hidden-resources">{fn:exists($options/edit-hidden)}</link>
            <link name="ldse:gear-new-page">{fn:exists($options/new-page)}</link>
            <link name="ldse:gear-toggle-carousel">{fn:exists($options/toggle-carousel)}</link>
            <link name="ldse:gear-omniture">true</link>
            <link name="ldse:gear-seomoz">true</link>
        </links>/node()

    return (
        $DEPRECATED,
        ice:add-gear($currentPage, $lang, $hiddenResources, $isTemplate,
                <options>
                    <variables>{ $variables }</variables>
                    <links>{ $links }</links>
                    <settings>{ $settings }</settings>
                    { $options/custom-option }
                </options>
        )
    )
};

declare function addGearCustomOptions($currentPage as xs:string, $locale as xs:string, $hiddenResources as map:map?, $isTemplate as xs:boolean, $options as element(options)?) as element(li)* {
    let $passed-functions as element(custom-option)* := $options/custom-option
    let $passed-function-names as xs:string* := $passed-functions/@name
    let $custom-functions as element(ldse:custom-option)* := $settings:ldse-settings/ldse:add-gear/ldse:custom-option[@name eq $passed-function-names or @global eq "true"]
    return (
        for $custom-function as element(ldse:custom-option) in $custom-functions
        let $seq as xs:integer := if ($custom-function/@seq castable as xs:integer) then ( xs:integer($custom-function/@seq) ) else ( 9999 )
        let $name as xs:string := $custom-function/@name
        let $namespace as xs:string := $custom-function/@namespace
        let $path as xs:string := $custom-function/@path
        let $function as xdmp:function := xdmp:function(fn:QName($namespace, $name), $path)
        where fn:not( $passed-functions[@name eq $name] eq "false" )
        order by $seq
        return (
            xdmp:apply($function, core:get-mode-root(), $currentPage, $locale, $hiddenResources, $isTemplate, $options)
        )
    )
};

(:~
    Retrieves the custom-page XML for a specified URI and LANG

    @param $deprecated-context the context to query
    @param $uri The URI for the custom-page XML
    @param $lang The LANG of the custom-page XML

    @return custom-page.xml
~:)
declare function ice:getCustomPage($deprecated-context as xs:string?, $uri as xs:string, $locale as xs:string) as element(custom-page)? {
    $DEPRECATED,
    ice:getCustomPage($uri, $locale)
};
declare function ice:getCustomPage($uri as xs:string, $locale as xs:string) as element(custom-page)? {
    let $page as element(custom-page)? := get-custom-page($uri, $locale)
    let $page as element(custom-page)? :=
        if ( fn:exists($page) ) then ($page) else (
            get-custom-page($uri, fn:replace($locale, "-.*", ""))
        )
    let $debug as empty-sequence() := xdmp:trace("ldse-query",fn:concat("getCustomPage:",xdmp:elapsed-time()))
    return $page
};

(: getCustomPage with no country fall back :)
declare function ice:get-custom-page($uri as xs:string, $locale as xs:string) as element(custom-page)? {
    ice:get-custom-page($uri, $locale, fn:true())
};

declare function ice:get-custom-page($uri as xs:string, $locale as xs:string, $add-to-map as xs:boolean) as element(custom-page)? {
    let $page as element(custom-page)? :=
        cts:search(/custom-page,
                cts:and-query((
                    core:get-filter-query(),
                    cts:element-attribute-value-query( xs:QName('custom-page'), xs:QName('uri'), $uri, ( 'diacritic-insensitive', "whitespace-insensitive", "unstemmed" ) ),
                    cts:element-attribute-value-query( xs:QName('custom-page'), xs:QName('locale'), $locale, 'exact')
                ))
        )[1]
    let $addToMap as empty-sequence() := if ( $add-to-map and fn:exists($page) ) then (add-type('customPage')) else ()
    return (
        $page
    )
};

declare function ice:get-custom-page(
    $uri as xs:string,
    $locale as xs:string,
    $add-to-map as xs:boolean,
    $site as xs:string?
) as element(custom-page)? {
    let $page as element(custom-page)? :=
        cts:search(/custom-page,
            cts:and-query((
                core:get-filter-query(),
                cts:element-attribute-value-query( xs:QName('custom-page'), xs:QName('uri'), $uri, ( 'diacritic-insensitive', "whitespace-insensitive", "unstemmed" ) ),
                cts:element-attribute-value-query( xs:QName('custom-page'), xs:QName('locale'), $locale, 'exact'),
                if ( fn:exists($site[. != '']) ) then (
                    cts:or-query((
                        cts:element-value-query(xs:QName('ldse:site-context'), $site, 'exact'),
                        cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('site'), $site, 'exact')
                    ))
                ) else ()
            ))
        )[1]
    let $addToMap as empty-sequence() := if ( $add-to-map and fn:exists($page) ) then (add-type('customPage')) else ()
    return (
        $page
    )
};

declare function ice:remove-reference-from-page($locale as xs:string, $uri as xs:string, $id as xs:string) as item()* {
    let $page as element(custom-page)? := ice:get-custom-page($uri, $locale)
    where fn:exists($page) and fn:not( document:is-updated(xdmp:node-uri($page)) )
    return (
        $page/content/*[. eq $id]/xdmp:node-delete(.)
    )
};

(: DEPRECATED moved to settings functions :)
declare function getRootQNames($deprecated-context as xs:string?) as xs:QName* {
    $DEPRECATED,
    $settings:root-qnames
};

(: DEPRECATED moved to util
declare function getFileName($file as element()) as xs:string? {
    fn:tokenize(xdmp:node-uri($file),'/')[fn:last()]
};:)

declare function buildChannelsList($channels as element(channels)* , $index as xs:string?) as element(ul) {
    let $levels as xs:integer := fn:count(fn:tokenize($index, '-')) + 1
    let $color as xs:integer := 248 - (16 * $levels)
    return (
        <ul style="background-color:rgb({$color},{$color},{$color})">
            {
                if ($index ne '') then (
                    <li>
                        <span>Always show section: </span>
                        {
                            if ($channels/@alwaysShow eq 'true') then (
                                <input type="checkbox" name="{fn:concat('alwaysShow',$index)}" value="true" checked="yes" />
                            ) else (
                                <input type="checkbox" name="{fn:concat('alwaysShow',$index)}" value="true"/>
                            )
                        }
                    </li>
                ) else ()
            }
            {
                for $c as element(channel) at $count in $channels/channel
                order by fn:number($c/@sequence) ascending
                return (buildChannelEntry($c, xs:string($count), $index))
            }
            <li><input type="button" class="addChannel ldse-button" onclick="addChannel(this, '{$index}')" value="Add Channel" /></li>
            <input type="hidden" id="count{$index}" name="{$index}" value="{fn:count($channels/channel)}" />
        </ul>
    )
};

declare function buildChannelEntry($channel as element(channel)? , $count as xs:string?, $index as xs:string?) as element(li) {
    let $sequence as xs:string := fn:concat('sequence',$index)
    let $name as xs:string := fn:concat('name',$index)
    let $url as xs:string := fn:concat('url',$index)
    let $attrName as xs:string := fn:lower-case(fn:concat('attrName',$index))
    let $sub as xs:string := fn:concat('sub',$index)

    let $entryId as xs:string := fn:concat('entry',$index)
    return (
        <li id="{$entryId}">
            <input type="hidden" id="subChannelIndex" name="{$sub}" value="{fn:concat($index, '-', $count)}" />
            <a href="#" onclick="deleteEntry(this);return false;">
                <span class="ldse-icon-x"></span>
            </a>
            <div style="display: inline-block;">
                <span class="inputLabel">Sequence:</span>
                <br/>
                <input type="text" name="{$sequence}" class="required" onblur="validateChannelForm();" value="{$channel/@sequence}" size="2"/>
            </div>
            <div style="display: inline-block;">
                <span class="inputLabel">Name:</span>
                <br/>
                <input type="text" name="{$name}" class="required" onblur="validateChannelForm();" value="{xs:string($channel/name)}" size="32"/>
            </div>
            <div style="display: inline-block;">
                <span class="inputLabel">URL:</span>
                <br/>
                <input type="text" name="{$url}" class="noEmpty" value="{xs:string($channel/url)}" size="32"/>
            </div>
            <div style="display: inline-block;">
                <span class="inputLabel">Name Attribute:</span>
                <br/>
                <input type="text" name="{$attrName}" class="noEmpty" value="{$channel/@name}" size="13"/>
            </div>
            {
                if ( fn:exists($channel/channels) ) then (
                    buildChannelsList($channel/channels, fn:concat($index,"-",$count))
                ) else (
                    <input type="button" class="addSub ldse-button" onclick="addSub(this, '{fn:concat($index,"-",$count)}')" value="Add Sub" />
                )
            }
        </li>
    )
};

(:
    Finds all related teasers for Teaser Manager
:)
declare function findSiblingTeasers($root-name as xs:string, $locale as xs:string, $uri as xs:string, $location as xs:string) as node()* {
    for $items as element() in
        cts:search(/*,
                cts:and-query((
                    core:get-filter-query(),
                    cts:element-attribute-value-query(xs:QName($root-name), xs:QName('location'), $location, 'exact'),
                    cts:element-attribute-value-query(xs:QName($root-name), xs:QName('locale'), $locale, 'exact'),
                    cts:or-query((
                        cts:element-attribute-value-query(xs:QName($root-name), xs:QName('page'), $uri, 'exact'),
                        cts:element-attribute-value-query(xs:QName($root-name), xs:QName('uri'), $uri, 'exact')
                    ))
                ))
        )
    order by fn:number($items/@sequence)
    return (
        $items
    )
};

declare function findSiblingTeasersComponent(
    $root-name as xs:string,
    $locale as xs:string,
    $uri as xs:string,
    $location as xs:string,
    $compId as xs:string?
) as node()* {
    for $items as element() in
        cts:search(/*,
                cts:and-query((
                    core:get-filter-query(),
                    cts:element-attribute-value-query(xs:QName($root-name), xs:QName('locale'), $locale, 'exact'),
                    if ( fn:exists($compId) ) then (
                        cts:element-attribute-value-query(xs:QName($root-name), xs:QName('compId'), $compId, 'exact')
                    ) else (
                        cts:element-attribute-value-query(xs:QName($root-name), xs:QName('location'), $location, 'exact')
                    )
                ))
        )
    order by fn:number($items/@sequence)
    return (
        $items
    )
};

(: *********************************
     COMMON CUSTOM DICE FUNCTIONS
   ********************************* :)

declare function tidy($xml as item()*) as item()* {
    xdmp:tidy($xml,
            <options xmlns="xdmp:tidy">
                <newline>LF</newline>
                <wrap>0</wrap>
                <new-inline-tags>pre,bdi,mark,meter,progress,ruby,rt,time,wbr</new-inline-tags>
                <new-blocklevel-tags>address,article,params,aside,audio,canvas,details,dialog,embed,figure,figcaption,footer,header,hgroup,output,nav,section,source,summary,track,video</new-blocklevel-tags>
                <hide-comments>true</hide-comments>
            </options>)/xhtml:html/xhtml:body/node()
};

declare function ice:html-tidy($xml as item()*) as item()* {
    xdmp:tidy($xml,
            <options xmlns="xdmp:tidy">
                <newline>LF</newline>
                <wrap>0</wrap>
                <new-inline-tags>pre,bdi,mark,meter,progress,ruby,rt,time,wbr</new-inline-tags>
                <new-blocklevel-tags>address,article,params,aside,audio,canvas,details,dialog,embed,figure,figcaption,footer,header,hgroup,output,nav,section,source,summary,track,video</new-blocklevel-tags>
                <hide-comments>true</hide-comments>
                <output-html>yes</output-html>
            </options>)/html/body/node()
};

declare function stripNamespaces($xml as item()*) as item()* {
    for $n as item() in $xml
    return (
        typeswitch ($n)
            case text() return $n
            case comment() return $n
            default return (
                element {fn:local-name($n)} {$n/@*, stripNamespaces($n/node())}
            )
    )
};

declare function getCountryOptions($value as xs:string) as element(option)* {
    for $country as element(country) in util:get-countries('eng')/country
    let $id as xs:string := $country/@id
    order by $country/name
    return (
        element option {
            attribute value {$id},
            if ($id eq $value) then (
                attribute selected {'selected'}
            ) else (),
            xs:string($country/name)
        }
    )
};

declare variable $globalParaCount as xs:int := 0;
declare variable $globalDivCount as xs:int := 0;
declare variable $globalHeadCount as xs:int := 0;

declare function wysiwygToldswebml($text as item()*, $uri as xs:string) as item()* {
    for $node as item() at $count in $text[fn:not(fn:string(.) eq '&#10;')]
    let $nodeName as xs:string := fn:normalize-space(fn:local-name($node))
    let $compareNode as item() := if ($nodeName eq "") then ($node) else (element {$nodeName}{'dummy node'})
    let $output as item() :=
        typeswitch ($compareNode)
            case element(pre) return $node
            case element(image) return $node
            case element(h1) return (
                blockHead($node, $uri)
            )
            case element(h2) return (
                blockHead($node, $uri)
            )case element(h3) return (
            blockHead($node, $uri)
        )
            case element(p) return (
                let $id as xs:int := (xdmp:set($globalParaCount, $globalParaCount+1), $globalParaCount)
                let $uri as xs:string := fn:concat($uri,'.p',$globalParaCount)
                return (
                    element block {
                        attribute type {"para"},
                        attribute uri {$uri},
                        $node/@*,
                        $node/node()
                    }
                )
            )
            case element(div) return (
        element div {
        $node/@*,
        wysiwygToldswebml($node/node(), $uri)
        }
        )
        default return ($node)
let $output as item()* := if (fn:empty($node/node())) then ($node) else ($output)
return ($output)
};

declare function blockHead($node as item(), $uri as xs:string) as element(block) {
let $id as xs:int := (xdmp:set($globalHeadCount, $globalHeadCount+1), $globalHeadCount)
let $uri as xs:string := fn:concat($uri,'.head',$globalHeadCount)
return (
element block {
attribute type {"heading"},
attribute uri {$uri},
$node
}
)
};

declare function ldswebmlToWysiwyg($text as item()*) as item()* {
for $node as item() at $count in $text
let $nodeName as xs:string := fn:normalize-space(fn:local-name($node))
let $compareNode as item() := if ($nodeName eq "") then ($node) else (element {$nodeName}{'dumpy node'})
let $output as item()* :=
typeswitch ($compareNode)
case element(block) return (
let $type as xs:string := $node/@type
let $elementType as xs:string :=
if ($type eq 'div') then ('div')
else if ($type eq 'para') then ('p')
else ('p')
return (
if ($type eq 'heading') then (
ldswebmlToWysiwyg($node/node())
) else (
element {$elementType} {
$node/@*[fn:not(fn:node-name(.) = (xs:QName("type"), xs:QName("uri")) )],
ldswebmlToWysiwyg($node/node())
}
)
)
)
case text() return $node
default return (
element { fn:QName(fn:namespace-uri($node), fn:name($node)) } { $node/@*, ldswebmlToWysiwyg($node/node()) }
)
return ($output)
};

declare function buildLeaderUri ($file as element()?, $input as element(ldse:input), $index as xs:string?, $value as item()*) as xs:string? {
let $form as element(ldse:formTemplate)? := fn:root($input)/ldse:formTemplate
let $base as xs:string? := xs:string($form/ldse:base-uri)
let $uri-titleInput as element(ldse:input)? := $form/ldse:structure/ldse:ldswebml/ldse:search-meta/ldse:uri-title/ldse:input
let $uri-title as xs:string? := form:getInputValue($uri-titleInput, $file, ())
let $uri as xs:string? := fn:concat($base, '/', $uri-title)
let $set as empty-sequence() := form:setVariable('uri',$uri)
return ($uri)
};

(: generic buildUri function :)
declare function buildUri ($file as element()?, $input as element(ldse:input), $index as xs:string?, $value as item()*) as xs:string? {
let $form as element(ldse:formTemplate)? := fn:root($input)/ldse:formTemplate
let $base as xs:string? := xs:string($form/ldse:base-uri)
let $uri-titleInput as element(ldse:input)? := $form/ldse:structure/(ldse:ldswebml/ldse:search-meta/ldse:uri-title|ldse:collection/ldse:meta/ldse:uri-title)[1]/ldse:input
let $uri-title as xs:string := form:getInputValue($uri-titleInput, $file, ())
let $uri as xs:string? := fn:concat($base, '/', $uri-title)
let $uri as xs:string? := util:sanitize-uri($uri)
let $set as empty-sequence() := if (form:getVariable('action') eq 'add') then (form:setVariable('uri',$uri)) else (
let $current-uri as xs:string? := form:dynamicXpath($file, xs:string($input/@xpath))
where fn:not($current-uri = "")
return (
form:setVariable('uri',$current-uri)
)
)
return (form:getVariable('uri'))
};

declare function getGaRoleOptions($value as xs:string?) as element(option)* {
for $role as element(role) in cts:search(/ga-roles/role, core:get-filter-query() )
let $id as xs:string := $role/@id
return (
element option {
attribute value {$id},
if ($id eq $value) then (
attribute selected {'selected'}
) else (),
xs:string($role)
}
)
};

declare function formatDefinitionTextForTopic($file as element()?, $input as element(ldse:input), $index as xs:string?, $value as item()*) as item()* {
if (fn:not($value eq '&#10;')) then (
for $node as item() in $value
let $nodename as xs:string := xs:string(fn:name($node))
let $output as xs:string := fn:replace(fn:replace($node, "&lt;.*?&gt;", ""), "\[teaser:\d+-\w+\]", "")
where $nodename eq 'p'
return (
$output
)
) else ('')
};


(: Dynamic Page Builder Functions :)
declare function uriPageBuilderInput($input as element(ldse:input), $file as element()?, $index as xs:string?) as element(dl)* {
let $name as xs:string := if (fn:exists($index)) then (fn:concat($input/@name, '-', $index)) else (xs:string($input/@name))
let $id as xs:string := if (fn:exists($input/@id)) then ($input/@id) else ($input/@name)
let $class as xs:string := form:addClass($input, 'xxxl')
let $value as item()* := form:dynamicXpath($file, xs:string($input/@xpath))
return (
if (fn:exists($file)) then (
<dl data-sequence="1">
<dt>
<label for="$id">Full Path</label>
<input type="hidden" id="{$id}" name="{$name}" value="{$value}" readonly="readonly" data-readonly="true"/>
</dt>
<dd>
<div id="fullPath" class="xxxl readonly">{$value}</div>
</dd>
</dl>
) else (
<dl data-sequence="1">
<dt>
<label for="uriContext">Context</label>
</dt>
<dd>{
element select {
attribute name {"uriContext"},
attribute id {"uriContext"},
(: attribute onchange {"updateFullUri();"}, :)
for $uriContext as xs:string in $settings:root-contexts
return (
<option value="{$uriContext}">{$uriContext}</option>
)
}
}</dd>
</dl>,
<dl data-sequence="1.1">
<dt>
<label for="path">Path</label>{form:required($input)}
</dt>
<dd>{
element input {
attribute name {"path"},
attribute type {"text"},
attribute value {},
(: attribute onkeyup {"updateFullUri(false);"},
                        attribute onblur {"updateFullUri(true);"}, :)
attribute id {"path"},
attribute class {$class}
}
}</dd>
</dl>,
<dl data-sequence="1.2">
<dt>
<label>Full Path</label>
<input type="hidden" id="{$id}" name="{$name}" value=""/>
</dt>
<dd>
<input id="fullPath" class="required" type="text" readonly="readonly" value=""/>
</dd>
</dl>
)
)
};

declare function uriPageBuilder($file as element()?, $input as element(ldse:input), $index as xs:string?, $value as item()*) as xs:string {
let $uri as xs:string :=
if ( fn:starts-with($value, form:getVariable('sharedPrefix') ) ) then (
$value
) else (
fn:concat(form:getVariable('sharedPrefix'), $value)
)
let $set as empty-sequence() := form:setVariable('uri', $uri)
return (
$uri
)
};
declare function themeOptions($value as xs:string?) as element(option)* {
<option value="auto">auto</option>,
for $t as xs:string in core:get-siteProperties()/themes/theme
return (
if ($t eq $value) then (
<option value="{$t}" selected="yes">{$t}</option>
) else (
<option value="{$t}">{$t}</option>
)
)
};

declare function templateInput($input as element(ldse:input), $file as element()?, $index as xs:string?) as element(dl) {
let $name as xs:string := if (fn:exists($index)) then (fn:concat($input/@name, '-', $index)) else ($input/@name)
let $value as item()* := form:dynamicXpath($file, xs:string($input/@xpath))
return (
<dl data-sequence="{xs:string($input/@seq)}" class="clearfix">
<dt>
<label>Template</label>
</dt>
<dd id="templateList">{
for $template as element(template) in
cts:search(/template,
cts:and-query((
core:get-filter-query(),
if (form:getVariable('country') ne '') then (
cts:element-attribute-value-query(xs:QName('template'), xs:QName('country'), 'true', 'exact')
) else ()
))
)
let $small-image as xs:string? := (
$template/images/small[@path = 'fixed'],
core:get-ldspub-cdn-uri(fn:concat('templates/images/',$template/@id/fn:string(), '-small.png'))
)[1]
let $large-image as xs:string? := (
$template/images/large[@path = 'fixed'],
core:get-ldspub-cdn-uri(fn:concat('templates/images/',$template/@id/fn:string(), '-large.png'))
)[1]
order by fn:number($template/@sequence) ascending, $template/name
return (
<section class="ldse-block tile ldse-notification-container ldse-toggle-content {if ( xs:string($value) = $template/@id ) then ( ' depressed' ) else () }">
<button class="ldse-button tile above" onclick="selectTemplate('{fn:concat("template-",$template/@id)}');">
<img class="tile-image" alt="{fn:concat("template-",$template/@id)}" src="{$small-image}" onerror="this.remove();"/>
<span>{$template/name/node()}</span>
</button>
<span class="ixf-option" style="display:none;">{
element input {
attribute type {"radio"},
attribute style { "display:none;" },
attribute id {fn:concat("template-",$template/@id)},
attribute class {"template"},
attribute value {xs:string($template/@id)},
attribute name {$name},
if ($value eq $template/@id) then (
attribute checked {"checked"}
) else ()
}
}
</span>
</section>
)
}</dd>
</dl>
)
};

declare function addRule(
    $file as element()?,
    $input as element(ldse:input),
    $index as xs:string?,
    $value as item()*
) as item()*{
    let $locale as xs:string := form:getVariable('locale')
    let $changeTemplate as xs:string? := form:getVariable('changeTemplate')
    let $url as xs:string := form:getVariable('uri')
    let $path as xs:string :=
        if ( fn:starts-with($url, form:getVariable('sharedPrefix')) and form:getVariable('sharedPrefix') != '' ) then (
            fn:substring-after($url, form:getVariable('sharedPrefix'))
        ) else ( $url )
    let $template as element(template) :=
        cts:search(/template,
            cts:and-query((
                core:get-filter-query(),
                cts:element-attribute-value-query(xs:QName('template'), xs:QName('id'), $value, 'exact')
            ))
        )
    let $rules as element(rewriteRules)? :=
        cts:search(/rewriteRules,
            cts:and-query((
                core:get-filter-query(),
                cts:element-attribute-value-query(xs:QName('rewriteRules'), xs:QName('locale'), $locale, 'exact'),
                if ( fn:exists($site) ) then (
                    cts:element-attribute-value-query(xs:QName('rewriteRules'), xs:QName('site'), $site, 'exact')
                ) else ()
            ))
        )
    let $topRule as element(rule)? := $rules/rule[1]
    let $params as xs:string? := $template/rule/@params[. != '']
    let $newRule as element(rule) :=
        <rule path="{ $path }" params="{ ( $params, 0 )[1] }">{
            fn:concat(fn:substring(xs:string($template/path), 2), "?url=", $url)
        }</rule>
    let $existingRule as element(rule)? := $rules/rule[@path = $path and @params = ( $params, '0' )[1]]
    let $insertRule as item()* :=
        if ( fn:exists($existingRule) ) then (
            if ( fn:exists($changeTemplate) ) then (
                xdmp:node-replace($existingRule, $newRule)
            ) else ()
        ) else (
            if ( fn:exists($topRule) ) then (
                xdmp:node-insert-before($topRule, $newRule)
            ) else (
                let $file as element() :=
                    <rewriteRules status="preview" locale="{ $locale }">{
                        if ( fn:exists($site) ) then (
                            attribute site { $site }
                        ) else (),
                        $newRule
                    }</rewriteRules>
                let $db-path as xs:string := core:build-db-path("", $locale, "", $file, ())
                let $db-path as xs:string :=
                    if ( fn:exists($site) ) then (
                        fn:replace($db-path, 'rewrite-rules', 'rewrite-rules-' || $site)
                    ) else ( $db-path )

                return (
                    core:save-file($db-path, $file, ())
                )
            )
        )

    return $value
};

declare function localeOptions($value as xs:string?) as element(option)* {
if (fn:exists(form:getVariable('changeTemplate'))) then (
element option {
attribute selected {"selected"},
attribute value {$value},
$value
}
) else (
let $value as xs:string := if ($value ne '') then ($value) else (form:getVariable('locale'))
return (
for $locale as xs:string in ac:locales()
order by $locale
return (
element option {
if ($locale eq $value) then (
attribute selected {"selected"}
) else (),
attribute value {$locale},
$locale
}
)
)
)
};

declare function updateLocale($file as element()?, $input as element(ldse:input), $index as xs:string?, $value as item()*) as item()* {
let $set as empty-sequence() := form:setVariable('locale', $value)
let $set as empty-sequence() := form:setVariable('lang', util:get-lang-from-locale($value))
let $set as empty-sequence() := form:setVariable('country', util:get-country-from-locale($value))
return (
form:getVariable('locale')
)
};
(: END of Dynamic Page Builder :)

(:~
    URL STRIPPING FUNCTIONS

    Upon saving each document, replace all fully qualified URL's (inside the
    <a> tags) with relative URLS, unless the URL is for an external site. If
    the URL is for a preview version of any LDS.org site, or its domain matches
    one of the strip domains in the ldse-settings config file, make the URL
    relative. A published page may not point to any part of a preview site.
~:)

declare function stripUrl($href as xs:string) as xs:string {
if (fn:contains($href, "://")) then (
let $protocol as xs:string := fn:substring-before($href, "://")
let $temp1 as xs:string := fn:substring-after($href, "://")
let $temp2 as xs:string := fn:substring-before($temp1, "/")
let $domain as xs:string :=
if (fn:exists($temp2) and $temp2 ne "") then ($temp2) else ($temp1)
let $strip as xs:string := fn:concat($protocol, "://", $domain)
return stripUrl($href, $strip, $domain)
) else (
let $strip as xs:string := fn:substring-before($href, "/")
let $strip as xs:string := if ($strip eq "") then ($href) else ($strip)
return stripUrl($href, $strip)
)
};

declare function stripUrl($href as xs:string, $strip as xs:string) as xs:string {
stripUrl($href, $strip, $strip)
};

(:~
    If the domain of the href matches one of the strip domains or it is a
    preview version of an lds.org domain, this function converts the href into
    a relative URL.

    @param $href    The link inside the href attribute.
    @param $strip   The part of the href attribute that is stripped if
                    necessary. The href attribute should begin with the
                    substring $strip.
    @param $domain  The domain that is checked against the strip domains. If
                    this domain matches one of the strip domains, or it is a
                    preview version of an lds.org domain, then $strip is
                    removed from $href to obtain the relative URL.
    @return The new URL after it is stripped (or not stripped).
~:)
declare function stripUrl($href as xs:string, $strip as xs:string, $domain as xs:string) as xs:string {
let $new-url as xs:string :=
if ($strip ne "") then (
let $path as xs:string := fn:substring-after($href, $strip)
let $path as xs:string := if ($path ne "") then ($path) else ("/")
let $stripped-url as xs:string :=
if (
settings:is-strip-domain($domain)
or (fn:ends-with($domain, ".churchofjesuschrist.org") and fn:contains($domain, "preview"))
) then ($path) else ($href)
return $stripped-url
) else (
$href (: There is nothing to strip. If the URL is already relative, just keep it. :)
)
return $new-url
};

(: This function should be called from save.xqy. :)
declare function stripUrlsProcess($item as item()) as item()* {
typeswitch ($item)
case element(map:map) return $item
case text() return $item
case element(a) return stripUrlsProcessElementA($item)
case element(xhtml:a) return stripUrlsProcessElementA($item)
case element() return stripUrlsProcessElement($item)
case document-node() return stripUrlsProcess($item/node())
default return ()
};

declare function stripUrlsProcessElement($item as element()) as item()* {
element { fn:node-name($item) } {
$item/@*,
stripUrlsProcess($item/node())
}
};

declare function stripUrlsProcessElementA($item as element()) as item()* {
element { fn:node-name($item) } {
stripUrlsProcessHref($item/@href), (
$item/@*[fn:node-name(.) ne xs:QName("href")]
),
stripUrlsProcess($item/node())
}
};

declare function stripUrlsProcessHref($href as attribute()) as attribute()? {
attribute href { stripUrl($href) }
};
(: END of URL stripping functions :)

declare function helpLink($help as xs:string) as element()? {
if ($help eq "")
then ()

else if (fn:contains($help, "://"))
then <a href="{$help}" target="_blank" class="sprite help icon"></a>

else <a href="{fn:concat("https://preview.churchofjesuschrist.org/lds-edit-help/article/view/", $help)}" target="_blank" class="sprite help icon"></a>



};

declare function inline-help-link(
    $input as element()
) as element(span)? {
    inline-help-link($input, "0")
};

declare function inline-help-link(
    $input as element(),
    $index as xs:string
) as element(span)? {
    inline-help-link($input, "0", ())
};

declare function inline-help-link(
    $input as element(),
    $index as xs:string,
    $template-id as xs:string?
) as element(span)? {
    if ( $input/(@inline-help|@help) ) then (
        let $locale as xs:string := (form:getVariable('locale'), 'eng')[1]
        let $inline-help-text as item()* :=  if (fn:contains($input/@inline-help/fn:string(),'|'))then get-bundle-value-for-helptext($input/@inline-help/fn:string(.), $locale, $template-id)[. != ''] else $input/@inline-help/fn:string(.)
        let $pre-id as xs:string := fn:concat($input/@name/fn:string(),'-',$index, xdmp:random(10000))
        return (
            if ( fn:exists($inline-help-text) ) then (
                <span id="{ $pre-id }_help_container">
                    <span id="{$pre-id }_help_button" class="ldse-info-button ldse-icon-ko-info ldse-icon ldse-toggle-content" title="Show Info" data-selector="#{ $pre-id }_help_info_text">Show Info</span>
                    <div id="{ $pre-id }_help_info_text" class="ldse-info-text ldse-hidden">
                    {
                        $inline-help-text,
                        if ( $inline-help-text ) then <br /> else (),
                        if ( $input/@help ) then (
                            let $link as element()? := helpLink($input/@help/fn:string())
                            return (
                                "Click ",
                                element a { $link/(@target|@href), "here" },
                                " for more information"
                            )
                        ) else ()
                    }
                    </div>
                </span>
            ) else ()
        )
    ) else ()
};

declare function get-bundle-value-for-helptext(
    $string as xs:string?,
    $locale as xs:string,
    $template-id as xs:string?
) as item()* {
    let $parts as xs:string* := fn:tokenize($string, "\|")
    let $bundle-name as xs:string? := $parts[1][fn:not(. = "")]
    let $bundle-key as xs:string? := $parts[2][fn:not(. = "")]
    let $default as xs:string? := $parts[3][fn:not(. = "")]
    let $value as item()* := fast:get-uncached-value($bundle-name, $locale, $template-id, $bundle-key)
(:    let $value as item()* := fast:get-value($locale, fn:concat($bundle-name, ':', $template-id || '-' || $bundle-key))[fn:not(. = "")]:)
    let $value as item()* :=
        if ( fn:exists($value) ) then (
            $value
        ) else ( fast:get-uncached-value($bundle-name, $locale, (), $bundle-key)[fn:not(. = "")] )
    return (
        if ( fn:exists($value) ) then (
            $value
        ) else (
            ($default,
            if ( fn:exists($bundle-name) and fn:exists($bundle-key) ) then () else ( $string ))[1]
        )
    )
};

declare function get-bundle-value(
    $string as xs:string?,
    $locale as xs:string
) as xs:string? {
    let $parts as xs:string* := fn:tokenize($string, "\|")
    let $bundle-name as xs:string? := $parts[1][fn:not(. = "")]
    let $bundle-key as xs:string? := $parts[2][fn:not(. = "")]
    let $default as xs:string? := $parts[3][fn:not(. = "")]
    return (
        fast:get-value($locale, fn:concat($bundle-name, ':', $bundle-key))[fn:not(. = "")],
        $default,
        $string,
        $bundle-key[fn:not(. = "")]
    )[1]
};

declare function match-regex($key as xs:string, $regexes as xs:string*) as xs:boolean {
some $regex as xs:string in $regexes satisfies fn:matches(fn:lower-case($key), $regex)
};

(:
<span id="element-{{index}}-rs-info" {{hidden ElementType 2}}>
	<span id="element-{{index}}-rs-info-button" class="ldse-info-button ldse-icon-ko-info ldse-icon ldse-toggle-content" data-selector="#element-{{index}}-rs-info-text" title="Show Info">Show Info</span>
	<div id="element-{{index}}-rs-info-text" class="ldse-info-text ldse-hidden">Please select a reporting statement for more information</div>
</span>
:)
