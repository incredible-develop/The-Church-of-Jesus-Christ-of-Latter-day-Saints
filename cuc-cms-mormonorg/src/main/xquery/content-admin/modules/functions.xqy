xquery version "1.0-ml";

module namespace af = "http://lds.org/code/lds-edit/content-admin/admin-functions";

import module namespace c = "http://lds.org/code/shared/common/common-functions" at "/shared/common/commonFunctions.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "/modules/utility-functions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "/modules/ldse-core.xqy";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace dynamicForms = "http://lds.org/code/shared/lds-edit/dynamicForms" at "/ice/modules/dynamicForms.xqy";
import module namespace ice = "http://lds.org/code/shared/lds-edit/iceFunction" at "/ice/modules/iceFunctions.xqy";
import module namespace images = "http://lds.org/code/seminary-and-institute/imageFunctions" at "imageFunctions.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "/modules/ldse-meta.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "/modules/ldse-settings.xqy";
import module namespace cf = "http://lds.org/code/lds-edit/content-admin/content-functions" at "/content-admin/modules/content-functions.xqy";
import module namespace mem = "http://lds.org/code/shared/common/memory-update" at "/shared/common/util/inMemoryUpdate.xqy";
import module namespace document = "http://lds.org/code/shared/lds-edit/document-functions" at "/modules/document-functions.xqy";
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";
import module namespace sp = "http://lds.org/code/modules/site-properties" at '/modules/site-properties.xqy';
import module namespace tf = 'http://lds.org/code/modules/titan-functions' at '/modules/titan-functions.xqy';
import module namespace security = "http://lds.org/code/shared/common/security/security-functions" at "/shared/common/security/securityFunctions.xqy";
import module namespace api = "http://lds.org/code/transforms/modules/api-functions" at "/transforms/modules/api-functions.xqy";
import module namespace library = "http://lds.org/code/shared/lds-edit/supported-languages" at "/supported-languages/modules/library.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";

declare variable $HOST as xs:string := c:getHost();
declare variable $FORMS := cts:search(/ldse:formTemplate, cts:and-query(()));

declare variable $lang as xs:string := ( util:escape-chars(xdmp:get-request-field("lang")[1])[. != ""], 'eng' )[1];
declare variable $clang as xs:string := util:escape-chars(xdmp:get-request-field("clang", $lang)[1]);
declare variable $sel-temp as xs:string? := util:escape-chars(xdmp:get-request-field('template'))[. != ""];
declare variable $template-id as xs:string? := util:escape-chars(xdmp:get-request-field('id'))[. != ""];
declare variable $site as xs:string? := ( util:escape-chars(xdmp:get-request-field('site'))[. != ""], $af:sites[1] )[1];
declare variable $admin-prefix as xs:string := $settings:shared-prefix || "/content-admin";
declare variable $page as xs:string := $settings:shared-prefix || '/content';
declare variable $searchTypes as xs:string := c:escapeChars(xdmp:get-request-field("type", ""));
declare variable $term as xs:string := xdmp:get-request-field("term", "");
declare variable $sortDirection as xs:string := c:escapeChars(xdmp:get-request-field("sort-dir", "descending"));
declare variable $sortType as xs:string := c:escapeChars(xdmp:get-request-field("sort-type", "date"));
declare variable $componentSearch as xs:string? := c:escapeChars(xdmp:get-request-field("component-search", "all"));
declare variable $languageSearch as xs:string? := c:escapeChars(xdmp:get-request-field("language-search", ""));
declare variable $sortAuthor as xs:string := c:escapeChars(xdmp:get-request-field("sort-author", "all"));
declare variable $pageSize as xs:int := xs:int(($core:siteProperties/admin-pages/search/page-size[. castable as xs:int], 50)[1]);
declare variable $currentPage as xs:int := xs:int((xdmp:get-request-field("page")[. castable as xs:int], 1)[1]);
declare variable $start as xs:int := ($pageSize * ($currentPage - 1)) + 1;
declare variable $sites as xs:string* := $sp:all-sites;
declare variable $site-properties as element(siteProperties)? := sp:get-site-properties($site);
declare variable $site-pages as element(page)* := $site-properties/admin-pages/nav/section/page;
declare variable $username as xs:string := ac:getUserName();
declare variable $locale as xs:string := ( util:escape-chars(xdmp:get-request-field("locale")[1])[. != ""], 'eng' )[1];
declare variable $ldse-settings as element(ldse:ldse-settings) := $core:ldse-settings;
declare variable $host-header as xs:string? := fn:lower-case(xdmp:get-request-header("host"));
declare variable $isDevOpCMS as xs:boolean :=
    if (starts-with($host-header, 'cuc-') or
        starts-with($host-header, 'msadm-') ) then
        fn:true()
    else fn:false();
declare function af:buildAdminPageLinks() as element()* {
    let $navSections as element(section)* := $site-properties/admin-pages/nav/section
    let $langsSelector := if (($site-properties/admin-pages/languages/enable[. eq 'true']/xs:boolean(.), fn:false())[1]) then (af:buildLanguageSelector()) else ()
    let $siteSelector := af:buildSiteSelector()
    let $id as xs:string := xdmp:get-request-field('id', '')
    let $currentPage as xs:string := xdmp:get-request-path()
    let $option-selected as element(option)? := $siteSelector//option[@selected]
    let $site-selected as xs:string? := fn:tokenize($option-selected/@value, '&amp;site=')[2]
    let $siteParam as xs:string := if ( c:stringNotEmpty($site) or $site-selected ) then ( '&amp;site=' || ( $site, $site-selected )[1] ) else ( '' )
    return (
        <nav class="filter-nav">{
            <form class="ldse-form">{
                $siteSelector,
                $langsSelector
            }</form>,
            <hr/>,
            for $section as element(section) at $pos in $navSections
            where fn:exists($section/page) and ( fn:contains($section/@site, $site) or $section/@site = 'all' or fn:empty($section/@site) )
            return (
                <h3 class="nav-header ldse-icon-tri-up" onclick="collapseHeaders(this)" id="{ 'section-' || $pos }">{$section/@label/xs:string(.)}</h3>,
                <hr/>,
                <div class="{ 'section-' || $pos }">{ af:get-page-sections($section, $siteParam, $id) }</div>
            ),
            <h3 class="nav-header ldse-icon-tri-up" onclick="collapseHeaders(this)" id="internal-links">Internal Links</h3>,
            <hr/>,
            <div class="internal-links">
                <a href="{ c:buildFullUrl($HOST, $settings:shared-prefix || '/string-manager', $lang, $clang, $siteParam) }"><h4 class="nav-header">String Manager</h4></a>
                <a href="{ c:buildFullUrl($HOST, $settings:shared-prefix || '/flexible-fields-manager',$lang, $clang, $siteParam) }"><h4 class="nav-header">Flexible Fields</h4></a>
                <a href="{ c:buildFullUrl($HOST, $settings:shared-prefix || '/titan-id-update', $lang, $clang, $siteParam) }"><h4 class="nav-header">Titan Image Update</h4></a>
                <a href="{ c:buildFullUrl($HOST, $settings:shared-prefix || '/titan-image-usage-search', $lang, $clang, $siteParam) }"><h4 class="nav-header">Titan Image Usage Search</h4></a>
                <a href="{ c:buildFullUrl($HOST, $settings:shared-prefix, $lang, $clang, $siteParam) }"><h4 class="nav-header">Publisher Home</h4></a>
                <a href="{ c:buildFullUrl($HOST, $settings:shared-prefix || '/content-admin/publishing', $lang, $clang, $siteParam) }"><h4 class="nav-header">Bulk Publishing</h4></a>
                {
                    if ( ac:has-permission('ldse:view-xml', '', '') ) then (
                        <a href="{ c:buildFullUrl($HOST, $settings:shared-prefix || '/content-admin', $lang, $clang, '&amp;id=site-creation' || $siteParam || '&amp;type=site' ) }"><h4 class="nav-header">Sites</h4></a>
                    ) else ()
                }
            </div>,
            <div>
                {
                    if ( ac:has-permission('ldse:edit-doc', '', '') ) then (
                        <h3 class="nav-header ldse-icon-tri-up" onclick="collapseHeaders(this)" id="cloning">Cloning</h3>,
                        <hr/>,
                        <div class="cloning">
                            <a href="{c:buildFullUrl($HOST, $settings:shared-prefix || '/ice/resources/ajax/clone-page/clone-multiple-pages', $lang, $clang, $siteParam)}"><h4 class="nav-header">Clone Resources and Pages</h4></a>
                            <a href="{c:buildFullUrl($HOST, $settings:shared-prefix || '/ice/resources/ajax/clone-page/clone-components', $lang, $clang, $siteParam)}"><h4 class="nav-header">Clone Components</h4></a>
                        </div>
                    )
                    else ()
                }
            </div>,
            <div>
                {
                   if ( ac:has-permission('ldse:view-reports-admin', '', '') ) then (
                        <h3 class="nav-header ldse-icon-tri-up" onclick="collapseHeaders(this)" id="reports">Reports</h3>,
                        <hr/>,
                        <div class="reports">
                            <a href="{c:buildFullUrl($HOST, $settings:shared-prefix || '/reports/page-status-report', $lang, $clang, $siteParam)}"><h4 class="nav-header">Page Status Report</h4></a>
                            <a href="{c:buildFullUrl($HOST, $settings:shared-prefix || '/reports/site-inventory-report', $lang, $clang, $siteParam)}"><h4 class="nav-header">Site Inventory Report MVP</h4></a>
                        </div>
                   )
                   else ()
                }
            </div>
        }</nav>
    )
};

declare function af:get-page-sections(
    $section as element(section),
    $siteParam as xs:string,
    $id as xs:string
) as element(a)* {
    for $page as element(page) in $section/page
    let $showPage as xs:boolean :=
        let $applicableSites := fn:tokenize($page/@site/xs:string(.), '\s*,\s*')
        return (
            $site = $applicableSites or $applicableSites = 'all' or fn:empty($applicableSites)
        )
    let $type as xs:string? := $page/@type
    let $typeParam as xs:string :=
        if ( fn:exists($type) and fn:not($type = "") ) then (
            '&amp;type=' || $type
        ) else ( '' )
    let $pub-type as xs:string :=
        if ( fn:exists($page/@pub-type) and fn:not($page/@pub-type = "") ) then (
            '&amp;pub-type=' || $page/@pub-type/xs:string(.)
        ) else ( '' )
    let $uri as xs:string? :=
        if ( $page/@only-one = 'true' and $showPage ) then (
            let $file as element()? := cf:get-custom-page-by-template-and-site($page/@template, $site)
            where fn:exists($file)
            return (
                "&amp;uri=" || ( $file/@uri/xs:string(.), ldsemeta:get-document-uri($file) )[1]
            )
         ) else ()
    let $meet-restriction as xs:boolean := af:checkTemplateRestriction($site, $page/@id/fn:string())
    where ac:has-permission("ldse:edit-doc", $lang, '', $site) and $meet-restriction
    return (
        let $href as xs:string :=
            if ( fn:contains($page/@href, '//') ) then (
                $page/@href
            ) else if (fn:exists($page/@href)) then (
                c:buildFullUrl($HOST, $settings:shared-prefix || $page/@href/xs:string(.), $lang, $clang, $siteParam)
            ) else if ($page/@template[. != 'false']) then (
                c:buildFullUrl($HOST, $settings:shared-prefix || '/content-admin', $lang, $clang, '&amp;id=' || $page/@id/xs:string(.) || $siteParam || $uri || $typeParam || $pub-type)
            ) else (
                c:buildFullUrl($HOST, $settings:shared-prefix || '/content-admin', $lang, $clang, '&amp;id=' || $page/@id/xs:string(.) || $siteParam || $uri || $typeParam || $pub-type)
            )

        let $isId as xs:boolean := $page/@id/xs:string(.) eq $id
        let $activeClass as xs:string? := if ( $isId ) then ( 'active' ) else ()
        let $test-id := fn:concat('template-',$id)
        return (
            if ( $showPage ) then (
                element a {
                    attribute href {$href},
                    if($id) then attribute data-testid {
                      $test-id
                    } else (),
                    element h4 {
                        attribute class {
                            fn:string-join(('nav-header', $activeClass), ' ')
                        },
                        $page/node()
                    }
                }
            ) else ()
        )
    )
};

declare function af:checkTemplateRestriction(
    $site as xs:string,
    $template-id as xs:string?
) as xs:boolean {
    let $restrictedList as element()* :=
        cts:search(/sub-site,
            cts:and-query((
                core:get-filter-query(),
                cts:element-value-query(xs:QName('ldse:site-context'), $site, 'exact')
            ))
        )/templates/template[type eq $template-id]/allow-access/username
    let $result as xs:boolean :=
        if ( $restrictedList ) then (
            let $match :=
                for $i in $restrictedList
                where fn:lower-case($i) eq fn:lower-case($username)
                return $i
            return (
                if ( $match ) then (
                    fn:true()
                ) else ( fn:false() )
            )
        ) else ( fn:true() )
    return (
        ( $result, fn:true() )[1]
    )
};

declare function af:buildSiteSelector() as element()* {
    let $uri as xs:string := $settings:shared-prefix || "/content-admin"
    let $currentSite as xs:string? := $site
    let $id as xs:string? := xdmp:get-request-field('id', '')
    let $id as xs:string? := if ($id) then ('&amp;id=' || $id) else ()
    let $emptySiteOption as element(option)? := if (c:stringIsEmpty($currentSite)) then (element option {}) else ()
    return (
        element div {
            attribute class {'nav-select'},
            element select {
                attribute onchange {'document.location.href = this.value'},
                attribute name {'sites'},
                attribute class {'select'},
                $emptySiteOption,
                for $i as xs:string in $sites
                let $is-supported-lang as xs:boolean := library:is-supported-language($i, $lang)
                let $use-this-lang as xs:string? := library:get-a-permitted-supported-languages-by-site($i, $lang)
                where fn:exists($sites) and ac:has-permission("ldse:edit-doc", $use-this-lang, '', $i)
                order by $i ascending
                return (
                        element option {
                            attribute value {c:buildFullUrl($HOST, $uri, $use-this-lang, $use-this-lang, '&amp;site=' || $i)},
                            attribute datatest-id {$i},
                            if ($i eq $currentSite) then (attribute selected {'selected'}) else (),
                            $i
                            }
                        )
            }
        }
    )
};

declare function af:buildLanguageSelector() as element()* {
    let $langs as xs:string* := af:getLangs()
    let $uri as xs:string := $settings:shared-prefix || xdmp:get-request-path()
    let $site as xs:string? := $site
    let $id as xs:string? := xdmp:get-request-field('id', '')
    let $id as xs:string? := if ($id) then ('&amp;id=' || $id) else ()
    let $siteParam as xs:string? := if (fn:exists($site)) then ('&amp;site=' || $site) else ()
    return (
        element div {
            attribute class {'nav-select'},
            element select {
                attribute onchange {'document.location.href = this.value'},
                attribute name {'languages'},
                attribute class {'select'},
                for $i as xs:string in $langs
                let $name as xs:string? := af:getEnglishName($i)
                where ac:has-permission("ldse:edit-doc", $i, '', $site)
                order by $name ascending
                return (
                    element option {
                        attribute value {c:buildFullUrl($HOST, $uri, $i, (), $id || $siteParam)},
                        attribute datatest-id {$i},
                        if ($i eq $lang) then ( attribute selected {'selected'}) else (),
                        $name
                    }
                )
            }
        }
    )
};

