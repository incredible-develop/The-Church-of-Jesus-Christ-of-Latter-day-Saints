xquery version "1.0-ml";

module namespace copy = "http://lds.org/code/shared/lds-edit/copy-functions";

import module namespace security = "http://lds.org/code/shared/common/security/security-functions" at "/shared/common/security/securityFunctions.xqy";

import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "/modules/ldse-settings.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "/modules/ldse-core.xqy";
import module namespace ice = "http://lds.org/code/shared/lds-edit/iceFunction" at "/ice/modules/iceFunctions.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "/modules/ldse-meta.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "/modules/utility-functions.xqy";
import module namespace tf = "http://lds.org/code/shared/lds-edit/fromTrigger" at "/translation/from/modules/fromTriggerFunctions.xqy";
import module namespace task = "http://lds.org/code/shared/lds-edit/task-functions" at "/pharaoh/modules/taskFunctions.xqy";
import module namespace document = "http://lds.org/code/shared/lds-edit/document-functions" at "/modules/document-functions.xqy";
import module namespace function = "http://lds.org/code/shared/lds-edit/function-apply" at "/invoke/function-apply.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace its = "http://www.w3.org/2005/11/its";

declare option xdmp:mapping "true";

declare function copy:copy-files-to-locale(
    $files as element()*,
    $source-locale as xs:string,
    $locale as xs:string
) as empty-sequence() {
    let $uris as xs:string* := fn:distinct-values(ldsemeta:get-document-uri($files, fn:true()))
    return (
        copy:copy-files-to-locale($files, $source-locale, $locale, $uris)
    )
};

declare function copy:copy-files-to-locale(
    $files as element()*,
    $source-locale as xs:string,
    $locale as xs:string,
    $uris as xs:string*
) as empty-sequence() {
    let $debug as item()* := xdmp:trace('ldse-copy', '************* copy-files-to-locale **********************')
    let $debug as item()* := xdmp:trace('ldse-copy', $locale)
    let $debug as item()* := xdmp:trace('ldse-copy', $uris)
    let $copy as item()* :=
        for $file as element() in $files
        let $existing-file as element()? := ldsemeta:get-file-in-locale($file, $locale)
        let $new-xml as element() := copy:update-xml-to-locale($file, $locale)
        let $new-xml as element() :=
            if (fn:node-name($new-xml) eq xs:QName('custom-page') and fn:exists($existing-file)) then (
                copy:merge-page-files($new-xml, $existing-file)
            ) else ($new-xml)

        let $dbpath as xs:string :=
            if ( fn:empty($existing-file) ) then (
                 core:build-db-path(ldsemeta:get-document-uri($new-xml), $locale, ldsemeta:get-document-id($new-xml), $new-xml, () )
            ) else (
                xdmp:node-uri($existing-file)
            )
        let $debug as item()* := xdmp:trace('ldse-copy', $dbpath)
        let $schedule-tasks as item()* := copy:copy-tasks($new-xml)
        where document:is-not-updated($dbpath)
        return (
           core:save-file($core:mode, $dbpath, $new-xml, $existing-file)
        )
    let $copy-rules as item()* := copy:copy-rewrite-rules($uris, $source-locale, $locale)
    return ()
};

declare function copy:update-xml-to-locale($xml as element(), $locale as xs:string) as element() {
    let $new-xml as element() := tf:remove-context($xml)
    let $id as xs:string := ldsemeta:get-document-id($xml)
    let $newId as xs:string := tf:buildNewId($id, $locale)

    let $ldse-meta as element(ldse:ldse-meta) := ldsemeta:remove-publish-date(ldsemeta:get-meta($new-xml, $newId, $locale, (), 'preview'))
    (: Updates :)
    let $new-xml as element() := tf:updateId($new-xml, $newId)
    let $new-xml as element() := tf:updateLocale($new-xml, $locale)
    let $new-xml as element() := tf:updateStatus($new-xml, 'preview')
    let $new-xml as element() := tf:updateLdseMeta($new-xml, $ldse-meta)
    let $new-xml as element() := tf:updateCollectionItems($new-xml, $locale)
    let $new-xml as element() := tf:mergeResources($new-xml, $locale)
    let $new-xml as element() := tf:updateCustomPage($new-xml, $locale)
    let $new-xml as element() := tf:updatePreTags($new-xml, $locale)

    return $new-xml
};

