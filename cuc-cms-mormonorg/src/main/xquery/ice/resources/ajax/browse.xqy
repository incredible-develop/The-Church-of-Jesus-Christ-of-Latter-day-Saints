xquery version "1.0-ml";
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
     
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../../modules/utility-functions.xqy";
import module namespace ice = "http://lds.org/code/shared/lds-edit/iceFunction" at "../../modules/iceFunctions.xqy";

import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../../modules/ldse-core.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../../modules/access-control-functions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../../modules/ldse-settings.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace meta = "http://lds.org/schema/meta/base/v1";
declare option xdmp:mapping "true";

declare variable $sharedPrefix as xs:string? := $settings:shared-prefix;
declare variable $host as xs:string := $util:host;
declare variable $protocol as xs:string := util:get-protocol();
declare variable $cdnPath as xs:string := $settings:cdn-path;
declare variable $site as xs:string := $core:site;

declare variable $country as xs:string? := util:escape-chars(xdmp:get-request-field("country", ""));
declare variable $preLang as xs:string := util:escape-chars(xdmp:get-request-field("lang", "eng"));
declare variable $lang as xs:string := if ($country ne '') then (fn:concat($preLang,'-',$country)) else ($preLang);

declare variable $ckEditorFuncNum as xs:string? := xdmp:get-request-field("CKEditorFuncNum");
declare variable $type as xs:string? := xdmp:get-request-field("type");
declare variable $subtype as xs:string? := xdmp:get-request-field("subtype");
declare variable $term as xs:string? := xdmp:get-request-field("term");

declare variable $searchLocale as xs:string? := util:escape-chars(xdmp:get-request-field("searchLocale", $lang));

(: Variables when dialog was opened directly from the page and not through the WYSIWYG :)
declare variable $source as xs:string? := xdmp:get-request-field("source", "");
declare variable $teaserType as xs:string? := xdmp:get-request-field("teaserType","factbox");

declare variable $player as xs:string? := util:escape-chars(xdmp:get-request-field("player", ""));

declare variable $page as xs:string? := xdmp:get-request-field("page");
declare variable $currentPage as xs:string? := xdmp:get-request-field("currentPage", $page);
declare variable $pageLocation as xs:string? := xdmp:get-request-field("pageLocation","inline");

declare variable $vaildInlineTeasers as xs:string* := ('factbox');

declare variable $locales as xs:string* := core:get-all-locales();

declare variable $options as xs:string* := ("case-insensitive","whitespace-insensitive","unstemmed","punctuation-insensitive","diacritic-insensitive","wildcarded");
declare variable $wordOptions as xs:string* := (
    "case-insensitive","whitespace-insensitive","punctuation-insensitive",
    "diacritic-insensitive","wildcarded", fn:concat('lang=',$preLang) );

declare variable $parse as element()? := 
    search:parse(xdmp:get-request-field("term", ""),
                   <options xmlns="http://marklogic.com/appservices/search">
                       <term>{
                       for $option as xs:string in $wordOptions
                       return (
                           <term-option>{ $option }</term-option>
                       )
                       }</term>
                   </options>);
                   
declare variable $wordQuery as cts:query := cts:query($parse);