declare private function af:getLangs() as xs:string* {
    core:get-all-locales()
};

declare private function af:getEnglishName(
    $langKey as xs:string
) as xs:string* {
    util:get-full-language-name-by-locale($langKey)
};

declare function af:buildNodes(
    $lang as xs:string,
    $page as xs:string?,
    $nodes as element()*,
    $nodeSrcs as element()*,
    $header as xs:string?,
    $nodeName as xs:string,
    $formName as xs:string,
    $formVars as xs:string*,
    $onlyOne as xs:boolean,
    $is-fixed as xs:boolean,
    $page-grouping as xs:string?,
    $template as xs:string?,
    $parent-id as xs:string?,
    $render as xs:string?
) as element()+ {
    let $ice-link as element(a)? := af:renderICE($lang, (), $nodeName, $page, (), $formName, $onlyOne, $formVars, ())//a[fn:contains(@class, "ldse-icon-ko-add")]

    let $href as attribute()? :=
        if ( fn:exists($parent-id) ) then (
            attribute href { $ice-link/@href || '&amp;wrapper-id=' || $parent-id }
        ) else ( attribute href { $ice-link/@href/xs:string(.) } )
    return (
        element div {
            if ( fn:not($formName = 'pageBuilder') and fn:not($is-fixed) ) then (
                attribute class { 'content-grouping' },
                attribute data-id { $nodes[1]/@id }
            ) else (
                attribute class { 'page-grouping' },
                attribute data-id { $nodes[1]/@id }
            ),
            <h2 class="node-title">{$header, if (fn:not($onlyOne) or ($onlyOne and fn:empty($nodes))) then (
                <a type="button" class="actionButton primaryButton ldse-responsive">{ $ice-link/@* except $ice-link/(@class|@href), $href }
                    <span class="ldse-secondary ldse-icon-ko-add"></span>
                </a>) else ()}
            </h2>,
            if ( fn:exists($nodes) ) then (
                element ul {
                    attribute class { "nodeContainer" },
                    attribute id { "container-for-content" },
                    if (fn:not($onlyOne) or ($onlyOne and fn:empty($nodes))) then (
                    ) else (),
                    if ( fn:exists($template) ) then (
                        af:nonPageTemplate($nodes, ())
                    ) else if (fn:not($onlyOne) or ($onlyOne and fn:exists($nodes))) then (
                        af:renderNodes($lang, $nodes, $nodeSrcs, $nodeName, $formVars, $render, $parent-id)
                    ) else ()
                }
            ) else ()
        }
    )
};

declare function af:renderICE(
    $lang as xs:string,
    $teaser as element()?,
    $type as xs:string,
    $page as xs:string?,
    $location as xs:string?,
    $formName as xs:string,
    $onlyOne as xs:boolean,
    $vars as xs:string*,
    $links as element(link)*
) as item()* {
    ice:add-ice($lang, $type, $teaser, ( $page, '' )[1],
        <options>
            <variables>
                <form>{$formName}</form>
                {
                    if ( $location ) then ( <location>{$location}</location> ) else (),
                    if ( fn:exists($vars) ) then (
                        for $var as xs:string in $vars
                        return (
                            element { xs:QName(fn:substring-before($var, ':')) } { fn:substring-after($var, ':') }
                        )
                    ) else ()
                }
            </variables>
            <site-folder>{ $site }</site-folder>
            <settings> {
                if ($onlyOne) then (
                    <only-one>true</only-one>
                ) else ()
            }</settings>
            {
                if (fn:exists($links)) then (
                    <links>{
                        $links
                    }</links>
                ) else ()
            }
        </options>
    )
};

declare function af:renderNodes(
    $lang as xs:string,
    $items as element()*,
    $itemSrcs as element()*,
    $contentTitle as xs:string?,
    $iceVars as xs:string*,
    $render as xs:string?,
    $parent-id as xs:string?
) as element()* {
    af:renderNodes($lang, $items, $itemSrcs, $contentTitle, $iceVars, $render, $parent-id, ())
};