declare function copy:copy-rewrite-rules($uris as xs:string*, $source-locale as xs:string, $locale as xs:string) as item()* {
    let $sourceRules as element(rewriteRules)? :=
        cts:search(/rewriteRules,
            cts:and-query((
                core:get-filter-query(),
                cts:element-attribute-value-query(xs:QName('rewriteRules'), xs:QName('locale'), $source-locale, 'exact')
            ))
        )
    let $existingRules as element(rewriteRules)? :=
        cts:search(/rewriteRules,
            cts:and-query((
                core:get-filter-query(),
                cts:element-attribute-value-query(xs:QName('rewriteRules'), xs:QName('locale'), $locale, 'exact')
            ))
        )

    let $rules as element(rule)* :=
        for $uri as xs:string in $uris
        let $sourceRule as element(rule)? := ($sourceRules/rule[@path = $uri and @params = "0"])[1]
        let $existingRule as element(rule)? := ($existingRules/rule[@path = $uri and @params = "0"])[1]
        where $uri != '' and fn:exists($sourceRule) and fn:empty($existingRule)
        return (
            $sourceRule
        )

    let $newRules as element(rewriteRules) :=
        element rewriteRules {
            attribute status { "preview" },
            attribute locale { $locale },
            attribute id {
                if ( fn:exists($existingRules/@id) ) then ($existingRules/@id) else ( util:generate-unique-id($locale) )
            },
            if ( fn:empty($existingRules) ) then (
                $existingRules/@*[fn:not( fn:node-name(.) = (xs:QName("status"), xs:QName("locale"), xs:QName("id")) )]
            ) else (
                $sourceRules/@*[fn:not( fn:node-name(.) = (xs:QName("status"), xs:QName("locale"), xs:QName("id")) )]
            ),
            $rules,
            $existingRules/*
        }

    let $path as xs:string :=
        if ( fn:exists($existingRules) ) then (
            xdmp:node-uri($existingRules)
        ) else (
            let $sourcePath as xs:string? := xdmp:node-uri($sourceRules)
            let $pathTokens as xs:string* := fn:tokenize($sourcePath, '/')
            let $fileName as xs:string := $pathTokens[fn:last()]
            let $fileName as xs:string :=
                if ( fn:contains($fileName, $source-locale) ) then (
                    fn:replace($fileName, $source-locale, $locale)
                ) else (
                    fn:replace($fileName, '.xml', fn:concat('-', $locale, '.xml') )
                )
            let $newPath as xs:string := fn:string-join(($pathTokens[1 to (fn:last() - 1)], $fileName), '/')
            return $newPath
        )
    let $insert as item()* :=
        if ( fn:exists($rules) ) then (
            core:save-file($core:mode, $path, $newRules, $existingRules)
        ) else ()
    let $debug as item()* :=
        if (fn:exists($rules)) then (
            xdmp:trace('ldse-copy', fn:concat('************* Rules Copied *************')),
            xdmp:trace('ldse-copy', $rules)
        ) else ()
    return (
        ()
    )
};

declare function copy:merge-page-files($newPage as element(custom-page), $existingPage as element(custom-page)) as element(custom-page) {
    element custom-page {
        attribute status {"preview"},
        $existingPage/@*[fn:not(fn:node-name(.) = xs:QName("status"))],
        $newPage/ldse:ldse-meta,
        element content {
            attribute its:translate {"no"},
            $existingPage/content/*,
            $newPage/content/*[ fn:not(. eq $existingPage/content/*)]
        },
        $existingPage/* except $existingPage/(content|ldse:ldse-meta)
    }
};

declare function send-to-country($files as element()+, $source-locale as xs:string) as empty-sequence() {
    if ( util:is-not-country($source-locale) ) then (
        let $files as element()* :=
            for $file as element() in $files
            let $uri as xs:string? := ldsemeta:get-document-uri($file)
            where settings:is-valid-country-copy($uri)
            return $file
        let $uris as xs:string* := fn:distinct-values(ldsemeta:get-document-uri($files, fn:true()))
        let $pageFiles as element(custom-page)* :=
            for $uri as xs:string in $uris
            where fn:empty($files[self::custom-page and @uri eq $uri ])
            return (
                ice:get-custom-page($uri, $source-locale)
            )
        let $files as element()* := ($files, $pageFiles)
        where fn:exists($files)
        return (
            for $site as element(site) in $util:country-sites[language/@key eq $source-locale or source-language/@key eq $source-locale]
            let $siteLocale as xs:string := fn:concat($site/language/@key,'-',$site/@key)
            return (
                copy:copy-files-to-locale($files, $source-locale, $siteLocale, $uris)
            )
        )
    ) else ()
};

declare function copy:copy-resource-file-to-countries($resource as element(resources)) as empty-sequence(){
    let $source-locale as xs:string := $resource/locale
    let $resource-name as xs:string := $resource/name
    return(
        for $site as element(site) in $util:country-sites[language/@key eq $source-locale or source-language/@key eq $source-locale]
        let $siteLocale as xs:string := fn:concat($site/language/@key,'-',$site/@key)
        let $countryResourceFile as element(resources)? :=
            cts:search(/resources,
                cts:and-query((
                    core:get-filter-query(),
                    cts:element-value-query(xs:QName('name'), $resource-name, 'exact'),
                    cts:element-attribute-value-query(xs:QName('resources'), xs:QName('locale'), $siteLocale, 'exact')
                ))
            )[1]
        let $newId as xs:string := fn:concat($siteLocale, '-', fn:string($resource/name))
        let $new-meta as element(ldse:ldse-meta) := ldsemeta:get-meta($resource,$newId,$siteLocale, (), "preview")
        return(
            (: Check to see if resources files already exists - if not copy - otherwise merge. :)
            if( fn:empty($countryResourceFile) ) then (
                let $resourceCopy as element(resources) :=
                    <resources locale="{$siteLocale}" status="publish">
                        {$resource/name}
                        {$resource/application}
                        <locale>{$siteLocale}</locale>
                        {$new-meta}
                        {$resource/properties}
                    </resources>
                let $dbPath as xs:string := core:build-db-path("", $siteLocale, $newId, $resourceCopy, () )
                return core:save-file($core:mode, $dbPath, $resourceCopy, ())
          ) else(
            copy:merge-resources($resource, $countryResourceFile, $siteLocale, $new-meta)
          )
        )
    )
};

declare function copy:merge-resources($resource as element(resources), $countryResourceFile as element(resources), $siteLocale as xs:string, $new-meta as element(ldse:ldse-meta)?) as item()* {
      let $map as map:map := map:map()

      let $_ as item()* := $resource/properties/entry/map:put($map, @key, .)
      let $_ as item()* := $countryResourceFile/properties/entry/map:put($map, @key, .)
      let $_ as item()* := $resource/properties/entry[@status = "edited"]/map:put($map, @key, .)

      let $updatedCountryResourceFile as element(resources) :=
            <resources locale="{$siteLocale}" status="preview">
                {$resource/name}
                {$resource/application}
                <locale>{$siteLocale}</locale>
                {$new-meta}
                <properties>{
                    for $key as xs:string in map:keys($map)
                    return (
                        map:get($map, $key)
                    )
                }</properties>
            </resources>
     return (
         core:document-replace($countryResourceFile,$updatedCountryResourceFile)
     )
};

(: Send single file to countries logic below :)
declare function send-file-to-country($file as element(), $source-locale as xs:string) as empty-sequence() {
    if ( util:is-not-country($source-locale) ) then (
        let $uri as xs:string? := ldsemeta:get-document-uri($file, fn:true())
        let $file as element()? := if (settings:is-valid-country-copy($uri)) then ( $file ) else ()
        where fn:exists($file)
        return (
            for $site as element(site) in $util:country-sites[language/@key eq $source-locale or source-language/@key eq $source-locale]
            let $site-locale as xs:string := fn:concat($site/language/@key,'-',$site/@key)
            return (
                copy:copy-file-to-locale($file, $source-locale, $site-locale, $uri)
            )
        )
    ) else ()
};

(: copy a single file to a new locale :)
declare function copy:copy-file-to-locale(
    $file as element(),
    $source-locale as xs:string,
    $locale as xs:string,
    $uri as xs:string
) as empty-sequence() {
    let $debug as item()* := xdmp:trace('ldse-copy', '************* copy-file-to-locale **********************')
    let $debug as item()* := xdmp:trace('ldse-copy', $locale)
    let $debug as item()* := xdmp:trace('ldse-copy', $uri)

    let $existing-file as element()? := ldsemeta:get-file-in-locale($file, $locale)
    let $new-xml as element() := copy:update-xml-to-locale($file, $locale)
    let $new-xml as element() :=
        if (fn:node-name($new-xml) eq xs:QName('custom-page') and fn:exists($existing-file)) then (
            copy:merge-page-files($new-xml, $existing-file)
        ) else ( $new-xml )
    let $dbpath as xs:string :=
        if ( fn:empty($existing-file) ) then (
             core:build-db-path($uri, $locale, ldsemeta:get-document-id($file), $file, () )
        ) else (
            xdmp:node-uri($existing-file)
        )

    let $debug as item()* := xdmp:trace('ldse-copy', $dbpath)
    let $source-lang as xs:string := util:get-lang-from-locale($source-locale)
    let $lang as xs:string := util:get-lang-from-locale($locale)
    let $schedule-tasks as item()* :=
        if($lang = $source-lang) then(
            copy-tasks($new-xml)
        )
        else()
    let $save as item()*  :=
    core:save-file($core:mode, $dbpath, $file, $existing-file)
    let $copy-rules as item()* := copy:copy-rewrite-rules($uri, $source-locale, $locale)
    return ()
};

declare function copy:copy-tasks(
    $file as element()
) as empty-sequence() {
    let $site as xs:string := $core:site
    let $id as xs:string := ldsemeta:get-document-id($file)
    let $locale as xs:string := ldsemeta:get-document-locale($file)
    let $uri as xs:string? := ldsemeta:get-document-uri($file)
    let $user as xs:string? := (ac:getUserName(),"lds-edit")[1]
    let $schedule-publish-date as xs:dateTime? := ldsemeta:get-schedule-publish($file)/@dateTime
    let $schedule-unpublish-date as xs:dateTime? := ldsemeta:get-schedule-unpublish($file)/@dateTime
    let $lang as xs:string := util:get-lang-from-locale($locale)
    let $country as xs:string? := util:get-country-from-locale($locale)
    let $copy-allowed as xs:boolean :=
        if ($country != "") then (
            fn:empty( $util:country-sites[@key = $country and language/@key = $lang and @scheduled-publishing = "false"] )
        ) else (
            fn:true()
        )
    let $scheduleTask as item()*  :=
        if ( $copy-allowed and fn:exists($schedule-publish-date) ) then (
            xdmp:trace('ldse-copy', 'schedule-publish'),
            task:queue-action-task('ldse:publish', $schedule-publish-date, $id, $locale, $uri, $user)
        ) else ()
    let $scheduleTask as item()*  :=
        if ( $copy-allowed and fn:exists($schedule-unpublish-date) ) then (
            xdmp:trace('ldse-copy', 'schedule-unpublish'),
            task:queue-action-task('ldse:unpublish', $schedule-unpublish-date, $id, $locale, $uri, $user)
        ) else ()
    return ()
};

(:Function to create bundle files from English to 28 languages. :)
(:$file-name : Name found in the source file resources/name :)
(:$env : 'preview' or 'published':)
declare function copy:copy-bundles-from-eng-to-other-langs(
    $file-name as xs:string,
    $site as xs:string,
    $env as xs:string
){
    let $env := fn:concat('/',$env,'/')
    let $languages := <langs>
                    <lang name='albanian'>alb</lang>
                    <lang name='armenian'>hye</lang>
                    <lang name='cebuano'>ceb</lang>
                    <lang name='croatian'>hrv</lang>
                    <lang name='czech'>ces</lang>
                    <lang name='danish'>dan</lang>
                    <lang name='dutch'>nld</lang>
                    <lang name='finnish'>fin</lang>
                    <lang name='french'>fra</lang>
                    <lang name='german'>deu</lang>
                    <lang name='greek'>ell</lang>
                    <lang name='hungarian'>hun</lang>
                    <lang name='indonesian'>ind</lang>
                    <lang name='italian'>ita</lang>
                    <lang name='japanese'>jpn</lang>
                    <lang name='korean'>kor</lang>
                    <lang name='latvian'>lav</lang>
                    <lang name='norwegian'>nor</lang>
                    <lang name='polish'>pol</lang>
                    <lang name='portuguese'>por</lang>
                    <lang name='romanian'>ron</lang>
                    <lang name='russian'>rus</lang>
                    <lang name='spanish'>spa</lang>
                    <lang name='swedish'>swe</lang>
                    <lang name='tagalog'>tgl</lang>
                    <lang name='thai'>tha</lang>
                    <lang name='ukrainian'>ukr</lang>
                    <lang name='chinese'>zho</lang>
                 </langs>

    let $file := cts:search(/resources,
                             cts:and-query((
                                   cts:directory-query($env, 'infinity'),
                                   cts:element-value-query(xs:QName('name'), $file-name),
                                   cts:element-attribute-value-query(xs:QName('resources'), xs:QName('locale'), 'eng'),
                                   cts:element-attribute-value-query(xs:QName('resources'), xs:QName('site'), $site)
                                     )) )[1]
    let $create := if ($file) then
                   for $lang in $languages/lang
                   let $url := fn:replace(fn:base-uri($file),'english',$lang/@name/fn:string())
                   let $locale := $lang/fn:string()
                   let $path := fn:replace($url, 'eng', $locale)
                   let $id := fn:replace($file/@id/fn:string(), 'eng', $locale)
                   let $source := if (fn:contains($locale, '-')) then
                                     fn:substring-after($locale, '-')
                                  else
                                     'chq'
                   let $status := if (fn:contains($env, 'preview')) then
                                     'preview'
                                  else
                                     'publish'
                   let $newContent := element resources {attribute locale {$locale},
                                                         attribute status {$status},
                                                         $file/@*  except ($file/@locale, $file/@status),
                                                         element ldse:ldse-meta {$file/ldse:ldse-meta/@*,
                                                                                 element ldse:document {attribute id {fn:replace($file/ldse:ldse-meta/ldse:document/@id/fn:string(),'eng', $locale)},
                                                                                                        attribute locale {$locale},
                                                                                                        attribute source {$source},
                                                                                                        attribute status {$status},
                                                                                                        $file/ldse:ldse-meta/ldse:document/@* except ($file/ldse:ldse-meta/ldse:document/@id,
                                                                                                                                                   $file/ldse:ldse-meta/ldse:document/@locale,
                                                                                                                                                   $file/ldse:ldse-meta/ldse:document/@source,
                                                                                                                                                   $file/ldse:ldse-meta/ldse:document/@status),
                                                                                                        $file/ldse:ldse-meta/* except ($file/ldse:ldse-meta/ldse:document)}},
                                                         element locale {$locale},
                                                         $file/application,
                                                         $file/name,
                                                         $file/properties}
                   let $exist := cts:search(/resources,
                                 cts:and-query((
                                       cts:directory-query($env, 'infinity'),
                                       cts:element-value-query(xs:QName('name'), $file-name),
                                       cts:element-attribute-value-query(xs:QName('resources'), xs:QName('locale'), $locale),
                                       cts:element-attribute-value-query(xs:QName('resources'), xs:QName('site'), $site)
                                         )) )[1]
                   return if ($exist) then ()
                          else xdmp:document-insert($path, $newContent)
            else ("English source file doesn't exits. ")
    return $create
};

(:Function to create bundle files from any language to any other language :)
(:$bundle-name : Name found in the source file resources/name or 'all' if you want all the bundles copied :)
(:$from-site : origin site name. Example 'churchofjesuschrist':)
(:$to-site : site we are coping to. Example 'venezauchrist':)
(:$from-locale : origin locale. Example 'eng':)
(:$to-locale : locale we are coping to. Example 'fra':)
(:$to-language-folder : language folder we are coping to. Example 'french':)
(:$env : 'preview' or 'published':)
declare function copy:copy-bundles-from-lang-to-other-langs(
    $bundle-name as xs:string,
    $from-site as xs:string,
    $to-site as xs:string,
    $from-locale as xs:string,
    $to-locale as xs:string,
    $to-language-folder as xs:string,
    $env as xs:string
){
    let $env := fn:concat('/',$env,'/')
    let $files := cts:search(/resources,
                            cts:and-query((
                                  cts:directory-query($env, 'infinity'),
                                  if ($bundle-name eq 'all') then () else (cts:element-value-query(xs:QName('name'), $bundle-name,'exact')),
                                  cts:element-attribute-value-query(xs:QName('resources'), xs:QName('locale'), $from-locale,'exact'),
                                  cts:element-attribute-value-query(xs:QName('resources'), xs:QName('site'), $from-site,'exact')
                                  )) )
    let $create := if ($files) then
               for $file in $files
                  let $file-name := fn:concat($to-site,'-', $file/name/fn:string())
                  let $path := fn:concat($env,'cms/content/',$to-language-folder,'/resources/',$to-locale,'-',$file-name,'-resources.xml')
                  let $status := if (fn:contains($env, 'preview')) then 'preview' else 'publish'
                  let $newContent := element resources {attribute locale {$to-locale},
                                                        attribute status {$status},
                                                        attribute site {$to-site},
                                                        element ldse:ldse-meta {$file/ldse:ldse-meta/@*,
                                                                                element ldse:document {attribute id {$file-name},
                                                                                                        attribute locale {$to-locale},
                                                                                                        attribute status {$status},
                                                                                                        attribute title {$file-name},
                                                                                                        $file/ldse:ldse-meta/ldse:document/@* except ($file/ldse:ldse-meta/ldse:document/@id,
                                                                                                                                                   $file/ldse:ldse-meta/ldse:document/@locale,
                                                                                                                                                   $file/ldse:ldse-meta/ldse:document/@status,
                                                                                                                                                   $file/ldse:ldse-meta/ldse:document/@title),
                                                                                                        $file/ldse:ldse-meta/* except ($file/ldse:ldse-meta/ldse:document)}},
                                                         element locale {$to-locale},
                                                         $file/application,
                                                         $file/name,
                                                         $file/properties}
                  let $exist := cts:search(/resources,
                                 cts:and-query((
                                       cts:directory-query($env, 'infinity'),
                                       cts:element-value-query(xs:QName('name'), $file-name,'exact'),
                                       cts:element-attribute-value-query(xs:QName('resources'), xs:QName('locale'), $to-locale,'exact'),
                                       cts:element-attribute-value-query(xs:QName('resources'), xs:QName('site'), $to-site,'exact')
                                         )) )
                   return if ($exist) then $newContent ()
                          else xdmp:document-insert($path, $newContent)
            else ("Source file doesn't exits. ")
    return 'done'

};