declare variable $files as element()* := 
    if ( fn:exists($term) ) then (
        if ($type eq "image" and $source eq 'media-library') then (
            cts:search(/ldswebml, 
                cts:and-query((
                    core:get-filter-query(),
                    cts:element-attribute-value-query(xs:QName('ldswebml'), xs:QName('type'), 'image', 'exact'),
                    cts:element-attribute-value-query(xs:QName('ldswebml'), xs:QName('locale'), $searchLocale, 'exact'),
                    cts:element-attribute-value-query(xs:QName('ldswebml'), xs:QName('uri'), '/media-library/images*', $options),
                    $wordQuery
                ))
            )
        ) else if ($type eq "image") then (
            cts:search(/image, 
                cts:and-query((
                    core:get-filter-query(),
                    $wordQuery
                ))
            )
        ) else if ($type eq "teaser" and $source eq 'wysiwyg') then (
            (: specific teaser type if the source is wysiwyg :)
            cts:search(/teaser,
                cts:and-query((
                    core:get-filter-query(),
                    cts:element-attribute-value-query(xs:QName('teaser'), xs:QName('type'), $vaildInlineTeasers, 'exact'),
                    cts:element-attribute-value-query(xs:QName('teaser'), xs:QName('locale'), $searchLocale, 'exact'),
                    $wordQuery
                ))
            )
        ) else if ($type eq "teaser") then (
            cts:search(/teaser, 
                cts:and-query((
                    core:get-filter-query(),
                    cts:element-attribute-value-query(xs:QName('teaser'), xs:QName('locale'), $searchLocale, 'exact'),
                    $wordQuery
                ))
            )
        ) else if ($type eq "video" and $source eq 'media-library') then (
            cts:search(/ldswebml, 
                cts:and-query((
                    core:get-filter-query(),
                    cts:element-attribute-value-query(xs:QName('ldswebml'), xs:QName('type'), 'video', 'exact'),
                    cts:element-attribute-value-query(xs:QName('ldswebml'), xs:QName('locale'), $searchLocale, 'exact'),
                    cts:element-attribute-value-query(xs:QName('ldswebml'), xs:QName('uri'), '/media-library/video*', $options),
                    $wordQuery
                ))
            )
        ) else if ($type eq "video") then (
            cts:search(/ldswebml, 
                cts:and-query((
                    core:get-filter-query(),
                    cts:element-attribute-value-query(xs:QName('ldswebml'), xs:QName('type'), 'video', 'exact'),
                    cts:element-attribute-value-query(xs:QName('ldswebml'), xs:QName('locale'), $searchLocale, 'exact'),
                    cts:element-value-query(xs:QName('path'), '*', $options),
                    $wordQuery
                ))
            )
        ) else if ($type eq "brightcove") then (
            cts:search(/ldswebml, 
                cts:and-query((
                    core:get-filter-query(),
                    cts:element-attribute-value-query(xs:QName('ldswebml'), xs:QName('type'), 'video', 'exact'),
                    cts:element-attribute-value-query(xs:QName('ldswebml'), xs:QName('locale'), $searchLocale, 'exact'),
                    cts:element-value-query(xs:QName('video-id'), '*', $options),
                    $wordQuery
                ))
            )
        ) else if ($type eq "gallery") then (
            cts:search(/ldswebml, 
                cts:and-query((
                    core:get-filter-query(),
                    cts:element-attribute-value-query(xs:QName('ldswebml'), xs:QName('type'), 'video', 'exact'),
                    cts:element-attribute-value-query(xs:QName('ldswebml'), xs:QName('locale'), $searchLocale, 'exact'),
                    cts:element-value-query(xs:QName('player'), 'gallery', 'exact'),
                    $wordQuery
                ))
            )
        ) else if ($type eq "audio" and $source eq 'media-library') then (
            cts:search(/ldswebml, 
                cts:and-query((
                    core:get-filter-query(),
                    cts:element-attribute-value-query(xs:QName('ldswebml'), xs:QName('type'), 'audio', 'exact'),
                    cts:element-attribute-value-query(xs:QName('ldswebml'), xs:QName('locale'), $searchLocale, 'exact'),
                    cts:element-attribute-value-query(xs:QName('ldswebml'), xs:QName('uri'), '/media-library/audio*', $options),
                    $wordQuery
                ))
            )
        ) else if ($type eq "audio") then (
            cts:search(/ldswebml[@type eq "audio"], 
                cts:and-query((
                    core:get-filter-query(),
                    cts:element-attribute-value-query(xs:QName('ldswebml'), xs:QName('type'), 'audio', 'exact'),
                    cts:element-attribute-value-query(xs:QName('ldswebml'), xs:QName('locale'), $searchLocale, 'exact'),
                    $wordQuery
                ))
            )
        ) else if ($type eq "collection") then (
            cts:search(/collection,
    			cts:and-query((
                    core:get-filter-query(),
    				$wordQuery,
    				if ( $subtype ne '') then (
    				    cts:element-attribute-value-query(xs:QName('collection'), xs:QName('type'), $subtype, 'exact')
    				) else (),
    				if ($source eq 'media-library') then (
    				    cts:element-value-query(xs:QName('meta:uri'), '/media-library/*', $options)
    				) else ()
    			))
			)
        ) else ()
    ) else ();