declare function af:renderNodes(
    $lang as xs:string,
    $items as element()*,
    $itemSrcs as element()*,
    $contentTitle as xs:string?,
    $iceVars as xs:string*,
    $render as xs:string?,
    $parent-id as xs:string?,
    $ref-parent-id as xs:string?
) as element()* {
    for $item as element() in $items
    let $formName as xs:string? := ( $item/ldse:ldse-meta/ldse:form-options/ldse:form, $item/form-options/form )[1]
    let $form as element(ldse:formTemplate)? := ($FORMS[@name eq $formName])[1]
    let $item as element() :=
        if ( fn:exists($itemSrcs) ) then (
            let $docId as xs:string? := dynamicForms:dynamicXpath($item, $form/ldse:id-xpath/xs:string(.))
            return (
                if (fn:exists($docId)) then (
                    let $srcItem := ldsemeta:get-file-by-id($docId)
                    return (
                        ($srcItem, $item)[1]/node()
                    )
                ) else ($item)
            )
        ) else ( $item )
    let $title as xs:string? := ( dynamicForms:dynamicXpath($item, $form/ldse:title-xpath), '' )[1]
    let $contentTitle as xs:string? := ( $contentTitle[. != ''], $item/@type, $formName )[1]
    let $uri as xs:string? := ldsemeta:get-document-uri($item)
    let $imgSrc as xs:string? :=
        let $path as xs:string? := dynamicForms:dynamicXpath($item, $form/ldse:image-xpath)[. != '']
        let $image-node as node()? := ( util:unpath($item, $form/ldse:image-xpath) )[1]
        let $path as xs:string? :=
            if ( fn:exists($path) ) then (
                $path
            ) else ( dynamicForms:dynamicXpath($item, $form/ldse:second-image-xpath) )
        let $i-path as xs:string? := fn:substring-after($path, fn:concat($settings:shared-prefix, '/bc'))
        let $folder as xs:string := util:substring-before-last(util:substring-before-last($i-path, '/'), '/')
        let $binary-content as element(binary-content)? := cf:get-binary-content($i-path)
        let $binary-content as element(binary-content)? :=
            if ( fn:exists($binary-content) ) then (
                $binary-content
            ) else (
                cf:get-binary-content-by-folder($folder)
            )
        let $crops as element(crop)* := $binary-content/crop
        let $sizes as element(resize)* := $crops/resize
        let $thumb as element(resize)? := ($sizes[@width = '300' and ( @height = '150' or @height = '300' )])[1]
        let $path as xs:string? :=
            if ( fn:exists($thumb) ) then (
                fn:string-join(($folder, functx:substring-after-last($path, '/')), '/300x150/')
            ) else ( $path )
        let $img := core:get-display-uri($path)

        return (
            if ( c:stringNotEmpty($img) and fn:exists($binary-content) ) then (
                $img
            ) else if ( fn:exists($path[. != '']) and fn:empty($binary-content) ) then (
                let $titan-object := api:get-asset-from-media-api($path, 'image')
                let $renditions as xs:string* :=
                    for $rendition in $titan-object/renditions
                    let  $url := $rendition/url/fn:string()
                    where fn:not( $url= "")
                    order by fn:abs($rendition/width - 250) ascending
                    return (
                        $url
                    )
                return (
                    ( $renditions[1], $image-node/@thumb/xs:string(.)[. != ''], $settings:content-api-url, '/id/' || $path )[1]
                )
            ) else ( $images:placeholderImg )
        )

    let $archive as xs:string? := $form/@archive
    let $links as element(link)* := (
        if ( $archive = "true" and fn:contains($uri, '/archive') ) then (
            <link name="ldse:unarchive">true</link>
        ) else if ( $archive = "true" ) then (
            <link name="ldse:archive">true</link>
        ) else (),

        if ( $formName = 'site-creator' ) then (
            <link name="ldse:delete">false</link>,
            <link name="ldse:publish">false</link>,
            <link name="ldse:translation-ready">false</link>
        ) else ()
    )
    let $iceVars as xs:string* := if ( fn:contains(fn:string-join($iceVars, ','), 'site-context') ) then ( $iceVars ) else ( 'site-context:' || $site )
    let $hasReferences as xs:boolean := fn:exists($item//*[@is-reference eq 'true'])
    let $refCompMark as element()? :=
                if(fn:not($formName = 'pageBuilder') or fn:not($uri eq $item/@uri/fn:string())) then (
                    af:refComponentMark($parent-id, $item, $lang)/span
                ) else ()
    let $isDisabled as xs:string := af:getDisableStatus($item, $ref-parent-id)
    let $componentType as xs:string := $form/ldse:title/xs:string(.)
    return (
        if ( $hasReferences ) then (
            <ul class="nodeReferenceContainer">
                <div class="title-component" data-parent-ref="{$ref-parent-id}" data-enable="{$isDisabled}">{af:buildNode($lang, $item, $contentTitle, $formName, $iceVars, $links, $imgSrc, $title, $componentType, $uri, $render, $parent-id)}{$refCompMark}</div>

                <div class="sub-component">{af:renderReferencedDocumentNodes($item, $lang, $uri, $parent-id)}</div>
            </ul>
        ) else ( <div class="lead-sub-component" data-parent-ref="{$ref-parent-id}" data-enable="{$isDisabled}"> {af:buildNode($lang, $item, $contentTitle, $formName, $iceVars, $links, $imgSrc, $title, $componentType, $uri, $render, $parent-id, $ref-parent-id)}{$refCompMark}</div>,af:buildBundleSection($items) )
    )
};

declare function af:buildBundleSection(
    $item as element()*
) as element()* {
    if(fn:name($item[1]) eq "custom-page") then (
        let $pageId := $item/ldse:ldse-meta/ldse:document/@id/fn:string()
        let $availableBundles := af:getPageStringBundles($pageId)
        let $result := (
            if($availableBundles/bundle) then (
                (<span class="page-bundle-title"><br/>Resource Bundle List</span>, if($availableBundles/bundle/@missing) then (<span class="page-bundle-missing" data-bundle-missing-count="{fn:count($availableBundles/bundle/@missing)}"> ({fn:count($availableBundles/bundle/@missing)} missing)</span>) else (),<span class="page-bundle">:</span>),
                <div class="page-bundle-div"> {
                    for $bundleItem in $availableBundles/bundle
                    let $bundleName :=
                        if($bundleItem/@missing) then (
                            <span class="page-bundle-missing">{$bundleItem/@name/fn:string()} (missing)</span>
                        ) else
                            $bundleItem/@name/fn:string()
                    order by $bundleItem/@name/fn:string()
                    return (
                        <li class="page-bundle" data-bundle-id="{$bundleItem/@name/fn:string()}">{
                            if (fn:exists($availableBundles/@admin)) then (
                                if($bundleItem/@missing) then (
                                    $bundleName
                                ) else (
                                    <a href="{$bundleItem/@href}" target="newTab">{$bundleName}</a>
                                )
                            ) else (
                                $bundleName
                            )
                        }</li>
                    )
                    }</div>
            ) else ()
        )
        return <div class="page-bundle-container">{$result}</div>
    ) else ()

};

declare function af:buildPage(
    $page as element(),
    $id as xs:string?
) as element()* {
    let $uriParam as xs:string? := '&amp;uri=' || $page/@uri
    let $currentSite as xs:string? := xdmp:get-request-field('site', '')[. != '']
    let $idParam as xs:string := '&amp;id=' || $id
    let $siteSelector := af:buildSiteSelector()
    let $option-selected as element(option)? := $siteSelector//option[@selected]
    let $site-selected as xs:string := fn:tokenize($option-selected/@value, '&amp;site=')[2]
    let $siteParam as xs:string := if ( c:stringNotEmpty($currentSite) or $site-selected ) then ( '&amp;site=' || ( $currentSite, $site-selected )[1] ) else ( '' )
    let $content-id-param as xs:string? :=
        if ( fn:empty($page/@uri[. != '']) ) then (
            '&amp;contentId=' || $page/@id
        ) else ()
    let $href as xs:string := c:buildFullUrl($HOST, $admin-prefix, $lang, $clang, $uriParam || $idParam || $siteParam || $content-id-param)
    let $type as xs:string := fn:substring-after($page/ldse:ldse-meta/ldse:document/@type, ':')
    let $merged-options as element()+ := ice:get-merged-options(())
    let $map as map:map := ice:load-map(map:map(), $lang, $type, $page, $page/@uri, $merged-options)
    let $status as element(status)* := ice:get-status($page, $map, $type)
    let $translation as element(ldse:translation-event)? := $page/ldse:ldse-meta/ldse:translation-event
    let $translation-date as xs:dateTime? := $page/ldse:ldse-meta/ldse:translation-event/element()[fn:last()]/@date/xs:dateTime(.)
    let $published-date as element(ldse:publish-date)? := $page/ldse:ldse-meta/ldse:publish-date
    let $contributor as element(ldse:contributor)? := core:get-contributor($published-date/@username)
    let $publisher as xs:string? := ( $contributor/ldse:name/@display, $contributor/ldse:name )[1]
    let $audiences as xs:string? := fn:string-join($page/audiences/audience, ', ')
    let $uri as xs:string? := $page/@uri
    let $locale as xs:string? := $page/@locale
    let $content-id as xs:string? := $page/@id
    let $exclude-referenced-components as xs:string? := if ($currentSite) then
                                                            cf:get-sub-site($site)/exclude-referenced-components/fn:string()
                                                        else ()
    let $availableBundles := af:getPageStringBundles($page/@id/xs:string(.))
    let $isBundleMissing := if($availableBundles/bundle/@missing) then ("true") else ("false")
    let $bundleMissingCount := fn:count($availableBundles/bundle/@missing)
    let $preview-host :=
        if ($isDevOpCMS) then
            fn:replace($host-header, '-cms.pvu.cf.churchofjesuschrist.org', '-hannah-preview.pvu.cf.churchofjesuschrist.org')
        else $site-properties/urls/url[@env = 'preview']/fn:string()
    let $published-host :=
        if ($isDevOpCMS) then
            fn:replace($host-header, '-cms.pvu.cf.churchofjesuschrist.org', '-hannah.pvu.cf.churchofjesuschrist.org')
        else $site-properties/urls/url[@env = 'published']/fn:string()
    let $devop-prefix := if ($isDevOpCMS) then
                            if ($site-properties/@site eq 'comeuntochrist') then
                                '/comeuntochrist-m'
                            else if ($site-properties/site-context eq ('', '/')) then
                                '/'||$site-properties/@site
                            else ()
                         else ()
    let $cms-api := $ldse-settings/ldse:feature-links/ldse:link[@type eq "cms-api"]/@path/fn:string()
    let $titan-images-used-api :=  $ldse-settings/ldse:feature-links/ldse:link[@type eq "titan-images-used-api"]/@path/fn:string()
    let $find-page-links := $ldse-settings/ldse:feature-links/ldse:link[@type eq "find-page-links"]/@path/fn:string()
    let $page-used-by := $ldse-settings/ldse:feature-links/ldse:link[@type eq "page-used-by"]/@path/fn:string()
    let $is-consolidated := $site-properties/consolidation-status/fn:string() eq 'consolidated'
    let $is-published := ($status[1]/fn:string() eq ('Published', 'Modified'))
    let $_cocj-host := sp:get-consolidation-info($currentSite, 'publish')
    let $cocj-host := $_cocj-host/@host||$_cocj-host/@prefix
    let $lang-param := if ($site-properties/suppress-lang-param eq 'true') then () else ('?lang='||$lang,'&amp;lang='||$lang )
    let $auth-required := ac:authRequired($site-properties/@site)
    let $disable-publishing := $site-properties/disable-publishing/fn:string() eq 'true'
    let $preview-links :=
        (
            <li><a href="{ '//' || $preview-host || $devop-prefix || $page/@uri/xs:string(.) || ($lang-param)[1] }" class="ldse-icon-binoculars" target="_blank">Preview Page</a></li>,
            if ($auth-required) then ()
            else <li><a href="{ $cms-api || $preview-host || $devop-prefix || $page/@uri/xs:string(.) || ($lang-param)[2] }" class="ldse-icon-tools" target="_blank">Preview JSON</a></li>
        )
    let $published-links :=
        if ($is-published) then (
            (
                <li><a href="{ '//' || $published-host || $devop-prefix || $page/@uri/xs:string(.) || ($lang-param)[1] }" class="ldse-icon-binoculars" target="_blank">Published Page</a></li>,
                if ($auth-required) then ()
                else <li><a href="{ $cms-api || $published-host || $devop-prefix || $page/@uri/xs:string(.) || ($lang-param)[2] }" class="ldse-icon-tools" target="_blank">Published JSON</a></li>
            )
        ) else ()
    let $cojc-links := if ($is-consolidated and $is-published and $cocj-host) then (
                            <li><a href="{ '//' || $cocj-host || $page/@uri/xs:string(.)}" class="ldse-icon-binoculars" target="_blank">Published Consolidated Page</a></li>,
                            <li><a href="{ $cms-api || $cocj-host || $page/@uri/xs:string(.) || '&amp;lang=' || $lang }" class="ldse-icon-tools" target="_blank">Published Consolidated JSON</a></li>
                            ) else ()
    let $test-id := if ($uriParam) then fn:concat('page-editor-',$page/@uri) else ""
    let $show-links-apis := if (fn:starts-with($page/ldse:ldse-meta/ldse:form-options/ldse:templateId/fn:string(), 'mo-')) then (
                                <li><a href="{ $find-page-links || $page/@id/xs:string(.) || '&amp;lang=' || $lang || '&amp;site=' || $currentSite}" class="ldse-icon-link" target="_blank" data-testid="{$test-id}">Current Page Links</a></li>,
                                <li><a href="{ $page-used-by || $page/@id/xs:string(.) || '&amp;lang=' || $lang || '&amp;site=' || $currentSite}" class="ldse-icon-list" target="_blank" data-testid="{$test-id}">Components Linked to this Page</a></li>
                            ) else ()
    return (
        <li class="node node-stats page-template">
            <header>
                <ice-div class="ice-page-settings">
                    <div class="ldse-ice-menu-container { $status/@class/xs:string(.) } { $page/@id/xs:string(.) }" data-bundle-missing-count="{$bundleMissingCount}" data-bundle-missing="{$isBundleMissing}">
                        <a href="#" class="ldse-ice-status" data-target="" data-testid="{$test-id}"></a>
                        <ul class="ldse-menu">
                            <li class="ldse-status-item"><span>{ $status[1] }</span></li>
                            <li><a href="{ $href }" class="ldse-icon-edit">Edit Page Content</a></li>
                            { if ($disable-publishing) then ()
                              else <li><a class="ldse-icon-send" onclick="performActionOnItems('ldse:publish', '{$page/@uri/xs:string(.)}', '{$lang}', '{$currentSite}', true, '{$page/@id/xs:string(.)}'); return false;" data-testid="{$test-id}">Publish Page &amp; Content</a></li>
                            }
                            <li><a class="ldse-icon-unpublish" onclick="performActionOnItems('ldse:unpublish', '{ $page/@uri/xs:string(.) }', '{ $lang }', '{ $currentSite }', true, '{ $page/@id/xs:string(.) }'); return false;" data-testid="{$test-id}">Un-Publish Page &amp; Content</a></li>
                            <li><a class="ldse-icon-trash" onclick="performActionOnItems('ldse:delete', '{ $page/@uri/xs:string(.) }', '{ $lang }', '{ $currentSite }', true, '{ $page/@id/xs:string(.) }'); return false;" data-testid="{$test-id}">Delete Page &amp; Content</a></li>
                            <li><a class="ldse-icon-review" onclick="ICE.translationReadyAll('ready', 'complete', '{ $page/@locale/xs:string(.) }', '{ $page/@id/xs:string(.) }', this); return false;" data-testid="{$test-id}">Mark Items Ready</a></li>
                            <li><a class="ldse-icon-review" onclick="ICE.translationSend('ready', 'complete', '{ $page/@locale/xs:string(.) }', '{ $page/@id/xs:string(.) }', this, '{ $exclude-referenced-components }'); return false;" data-testid="{$test-id}">Mark Ready &amp; Send</a></li>
                            <li><a class="ldse-icon-copy" onclick="ICE.clonePage('{$locale}', '{$uri}', 'ldse:clone-page', '{$content-id}')" data-testid="{$test-id}">Clone Page</a></li>
                            {$preview-links}
                            {$published-links}
                            {$cojc-links}
                            <li><a href="{ $titan-images-used-api || $page/@id/xs:string(.) || '&amp;lang=' || $lang || '&amp;site=' || $currentSite}" class="ldse-icon-picture" target="_blank" data-testid="{$test-id}">Titan Images Used</a></li>
                            {$show-links-apis}
                        </ul>
                    </div>
                </ice-div>
                <h2 class="node-title">{$page/title/fn:string()}</h2>
            </header>
            <section>
                {
                    if ( fn:exists($audiences[. != '']) ) then (
                        <div class="page-uri">Audience: { $audiences }</div>
                    ) else ( <div class="page-uri" /> ),
                    if ( fn:exists($translation) ) then (
                        <div class="page-uri">Translation: { $translation/@status/xs:string(.) || ' -', fn:format-dateTime($translation-date, '[D] [MNn,*-3] [Y]') }</div>
                    ) else ( <div class="page-uri" /> ),
                    if ( fn:exists($published-date) ) then (
                        <div class="page-uri">Last Published: { fn:format-dateTime($published-date/@date/xs:dateTime(.), '[D] [MNn,*-3] [Y]') || ' - ' || $publisher }</div>
                    ) else ( <div class="page-uri" /> )
                }
                <div class="page-uri">{ if ( fn:exists($page/@uri[. != '']) ) then ( 'uri: ' ) else () }<a href="{ '//' || $preview-host || $page/@uri/xs:string(.) || '?lang=' || $lang }" target="_blank">{ $page/@uri/xs:string(.) }</a></div>
            </section>
        </li>
    )
};

declare function af:nonPageTemplate(
    $content as element(),
    $id as xs:string?
) as element()* {
    let $id as xs:string? := ( $id, $content/ldse:ldse-meta/ldse:form-options/ldse:pageId )[1]
    return af:buildPage($content, $id)
};

declare function af:buildNode(
    $lang as xs:string,
    $item as element(),
    $contentTitle as xs:string,
    $formName as xs:string,
    $iceVars as xs:string*,
    $links as element(link)*,
    $imgSrc as xs:string?,
    $title as xs:string?,
    $componentType as xs:string?,
    $uri as xs:string?,
    $render as xs:string?,
    $parent-id as xs:string?
) {
    af:buildNode($lang, $item, $contentTitle, $formName, $iceVars, $links, $imgSrc, $title, $componentType, $uri, $render, $parent-id, ())
};

declare function af:buildNode(
    $lang as xs:string,
    $item as element(),
    $contentTitle as xs:string,
    $formName as xs:string,
    $iceVars as xs:string*,
    $links as element(link)*,
    $imgSrc as xs:string?,
    $title as xs:string?,
    $componentType as xs:string?,
    $uri as xs:string?,
    $render as xs:string?,
    $parent-id as xs:string?,
    $ref-parent-id as xs:string?
) {
    let $root := fn:local-name($item)
    let $rootClass := fn:concat("view-", $root)
    let $iceVars as xs:string* :=
        if ( fn:exists($parent-id) ) then (
            $iceVars, 'wrapper-id:' || $parent-id
        ) else ( $iceVars )
    return (
        switch ( $render )
        case "media" return (
            af:renderICE($lang, $item, $contentTitle, $uri, (), $formName, fn:true(), $iceVars, $links),
            af:buildMediaNode($lang, $item, $imgSrc, $title, $uri, $title, $rootClass, $root)
        )
        case "text" return (
            af:renderICE($lang, $item, $contentTitle, $uri, (), $formName, fn:true(), $iceVars, $links),
            af:buildTextNode($lang, $item, $contentTitle, $title, $componentType, $uri, $root, $rootClass, $ref-parent-id)
        )
        case "tile" return (
            af:renderICE($lang, $item, $contentTitle, $uri, (), $formName, fn:true(), $iceVars, $links),
            af:buildTileNode($lang, $item, $imgSrc, $title, $uri, $title, $rootClass, $root)
        )
        default return af:default-rendering($lang, $item, $contentTitle, $formName, $iceVars, $links, $imgSrc, $title, $uri, $parent-id)
    )
};

(:
    When component has been marked as ready it adds context to component's title in the GUI by using a tag.
:)
declare function af:getMarkReadyStatus(
    $item as element()){
        let $translationReady := $item/ldse:ldse-meta/ldse:translation-event
        return
            if(fn:exists($translationReady)) then (
                let $status := $translationReady/@status/fn:string()
                return
                    if($status eq "ready") then (
                        <span class="translation-status-ready">{$translationReady/@status/fn:string()}</span>
                    ) else (
                        <span class="translation-status-sent">{$translationReady/@status/fn:string()}</span>
                    )
            ) else ()
};

declare function af:getDisableSpan( ) {
    <span class="component-status-enabled"></span>
};

declare function af:getDisableStatus(
    $item as element(),
    $parent-id as xs:string?
) as xs:string {
    let $item-meta-doc := $item/ldse:ldse-meta
    let $parent := if($parent-id) then (
                        ldsemeta:get-file-by-id($parent-id)
                   ) else (
                        dynamicForms:get-custom-page($item-meta-doc/ldse:document/@uri/fn:string(), $item-meta-doc/ldse:document/@locale/fn:string(), ($item-meta-doc/ldse:form-options/ldse:site-context)[1]/fn:string())
                   )
    let $type := fn:name($parent)
    let $componentRef :=  if ($type eq 'custom-page') then $parent/content/*[. eq $item-meta-doc/ldse:document/@id/fn:string()]
                          else  $parent//*[@is-reference eq 'true' and . eq $item-meta-doc/ldse:document/@id/fn:string()]
    return
        if($componentRef/@disable) then (
            "disabled"
        ) else ( "enabled" )
};

declare function af:default-rendering(
    $lang as xs:string,
    $item as element(),
    $contentTitle as xs:string,
    $formName as xs:string,
    $iceVars as xs:string*,
    $links as element(link)*,
    $imgSrc as xs:string?,
    $title as xs:string?,
    $uri as xs:string?,
    $parent-id as xs:string?
) {
    let $preview-host :=
            if ($isDevOpCMS) then
                fn:replace($host-header, '-cms.pvu.cf.churchofjesuschrist.org', '-hannah-preview.pvu.cf.churchofjesuschrist.org')
            else $site-properties/urls/url[@env = 'preview']/fn:string()
    return
            <li class="node node-content published">
                { af:renderICE($lang, $item, $contentTitle, $uri, (), $formName, fn:true(), $iceVars, $links) }
                <header>
                    <div class="node-vignet"> {
                        if ( c:stringNotEmpty($imgSrc) ) then (
                            <img src="{$imgSrc}"/>
                        ) else ( <div/> )
                    } </div>
                </header>
                <section>
                    <div class="content node-row">{ $title } {af:getMarkReadyStatus($item)} {af:getDisableSpan()}
                    {   if(fn:name($item) eq "custom-page") then (
                            <span class="page-uri"><br/>{ if ( fn:exists($uri[. != '']) ) then ( 'Uri: ' ) else () }<a href="{ '//' || $preview-host || $uri || '?lang=' || $lang }" target="newTab">{ $uri}</a></span>
                        ) else ()
                    }
                    </div>
                </section>
            </li>
};

declare function af:buildTextNode(
    $lang as xs:string,
    $item as element(),
    $contentTitle as xs:string,
    $title as xs:string?,
    $componentType as xs:string?,
    $uri as xs:string?,
    $root as xs:string?,
    $rootClass as xs:string?
) as element(li) {
    af:buildTextNode($lang, $item, $contentTitle, $title, $componentType, $uri, $root, $rootClass, ())
};

declare function af:buildTextNode(
    $lang as xs:string,
    $item as element(),
    $contentTitle as xs:string,
    $title as xs:string?,
    $componentType as xs:string?,
    $uri as xs:string?,
    $root as xs:string?,
    $rootClass as xs:string?,
    $ref-parent-id as xs:string?
) as element(li) {
    let $useTitle := if($title and fn:string-length($title) <= 100) then ($title) else (($item//title/xs:string(.))[1])
    let $_showText := if($item/text) then ($item/text) else ($item/sub-title)
    let $showText := if (fn:string-length($_showText) <= 100) then $_showText else substring($_showText, 1, 100)||'...'
    return (
        <li class="node-content published" style="display: flex; align-items: center;">
            <section>
                <header>
                    {
                        if ( $root eq 'share-options' ) then (
                            for $node in $item//*[(.) eq 'true']
                            return (fn:local-name($node))
                        ) else ( $useTitle )
                    }
                    {af:getMarkReadyStatus($item)}
                    {af:getDisableSpan()}
                </header>
                {
                    if ($componentType) then
                    (
                        <header style="font-size: 14px; font-weight: lighter; color: gray;">{$componentType}</header>
                    ) else ()
                }
                <div class="{$rootClass}">{$showText}</div>
            </section>
        </li>
    )
};

declare function af:buildMediaNode(
    $lang as xs:string,
    $item as element(),
    $imgSrc as xs:string?,
    $title as xs:string?,
    $uri as xs:string?,
    $useTitle as xs:string?,
    $rootClass as xs:string?,
    $root as xs:string?
) as element(li)* {
    let $isVideo := if($root eq 'media-block' and ($item//video-id != '' or $item//youtube-id != '')) then (fn:true()) else (fn:false())
    return (
        if ( fn:exists($imgSrc[. != '']) ) then (
            <li class="node node-content published">
                <section>
                    <header>
                        <div class="node-vignet">
                            <img src="{ $imgSrc }"/>
                        </div>
                    </header>
                    <div class="content node-row">{
                        $title
                    }</div>
                </section>
            </li>
        ) else (),
        <li class="node-content published" style="min-height:206px;">
    <!--This is a temporary style hack for collections...we need a custom handler for collections most likely-->
            <section>
                {
                    if ( fn:empty($imgSrc[. != '']) ) then ( <div class="content node-row">{ $title }</div> ) else (),
                    if ( fn:exists($item/(sub-title|description)) ) then ( <div class="content node-row">{ $item/(sub-title|description) }</div> ) else (),
                    if ( fn:exists($imgSrc[. != '']) or $isVideo ) then (
                        <header style="font-size: 18px; font-weight: lighter; padding-bottom:8px;">Asset Data:</header>,
                        <div class="{$rootClass}">
                            <ul style="list-style-type:none;">
                                {
                                    if ( $isVideo ) then (
                                        <li><em>Brightcove: </em> {$item//video-id}</li>,
                                        <li><em>Youtube ID: </em> {$item//youtube-id}</li>
                                    ) else ()
                                }
                                <li><em>Caption: </em> {$item//text/*}</li>
                                {
                                    if ( fn:exists($imgSrc[. != '']) ) then (
                                        <li><em>Titan Asset: </em>
                                            <a target="_blank" href="{fn:concat('https://titan.ldschurch.org/?type=IMAGE&amp;assetID=', $item/image)}">View in Titan</a>
                                        </li>
                                    ) else ()
                                }
                            </ul>
                        </div>
                    ) else ()
                }
            </section>
        </li>
    )
};

declare function af:buildTileNode(
    $lang as xs:string,
    $item as element(),
    $imgSrc as xs:string?,
    $title as xs:string?,
    $uri as xs:string?,
    $useTitle as xs:string?,
    $rootClass as xs:string?,
    $root as xs:string?
) as element(li)* {
    <li class="tile-container ">
        <span class="tile-title">{ $title }</span>{af:getMarkReadyStatus($item)}
        <div class="tile-subtitle">
            <span class="tile-author">{ $item/url }</span>
            <!--<span class="tile-meta">{$item/url}</span>-->
        </div>
        <div class="tile-bodywrapper">
            { if ( fn:exists($imgSrc[. != '']) ) then (
                <img sizes="100vw" src="{$imgSrc}" alt="" class="tile-image"></img>
            ) else () }
            <div class="">
                <div class="tile-description">
                {$item/sub-title}
                </div>
            </div>
        </div>
    </li>
};

declare function af:buildPage(
    $page as element()
) as element()* {
    <li class="node node-stats page-template">
        <header>
            <h2 class="node-title">{ $page/search-meta/title/fn:string() }</h2>
        </header>
        <section>
        </section>
    </li>
};

declare function af:getPages(
    $start as xs:int?,
    $end as xs:int?
) as element()* {
    let $content as element()* :=
        (for $content as element() in cf:get-content($template-id, $site)
        let $date as xs:dateTime? := ldsemeta:get-last-modified($content)[. ne ""]
        order by $date descending
        return (
            $content
        ))[$start to $end]
    return (
        af:renderNodes($lang, $content, (), (), (), (), ())
    )
};

declare function af:addPageEdit(
    $page as xs:string,
    $lang as xs:string,
    $riceStrings as xs:string*,
    $custom-page as element(custom-page)*,
    $isTemplate as xs:boolean
) as item()* {
    ice:add-gear($page, $lang, $riceStrings, $isTemplate,
        <options>
            <variables>{
                if ( fn:exists($custom-page) and fn:count($custom-page) = 1 ) then (
                    let $uri as xs:string := ( $custom-page/uri-definition/uri-path[. != ""], ldsemeta:get-document-uri($custom-page)[. != ""] )[1]

                    return (
                        element uri { $uri }
                    )
                ) else ()
            }</variables>
            <links>
                <link name="ldse:gear-publish">true</link>
                <link name="ldse:gear-unpublish">true</link>
                <link name="ldse:gear-edit-hidden-resources">true</link>
                <link name="ldse:gear-new-page">false</link>
                <link name="ldse:gear-omniture">false</link>
                <link name="ldse:gear-seomoz">false</link>
                {if ($isTemplate) then (<link name="ldse:gear-page-settings">false</link>) else ()}
            </links>
            <settings></settings>
        </options>
    )
};

declare function af:buildTemplates(
    $start as xs:int,
    $end as xs:int,
    $page-id as xs:string,
    $template-id as xs:string?,
    $site as xs:string?
) as element()* {
    for $t in fn:tokenize($template-id, "\s*,\s*")
    let $page-id as xs:string :=
        if ( fn:exists($page-id) and fn:not($page-id = "") ) then (
            $page-id
        ) else ( $site-pages[@template = $template-id]/@id )
    let $template as element(template)? := cf:getTemplateById($t)
    let $template-name as xs:string? := $template/name
    let $template-id as xs:string? :=  $template/@id
    let $templateConfig as element(page)? := af:getAdminPage($page-id)
    let $uri as xs:string? := $templateConfig/@uri
    let $formVars as xs:string* := ("templateId:" || $template-id, "templateName:" || $template-name, "templateUri:" || $uri, "site:" || $site, "siteUriContext:" || $site-properties/site-context, "pageId:" || $page-id, 'requiredFields:' || $template/@required-fields)
    let $ice-link as element(a)? := af:renderICE($lang, (), $template-name, (), (), ( $template/@form, 'pageBuilder' )[1], fn:true(), $formVars, ())//a[fn:contains(@class, "ldse-icon-ko-add")]
    let $pages := af:getPages($start, $end, $page-id, $template, $site)

    return (
        if ( fn:exists($template) and fn:not($template/@only-one = "true") ) then (
            <h2 class="node-title">{ $template-name, <a type="button" class="primaryButton actionButton ldse-responsive">{$ice-link/@* except $ice-link/@class}<span class="ldse-secondary ldse-icon-ko-add"></span></a> }</h2>,
            <ul class="nodeContainer">{ $pages }</ul>
        ) else (
            <h2 class="node-title">{$template-name, <a type="button" class="primaryButton actionButton ldse-responsive">{$ice-link/@* except $ice-link/@class}<span class="ldse-secondary ldse-icon-ko-add"></span></a>}</h2>,
            <ul class="nodeContainer"></ul>
        )
    )
};

declare function af:getPages(
    $start as xs:int,
    $end as xs:int,
    $pageId as xs:string,
    $template as element(template),
    $site as xs:string?
) as element()* {
    let $template-id as xs:string? := $template/@id
    let $template-name as xs:string? := $template/name
    let $templateConfig as element(page)? := af:getAdminPage($pageId)
    let $uri as xs:string? := $templateConfig/@uri
    let $formVars as xs:string* := ("templateId:" || $template-id, "templateName:" || $template-name, "templateUri:" || $uri, "site:" || $site, "site-context:" || $site, "siteUriContext:" || $site-properties/site-context, "pageId:" || $pageId)

    return (
        (for $page as element(custom-page)* in af:getCustomPages($template-id, $pageId, $site, ())
        order by ldsemeta:get-last-modified($page)/@dateTime descending
        return (
            af:buildPage($page, $pageId)
        ))[$start to $end]
    )
};

declare function af:getAdminPage(
    $id as xs:string
) as element(page)? {
    let $page as element(page)? :=
        if ( $id = "" or fn:empty($id) ) then (
            ($site-properties/admin-pages/nav//page[fn:contains(@site, $site) or @site = "all" or fn:empty(@site)])[1]
        ) else ( $site-properties/admin-pages/nav//page[@id = $id] )
    let $page as element(page)? :=
        if ( fn:exists($page) ) then (
            $page
        ) else ( $site-properties/admin-pages/nav//page[@template = $id] )
    return (
        if ( fn:contains($page/@site, $site) or $page/@site = "all" or fn:empty($page/@site) ) then (
            $page
        ) else ( ($site-properties/admin-pages/nav//page[fn:contains(@site, $site) or @site = "all" or fn:empty(@site)])[1] )
    )
};

declare function af:getCustomPages(
    $templateId as xs:string,
    $pageId as xs:string,
    $site as xs:string?,
    $uri as xs:string?
) as element(custom-page)* {
    cts:search(/custom-page,
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-value-query(xs:QName('custom-page'), xs:QName('locale'), $lang, 'exact'),
            if (c:stringNotEmpty($uri)) then (
                cts:element-attribute-value-query(xs:QName('custom-page'), xs:QName('uri'), $uri, 'exact')
            ) else (),
            cts:element-value-query(xs:QName('template-id'), $templateId, 'exact'),
            if ( fn:exists($site) ) then (
                cts:element-value-query(xs:QName('site-context'), $site, 'exact')
            ) else (),
            cts:element-value-query(xs:QName('ldse:pageId'), $pageId, 'exact')
        )),
        'unfiltered'
    )
};

declare function af:render-template(
    $uri as xs:string?,
    $content as element()?
) {
    let $template-id as xs:string? := ( $content/template-id, $content/ldse:ldse-meta/ldse:form-options/ldse:templateId, $template-id )[1]
    let $page as element(page)? := $site-pages[@id = $content/ldse:ldse-meta/ldse:form-options/ldse:pageId and @template = $template-id]
    let $template as element(template)? := cf:getTemplateById($page/@template)
    let $sub-template as element(sub-template)? := cf:get-sub-template($page/@sub-template)
    return (
        if ( fn:exists($content) and fn:not(fn:name($content) = 'custom-page') ) then (
            af:get-custom-item($uri, $content)
        ) else ( af:get-custom-page($uri, $content) ),

        if ( ( $template/@display = "custom" and fn:empty($sub-template) ) or $sub-template/@display = 'custom' ) then (
            af:render-page-items($uri, ( $sub-template, $template )[1], $content)
        ) else ( af:render-template-items($uri, ( $sub-template, $template )[1], $content) )
    )
};

declare function af:render-page-items(
    $uri as xs:string?,
    $template as element(),
    $content as element()?
) {
    let $wrapper-id as xs:string? := $content/@id
    let $suppress-reference := $template/@suppress-reference/fn:string()
    for $template-section as element() in $template/(content|region)
    let $options as element(option)* := af:get-template-options($uri, $template-section, $content)
    let $sectionDivId := fn:concat($template-section/@id/xs:string(.), '-action-button-div')  (:added this to allow a template to have multiple component selectors :)
    let $componentSelectorId := fn:concat($template-section/@id/xs:string(.), '-component-selector')  (:added this to allow a template to have multiple component selectors :)
    let $buttons := if ($suppress-reference eq 'true') then (
                        <a href="#d" class="ldse-button secondary ldse-icon-ko-add" onclick="window.location = $('#{$componentSelectorId}').val();">Create New</a>,
                        <a href="#d" class="ldse-button secondary ldse-icon-search prefix searchFormItem clone-existing-button" onclick="openSearchModal(this, '{$componentSelectorId}'); return false;">Clone Existing</a>
                        )
                    else (
                        <a href="#d" class="ldse-button secondary ldse-icon-ko-add" onclick="window.location = $('#{$componentSelectorId}').val();">Create New</a>,
                        <a href="#d" class="ldse-button secondary ldse-icon-search prefix searchFormItem add-existing-button" onclick="openSearchModal(this, '{$componentSelectorId}'); return false;">Add Existing</a>,
                        <a href="#d" class="ldse-button secondary ldse-icon-search prefix searchFormItem clone-existing-button" onclick="openSearchModal(this, '{$componentSelectorId}'); return false;">Clone Existing</a>
                        )
    return (
        <region-div id="{ ( $template-section/@id/xs:string(.), 'content' )[1] }">
            <section class="ldse-group ldse-section " >
                <div class="ldse-section--header">
                    <h2 class=" ldse-group-header">{ $template-section/@title/xs:string(.) }
                    </h2>
                </div>
                <div class="ldse-section--body ldse-form ">
                    <section class="sortable">
                        {
                            if ( fn:exists($options) and ( ( $template-section/@only-one = 'true' and fn:count($content/content/element()[@region = $template-section/@id]) < 1 ) or fn:not($template-section/@only-one = 'true') ) ) then (
                                <div class="nav-select">
                                    <h3 class="node-title" style="padding-right:10px;">Add Component</h3>
                                    <select class="select override-width ldse-select-override" name="sort-dir" id="{$componentSelectorId}" onchange="document.getElementById('{$sectionDivId}').style.display = 'block'">
                                        <option>Please Select</option>
                                        { $options }
                                    </select>
                                    <div style="display:none;" id="{$sectionDivId}">
                                        {$buttons}
                                    </div>
                                </div>
                            ) else (),
                            if ( fn:local-name($template-section) = 'region' ) then (
                                <div class="sortable-items">
                                {
                                    af:get-custom-page-fixed-items($uri, $template-section, $content),
                                    af:get-custom-page-region-content($uri, $template-section, $content)
                                }
                                </div>
                            ) else ( af:get-custom-page-content($uri, $template-section, $content) )
                        }
                    </section>
                </div>
            </section>
        </region-div>
    )
};

declare function af:get-custom-page-fixed-items(
    $uri as xs:string?,
    $template as element(),
    $content as element()?
) {
    for $item as element() in $template/element()[@fixed = 'true']
    let $page-content as element()* := $content/content/element()[fn:local-name(.) = fn:local-name($item) and @region = $template/@id]
    let $page-content as element()? := if ( fn:exists($item/@admin-location) ) then ( $page-content[@admin-location = $item/@admin-location] ) else ( $page-content )
    let $formName as xs:string? := $item/@content-type
    let $contentName as xs:string? := ( $item/@content-name/xs:string(.), $formName )[1]
    let $admin-location as xs:string? := if ( fn:exists($item/@admin-location[. != '']) ) then ( ',admin-location-var=' || $item/@admin-location ) else ()
    let $formVars as xs:string* := 'site-context:' || $site || ',templateName:' || $content/ldse:ldse-meta/ldse:form-options/ldse:templateId || ',region=' || $template/@id || $admin-location || ',requiredFields:' || $item/@required-fields || ',removedFields:' || $item/@removed-fields || ',addedFields:' || $item/@added-fields
    let $files as element()* := cf:getContentById($page-content)
    return (
        af:buildNodes($lang, $uri, $files, (), $item/@title || ' (fixed)', $contentName, $formName, $formVars, fn:true(), fn:true(), (), (), $content/@id, $item/@render)
    )
};

declare function af:get-custom-page-region-content(
    $uri as xs:string?,
    $template-section as element(),
    $content as element()
) {
    for $item as element() in $content/content/element()[@region = $template-section/@id and fn:not(@fixed = 'true')]
    return (
        af:get-item-for-custom-page($item, $uri, $template-section, $content)
    )
};

declare function af:get-item-for-custom-page(
    $item as element(),
    $uri as xs:string?,
    $template-section as element(),
    $content as element()
) {
    let $template as element()* := $template-section/element()[fn:local-name(.) = fn:local-name($item) and fn:not(@fixed = 'true')]
    let $template as element()? := if ( fn:exists($item/@admin-location) ) then (  $template[@admin-location = $item/@admin-location] ) else ( $template )
    let $formName as xs:string? := $template/@content-type
    let $contentName as xs:string? := ( $template/@content-name/xs:string(.), $formName )[1]
    let $admin-location as xs:string? := if ( fn:exists($item/@admin-location[. != '']) ) then ( ',admin-location-var=' || $item/@admin-location ) else ()
    let $formVars as xs:string* := 'site-context:' || $site || ',templateName:' || $content/ldse:ldse-meta/ldse:form-options/ldse:templateId || ',region=' || $template-section/@id || $admin-location
    let $files as element()* := cf:getContentById($item)
    return (
        af:buildNodes($lang, $uri, $files, (), $template/@title, $contentName, $formName, $formVars, fn:true(), fn:false(), $template-section/@id, (), $content/@id, $template/@render)
    )
};

declare function af:get-custom-page-content(
    $uri as xs:string,
    $template-section as element(),
    $content as element()
) {
    for $item as element() in $content/content/element()
    return (
        af:get-item-for-custom-page($item, $uri, $template-section, $content)
    )
};

declare function af:get-template-options(
    $uri as xs:string,
    $template as element(),
    $content as element()
) as element(option)* {
    let $wrapper-id as xs:string := $content/@id
    for $item as element() in $template/element()[fn:not(@fixed = 'true')]
    let $admin-location as xs:string? := if ( fn:exists($item/@admin-location[. != '']) ) then ( ',admin-location-var=' || $item/@admin-location ) else ()
    let $formVars as xs:string* := fn:concat("site-context:", $site, ',templateName:', $content/ldse:ldse-meta/ldse:form-options/ldse:templateId, ',location=', fn:local-name($item), ',region=', $template/@id/xs:string(.), $admin-location, ",siteUriContext:", $site-properties/site-context, ',requiredFields:', $item/@required-fields, ',removedFields:', $item/@removed-fields, ',addedFields:', $item/@added-fields)
    let $ice-link as element(a)? := af:renderICE($lang, (), fn:local-name($item), (), (), $item/@content-type, fn:true(), $formVars, ())//a[fn:contains(@class, "ldse-icon-ko-add")]
    let $link as xs:string := $ice-link/@href || '&amp;option=' || xdmp:url-encode($ice-link/@data-post.option) || '&amp;uri=' || $uri || '&amp;wrapper-id=' || $wrapper-id
    order by $item/@title
    return (
        <option value="{$link}" name="{ $item/@content-type/xs:string(.) }">{ $item/@title/fn:string() }</option>
    )
};

declare function af:render-template-items(
    $uri as xs:string,
    $template as element()?,
    $content as element()?
) {
    for $template-section as element() at $i in $template/content/element()
    return (
        af:get-template-items($uri, $template-section, $content)
    )
};

declare function af:get-template-items(
    $uri as xs:string,
    $template-section as element(),
    $content as element()?
) {
    let $title as xs:string := ( $template-section/@title/xs:string(.), fn:local-name($template-section) )[1]
    let $formName as xs:string? := $template-section/@content-type
    let $contentName as xs:string? := ( $template-section/@content-name/xs:string(.), $formName )[1]
    let $location as xs:string? := fn:local-name($template-section)
    let $files as element()* :=
        for $item in cf:get-content-by-uri-type($uri, $formName, $location, $template-section/@admin-location)
        let $sequence as xs:string? := $item/sequence[. != '']
        let $sequence as xs:int? :=
            if ( fn:exists($sequence) ) then (
                xs:int($sequence)
            ) else ()
        order by $sequence
        return $item
    let $site as xs:string? := xdmp:get-request-field('site')
    let $onlyOne as xs:boolean := $template-section/@only-one = 'true'
    let $pubType as xs:string? := $template-section/@pubType
    let $admin-location as xs:string? := if ( fn:exists($template-section/@admin-location) ) then ( 'admin-location:' || $template-section/@admin-location || ',admin-location-var=' || $template-section/@admin-location ) else ()
    let $formVars as xs:string* := ( 'location:' || $location, "type:" || $formName, "site-context:" || $site, "page-type:" || $pubType, "siteUriContext:" || $site-properties/site-context, 'requiredFields:' || $template-section/@required-fields, 'removedFields:' || $template-section/@removed-fields, 'addedFields:', $template-section/@added-fields, $admin-location )

    return (
        af:buildNodes($lang, $uri, $files, (), $title, $contentName, $formName, $formVars, $onlyOne, fn:false(), (), (), (), ())
    )
};

declare function af:get-custom-item(
    $uri as xs:string?,
    $content as element()
) {
    let $title as xs:string := "Page Settings"
    let $template-id as xs:string := $content/ldse:ldse-meta/ldse:form-options/ldse:templateId
    let $page as element(page)? := $site-properties/admin-pages/nav/section/page[@id = $content/ldse:ldse-meta/ldse:form-options/ldse:pageId] (: or @template = $template-id:)
    let $template-id as xs:string := $page/@template
    let $template as element(template) := cf:getTemplateById($template-id)
    let $formName as xs:string := ( $template/@formName, 'pageBuilder' )[1]
    let $contentName as xs:string := ( $template/name/xs:string(.) || ' Settings', "Page Settings" )[1]
    let $location as xs:string := ( $template/@formName, 'pageBuilder' )[1]
    let $pageId as xs:string := ( xdmp:get-request-field('id'), $content/template-id, $template-id )[1]
    let $site as xs:string? := xdmp:get-request-field('site')
    let $onlyOne as xs:boolean := fn:true()
    let $pub-type as xs:string? :=
        if ( fn:exists($content/ldse:ldse-meta/ldse:form-options/ldse:pub-type) ) then (
            'pub-type:' || $content/ldse:ldse-meta/ldse:form-options/ldse:pub-type
        ) else ()
        let $test := $site-properties/site-context/xs:string(.)
    let $sub-template as element(sub-template)? := cf:get-sub-template($page/@sub-template)
    let $required-fields as xs:string* := ( $template/@required-fields, $sub-template/@required-fields )
    let $removed-fields as xs:string* := ( $sub-template/@removed-fields, $template/@removed-fields )[1]
    let $added-fields as xs:string* := ( $template/@added-fields, $sub-template/@added-fields )
    let $formVars as xs:string* := ( 'location:' || $location, 'templateUri:' || $page/@uri, 'templateName:' || ( $page/@sub-template, $page/@template )[1], 'pageId:' || $pageId, fn:concat("templateId:", ( $content/template-id[. != ''], $template-id )[1]), "site-context:" || $site, "siteUriContext:" || $site-properties/site-context, $pub-type, 'requiredFields:' || $required-fields, 'removedFields:' || $removed-fields, 'addedFields:' || $added-fields )
    return (
        af:buildNodes($lang, $uri, $content, (), $title, $contentName, $formName, $formVars, $onlyOne, fn:false(), (), (), (), ())
    )
};

declare function af:get-custom-page(
    $uri as xs:string?,
    $custom-page as element(custom-page)
) {
    let $title as xs:string := "Page Settings"
    let $page as element(page)? := $site-properties/admin-pages/nav/section/page[@id = $custom-page/ldse:ldse-meta/ldse:form-options/ldse:pageId]
    let $template-id as xs:string := $page/@template
    let $template as element(template) := cf:getTemplateById($template-id)
    let $formName as xs:string := ( $template/@form, 'pageBuilder' )[1]
    let $contentName as xs:string := "Page Settings"
    let $location as xs:string := ( $template/@form, 'pageBuilder' )[1]
    let $files as element()* := cf:get-custom-page-by-uri($uri, $site)
    let $pageId as xs:string := ( xdmp:get-request-field('id'), $custom-page/template-id )[1]
    let $site as xs:string? := xdmp:get-request-field('site')
    let $onlyOne as xs:boolean := fn:true()
    let $formVars as xs:string* := ( 'location:' || $location, 'pageId:' || $pageId, 'templateName:' || ( $page/@sub-template, $page/@template )[1], "templateId:" || $files/template-id/fn:string(), "site-context:" || $site, "siteUriContext:" || $site-properties/site-context, 'requiredFields:' || $template/@required-fields, 'removedFields:' || $template/@removed-fields, 'addedFields:' || $template/@added-fields )

    return (
        af:buildNodes($lang, $uri, $files, (), $title, $contentName, $formName, $formVars, $onlyOne, fn:false(), (), (), (), ())
    )
};

declare function af:buildContentAdminPage(
    $lang as xs:string,
    $page as xs:string?,
    $site as xs:string?,
    $adminPage as element(page)?,
    $header as xs:string,
    $nodeName as xs:string,
    $formName as xs:string,
    $id as xs:string,
    $formVars as xs:string*,
    $onlyOne as xs:boolean,
    $pub-type as xs:string?,
    $template as xs:string?
) as element()* {
    af:buildContentAdminPage($lang, $page, $site, $adminPage, $header, $nodeName, $formName, $id, $formVars, $onlyOne, $pub-type, $template, ())
};

declare function af:buildContentAdminPage(
    $lang as xs:string,
    $page as xs:string?,
    $site as xs:string?,
    $adminPage as element(page)?,
    $header as xs:string,
    $nodeName as xs:string,
    $formName as xs:string,
    $id as xs:string,
    $formVars as xs:string*,
    $onlyOne as xs:boolean,
    $pub-type as xs:string?,
    $template as xs:string?,
    $sites as element(sub-site)*
) as element()* {
    let $content as element()* :=
        if ( $formName = 'pageBuilder' or ( fn:empty($formName) and fn:empty($nodeName) ) ) then (
            cf:get-custom-page-by-template-id-and-lang($id, $site, $lang)
        ) else if ( fn:exists($formName[. != '']) and fn:not($adminPage/@pagination = 'true') ) then (
            cf:getContent($formName, $site)
        ) else if ( $adminPage/@pagination = 'true' and fn:exists($adminPage/@formName[. != '']) and fn:empty($adminPage/@template) ) then (
            cf:getContent($formName, $site)
        ) else ()
    let $paginateContent as xs:boolean := ( ( $adminPage/@pagination = 'true' or ( $formName = "pageBuilder" or fn:empty($formName) ) ) and fn:not($onlyOne) )
    let $db-template as element()* :=
        if ( fn:exists($adminPage/@sub-template) ) then (
            cf:get-sub-template($adminPage/@sub-template)
        ) else ( cf:getTemplateById($template) )
    let $formVars as xs:string* :=
        if ( fn:exists($template) ) then (
            ( $formVars, 'pageId:' || $id, 'templateName:' || $db-template/@id, 'templateId:' || $template, 'templateUri:' || $adminPage/@uri, "siteUriContext:" || $site-properties/site-context, 'requiredFields:' || $db-template/@required-fields, 'removedFields:' || $db-template/@removed-fields, 'addedFields:' || $db-template/@added-fields )
        ) else ( $formVars )
    let $custom-page := af:getCustomPages($template, $id, $site, $page)
    return (
        if ( $id = 'site-creation' ) then (
            af:buildPagination($lang, $page, $site, $header, $nodeName, $formName, $id, $formVars, $onlyOne, $adminPage, $pub-type, $template, $sites)
        ) else if ( $paginateContent ) then (
            af:buildPagination($lang, $page, $site, $header, $nodeName, $formName, $id, $formVars, $onlyOne, $adminPage, $pub-type, $template, $content)
        ) else if ( $formName = 'pageBuilder' ) then (
            let $ice-link := af:renderICE($lang, (), 'custom-page', $page, (), 'pageBuilder', fn:true(), $formVars, ())//a[fn:contains(@class, "ldse-icon-ko-add")]
            return (
                <h2 class="node-title">{ $header }<a type="button" class="actionButton primaryButton ldse-responsive">{$ice-link/@* except $ice-link/@class}<span class="ldse-secondary ldse-icon-ko-add"></span></a></h2>
            )
        ) else (
            af:buildNodes($lang, $page, $content, (), $header, $nodeName, $formName, $formVars, $onlyOne, fn:false(), (), (), (), ())
        )
    )
};

declare function af:buildPagination(
    $lang as xs:string,
    $page as xs:string?,
    $site as xs:string?,
    $header as xs:string,
    $nodeName as xs:string,
    $formName as xs:string,
    $id as xs:string,
    $formVars as xs:string*,
    $onlyOne as xs:boolean,
    $adminPage as element(page)?,
    $pubType as xs:string?,
    $template as xs:string?,
    $content as element()*
) as element()* {
    if ( fn:not($formName = 'pageBuilder') ) then (
        let $custom-search as element(custom-search)? := $site-properties/custom-search
        let $articleSearchResults :=
            if ( fn:exists($custom-search) ) then (
                xdmp:apply(xdmp:function(fn:QName($custom-search/@ns, $custom-search/@name), $custom-search/@path), $term, $lang, $site, $searchTypes[. ne ''], $start, $pageSize, $sortType, $sortDirection, $adminPage, $pubType)
            ) else ( cf:getPaginatedArticles($term, $lang, (), (), $site, fn:false(), $searchTypes[. ne ''], $start, $pageSize, $sortType, $sortDirection, $adminPage, $pubType) )
        let $filteredSearch :=
            if($languageSearch ne '')
            then(
                let $langMatches := cf:getSitesThatSupportLanguage($languageSearch)
                let $allArticlesSearchResults := cf:getPaginatedArticles($term, $lang, (), (), $site, fn:false(), $searchTypes[. ne ''], $start, 999, $sortType, $sortDirection, $adminPage, $pubType)
                return (
                    <search:response snippet-format='raw' total='' start='1' page-length='150' xmlns:search="http://marklogic.com/appservices/search">
                        {
                            for $a in $allArticlesSearchResults/search:result
                            return if(fn:exists(index-of($langMatches/search:result/supportedLanguages/@site, $a/sub-site/name/fn:string()))) then($a) else()
                        }
                    </search:response>
                )
            )else ()
        let $articlesTotal as xs:int :=
            if(fn:exists($filteredSearch))
            then(xs:int(fn:count($filteredSearch/node())))
            else($articleSearchResults/@total/xs:int(.))
        let $articlesTotal as xs:int :=
            if ( $articlesTotal = 0 and $formName ne 'site-creator') then (
                fn:ceiling(fn:count($content) div 50)
            ) else ( $articlesTotal )
        let $articles as element()* :=
            if(fn:exists($filteredSearch))
            then(cf:getContentFromSearch($filteredSearch))
            else(cf:getContentFromSearch($articleSearchResults))
        let $content as element()* :=
            if ( fn:exists($articles) or $formName eq 'site-creator' ) then (
                $articles
            ) else ( $content )
        return (
            af:buildArticleContentPage($lang, $content, $articlesTotal, $page, $site, $header, $nodeName, $formName, $id, $formVars, $onlyOne, $pubType, $template)
        )
    ) else if ( fn:local-name($content[1]) = 'custom-page' or ( fn:empty($nodeName) and fn:empty($formName) ) or fn:exists($template) ) then (
        let $results as element()* := cf:get-custom-pages($term, $template, $id, $site, (), $lang, $start, $pageSize, $sortDirection, $sortType, $sortAuthor, $componentSearch)
        let $total as xs:int := xs:int($results/@total)
        let $pages as element(custom-page)* := $results/search:result/element()
        let $pages as element(custom-page)* :=
            if ( fn:exists($pages) ) then (
                $pages
            ) else if ( fn:name($content[1]) = 'custom-page' ) then (
                $content
            ) else ()
        let $formName as xs:string? := $pages[1]/ldse:ldse-meta/ldse:form-options/ldse:form
        let $name as xs:string? := fn:local-name($pages[1])
        return (
            af:buildPageContentPage($lang, $pages, $total, $page, $site, $header, $name, $formName, $id, $formVars, $onlyOne, $pubType, $template, $adminPage)
        )
    ) else ()
};

declare function buildPageContentPage(
    $lang as xs:string,
    $pages as element()*,
    $articlesTotal as xs:integer,
    $page as xs:string?,
    $site as xs:string,
    $header as xs:string?,
    $nodeName as xs:string?,
    $formName as xs:string?,
    $id as xs:string?,
    $formVars as xs:string*,
    $onlyOne as xs:boolean,
    $pubType as xs:string?,
    $template as xs:string?,
    $adminPage as element(page)?
) as element()+ {
    let $resultCount as xs:int := fn:count($pages)
    let $pageCount as xs:int := fn:ceiling($articlesTotal div $pageSize)
    let $end as xs:int :=
        let $calculated := $start + ($pageSize - 1)
        let $addend := (if ($calculated gt $resultCount) then ($resultCount) else ($calculated)) - 1
        return (
            ($start + $addend)
        )
    let $pageAdmin as element(page)? :=
        if ( fn:exists($adminPage) ) then (
            $adminPage
        ) else ( af:getAdminPage($template) )
    let $template-name as element(template)? := ( /template[@id = $id], /template[@id = $template] )[1]
    let $header as xs:string? := $template-name/name
    let $uri as xs:string? := $pageAdmin/@uri
    let $formVars as xs:string* := ( "templateId:" || $template, "templateName:" || $header, "templateUri:" || $uri, "current-page:" || $uri, "site:" || $site, "site-context:" || $site, "siteUriContext:" || $site-properties/site-context, "pageId:" || $id, 'requiredFields:' || $template-name/@required-fields, 'removedFields:' || $template-name/@removed-fields, 'addedFields:' || $template-name/@added-fields )
    let $ice-link as element()? := af:renderICE($lang, (), $header, $uri, (), 'pageBuilder', fn:true(), $formVars, ())//a[fn:contains(@class, "ldse-icon-ko-add")]
    let $pagination := af:buildPages($lang, $site, $id, $articlesTotal, $pageCount, $end, $pubType)
    return (
        <section class="management-header form">
            <form class="ldse-form" name="search" method="GET" action="{ $admin-prefix }">
                {
                    buildSearchForm($lang, $site, $id),
                    buildArticleFilters($lang, $site, $id, $pages)
                }
                <input type="hidden" name="lang" value="{$lang}"/>
                <input type="hidden" name="site" value="{$site}"/>
                <input type="hidden" name="id" value="{$id}"/>
                <input type="hidden" name="pageId" value="{$template}"/>
            </form>
        </section>,
        $pagination,
        af:buildResults($lang, $site, $id, $articlesTotal, $pageCount, $end),
        <h2 class="node-title">
            {
                $header,
                if ( fn:not($onlyOne) or ($onlyOne and fn:empty($pages)) ) then (
                    <a type="button" class="actionButton primaryButton ldse-responsive">{$ice-link/@* except $ice-link/@class}<span class="ldse-secondary ldse-icon-ko-add"  datatest-id="createpage"></span></a>
                ) else ()
            }
        </h2>,
        <ul class="nodeContainer">{
            af:buildPage($pages, $id)
        }</ul>,
        $pagination
    )
};

declare function af:buildArticleContentPage(
    $lang as xs:string,
    $articles as element()*,
    $articlesTotal as xs:integer,
    $page as xs:string,
    $site as xs:string?,
    $header as xs:string,
    $nodeName as xs:string,
    $formName as xs:string,
    $id as xs:string,
    $formVars as xs:string*,
    $onlyOne as xs:boolean,
    $pubType as xs:string?
) as element()+ {
    af:buildArticleContentPage($lang, $articles, $articlesTotal, $page, $site, $header, $nodeName, $formName, $id, $formVars, $onlyOne, $pubType, ())
};

declare function af:buildArticleContentPage(
    $lang as xs:string,
    $articles as element()*,
    $articlesTotal as xs:integer,
    $page as xs:string,
    $site as xs:string?,
    $header as xs:string,
    $nodeName as xs:string,
    $formName as xs:string,
    $id as xs:string,
    $formVars as xs:string*,
    $onlyOne as xs:boolean,
    $pubType as xs:string?,
    $template as xs:string?
) as element()+ {
    let $resultCount as xs:int := fn:count($articles)
    let $pageCount as xs:int := fn:ceiling($articlesTotal div $pageSize)

    let $end as xs:int :=
        let $calculated as xs:int := $start + ($pageSize - 1)
        let $addend as xs:int := (if ($calculated gt $resultCount) then ($resultCount) else ($calculated)) - 1
        return (
            $start + $addend
        )
    let $pagination := af:buildPages($lang, $site, $id, $articlesTotal, $pageCount, $end, $pubType)

    return (
        <section class="management-header form">
            <form class="ldse-form" name="search" method="GET" action="{$settings:shared-prefix}/content-admin?lang={$lang}&amp;id={$id}">
                {
                    af:buildSearchForm($lang, $site, $id),
                    if ($formName eq 'site-creator') then( af:buildSiteFilters($id, $articles) ) else( af:buildArticleFilters($lang, $site, $id, $articles) )
                }
                <input type="hidden" name="lang" value="{$lang}"/>
                <input type="hidden" name="site" value="{$site}"/>
                <input type="hidden" name="id" value="{$id}"/>
                <input type="hidden" name="type" value="{$searchTypes}"/>
            </form>
        </section>,
        $pagination,
        af:buildResults($lang, $site, $id, $articlesTotal, $pageCount, $end),
        af:buildNodes($lang, $page, $articles, (), $header, $nodeName, $formName, $formVars, $onlyOne, fn:false(), (), $template, (), ()),
        $pagination
    )
};

declare function af:buildResults(
    $lang as xs:string,
    $site as xs:string?,
    $formId as xs:string,
    $totalCount as xs:integer,
    $pageCount as xs:integer,
    $end as xs:integer
) as element(h2) {
    <h2>
        {
            if ($totalCount gt 0) then (
                'Showing ' || $start || ' to ' || $end || ' of ' || $totalCount || ' Results'
            ) else (
                'No Results'
            )
        }
    </h2>
};

declare function af:buildPages(
    $lang as xs:string,
    $site as xs:string?,
    $formId as xs:string,
    $totalCount as xs:integer,
    $pageCount as xs:integer,
    $end as xs:integer,
    $pubType as xs:string?
) as element(section)* {
    let $pub-type as xs:string? :=
        if ( fn:exists($pubType) ) then (
            '&amp;pub-type=' || $pubType
        ) else ()
    return (
        <section class="management-header pages">
            {
                if ( $pageCount > 1 ) then (
                    for $i in (1 to $pageCount)
                    return (
                        element a {
                            attribute class {
                                fn:concat('page-link', if ($i eq $currentPage) then ('-active selected') else ())
                            },
                            attribute href {$admin-prefix || '?lang=' || $lang || '&amp;site=' || $site || '&amp;id=' || $formId || '&amp;term=' || $term || '&amp;component-search=' || $componentSearch|| '&amp;sort-author=' || $sortAuthor || '&amp;type=' || $searchTypes || '&amp;sort-type=' || $sortType || '&amp;sort-dir=' || $sortDirection || '&amp;page=' || $i || $pub-type},
                            $i
                        }
                    )
                ) else ()
            }
        </section>
    )
};

declare function af:buildSearchForm($lang, $site, $formId)
{
    <input type="text" class="gutter override-width" name="term" value="{ $term }" placeholder="Search..."/>,
    <input type="submit" class="between" value="Search"/>,
    <br/>
};

declare function af:renderReferencedDocumentNodes(
    $item as element(),
    $lang as xs:string,
    $uri as xs:string*,
    $parent-id as xs:string?
) as element(li)* {
    for $reference as xs:string in $item//node()[@is-reference eq 'true']
    let $ref-parent-id as xs:string? := $item/ldse:ldse-meta/ldse:document/@id/fn:string()
    let $doc as element()? := if($reference) then cf:getContentById($reference) else ()
    let $formName as xs:string? := $doc/ldse:ldse-meta/ldse:form-options/ldse:form/xs:string(.)
    let $form as element(ldse:formTemplate)? := ($FORMS[@name eq $formName])[1]
    let $location as xs:string? := $doc/@location
    let $site as xs:string? := xdmp:get-request-field('site')
    let $iceVars := (fn:concat('location:', $location), fn:concat("type:", $formName), fn:concat("current-page:", $uri), fn:concat("site-context:", $site), "siteUriContext:" || $site-properties/site-context)
    let $type as xs:string :=
        switch ( fn:local-name($doc) )
        case 'media-figure' return 'media'
        case 'teaser' return 'tile'
        default return 'text'
    return (
        af:renderNodes($lang, $doc, (), $form/ldse:title/xs:string(.), $iceVars, $type, $parent-id, $ref-parent-id)
    )
};

declare function af:buildArticleFilters(
    $lang as xs:string,
    $site as xs:string?,
    $formId as xs:string?,
    $articles as element()*
) as element(select)* {
    let $filter as element()* := $core:siteProperties/filters[@type = $searchTypes]/filter
    let $authors := af:get-authors-display-name($formId, $site, $lang)
    let $component-list := functx:distinct-deep
                            (
                                for $component in cf:getTemplateById($formId)/region/*
                                order by $component/@title
                                return element component {attribute name{fn:node-name($component)},
                                                          attribute value{$component/@content-type}} )
    return (
        if ( fn:exists($filter) ) then (
            xdmp:apply(xdmp:function(fn:QName($filter/@ns, $filter/@name), $filter/@path), $searchTypes, $articles)
        ) else (),
        <select class="select override-width gutter ldse-select-override" name="sort-type" onchange="this.form.submit()">
            {
                element option {
                    attribute value { "date" },
                    if ( $sortType = "date" ) then (
                        attribute selected { "selected" }
                    ) else (),
                    "Sort Last Modified"
                },
                element option {
                    attribute value { "alphabetic" },
                    if ( $sortType = "alphabetic" ) then (
                        attribute selected { "selected" }
                    ) else (),
                    "Sort Title Alphabetically"
                }
            }
        </select>,
        <select class="select override-width gutter ldse-select-override" name="sort-dir" onchange="this.form.submit()">
            {
                element option {
                    attribute value { "ascending" },
                    if ( $sortDirection = "ascending" ) then (
                        attribute selected { "selected" }
                    ) else (),
                    "ascending"
                },
                element option {
                    attribute value { "descending" },
                    if ( $sortDirection = "descending" ) then (
                        attribute selected { "selected" }
                    ) else (),
                    "descending"
                }
            }
        </select>,
        <select class="select override-width gutter ldse-select-override" name="sort-author" onchange="this.form.submit()">
            {
                element option {
                    attribute value { "all" },
                    "Modified By All"
                },
                for $author in $authors
                return
                    element option {
                        attribute value { $author },
                        if ( $sortAuthor = $author ) then (
                            attribute selected { "selected" }
                        ) else (),
                        $author
                    }
            }
        </select>,
        <select class="select override-width gutter ldse-select-override" name="component-search" onchange="this.form.submit()">
            {
                element option {
                    attribute value { "all" },
                    "Search by First Level Component"
                },
                for $component in $component-list
                return
                    element option {
                        attribute value { fn:string($component/@value) },
                        if ( fn:string($component/@value) eq $componentSearch ) then (
                            attribute selected { "selected" }
                        ) else (),
                        fn:string($component/@name)
                    }
            }
        </select>
            )
};

declare function af:buildSiteFilters(
    $formId as xs:string?,
    $articles as element()*
) as element(select)* {
    let $filter as element()* := $core:siteProperties/filters[@type = $searchTypes]/filter
    let $languages := cf:getAllSupportedLanguages()
    return (
        if ( fn:exists($filter) ) then (
            xdmp:apply(xdmp:function(fn:QName($filter/@ns, $filter/@name), $filter/@path), $searchTypes, $articles)
        ) else (),
        <select class="select override-width gutter ldse-select-override" name="sort-type" onchange="this.form.submit()">
            {
                element option {
                    attribute value { "date" },
                    if ( $sortType = "date" ) then (
                        attribute selected { "selected" }
                    ) else (),
                    "Sort Last Modified"
                },
                element option {
                    attribute value { "alphabetic" },
                    if ( $sortType = "alphabetic" ) then (
                        attribute selected { "selected" }
                    ) else (),
                    "Sort Title Alphabetically"
                }
            }
        </select>,
        <select class="select override-width gutter ldse-select-override" name="sort-dir" onchange="this.form.submit()">
            {
                element option {
                    attribute value { "ascending" },
                    if ( $sortDirection = "ascending" ) then (
                        attribute selected { "selected" }
                    ) else (),
                    "ascending"
                },
                element option {
                    attribute value { "descending" },
                    if ( $sortDirection = "descending" ) then (
                        attribute selected { "selected" }
                    ) else (),
                    "descending"
                }
            }
        </select>,
        <select class="select override-width gutter ldse-select-override" name="language-search" onchange="this.form.submit()">
            {
                element option{
                    attribute value { '' },
                    "All Languages"
                },
                for $language in $languages/name
                return
                    element option {
                    attribute value { $language/@locale },
                    if ( $language/@locale eq $languageSearch ) then (
                        attribute selected { "selected" }
                    ) else (),
                        fn:string($language/fn:string())
                    }
            }
        </select>
    )
};

declare function af:page-builder-redirect(
    $origFile as element()?,
    $newXml as element(),
    $form as element(ldse:formTemplate)
) as xs:string {
    fn:concat($settings:shared-prefix, '/content-admin?lang=', $lang, '&amp;id=', $newXml/ldse:ldse-meta/ldse:form-options/ldse:pageId, '&amp;uri=', $newXml/@uri, '&amp;site=', $newXml/uri-definition/site-context)
};

declare function af:page-builder-contexts(
    $value as item()?
) as element(option)* {
    for $uriContext as element(site) in $sites
    return (
        <option value="{$uriContext/@value}">{
            if ( $uriContext/xs:string(.) = $value) then (
                attribute selected {'true'}
            ) else (),
            $uriContext
        }</option>
    )
};

declare function af:check-categories(
    $origFile as element()?,
    $newXml as element(),
    $form as element(ldse:formTemplate)
) as element() {
    let $update-category :=
        if($newXml/category-name != $origFile/category-name) then (
            let $id as xs:string := $newXml/@id
            return (
                if ( $newXml/category-name ne $origFile/category-name ) then (
                    let $articles as element()* := cf:get-category-content($id)
                    return replace-category($articles, $newXml, $id, fn:false())
                ) else ()
            )
        ) else()
    let $updatesub-categories :=
        for $subCat as element(sub-category) in $newXml/sub-categories/sub-category
        let $id as xs:string := $subCat/@id
        return (
            if ( $subCat/sub-category-name ne $origFile/sub-categories/sub-category[@id = $id]/sub-category-name ) then (
                let $articles := cf:get-category-content($id)
                return replace-category($articles, $subCat, $id, fn:true())
            ) else ()
        )
    return ($newXml)
};

declare function af:replace-category(
    $articles as element()*,
    $category as element(),
    $id as xs:string,
    $isSub as xs:boolean
) as item()* {
    for $article as element() in $articles
    return (
        if($isSub) then (
            let $newName as element(sub-category-name) := element sub-category-name {$category/sub-category-name/fn:string()}
            return (
                xdmp:node-replace($article/categories/category/sub-categories/sub-category[@id = $id]/sub-category-name, $newName)
            )
        ) else (
            let $newName as element(category-name) := element category-name {$category/category-name/fn:string()}
            return (
                xdmp:node-replace($article/categories/category[@id = $id]/category-name, $newName)
            )
        )
    )
};

declare function af:update-custom-page(
    $locale as xs:string,
    $uri as xs:string,
    $ids as xs:string*,
    $site as xs:string
) as item()* {
    let $item as element()? := cf:get-content-with-uri($locale, $uri, ( 'preview', 'unpublish' ), $site)
    where fn:exists($item)
    return (
        let $new-item as element()? :=
            element { fn:name($item) } {
                $item/@*,
                $item/* except $item/content,
                element content {
                    $item/content/@*,
                    for $id as xs:string in $ids
                    return (
                        ( $item/content/element()[. = $id] )[1]
                    )
                }
            }
        let $new-item-date-updated := mem:node-replace($new-item/ldse:ldse-meta/ldse:last-modified/@date, attribute date { fn:current-dateTime() })
        let $new-item-user-updated := mem:node-replace($new-item-date-updated/ldse:ldse-meta/ldse:last-modified/@username, attribute username { $username })
        let $replace-document := document:document-replace($item, $new-item-user-updated)
        return (
            xdmp:set-response-code(200,"success")
        )
    )
};

declare function af:clone-component ($locale as xs:string, $uri as xs:string, $id as xs:string, $path as xs:string, $newid as xs:string?, $wrapper-id as xs:string, $template as xs:string) as item()* {
    let $content as element() := cf:get-content-by-id($id, ( 'preview', 'unpublish' ))
    let $childComponents as element()* := $content//*[@is-reference eq 'true']/..
    let $childComponentsMap as map:map := map:map()
    let $dataMap as map:map := map:map()
    let $put as empty-sequence() := map:put($dataMap, $id, $content)
    let $newComponents as element()* := for $group in $childComponents
                                        return element {fn:node-name($group)} { $group/@*,
                                            for $child in $group/*
                                            let $id as element()* := $child[@is-reference eq 'true']
                                            let $newId as xs:string := dynamicForms:newId($locale)
                                            let $add as empty-sequence():= map:put($childComponentsMap, $id,  $newId)
                                            let $newElement as element()* := functx:replace-element-values($id, $newId)
                                            return $newElement }
    let $updateContent as empty-sequence()  := for $i in $newComponents
                                                let $getContent as element() := root(map:get($dataMap, $id))/node()
                                                let $nodeName as xs:string := xs:string(fn:node-name($i))
                                                let $oldContent := (functx:dynamic-path($getContent, $nodeName), $getContent//*[local-name() = $nodeName])[1]
                                                let $newContent as node() := mem:node-replace($oldContent, $i)
                                                return map:put($dataMap, $id, $newContent)
    let $updatedContent as element()? := root(map:get($dataMap, $id))/node()
    let $username as xs:string? := ac:getUserName()
    let $userId as xs:string? := ac:getPersonId()
    return
        let $clone-node as item()* :=
            if ($updatedContent) then (
                let $new-id as xs:string := if ($newid) then $newid else dynamicForms:newId($locale)
                let $form-options as element(form-options)? := ldsemeta:get-form-options($updatedContent)
                let $form-name as xs:string? := $form-options/form/fn:string(.)
                let $clone-content as element() := element {$form-name} {
                                                        $updatedContent/@* except ($updatedContent/@id, $updatedContent/@uri),
                                                        attribute id {$new-id},
                                                        attribute uri{$uri},
                                                        <ldse:ldse-meta its:translate="no" xmlns="http://lds.org/code/lds-edit"  xmlns:its="http://www.w3.org/2005/11/its">
                                                            <ldse:document>
                                                                {
                                                                 attribute id {$new-id},
                                                                 attribute uri {$uri},
                                                                 $content/ldse:ldse-meta/ldse:document/@*
                                                                    except ($content/ldse:ldse-meta/ldse:document/@id,
                                                                            $content/ldse:ldse-meta/ldse:document/@uri)
                                                                }
                                                            </ldse:document>
                                                            <ldse:created date="{fn:current-dateTime()}" userid="{$userId}" username="{$username}"/>
                                                            <ldse:last-modified date="{fn:current-dateTime()}" userid="{$userId}" username="{$username}"/>
                                                            <ldse:sensitive>
                                                                {
                                                                 attribute username {$username},
                                                                 attribute userid {$userId},
                                                                 attribute last-changed {fn:current-dateTime()},
                                                                 $updatedContent/ldse:ldse-meta/ldse:sensitive/@*
                                                                    except ($updatedContent/ldse:ldse-meta/ldse:sensitive/@username,
                                                                            $updatedContent/ldse:ldse-meta/ldse:sensitive/@userid,
                                                                            $updatedContent/ldse:ldse-meta/ldse:sensitive/@last-changed)
                                                                 }
                                                            </ldse:sensitive>
                                                            {$updatedContent/ldse:ldse-meta/*
                                                                except ($updatedContent/ldse:ldse-meta/ldse:document,
                                                                        $updatedContent/ldse:ldse-meta/ldse:created,
                                                                        $updatedContent/ldse:ldse-meta/ldse:last-modified,
                                                                        $updatedContent/ldse:ldse-meta/ldse:publish-date,
                                                                        $updatedContent/ldse:ldse-meta/ldse:unpublish-date,
                                                                        $updatedContent/ldse:ldse-meta/ldse:sensitive,
                                                                        $updatedContent/ldse:ldse-meta/ldse:translation-event)}
                                                            </ldse:ldse-meta>,
                                                         $updatedContent/* except ($updatedContent/ldse:ldse-meta)
                                                        }
                let $clone-content as element()? := if ($clone-content/ldse:ldse-meta/ldse:form-options/ldse:current-page) then
                                                       mem:node-replace($clone-content/ldse:ldse-meta/ldse:form-options/ldse:current-page, <ldse:current-page xmlns="http://lds.org/code/lds-edit">{$uri}</ldse:current-page>)
                                                   else $clone-content
                let $clone-content as element()? := if ($clone-content/ldse:ldse-meta/ldse:form-options/ldse:wrapper-id) then
                                                        mem:node-replace($clone-content/ldse:ldse-meta/ldse:form-options/ldse:wrapper-id, <ldse:wrapper-id xmlns="http://lds.org/code/lds-edit">{$wrapper-id}</ldse:wrapper-id>)
                                                    else $clone-content
                let $clone-content as element()? := if ($clone-content/ldse:ldse-meta/ldse:form-options/ldse:templateName) then
                                                        mem:node-replace($clone-content/ldse:ldse-meta/ldse:form-options/ldse:templateName, <ldse:templateName xmlns="http://lds.org/code/lds-edit">{$template}</ldse:templateName>)
                                                    else $clone-content
                let $new-uri as xs:string := fn:concat($path,'/',$form-name,'/',$form-name,'-',$new-id,".xml")
                let $insertClone as item()? := xdmp:document-insert($new-uri,$clone-content)
                let $childKeys as xs:string* := map:keys($childComponentsMap)
                let $processChildren as item()* := for $i in $childKeys
                                                        let $newid as xs:string := map:get($childComponentsMap, $i)
                                                        return af:clone-component ($locale, $uri, $i, $path, $newid, $wrapper-id, $template)  (::::::::clone nested components::::::::)
                return ($new-id, $clone-content)
            ) else ()

    return $clone-node
};

declare function af:add-to-custom-page(
    $locale as xs:string,
    $uri as xs:string,
    $id as xs:string,
    $clone as xs:string?,
    $region as xs:string?,
    $site as xs:string?
) as item()* {
    let $page as element()? := cf:get-custom-page-with-uri-lang-site($uri, $locale, $site)
    let $templateId as xs:string := $page/ldse:ldse-meta/ldse:form-options/ldse:templateId/fn:string()
    let $wrapper-id as xs:string := $page/@id/fn:string()
    let $file-uri as xs:string :=  fn:substring-before($page/base-uri(),'/page')
    let $content as element() := cf:get-content-by-id($id, ( 'preview', 'unpublish' ))
    let $clone-node as item()* := if ( fn:exists($clone) and fn:not($clone = '') ) then ( af:clone-component($locale, $uri, $id, $file-uri, (), $wrapper-id, $templateId) ) else ()
    let $id as xs:string := if ( fn:exists($clone-node) and fn:not($clone-node = '') ) then ( ($clone-node)[1] ) else $id
    let $content as element()* := if ( fn:exists($clone-node) and fn:not($clone-node = '') ) then ( ($clone-node)[2] ) else $content
    let $new-page as element() :=
        if ( fn:exists($page/contents) ) then (
            mem:node-insert-child($page/contents, element { fn:local-name($content) } { if ( fn:exists($region) ) then ( attribute region { $region } ) else (), $id })/*
        ) else ( mem:node-insert-child($page/content, element { fn:local-name($content) } { if ( fn:exists($region) ) then ( attribute region { $region } ) else (), $id })/* )
    let $new-page := mem:node-replace($new-page/ldse:ldse-meta/ldse:last-modified/@date, attribute date { fn:current-dateTime() })/*
    where fn:exists($page)
    return core:document-replace($page, $new-page)
};

declare function af:build-asset-collection-list(
    $lang as xs:string,
    $site as xs:string,
    $asset-id as xs:string?
) as element(tr)* {
    let $collections as element()* := cf:get-collections-by-asset-id-in-language($lang, $site, $asset-id)
    return (
        af:get-asset-collection-information($collections)
    )
};

declare function af:build-asset-list(
    $lang as xs:string,
    $site as xs:string
) as element(tr)* {
    let $collection-items as element()* := ( cf:get-collections-in-language($lang, $site, (), ( 'preview', 'unpublish' )), cf:get-items-from-collections($site) )/items/element()
    for $collection-item as element() in af:get-unique-assets($collection-items)
    return (
        <tr>
            <td>
                <a href="/cms/content-admin/collection-management?lang={ $lang }&amp;site={ $site }&amp;asset-id={ $collection-item/xs:string(.) }">{ $collection-item/xs:string(.) }</a>
            </td>
            <td>{ $collection-item/@title/xs:string(.) }</td>
            <td>{ $collection-item/@type/xs:string(.) }</td>
        </tr>
    )
};

declare function af:get-unique-assets(
    $collection-items as element()*
) as element()* {
    let $map as map:map := map:map()
    for $item as element() in $collection-items
    where fn:empty(map:get($map, $item/xs:string(.)))
    return (
        $item, map:put($map, $item/xs:string(.), $item/xs:string(.))
    )
};

declare function af:get-asset-collection-information(
    $collections as element()*
) {
    for $collection as element() in $collections[@status != 'publish']
    let $collection-id as xs:string := $collection/@id
    return (
        <tr>
            <td>{ <input type="checkbox" class="collection-checkbox" value="{ $collection/@id/xs:string(.) }" /> }</td>
            <td>{ $collection/title/xs:string(.) }</td>
            <td>{ $collection/@id/xs:string(.) }</td>
            <td>{
                if ( $collection-id = $collections[@status = 'publish']/@id ) then (
                    'publish'
                ) else ( 'preview' )
            }</td>
        </tr>
    )
};

declare function af:update-collection-asset(
    $lang as xs:string,
    $ids as xs:string*,
    $site as xs:string,
    $asset-id as xs:string,
    $status as xs:string
) {
    for $collection-id as xs:string in fn:distinct-values($ids)
    let $preview-collection as element() := cf:get-collections-in-language($lang, $site, $collection-id, ( 'preview', 'unpublish' ))
    let $published-collection as element()? := cf:get-collections-in-language($lang, $site, $collection-id, 'publish')
    return (
        switch ( $status )
        case 'publish' return (

            let $update-collection as element()? := af:update-publisher-collection($preview-collection, $published-collection, $asset-id)
            let $update-titan := tf:post-collection-to-titan((), $update-collection, (), 'ldse:publish')
            let $update-titan := af:update-collection-in-titan($collection-id, $asset-id)
            let $publish := af:publish-collection($preview-collection, $published-collection, $update-collection)
            return ()
        )
        case 'unpublish' return af:unpublish-asset($asset-id, $published-collection)
        case 'remove' return (
            af:unpublish-asset($asset-id, $published-collection),
            af:remove-asset($asset-id, $published-collection, $preview-collection)
        )
        default return ()
    ),

    object-node {
        'success': 'true'
    }
};

declare function af:unpublish-asset(
    $asset-id as xs:string,
    $published-collection as element()?
) {
    xdmp:node-delete($published-collection/element()/element()[. = $asset-id])
};

declare function af:remove-asset(
    $asset-id as xs:string,
    $published-collection as element()?,
    $preview-collection as element()?
) {
    xdmp:node-delete($preview-collection/element()/element()[. = $asset-id])
};

declare function af:update-collection-in-titan(
    $collection-id as xs:string,
    $asset-id as xs:string
) {
    tf:add-asset-to-collection($collection-id, $asset-id)
};

declare function af:update-publisher-collection(
    $preview-collection as element(),
    $published-collection as element()?,
    $asset-id as xs:string
) as element()? {
    if ( fn:exists($published-collection) ) then (
        let $existing as element()? := $published-collection/items/element()[. = $asset-id]
        return (
            if ( fn:empty($existing) ) then (
                af:add-item-to-published-collection($preview-collection, $published-collection, $asset-id)
            ) else ()
        )
    ) else (
        af:create-publish-collection-with-asset($preview-collection, $published-collection, $asset-id)
    )
};

declare function af:add-item-to-published-collection(
    $preview-collection as element(),
    $published-collection as element()?,
    $asset-id as xs:string
) as element() {
    let $preview-item as element() := $preview-collection/items/element()[. = $asset-id]
    let $new-item as element() :=
        element { fn:name($preview-item) } {
            $preview-item/@*,
            $preview-item/*,
            $preview-item/xs:string(.)
        }
    return util:get-root(mem:node-insert-child($published-collection/items, $new-item))
};

declare function af:create-publish-collection-with-asset(
    $preview-collection as element(),
    $published-collection as element()?,
    $asset-id as xs:string
) as element() {
    let $preview-collection as element() := util:get-root(mem:node-replace($preview-collection/ldse:ldse-meta/ldse:document/@status, attribute status { 'publish' }))
    return (
        element { fn:name($preview-collection) } {
            $preview-collection/@* except $preview-collection/@status,
            attribute status { 'publish' },
            $preview-collection/* except $preview-collection/items,
            element items {
                $preview-collection/items/@*,
                $preview-collection/items/element()[. = $asset-id]
            }
        }
    )
};

declare function af:publish-collection(
    $preview-collection as element(),
    $published-collection as element()?,
    $update-collection as element()
) {
    if ( fn:exists($published-collection) ) then (
        document:document-replace($published-collection, $update-collection)
    ) else (
        let $db-path as xs:string := util:clean-db-uri('/published/' || fn:substring-after(xdmp:node-uri($preview-collection), '/preview/'))
        return (
            document:document-insert($db-path, $update-collection)
        )
    )
};

(: Mark a component and all of its nested components to be ready for translation by using their ids :)
declare function af:mark-all-items(
    $status as xs:string?,
    $locale as xs:string?,
    $action as xs:string?,
    $site as xs:string?,
    $id as xs:string?
) as item()* {
    let $ids as xs:string* := af:findAllFilesUsedByPageSettings($id, $locale)
    let $idFile as element()? := ldsemeta:get-file-by($id, $locale, (), ())
    let $idUri as xs:string? := $idFile/ldse:ldse-meta/ldse:document/@uri/fn:string()
    let $exclude-referenced-components as xs:string? := if ($site) then
                                            cf:get-sub-site($site)/exclude-referenced-components/fn:string()
                                         else ()
    let $markAll as xs:string* := for $compId as xs:string in $ids
                                    let $compFile as element()? := ldsemeta:get-file-by($compId, $locale, (), ())
                                    return if ($compFile) then (
                                                if (($exclude-referenced-components eq '') or
                                                    (fn:empty($exclude-referenced-components)) or
                                                    ($exclude-referenced-components eq 'true' and $idUri eq $compFile/ldse:ldse-meta/ldse:document/@uri/fn:string())) then (
                                                        let $ldse-meta as element(ldse:ldse-meta) := $compFile/ldse:ldse-meta
                                                        let $new-meta as element(ldse:ldse-meta) := ldsemeta:translation-mark-ready($ldse-meta, ())
                                                        let $new-file as element() := mem:node-replace($compFile/ldse:ldse-meta, $new-meta)/*
                                                        let $process := core:document-replace($compFile, $new-file)
                                                        return $compId
                                                ) else ()
                                            ) else ()
    return (element mark-all-items {attribute marked {fn:count($markAll)}})
};

declare function af:findNestedComponents ($components as element()*, $locale as xs:string, $map as map:map) {

    for $i in $components
    let $childIds as xs:string* :=  try { fn:doc($i)//@is-reference/../fn:string(.) } catch ($e) {}
    let $childDoc as item()* :=  for $childId in $childIds
                                    let $doc := cts:search(//ldse:ldse-meta,
                                        cts:and-query((
                                        core:get-filter-query(),
                                        cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('id'), $childId, 'exact'),
                                        cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), $locale, 'exact')
                                        ))
                                    )
                                    let $element := if ($doc) then
                                                        let $result := element component {attribute id {$childId}, attribute uri {$doc/ldse:document/@uri}, $doc/fn:base-uri()}
                                                        let $add := map:put($map, $childId, $result)
                                                        return $result
                                                    else ()
                                    return if ($doc) then
                                                af:findNestedComponents($element, $locale, $map)
                                            else ()
    return $childDoc
};

declare function af:findAllFilesUsedByPageSettings ($id as xs:string, $locale as xs:string) as xs:string* {
    let $map := map:map()
    let $page as element()? :=  for $page in ldsemeta:get-file-by($id, $locale, (), ())
                                        let $result := element component {attribute id {$page/ldse:ldse-meta/ldse:document/@id}, attribute uri {$page/ldse:ldse-meta/ldse:document/@uri}, $page/fn:base-uri()}
                                        let $add := map:put($map, $page/ldse:ldse-meta/ldse:document/@id/fn:string(), $result)
                                        return $page
    let $primary-components as element()* := for $referenced-component in $page/content/*
                                                let $docId := $referenced-component/fn:string()
                                                let $doc := cts:search(//ldse:ldse-meta,
                                                                cts:and-query((
                                                                core:get-filter-query(),
                                                                cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('id'), $docId, 'exact'),
                                                                cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), $locale, 'exact')
                                                                ))
                                                             )
                                                return if ($doc) then
                                                            let $result := element component {attribute id {$docId}, attribute uri {$doc/ldse:document/@uri}, $doc/fn:base-uri()}
                                                            let $add := map:put($map, $docId, $result)
                                                            let $process := af:findNestedComponents($result, $locale, $map)
                                                            return $result
                                                       else ()

    return map:keys($map)
};

declare function af:getChildrenComponents ($id as xs:string, $locale as xs:string) as xs:string* {
    let $map := map:map()
    let $page as element()? :=  for $page in ldsemeta:get-file-by($id, $locale, (), ())
                                let $result := element component {attribute id {$page/ldse:ldse-meta/ldse:document/@id}, attribute uri {$page/ldse:ldse-meta/ldse:document/@uri}, $page/fn:base-uri()}
                                (: let $add := map:put($map, $page/ldse:ldse-meta/ldse:document/@id/fn:string(), $result) :)
                                return $result
    let $children-components := af:findNestedComponents($page, $locale, $map)
    return map:keys($map)
};

(: Returns the elements required to visualize wheter a component is a referenced component (external) or not
   parent-id is the custom-page being analized, while node is the component currently being build for display. :)
declare function af:refComponentMark($parent-id as xs:string?, $node as element(), $locale as xs:string) as element()? {
    if($parent-id and $node) then (
        let $parentFile as element()? := ldsemeta:get-file-by($parent-id, $locale, (), ())
        let $parent-uri as xs:string := $parentFile/ldse:ldse-meta/ldse:document/@uri/fn:string()
        let $node-uri as xs:string := $node/ldse:ldse-meta/ldse:document/@uri/fn:string()
        return
            if (fn:not($parent-uri eq $node-uri)) then (
                element is-referenced-component { attribute class {" component-external"},
                <span class="component-external-uri">Referenced from: {$node-uri}</span>}
            ) else ( )
    ) else ( )
};

(: Returns a sorted list of the display name of authors(content creators) of current content.
   Unassigned identifies those authors who aren't currently active, but whose
   content still remains active:)
declare function af:get-authors-display-name(
    $templateId as xs:string,
    $site as xs:string,
    $lang as xs:string
) as xs:string* {
    let $activeAuthors as element()* := af:get-active-contributors($templateId, $site, $lang, fn:false())
    let $activeAuthorsDisplayName as xs:string* :=
      for $name in $activeAuthors/ldse:contributor/ldse:name/@display/fn:string()
      order by $name
      return $name
    return
        if($activeAuthors/@unassigned) then ( ($activeAuthorsDisplayName, "Unassigned") ) else ( $activeAuthorsDisplayName )
};

(: Returns the username of an author(s) (content creator) display name.
   It will return a list of Unassigned authors when "Unassigned" is specified :)
declare function af:get-author-username(
    $templateId as xs:string,
    $site as xs:string,
    $lang as xs:string,
    $author as xs:string
) as xs:string* {
    if ($author eq "Unassigned") then (
        let $contributors := af:get-active-contributors($templateId, $site, $lang, fn:true())
        return
            for $contributor in $contributors
            return $contributor/contributor/fn:string()
    ) else (
        let $contributors := af:get-active-contributors($templateId, $site, $lang, fn:false())
        let $username := ($contributors/ldse:contributor/ldse:name[@display/fn:string() eq $author])[1]
        return
            if($username) then $username/fn:string() else ()
    )
};

(: Returns custom-page content contributors (authors)
   When activeAuthorsRequested is true, returns the list of active content creators.
   Otherwise (false) returns content creators no longer active bfunctions.xqyut with active content. :)
declare function af:get-active-contributors(
    $templateId as xs:string,
    $site as xs:string,
    $lang as xs:string,
    $activeAuthorsRequested as xs:boolean
) as element()* {
    (: contributors :)
    let $contributors as element()* := cts:search(/ldse:contributor,
                                            cts:or-query((
                                                cts:element-attribute-value-query(xs:QName("ldse:role"), xs:QName("name"), 'publisher', "exact"),
                                                cts:element-attribute-value-query(xs:QName("ldse:role"), xs:QName("name"), 'super', "exact")
                                            ))
                                        )
    let $activeAuthorsUnfiltered as element(custom-page)* := cf:get-custom-page-by-template-id-and-lang($templateId, $site, $lang)
    (: current content creators :)
    let $activeAuthorsFiltered as xs:string* := fn:distinct-values($activeAuthorsUnfiltered/ldse:ldse-meta/ldse:last-modified/@username/fn:string())
    let $activeAuthors as element()* := ($contributors[ldse:name/fn:string() eq $activeAuthorsFiltered])
    return
        if ($activeAuthorsRequested) then (
            let $activeMap := map:map()
            let $fillingMap := for $authorName in $activeAuthors/ldse:name/fn:string()
                               return map:put($activeMap, $authorName, fn:true())
            let $unassignedContributors as element()*:=
                    for $unassignedName in $activeAuthorsFiltered
                    return
                        if(fn:not(map:get($activeMap, $unassignedName))) then element contributor {$unassignedName} else ()
            return
                element contributors { $unassignedContributors }
        ) else (
            if (fn:not(fn:count($activeAuthorsFiltered) eq fn:count($activeAuthors))) then (
                element contributors {
                    attribute unassigned {"true"},
                    $activeAuthors
                }
            ) else (
                element contributors { $activeAuthors }
            )
        )
};

declare function af:getPageStringBundles(
    $pageId as xs:string
) as element()*{
    let $page := (cts:search(/custom-page, cts:and-query((
              cts:element-attribute-value-query(xs:QName('custom-page'), xs:QName('id'), $pageId, 'exact'),
              cts:element-attribute-value-query(xs:QName('custom-page'), xs:QName('locale'), $lang, 'exact'),
              cts:element-value-query(xs:QName('ldse:site-context'), $site, 'exact') ))))
    let $components := for $i in $page/content/*
                       let $doc := (cts:search(/,
                                  cts:and-query((
                                   cts:directory-query('/preview/', 'infinity'),
                                   cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('id'), $i/fn:string(),'exact')
                                    ))
                                  ))
                       return $doc//ldse:form-options/ldse:form
    let $_bundles := for $c in $components
                       return /ldse:formTemplate[@name eq $c]/ldse:string-bundles/*
    let $bundles := fn:distinct-values($_bundles)
    let $bundles-links := for $s in $bundles
                          let $resource := (cts:search(/resources,
                              cts:and-query((
                                  cts:directory-query('/preview/', 'infinity'),
                                  cts:element-value-query(xs:QName('name'),xs:string($s), 'exact'),
                                  cts:element-attribute-value-query(xs:QName('resources'), xs:QName('site'), $site, 'exact'),
                                  cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), $lang, 'exact')
                               ))
                           ))
                          return
                            element bundle {
                                attribute name {xs:string($s)},
                                attribute href {fn:concat($settings:shared-prefix,'/string-manager/bundle-editor?lang=',$lang,'&amp;bundle=',$s,'&amp;locale=',$lang,'&amp;site=',$site)},
                                if(fn:not(fn:exists($resource))) then
                                    attribute missing {'true'}
                                else ()
                            }

    return
        if ( ac:has-permission('ldse:view-rice-admin', '', '', $site) ) then (
            element bundle-links { attribute admin {"true"}, $bundles-links}
        ) else (
            element bundle-links { $bundles-links }
        )

};

declare function af:findNestedEnabledComponents ($components as element()*, $locale as xs:string, $map as map:map) {

    for $i in $components
    let $childIds as xs:string* :=  try { fn:doc($i)//*[(@is-reference) and not(@disable)]/fn:string(.) } catch ($e) {}
    return
        for $childId in $childIds
        let $doc :=
            cts:search(//ldse:ldse-meta,
                cts:and-query((
                core:get-filter-query(),
                cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('id'), $childId, 'exact'),
                cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), $locale, 'exact')
                ))
            )
        let $element :=
            if ($doc) then
                let $result := element component {attribute id {$childId}, attribute uri {$doc/ldse:document/@uri}, $doc/fn:base-uri()}
                let $add := map:put($map, $childId, $result)
                return $result
            else ()
        return
            if ($doc) then
                af:findNestedEnabledComponents($element, $locale, $map)
            else ()
};

declare function af:findAllEnabledComponentsUsedByPageSettings ($id as xs:string, $locale as xs:string) as xs:string* {
    let $map := map:map()
    let $page as element()? :=
        for $page in ldsemeta:get-file-by($id, $locale, (), ())
        let $result := element component {attribute id {$page/ldse:ldse-meta/ldse:document/@id}, attribute uri {$page/ldse:ldse-meta/ldse:document/@uri}, $page/fn:base-uri()}
        let $add := map:put($map, $page/ldse:ldse-meta/ldse:document/@id/fn:string(), $result)
        return $page
    let $primary-components as element()* :=
        for $referenced-component in $page/content/*[not(@disable)]
        let $docId := $referenced-component/fn:string()
        let $doc :=
            cts:search(//ldse:ldse-meta,
                cts:and-query((
                core:get-filter-query(),
                cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('id'), $docId, 'exact'),
                cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), $locale, 'exact')
                ))
            )
        return
            if ($doc) then
                let $result := element component {attribute id {$docId}, attribute uri {$doc/ldse:document/@uri}, $doc/fn:base-uri()}
                let $add := map:put($map, $docId, $result)
                let $process := af:findNestedEnabledComponents($result, $locale, $map)
                return $result
            else ()

    return map:keys($map)
};


declare function af:duplicateComponent ($site as xs:string, $locale as xs:string, $uri as xs:string, $id as xs:string)
{
    let $content as element() := cf:get-content-by-id($id, ( 'preview', 'unpublish' ))
    let $locale := $content/@locale
    let $new-id as xs:string := dynamicForms:newId($locale)
    let $custom-page :=
        cts:search(/custom-page,
            cts:and-query((
            cts:directory-query('/preview/', 'infinity'),
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('uri'), $uri,'exact'),
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), $locale,'exact'),
            cts:element-value-query(xs:QName('ldse:site-context'), $site,'exact')
            )))
    let $template := $custom-page/ldse:ldse-meta/ldse:form-options/ldse:templateName/fn:string()
    let $wrapper-id := $custom-page/@id
    let $parent-doc as element()? :=
        if ($custom-page/content//*[. eq $id]) then
            $custom-page
        else
            let $pageFiles := af:findAllFilesUsedByPageSettings($custom-page/@id, $locale)
            return
                cts:search(fn:collection(),
                cts:and-query((
                cts:directory-query('/preview/', 'infinity'),
                cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('id'),$pageFiles,'exact'),
                cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), $locale,'exact'),
                cts:word-query($id, 'exact')
                )))/node()
    let $existing-and-new-node as element()* :=
        if (fn:name($parent-doc) eq 'custom-page') then
            let $existing := $parent-doc/content/*[ . eq $id]
            return ($existing, element {fn:name($existing)} {$existing/@region, attribute is-id {'true'}, $new-id})
        else
            let $existing := $parent-doc//*[@is-reference eq 'true' and . eq $id]
            return ($existing, element {fn:name($existing)} {$existing/@*, $new-id})
    let $path := substring-before($content/fn:base-uri(), '/'||fn:name($content))
    return (
            af:clone-component ($locale, $uri, $id, $path, $new-id, $wrapper-id, $template),
            xdmp:node-insert-after(($existing-and-new-node)[1], ($existing-and-new-node)[2])
            )
};