declare variable $results as item()* :=
    if ($type eq "image") then (
        for $file as element() in $files
        return
            if ($source eq "media-library") then (
                let $imgPath as xs:string? := $file/no-search/images/small
                let $src as xs:string? := if ($protocol eq "https") then (fn:replace($imgPath,'http://','https://')) else ($imgPath)
                let $title as xs:string? := $file/search-meta/title
                let $uri as xs:string? := xs:string($file/@uri)
                return (
                    <li>
                        <a href="#d" onclick="insertImageIntoList('{$uri}');window.close();">
                            <img src="{$src}" title="{$title}" border="0"/>
                        </a>
                    </li>
                )
            ) else (
                <li>
                    <a href="#d" onclick="selectImageUrl('{core:get-display-uri($file/default)}');window.close();">
                        <img src="{core:get-display-uri($file/default)}" title="{$file/altText}" border="0"/>
                    </a>
                </li>
            )
    ) else if ($type eq ("video", "audio")) then (
        for $file as element() at $count in $files
        let $id as xs:string? := $file/search-meta/source
        let $file-locale as xs:string := $file/@locale
        let $rowClass as xs:string := if ($count mod 2 eq 0) then ("even") else ("odd")
        return
            <tr class="{$rowClass}">
                <td class="titleCell">{if ( fn:exists($file/search-meta/title/node()) ) then ($file/search-meta/title/node()) else ("&nbsp;")}</td>
                <td class="typeCell">{if ( $file/no-search/length ne '' ) then ($file/no-search/length) else ("&nbsp;")}</td>
                <td class="pageCell">{if ( $file/no-search/path ne '' ) then ($file/no-search/path) else ($file/no-search/path-secondary)}</td>
                <td class="viewMoreCell"><a href="#d" onclick="window.resizeTo(1024,768); moreInfo('{$id}', '{$file-locale}', '{$type}');">View Xml</a></td>
                <td class="selectButtonCell">
                {
                    if ($source eq "wysiwyg") then (
                        <input type="button" value="Select" onclick="insertTeaserTag('{$type}','{$id}','{$currentPage}','{$lang}');"/>
                    ) else if ($source eq "media-library" and $type eq "video") then (
                        <input type="button" value="Select" onclick="insertVideoIntoList('{$file/search-meta/uri-title/node()}');"/>
                    ) else if ($source eq "media-library" and $type eq "audio") then (
                        <input type="button" value="Select" onclick="insertAudioIntoList('{xs:string($file/search-meta/uri-title)}');"/>
                    ) else (
                        <input type="button" value="Select" onclick="selectTeaser('{$teaserType}', '{$id}', '{$page}', '{$currentPage}', '{$pageLocation}', '{$lang}');window.opener.location.reload();alert('You may need to refresh the page for the changes to occur.');window.close();"/>
                    )
                }
                </td>
            </tr>
    ) else if ($type eq "brightcove" and $source eq "wysiwyg") then (
        for $file as element() at $count in $files
        let $id as xs:string? := $file/search-meta/source
        let $file-locale as xs:string := $file/@locale
        let $rowClass as xs:string := if ($count mod 2 eq 0) then ("even") else ("odd")
        return
            <tr class="{$rowClass}">
                <td class="titleCell">{if ( fn:exists($file/search-meta/title/node()) ) then ($file/search-meta/title/node()) else ("&nbsp;")}</td>
                <td class="typeCell">{if ( $file/no-search/length ne '') then ($file/no-search/length) else ("&nbsp;")}</td>
                <td class="pageCell">{if ( $file/no-search/video-id ne '') then (xs:string($file/no-search/video-id)) else ("&nbsp;")}</td>
                <td class="viewMoreCell"><a href="#d" onclick="window.resizeTo(1024,768); moreInfo('{$id}', '{$file-locale}', '{$type}');">View Xml</a></td>
                <td class="selectButtonCell">
                    <input type="button" value="Select" onclick="insertTeaserTag('{$type}','{$id}','{$currentPage}','{$lang}');"/>
                </td>
            </tr>
    ) else if ($type eq "gallery" and $source eq "wysiwyg") then (
        for $file as element() at $count in $files
        let $id as xs:string? := $file/search-meta/source
        let $file-locale as xs:string := $file/@locale
        let $rowClass as xs:string := if ($count mod 2 eq 0) then ("even") else ("odd")
        return
            <tr class="{$rowClass}">
                <td class="titleCell">{if ( fn:exists($file/search-meta/title/node()) ) then ($file/search-meta/title/node()) else ("&nbsp;")}</td>
                <td class="typeCell">{if ($file/no-search/length ne '') then (xs:string($file/no-search/length)) else ("&nbsp;")}</td>
                <td class="pageCell">{if ($file/no-search/player-id ne '') then (xs:string($file/no-search/player-id)) else ("&nbsp;")}</td>
                <td class="viewMoreCell"><a href="#d" onclick="window.resizeTo(1024,768); moreInfo('{$id}', '{$file-locale}', '{$type}');">View Xml</a></td>
                <td class="selectButtonCell">
                    <input type="button" value="Select" onclick="insertTeaserTag('{$type}','{$id}','{$currentPage}','{$lang}');"/>
                </td>
            </tr>
    ) else if ($type eq "teaser") then (
        for $file as element() at $count in $files
        let $id as xs:string? := fn:data($file/@id)
        let $file-locale as xs:string := $file/@locale
        let $rowClass as xs:string := if ($count mod 2 eq 0) then ("even") else ("odd")
        return
            <tr class="{$rowClass}">
                <td class="titleCell">{if ( fn:exists($file/title/node()) ) then ($file/title/node()) else ("&nbsp;")}</td>
                <td class="typeCell">{if ( $file/@type ne '') then (fn:data($file/@type)) else ("&nbsp;")}</td>
                <td class="pageCell">{if ($file/@page ne '') then (fn:data($file/@page)) else ("&nbsp;")}</td>
                <td class="viewMoreCell"><a href="#d" onclick="window.resizeTo(1024,768); moreInfo('{fn:data($file/@id)}', '{$file-locale}', '{$type}');">View Xml</a></td>
                <td class="selectButtonCell">
                {
                    if ($source eq "wysiwyg") then (
                        <input type="button" value="Select" onclick="insertTeaserTag('{$type}','{$id}','{$currentPage}','{$lang}');"/>
                    ) else (
                        <input type="button" value="Select" onclick="selectTeaser('{$teaserType}', '{$id}', '{$page}', '{$currentPage}', '{$pageLocation}', '{$lang}'); return false;"/>
                    )
                }
                </td>
            </tr>
    ) else if ($type eq "collection") then (
		 for $file as element() in $files
         let $imgPath as xs:string? := $file/images/small
         let $src as xs:string? := if ($protocol eq "https") then (fn:replace($imgPath,'http://','https://')) else ($imgPath)
         let $title as xs:string? := $file/meta:meta/meta:title
         let $uri as xs:string? := $file/meta:meta/meta:uri
         return (
             <li>
                 <a href="#d" onclick="insertImageIntoList('{$uri}');window.close();">
					 <span class="titleCell">{$title}</span>
                     <img src="{$src}" title="{$title}" border="0"/>
                 </a>
             </li>
         )
    ) else ();
    

xdmp:set-response-content-type( "text/html" ),
'<!DOCTYPE html>',
<html xml:lang="en" lang="en">
    <head xmlns="http://www.w3.org/1999/xhtml">
        <title>Content Browser</title>
        <link rel="stylesheet" type="text/css" media="screen" href="{$sharedPrefix}/ice/resources/styles/browse.css" />
        <link rel="stylesheet" type="text/css" media="screen" href="{$sharedPrefix}/ice/resources/styles/incontext.css" />
        <link rel="stylesheet" type="text/css" media="screen" href="{$sharedPrefix}/resources/css/ldspublisher-ice.css" />
        <link rel="stylesheet" type="text/css" href="{$settings:shared-prefix}/ice/resources/styles/binaryManager.css" />
        <script type="text/javascript" src="{$cdnPath}/scripts/jquery/1.7.1/jquery.min.js">&nbsp;</script>
        <script type="text/javascript" src="{$cdnPath}/ml/platform/scripts/platform-utilities.js">&nbsp;</script>
        <script type="text/javascript" src="{$cdnPath}/scripts/jquery/plugins/query/jquery.query-2.1.7.js">&nbsp;</script>
        { ice:get-ice-script() }
        <script type="text/javascript" src="{$sharedPrefix}/ice/resources/script/browse.js">&nbsp;</script>
    </head>

    <body>
        <div id="medialibrary" class="browse">
            <div class="filters">
                <form action="{$sharedPrefix}/ice/resources/ajax/browse" method="GET">
                    <input type="hidden" name="lang" value="{$preLang}"/>
                    <input type="hidden" name="country" value="{$country}"/>
                    <input type="hidden" name="type" value="{$type}"/>

                    {if ($source ne '') then (<input type="hidden" name="source" value="{$source}"/>) else ()}
                    {
                        if ($type eq ("teaser", "video", "audio")) then (
                            <input type="hidden" name="currentPage" value="{$currentPage}"/>,
                            <input type="hidden" name="teaserType" value="{if (fn:empty($teaserType)) then ('factbox') else ($teaserType)}"/>,
                            <input type="hidden" name="pageLocation" value="{$pageLocation}"/>
                        ) else ()
                    }
                    <input type="hidden" name="CKEditor" value="{xdmp:get-request-field('CKEditor', '')}"/>
                    <input type="hidden" name="CKEditorFuncNum" value="{$ckEditorFuncNum}"/>
                    
                    <input type="text" name="term" class="quicksearch" value="{$term}"/>
                    <br/><br/>
                    <input type="submit" value="Search" class="button secondary"/>
                    <p>{fn:count($files)} Matches</p>
                    <br/>
                    <br/>
                    {
                        if ($type eq "teaser") then (
                            let $form as xs:string? := ice:getPluginForm('inlineteaser')
                            let $options as xs:string := fn:concat('form:', $form, ',ajax:true,location:', $pageLocation)
                            where $form ne ''
                            return (
                                <input type="button" value="Create New" onClick="window.resizeTo(1024,768); ICE.openForm('{$lang}', '', 'add', '{$form}', '{$currentPage}', '{$currentPage}', '{$options}'); ajaxForm(); return false;" class="button secondary"/>
                            )
                            ,<br/>
                            ,<br/>
                            ,<div>Locale:</div>
                            ,<select name="searchLocale">{
                                if (fn:count($locales) > 0)
                                then (
                                    for $locale as xs:string in $locales
                                    let $name as xs:string := $locale
                                    order by $locale
                                    return if ($locale eq $searchLocale) 
                                         then (<option value="{$locale}" SELECTED="true">{$name}</option>)
                                         else (<option value="{$locale}">{$name}</option>)
                                ) else (<option>(None)</option>)
                            }</select>
                        ) else if ($type eq "video") then (
                            <select name="searchLocale">{
                                if (fn:count($locales) > 0)
                                then (
                                    for $locale as xs:string in $locales
                                    let $name as xs:string := $locale
                                    order by $locale
                                    return if ($locale eq $searchLocale) 
                                         then (<option value="{$locale}" SELECTED="true">{$name}</option>)
                                         else (<option value="{$locale}">{$name}</option>)
                                ) else (<option>(None)</option>)
                            }</select>,
                            <input type="button" value="Create New" onclick="window.resizeTo(980,700); videoForm('{core:get-mode-root()}', '{$lang}', '{$currentPage}', '', '{$source}', 'video', 'universal');" class="button secondary"/>
                        ) else if ($type eq "brightcove") then (
                            <select name="searchLocale">{
                                if (fn:count($locales) > 0)
                                then (
                                    for $locale as xs:string in $locales
                                    let $name as xs:string := $locale
                                    order by $locale
                                    return if ($locale eq $searchLocale) 
                                         then (<option value="{$locale}" SELECTED="true">{$name}</option>)
                                         else (<option value="{$locale}">{$name}</option>)
                                ) else (<option>(None)</option>)
                            }</select>,
                            let $form as xs:string? := ice:getPluginForm('brightcove')
                            let $options as xs:string := fn:concat('form:', $form, ',ajax:true,location:', $pageLocation)
                            where $form ne ''
                            return (
                                <input type="button" value="Create New" onClick="window.resizeTo(1024,768); ICE.openForm('{$lang}', '', 'add', '{$form}', '{$currentPage}', '{$currentPage}', '{$options}'); ajaxForm(); return false;" class="button secondary"/>
                            )
                        ) else if ($type eq "gallery") then (
                            <select name="searchLocale">{
                                if (fn:count($locales) > 0)
                                then (
                                    for $locale as xs:string in $locales
                                    let $name as xs:string := $locale
                                    order by $locale
                                    return if ($locale eq $searchLocale) 
                                         then (<option value="{$locale}" SELECTED="true">{$name}</option>)
                                         else (<option value="{$locale}">{$name}</option>)
                                ) else (<option>(None)</option>)
                            }</select>,
                            let $form as xs:string? := ice:getPluginForm('gallery')
                            let $options as xs:string := fn:concat('form:', $form, ',ajax:true,location:', $pageLocation)
                            where $form ne ''
                            return (
                                <input type="button" value="Create New" onClick="window.resizeTo(1024,768); ICE.openForm('{$lang}', '', 'add', '{$form}', '{$currentPage}', '{$currentPage}', '{$options}'); ajaxForm(); return false;" class="button secondary"/>
                            )
                        ) else if ($type eq ("image","audio") and $source eq 'lds-media') then (
                            <select name="searchLocale">{
                                if (fn:count($locales) > 0)
                                then (
                                    for $locale as xs:string in $locales
                                    let $name as xs:string := $locale
                                    order by $locale
                                    return if ($locale eq $searchLocale) 
                                         then (<option value="{$locale}" SELECTED="true">{$name}</option>)
                                         else (<option value="{$locale}">{$name}</option>)
                                ) else (<option>(None)</option>)
                            }</select>
                        ) else if ($type eq "audio" and $source ne 'lds-media') then (
                            <input type="button" value="Create New" onclick="window.resizeTo(980,700); audioForm('{core:get-mode-root()}', '{$lang}', '{$currentPage}', '', '{$source}');" class="button secondary"/>
                        ) else ()
                    }
                </form>
            </div>
            {
            if ($type eq "teaser") then (
            <div id="teaserList">
                <table>
                    <tr class="tableHead">
                        <th class="titleCell">Title</th>
                        <th class="typeCell">Type</th>
                        <th class="pageCell">Page</th>
                        <th class="viewMoreCell">More</th>
                        <th class="selectButtonCell">Select</th>
                    </tr>
                    {$results}
                 </table>
            </div>
            ) else if ($type eq "video") then (
                <div id="teaserList">
                    <table>
                        <tr class="tableHead">
                            <th class="titleCell">Title</th>
                            <th class="typeCell">Length</th>
                            <th class="pageCell">Video Path</th>
                            <th class="viewMoreCell">More</th>
                            <th class="selectButtonCell">Select</th>
                        </tr>
                        {$results}
                     </table>
                </div>
            ) else if ($type eq "brightcove") then (
                <div id="teaserList">
                    <table>
                        <tr class="tableHead">
                            <th class="titleCell">Title</th>
                            <th class="typeCell">Length</th>
                            <th class="pageCell">Video ID</th>
                            <th class="viewMoreCell">More</th>
                            <th class="selectButtonCell">Select</th>
                        </tr>
                        {$results}
                     </table>
                </div>
            ) else if ($type eq "gallery") then (
                <div id="teaserList">
                    <table>
                        <tr class="tableHead">
                            <th class="titleCell">Title</th>
                            <th class="typeCell">Length</th>
                            <th class="pageCell">Player ID</th>
                            <th class="viewMoreCell">More</th>
                            <th class="selectButtonCell">Select</th>
                        </tr>
                        {$results}
                     </table>
                </div>
            ) else if ($type eq "audio") then (
                <div id="teaserList">
                    <table>
                        <tr class="tableHead">
                            <th class="titleCell">Title</th>
                            <th class="typeCell">Length</th>
                            <th class="pageCell">Audio Path</th>
                            <th class="viewMoreCell">More</th>
                            <th class="selectButtonCell">Select</th>
                        </tr>
                        {$results}
                     </table>
                </div>
            ) else (
                <ul class="imagesort" id="librarymedia">{$results}</ul>
            )
            }
        </div>
    </body>
</html>
