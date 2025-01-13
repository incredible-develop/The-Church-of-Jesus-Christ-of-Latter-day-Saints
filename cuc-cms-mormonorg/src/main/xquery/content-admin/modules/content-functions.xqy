xquery version "1.0-ml";

module namespace cf = "http://lds.org/code/lds-edit/content-admin/content-functions";

import module namespace c = "http://lds.org/code/shared/common/common-functions" at "/shared/common/commonFunctions.xqy";
import module namespace ldseUtil = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../modules/utility-functions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../modules/ldse-core.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../modules/ldse-settings.xqy";
import module namespace json = "http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module namespace form = "http://lds.org/code/shared/lds-edit/dynamicForms" at "../../ice/modules/dynamicForms.xqy";
import module namespace af = "http://lds.org/code/lds-edit/content-admin/admin-functions" at "functions.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace its = "http://www.w3.org/2005/11/its";

declare variable $sel-temp as xs:string? := ldseUtil:escape-chars(xdmp:get-request-field('template'))[. != ""];
declare variable $lang as xs:string := ( ldseUtil:escape-chars(xdmp:get-request-field("lang")[1])[. != ""], 'eng' )[1];

declare function cf:get-file-by(
    $lang as xs:string*,
    $id as xs:string*,
    $uri as xs:string*,
    $site as xs:string?
) as element()* {
    cts:search(fn:collection(),
        cts:and-query((
            core:get-filter-query(),
            if ( fn:exists($lang) ) then (
                cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), $lang, 'exact')
            ) else (),
            if ( fn:exists($uri) ) then (
                cts:or-query((
                    cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('uri'), $uri, 'exact'),
                    cts:element-value-query(xs:QName("uri-path"), $uri, 'exact')
                ))
            ) else (),
            if ( fn:exists($id) ) then (
                cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('id'), $id, 'exact')
            ) else ()
        )),
        "unfiltered"
    )/*
};

declare function cf:get-components() as element(components)? {
    element components {cts:search(/components, ())/*}
};

declare function cf:get-content-by-id(
    $id as xs:string,
    $status as xs:string*
) as element()? {
    cts:search(fn:collection(),
        cts:and-query((
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('id'), $id, 'exact'),
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('status'), $status, 'exact')
        ))
    )/*
};

declare function cf:get-preview-content-by-id(
    $id as xs:string
) as element()? {
    cts:search(fn:collection(),
        cts:and-query((
            cts:directory-query('/preview/', 'infinity'),
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('id'), $id, 'exact')
        ))
    )/*
};

declare function cf:getDictionary(
    $lang as xs:string,
    $bundle as xs:string*
) as element(resources)* {
    cf:getDictionary($lang, $bundle, ())
};

declare function cf:getDictionary(
    $lang as xs:string,
    $bundle as xs:string*,
    $site as xs:string?
) as element(resources)* {
    cts:search(/resources,
        cts:and-query((
            core:get-filter-query(),
            if ( fn:exists($bundle[. ne '']) ) then (
                cts:element-value-query(xs:QName('name'), $bundle, 'exact')
            ) else (),
            cts:element-attribute-value-query(xs:QName('resources'), xs:QName('locale'), $lang, 'exact'),
            if ( fn:exists($site) ) then (
                cts:element-attribute-value-query(xs:QName('resources'), xs:QName('site'), $site, 'exact')
            ) else (),
            cts:not-query((
                cts:element-value-query(xs:QName('name'), 'helpText', 'exact'),
                cts:element-value-query(xs:QName('name'), 'titleKey', 'exact')
            ))
        ))
    )
};

declare function cf:getTemplateById(
    $id as xs:string?
) as element(template)* {
    cts:search(/template,
        cts:and-query((
            cts:element-attribute-value-query(xs:QName("template"), xs:QName("id"), $id, "exact")
        )),
        "unfiltered"
    )
};

declare function cf:getSiteHeader(
    $lang as xs:string?,
    $site as xs:string?
) as element(site-header)* {
    cts:search(/site-header,
        cts:and-query((
            core:get-filter-query(),
            if ( fn:exists($lang) ) then (
                cts:element-attribute-value-query(xs:QName("site-header"), xs:QName("locale"), $lang, "exact")
            ) else (),
            if ( fn:exists($site) ) then (
                cts:element-value-query(xs:QName("ldse:site-context"), $site, "exact")
            ) else ()
        )),
        "unfiltered"
    )
};

declare function cf:getCustomPages() as element(custom-page)* {
    cts:search(/custom-page,
        cts:and-query((
            core:get-filter-query(),
            if ( fn:exists($sel-temp) ) then (
                cts:element-value-query(xs:QName('template-id'), $sel-temp, 'exact')
            ) else ()
        )),
        'unfiltered'
    )
};

declare function cf:getPageTemplates() as element(template)* {
    cf:getPageTemplates(())
};

declare function cf:getPageTemplates($template as xs:string?) as element(template)* {
    cts:search(/template,
        cts:and-query((
            if ( $template ) then (
                cts:element-attribute-value-query(xs:QName("template"), xs:QName("id"), $template, "exact")
            ) else()
        )),
        'unfiltered'
    )
};

declare function cf:get-content(
    $template-id as xs:string?,
    $site as xs:string?
) as element()* {
    cts:search(fn:collection(),
        cts:and-query((
            core:get-filter-query(),
            if ( fn:exists($template-id) ) then (
                cts:element-value-query(xs:QName('template-id'), $template-id, 'exact')
            ) else (),
            if ( fn:exists($site) ) then (
                cts:element-value-query(xs:QName('ldse:site-context'), $site, 'exact')
            ) else (),
            (:            cts:element-value-query(xs:QName('ldse:pageId'), $pageId, 'exact'), :)
            cts:element-query(xs:QName('ldse:ldse-meta'), cts:and-query( () ) )
        )),
        "unfiltered"
    )/*
};

declare function cf:get-custom-page-by-uri(
    $uri as xs:string,
    $site as xs:string
) as element()* {
    cts:search(/custom-page,
        cts:and-query((
            core:get-filter-query(),
            cts:or-query((
                cts:element-attribute-value-query(xs:QName('custom-page'), xs:QName('uri'), $uri, 'exact'),
                cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('uri'), $uri, 'exact')
            )),
            cts:element-value-query(xs:QName('ldse:site-context'), $site, 'exact'),
            cts:element-attribute-value-query(xs:QName('custom-page'), xs:QName('locale'), $lang, 'exact')
        ))
    )
};

declare function cf:get-content-by(
    $uri as xs:string,
    $lang as xs:string,
    $site as xs:string,
    $type as xs:string
) as element()* {
    cts:search(fn:collection(),
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('uri'), $uri, 'exact'),
            cts:element-value-query(xs:QName('ldse:site-context'), $site, 'exact'),
            cts:element-attribute-value-query(xs:QName('custom-page'), xs:QName('locale'), $lang, 'exact'),
            cts:element-value-query(xs:QName('ldse:form'), $type, 'exact')
        ))
    )/*
};

declare function cf:get-custom-page-by(
    $temp-id as xs:string,
    $site as xs:string?,
    $pageId as xs:string
) as element()* {
    cts:search(/custom-page,
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-value-query(xs:QName('custom-page'), xs:QName('locale'), $lang, 'exact'),
            if ( fn:exists($site) ) then (
                cts:element-value-query(xs:QName('ldse:site-context'), $site, 'exact')
            ) else (),
            cts:element-value-query(xs:QName('template-id'), $temp-id, 'exact'),
            cts:element-value-query(xs:QName('ldse:pageId'), $pageId, 'exact')
        ))
    )
};

declare function cf:get-content-by-uri-type(
    $uri as xs:string,
    $type as xs:string,
    $location as xs:string?,
    $admin-location as xs:string?
) as element()* {
    cts:search(/*,
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('uri'), $uri, 'exact'),
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), $lang, 'exact'),
            cts:element-value-query(xs:QName('ldse:form'), $type, 'exact'),
            if ( fn:exists($location) ) then (
                cts:element-value-query(xs:QName('ldse:location'), $location, 'exact')
            ) else (),
            if ( fn:exists($admin-location) ) then (
                cts:element-value-query(xs:QName('ldse:admin-location'), $admin-location, 'exact')
            ) else ()
        )),
        "unfiltered"
    )
};

declare function cf:get-content-by-uri(
    $uri as xs:string,
    $type as xs:string
) as element()* {
    cts:search(fn:collection(),
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('uri'), $uri, 'exact'),
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), $lang, 'exact'),
            cts:element-value-query(xs:QName('ldse:form'), $type, 'exact')
        )),
        "unfiltered"
    )/*
};

declare function cf:get-content-with-uri(
    $lang as xs:string,
    $uri as xs:string*
) {
    cts:search(fn:collection(),
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('uri'), $uri, 'exact'),
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), $lang, 'exact'),
            cts:element-query(xs:QName('ldse:templateId'), cts:and-query(()))
        ))
    )/*
};

declare function cf:get-content-with-uri(
    $lang as xs:string,
    $uri as xs:string*,
    $status as xs:string
) as element()* {
    cf:get-content-with-uri($lang, $uri, $status, ())
};

declare function cf:get-content-with-uri(
    $lang as xs:string,
    $uri as xs:string*,
    $status as xs:string*,
    $site as xs:string*
) as element()* {
    cts:search(fn:collection(),
        cts:and-query((
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('uri'), $uri, 'exact'),
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), $lang, 'exact'),
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('status'), $status, 'exact'),
            cts:element-query(xs:QName('ldse:templateId'), cts:and-query(())),
            if ( fn:exists($site) ) then (
                cts:element-value-query(xs:QName('ldse:site-context'), $site, 'exact')
            ) else ()
        ))
    )/*
};

declare function cf:get-custom-page-with-uri-lang-site(
    $uri as xs:string*,
    $lang as xs:string,
    $site as xs:string
) {
    cts:search(/custom-page,
        cts:and-query((
            cts:directory-query('/preview/', 'infinity'),
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('uri'), $uri, 'exact'),
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), $lang, 'exact'),
            cts:element-value-query(xs:QName('ldse:site-context'), $site, 'exact')
        ))
    )
};

declare function cf:get-custom-page-by-template-and-site(
    $template-id as xs:string?,
    $site as xs:string?
) as element()? {
    cts:search(/custom-page,
        cts:and-query((
            core:get-filter-query(),
            cts:element-value-query(xs:QName('ldse:templateId'), $template-id, 'exact'),
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), $lang, 'exact'),
            if ( fn:exists($site) ) then (
                cts:element-value-query(xs:QName('ldse:site-context'), $site, 'exact')
            ) else ()
        )),
        "unfiltered"
    )[1]
};

declare function cf:get-custom-page-items(
    $elementName as xs:string,
    $location as xs:string,
    $type as xs:string?,
    $uri as xs:string
) as element()* {
    let $items :=
        cts:search(/*,
            cts:and-query((
                core:get-filter-query(),
                cts:element-value-query(xs:QName('ldse:location'), $location, "exact"),
                cts:element-value-query(xs:QName('ldse:type'), $type, "exact"),
                cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName("locale"), $lang, "exact"),
                cts:element-attribute-value-query(xs:QName("ldse:document"), xs:QName("uri"), $uri, "exact")
            )),
            'unfiltered'
        )

    let $items :=
        if (fn:exists($items) and fn:exists($items/sequence)) then (
            for $item in $items
            let $sequence as xs:integer := (($item/sequence)[. castable as xs:integer], 0)[1]
            order by $sequence ascending
            return
                $item
        ) else ($items)

    return $items
};

declare function cf:getContentFromSearch(
    $searchResults as element(search:response)
) as element()* {
    for $xml in $searchResults/search:result/node()
    let $doc := document {$xml}/node()
    return (
        $doc
    )
};

declare function cf:getContent(
    $formName as xs:string,
    $site as xs:string?
) as element()* {
    cts:search(fn:collection(),
        cts:and-query((
            core:get-filter-query(),
            cts:element-value-query(xs:QName('ldse:form'), $formName, 'exact'),
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName("locale"), $lang, "exact"),
            cts:element-value-query(xs:QName("ldse:site-context"), $site, "exact")[fn:exists($site)]
        ))
    )/*
};

declare function cf:getPaginatedArticles(
    $lang as xs:string?,
    $id as xs:string?,
    $uriPath as xs:string*,
    $site as xs:string?,
    $start as xs:integer,
    $pageSize as xs:integer,
    $sortDirection as xs:string?
) as element(search:response) {
    cf:getPaginatedArticles((), $lang, $id, $uriPath, $site, (), (), $start, $pageSize, (), $sortDirection, (), ())
};

declare function cf:getPaginatedArticles(
    $lang as xs:string?,
    $id as xs:string?,
    $uriPath as xs:string*,
    $site as xs:string?,
    $filterNonNews as xs:boolean?,
    $start as xs:integer,
    $pageSize as xs:integer,
    $sortDirection as xs:string?
) as element(search:response) {
    cf:getPaginatedArticles((), $lang, $id, $uriPath, $site, $filterNonNews, (), $start, $pageSize, (), $sortDirection, (), ())
};

declare function cf:getPaginatedArticles(
    $term as xs:string?,
    $lang as xs:string?,
    $id as xs:string*,
    $uriPath as xs:string*,
    $site as xs:string?,
    $filterNonNews as xs:boolean?,
    $filterTypes as xs:string*,
    $start as xs:integer,
    $pageSize as xs:integer,
    $sortType as xs:string?,
    $sortDirection as xs:string?,
    $adminPage as element(page)?,
    $pub-type as xs:string?
) as element(search:response) {
    let $searchTags as xs:string* := if ($filterNonNews) then (cf:getNewsTags($lang)[(. = $filterTypes)[fn:exists($filterTypes)],fn:true()[fn:not(fn:exists($filterTypes))]]) else ($filterTypes[. ne ''])
    return (
        search:search(($term,'')[1], cf:buildArticleSearchOptions($lang, $id, $site, $uriPath, $searchTags, $sortType, $sortDirection, $adminPage, $pub-type), $start, $pageSize)
    )
};

declare function cf:getAllSupportedLanguages() as element(languages){
    let $allLanguages :=  for $i in cts:search(/languages,())/language
                          order by $i/englishName/text()
                          return element name {attribute locale {$i/@key}, $i/englishName/text()}
    let $supported := distinct-values(cts:search(/supportedLanguages, ())/language/@key)

    return
    <languages>
    {
        for $lang in $allLanguages
        return if (index-of($supported, $lang/@locale)) then $lang else ()
    }
    </languages>

};
declare function cf:getSitesThatSupportLanguage(
    $searchTags as xs:string
) as element(search:response){
    let $query :=
    <options xmlns="http://marklogic.com/appservices/search">
    <searchable-expression>/</searchable-expression>
    <additional-query>
      {
        cts:and-query((
          core:get-filter-query(),
          cts:element-query(xs:QName('supportedLanguages'),
                cts:element-attribute-value-query(xs:QName('language'), xs:QName("key") , $searchTags, "exact")[fn:exists($searchTags)]
          )
        ))
      }
    </additional-query>
    <search-option>unfiltered</search-option>
    <return-results>true</return-results>
    <transform-results apply="raw"/>
    <term>
      <empty apply="all-results"/>
      <term-option>case-insensitive</term-option>
      <term-option>diacritic-insensitive</term-option>
      <term-option>punctuation-insensitive</term-option>
      <term-option>whitespace-insensitive</term-option>
    </term>
  </options>

    return (
        if($searchTags ne '')
        then(
            search:search('', $query, 1, 50)
            )
        else()
    )
};

declare function cf:getNewsTags($lang as xs:string) as xs:string*{
    cts:search(/article-types,
        cts:and-query((
            core:get-filter-query(),
            cts:element-value-query(xs:QName("news-include"), "true", "exact"),
            cts:element-attribute-value-query(xs:QName("article-types"), xs:QName("locale"), $lang, "exact")
        ))
    )/types[./news-include eq 'true']/name/xs:string(.)
};

declare function cf:buildArticleSearchOptions(
    $lang as xs:string?,
    $id as xs:string?,
    $site as xs:string?,
    $uriPath as xs:string*,
    $searchTags as xs:string*,
    $sortType as xs:string?,
    $sortDirection as xs:string?,
    $adminPage as element(page)?,
    $pub-type as xs:string?
) as element(search:options) {
    let $rootElement as xs:string? := form:getFormTemplate($adminPage/@formName)/ldse:structure/element()/fn:local-name(.)
    return (
        <options xmlns="http://marklogic.com/appservices/search">
            <searchable-expression>/</searchable-expression>
            <additional-query>
                {
                    cts:and-query((
                        core:get-filter-query(),
                        cts:element-attribute-value-query(xs:QName($rootElement), xs:QName("id"), $id, "exact")[fn:exists($id)],
                        cts:element-value-query(xs:QName("uri-path"), $uriPath, "exact")[fn:exists($uriPath)],
                        if ( fn:exists($searchTags) and fn:not($searchTags = "") ) then (
                            cts:or-query((
                                cts:element-value-query(xs:QName("tag") , $searchTags, "exact")[fn:exists($searchTags)],
                                cts:element-attribute-value-query(xs:QName($rootElement), xs:QName("type") , $searchTags, "exact")[fn:exists($searchTags)],
                                cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName("type") , "sub-site?", "wildcarded")
                            ))
                        ) else (),
                        if ( fn:exists($pub-type) ) then (
                            cts:or-query((
                                cts:element-value-query(xs:QName('ldse:pub-type'), $pub-type, 'exact'),
                                cts:element-value-query(xs:QName('ldse:pubType'), $pub-type, 'exact')
                            ))
                        ) else ()
                    ))
                }
            </additional-query>
            <search-option>unfiltered</search-option>
            <return-results>true</return-results>
            <transform-results apply="raw"/>
            <term>
                <empty apply="all-results"/>
                <term-option>case-insensitive</term-option>
                <term-option>diacritic-insensitive</term-option>
                <term-option>punctuation-insensitive</term-option>
                <term-option>whitespace-insensitive</term-option>
                <term-option>lang={$lang}</term-option>
            </term>
            {
                let $sort as xs:string := ($sortDirection[. = ('asc', 'ascending')], 'descending')[1]
                return
                    if ( $sortType = 'date' ) then (
                        <sort-order type="xs:dateTime" direction="{$sort}">
                            <element ns="http://lds.org/code/lds-edit" name="last-modified" />
                            <attribute name="date" />
                        </sort-order>
                    ) else if ( $sortType = 'alphabetic' ) then (
                        <sort-order type="xs:string" direction="{ $sort }">
                            <element ns="http://lds.org/code/lds-edit" name="document" />
                            <attribute name="title" />
                        </sort-order>
                    ) else ()
            }
        </options>
    )
};

declare function getArticleTypes(
    $lang as xs:string
) as element(article-types)* {
    cts:search(/article-types,
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-value-query(xs:QName("article-types"), xs:QName("locale"), $lang, "exact")
        ))
    )
};

declare function cf:getFormTitle(
    $formName as xs:string
) as xs:string {
    let $form :=
        cts:search(/ldse:formTemplate,
            cts:and-query((
                core:get-filter-query(),
                cts:element-attribute-value-query(xs:QName('ldse:formTemplate'), xs:QName('name'), $formName, "exact")
            )),
            'unfiltered'
        )
    return (
        if ( fn:exists($form) and fn:exists($form/ldse:title) ) then (
            $form/ldse:title
        ) else ( '' )
    )
};

declare function cf:get-image-xml(
    $imagePath as xs:string?
) as element(binary-content)? {
    cts:search(/binary-content,
        cts:and-query((
            cts:element-value-query(xs:QName('path'), $imagePath, 'exact')
        ))
    )
};

declare function cf:get-category-content(
    $id as xs:string*
) as element()* {
    cts:search(/article,
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-value-query(xs:QName("ldse:document"), xs:QName("locale"), $lang, "exact"),
            cts:not-query((
                cts:element-attribute-value-query(xs:QName("ldse:document"), xs:QName("type"), "category", "exact"),
                cts:element-query(xs:QName('custom-page'), cts:and-query(( () )))
            )),
            if ( fn:exists($id) ) then (
                cts:element-value-query(xs:QName("category"), $id, 'exact')
            ) else ()
        ))
    )
};

declare function cf:get-subcategory-content(
    $id as xs:string*
) as element()* {
    cts:search(fn:collection(),
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-value-query(xs:QName("ldse:document"), xs:QName("locale"), $lang, "exact"),
            cts:not-query((
                cts:element-attribute-value-query(xs:QName("ldse:document"), xs:QName("type"), "category", "exact")
            )),
            if ( fn:exists($id) ) then (
                cts:element-attribute-value-query(xs:QName("subcategory"), xs:QName("id"), $id, 'exact')
            ) else ()
        ))
    )/*
};

declare function cf:get-tag-content(
    $id as xs:string*
) as element()* {
    cts:search(fn:collection(),
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-value-query(xs:QName("ldse:document"), xs:QName("locale"), $lang, "exact"),
            cts:not-query((
                cts:element-attribute-value-query(xs:QName("ldse:document"), xs:QName("type"), "category", "exact")
            )),
            if ( fn:exists($id) ) then (
                cts:element-attribute-value-query(xs:QName("tag"), xs:QName("id"), $id, 'exact')
            ) else ()
        ))
    )/*
};

declare function cf:get-subtag-content(
    $id as xs:string*
) as element()* {
    cts:search(fn:collection(),
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-value-query(xs:QName("ldse:document"), xs:QName("locale"), $lang, "exact"),
            cts:not-query((
                cts:element-attribute-value-query(xs:QName("ldse:document"), xs:QName("type"), "category", "exact")
            )),
            cts:element-attribute-value-query(xs:QName("sub-tag"), xs:QName("id"), $id, 'exact')
        ))
    )/*
};

declare function cf:get-categories(
    $uri as xs:string?
) {
    cts:search(/category,
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-value-query(xs:QName("ldse:document"), xs:QName("locale"), $lang, "exact"),
            cts:element-attribute-value-query(xs:QName("ldse:document"), xs:QName("type"), "category", "exact"),
            if ( fn:exists($uri) ) then (
                cts:element-attribute-value-query(xs:QName("ldse:document"), xs:QName("uri"), $uri, "exact")
            ) else ()
        ))
    )
};

declare function cf:get-tags(
    $uri as xs:string?
) {
    cts:search(/category,
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-value-query(xs:QName("ldse:document"), xs:QName("locale"), $lang, "exact"),
            cts:element-attribute-value-query(xs:QName("ldse:document"), xs:QName("type"), "category", "exact"),
            if ( fn:exists($uri) ) then (
                cts:element-attribute-value-query(xs:QName("ldse:document"), xs:QName("uri"), $uri, "exact")
            ) else ()
        ))
    )
};

declare function cf:getContentById(
    $id as xs:string
) as element()? {
    cts:search(fn:collection(),
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('id'), $id, 'exact')
        ))
    )/*
};

declare function cf:get-binary-content(
    $image-path as xs:string
) as element(binary-content)? {
    cts:search(/binary-content,
        cts:element-value-query(xs:QName('path'), $image-path, 'exact')
    )[1]
};

declare function cf:get-binary-content-by-folder(
    $image-path as xs:string
) as element(binary-content)? {
    cts:search(/binary-content,
        cts:element-value-query(xs:QName('folder'), $image-path, 'exact')
    )[1]
};

declare function cf:get-custom-page-by-template-id(
    $template-id as xs:string?,
    $site as xs:string
) as element(custom-page)* {
    cts:search(/custom-page,
        cts:and-query((
            core:get-filter-query(),
            cts:element-value-query(xs:QName('template-id'), $template-id, 'exact'),
            cts:element-value-query(xs:QName('site-context'), $site, 'exact')
        ))
    )
};

declare function cf:get-custom-page-by-template-id-and-lang(
    $template-id as xs:string?,
    $site as xs:string,
    $lang as xs:string
) as element(custom-page)* {
    cts:search(/custom-page,
        cts:and-query((
            core:get-filter-query(),
            cts:element-value-query(xs:QName('ldse:pageId'), $template-id, 'exact'),
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), $lang, 'exact'),
            cts:element-value-query(xs:QName('ldse:site-context'), $site, 'exact')
        ))
    )
};

declare function cf:get-custom-pages(
    $term as xs:string?,
    $templateId as xs:string,
    $pageId as xs:string,
    $site as xs:string,
    $uri as xs:string?,
    $lang as xs:string?,
    $start as xs:int?,
    $size as xs:int?,
    $sortDirection as xs:string?,
    $sortType as xs:string?,
    $sortAuthor as xs:string?,
    $componentSearch as xs:string?
) as element()* {
    search:search($term || '*', cf:get-custom-page-options($templateId, $pageId, $site, $uri, $lang, $sortDirection, $sortType, $sortAuthor, $componentSearch), $start, $size)
};

declare function cf:get-custom-page-options(
    $templateId as xs:string,
    $pageId as xs:string,
    $site as xs:string,
    $uri as xs:string?,
    $lang as xs:string?,
    $sortDirection as xs:string?,
    $sortType as xs:string?,
    $sortAuthor as xs:string?,
    $componentSearch as xs:string?
) as element(search:options) {
    <options xmlns="http://marklogic.com/appservices/search">
        <searchable-expression>/custom-page</searchable-expression>
        <additional-query> {
            cts:and-query((
                core:get-filter-query(),
                cts:element-attribute-value-query(xs:QName('custom-page'), xs:QName('locale'), $lang, 'exact'),
                if ( c:stringNotEmpty($uri) ) then (
                    cts:element-attribute-value-query(xs:QName('custom-page'), xs:QName('uri'), $uri, 'exact')
                ) else (),
                if( $sortAuthor ) then (
                    if(fn:not($sortAuthor eq "all")) then (
                        cts:element-attribute-value-query(fn:QName('http://lds.org/code/lds-edit', 'last-modified'), xs:QName('username'),
                            af:get-author-username($templateId, $site, $lang, $sortAuthor), 'exact')
                    ) else ()
                ) else (),
                if( $componentSearch ne 'all' and $componentSearch ne '' ) then (
                    cts:element-attribute-value-query(xs:QName($componentSearch), xs:QName("is-id"), "true", 'exact')
                ) else (),
                cts:element-value-query(xs:QName('template-id'), $templateId, 'exact'),
                cts:element-value-query(xs:QName('ldse:pageId'), $pageId, 'exact'),
                cts:element-value-query(xs:QName('site-context'), $site, 'exact')
            ))
        }</additional-query>
        <search-option>unfiltered</search-option>
        <return-results>true</return-results>
        <transform-results apply="raw"/>
        {
            let $sort as xs:string := ($sortDirection[. = ('asc', 'ascending')], 'descending')[1]
            return (
                if ( $sortType = 'date' ) then (
                    <sort-order type="xs:dateTime" direction="{ $sort }">
                        <element ns="http://lds.org/code/lds-edit" name="last-modified" />
                        <attribute name="date" />
                    </sort-order>
                ) else if ( $sortType = 'alphabetic' ) then (
                    <sort-order type="xs:string" direction="{ $sort }">
                        <element ns="http://lds.org/code/lds-edit" name="document" />
                        <attribute name="title" />
                    </sort-order>
                ) else ()
            )
        }
        <term>
            <empty apply="all-results"/>
            <term-option>case-insensitive</term-option>
            <term-option>diacritic-insensitive</term-option>
            <term-option>punctuation-insensitive</term-option>
            <term-option>whitespace-insensitive</term-option>
            <term-option>unstemmed</term-option>
            <term-option>wildcarded</term-option>
            <term-option>lang={$lang}</term-option>
        </term>
    </options>
};

declare function cf:get-sub-sites() as element(sub-site)* {
    cts:search(/sub-site,
        cts:and-query((
            core:get-filter-query()
        ))
    )
};

declare function cf:get-sub-site($site as xs:string) as element(sub-site) {
    cts:search(/sub-site,
        cts:and-query((
            core:get-filter-query(),
            cts:element-value-query(xs:QName('name'), $site, "exact")
        ))
    )
};

declare function cf:get-specific-sub-site($site as xs:string) as element(sub-site)? {
    cts:search(/sub-site,  cts:element-value-query(xs:QName('ldse:site-context'), $site, "exact"))
};

declare function cf:get-custom-page(
    $lang as xs:string,
    $uri as xs:string*
) as element()* {
    cts:search(/custom-page,
        cts:and-query((
            core:get-filter-query(),
            cts:or-query((
                cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('uri'), $uri, 'exact'),
                cts:element-attribute-value-query(xs:QName('custom-page'), xs:QName('uri'), $uri, 'exact')
            )),
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), $lang, 'exact')
        ))
    )
};

declare function cf:get-custom-page(
    $lang as xs:string,
    $uri as xs:string*,
    $status as xs:string
) as element()* {
    cf:get-custom-page($lang, $uri, $status, (), ())
};

declare function cf:get-custom-page(
    $lang as xs:string,
    $uri as xs:string*,
    $status as xs:string,
    $site as xs:string*,
    $audience as xs:string*
) as element()* {
    cts:search(/custom-page,
        cts:and-query((
            cts:or-query((
                cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('uri'), $uri, 'exact'),
                cts:element-attribute-value-query(xs:QName('custom-page'), xs:QName('uri'), $uri, 'exact')
            )),
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), $lang, 'exact'),
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('status'), $status, 'exact'),
            if ( fn:exists($site) ) then (
                cts:element-value-query(xs:QName('ldse:site-context'), $site, 'exact')
            ) else (),
            if ( fn:exists($audience) ) then (
                cts:or-query((
                    cts:element-attribute-value-query(xs:QName('audience'), xs:QName('id'), $audience, 'exact'),
                    cts:not-query(cts:element-query(xs:QName('audience'), cts:and-query( () )))
                ))
            ) else ()
        ))
    )
};

declare function cf:get-published-custom-page-by-site-and-uri(
    $uris as xs:string*,
    $site as xs:string*
) as element()* {
  cts:search(/custom-page, cts:and-query((
                cts:directory-query('/published/', 'infinity'),
                cts:element-value-query(xs:QName('ldse:site-context'), $site, 'exact' ),
                cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('uri'), ($uris), 'exact' )
            )))
};

declare function cf:get-error(
    $site as xs:string,
    $error-type as xs:string
) as element(error)? {
    cts:search(/error,
        cts:and-query((
            core:get-filter-query(),
            cts:element-value-query(xs:QName('site'), $site, 'exact'),
            cts:element-value-query(xs:QName('error-type'), $error-type, 'exact')
        ))
    )
};

declare function cf:get-sub-template(
    $id as xs:string
) as element(sub-template)? {
    cts:search(/sub-template,
        cts:and-query((
            cts:element-attribute-value-query(xs:QName('sub-template'), xs:QName('id'), $id, 'exact')
        ))
    )
};

declare function cf:get-rewrite-rules(
    $locale as xs:string,
    $site as xs:string?
) as element(rewriteRules)? {
    cts:search(/rewriteRules,
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-value-query(xs:QName('rewriteRules'), xs:QName('locale'), $locale, 'exact'),
            if ( fn:exists($site) ) then (
                cts:element-attribute-value-query(xs:QName('rewriteRules'), xs:QName('site'), $site, 'exact')
            ) else ()
        ))
    )
};

declare function cf:get-tags-by-site(
    $locale as xs:string,
    $site as xs:string,
    $status as xs:string
) as element(tags)* {
    cts:search(/tags,
        cts:and-query((
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), $locale, 'exact'),
            cts:element-value-query(xs:QName('ldse:site-context'), $site, 'exact'),
            cts:element-attribute-value-query(xs:QName('tags'), xs:QName('status'), $status, 'exact')
        )),
        'unfiltered'
    )
};

declare function cf:get-content-by-status(
    $id as xs:string,
    $status as xs:string,
    $site as xs:string?
) as element()? {
    cts:search(fn:collection(),
        cts:and-query((
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('id'), $id, 'exact'),
            if ( fn:exists($site) ) then (
                cts:element-value-query(xs:QName('ldse:site-context'), $site, 'exact')
            ) else (),
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('status'), $status, 'exact')
        )),
        'unfiltered'
    )/*
};

declare function cf:get-collections-in-language(
    $lang as xs:string,
    $site as xs:string,
    $id as xs:string?,
    $status as xs:string*
) as element()* {
    cts:search(fn:collection(),
        cts:and-query((
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), $lang, 'exact'),
            if ( fn:exists($id[. != '']) ) then (
                cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('id'), $id, 'exact')
            ) else (),
            if ( fn:exists($status[. != '']) ) then (
                cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('status'), $status, 'exact')
            ) else (),
            cts:element-value-query(xs:QName('ldse:site-context'), $site, 'exact'),
            cts:or-query((
                cts:element-query(xs:QName('titan-collection'), cts:and-query(())),
                cts:element-query(xs:QName('collection'), cts:and-query(()))
            ))
        ))
    )/*
};
declare function cf:get-items-from-collections(
    $site as xs:string
) {
    cts:search(fn:collection(),
        cts:and-query((
            cts:element-value-query(xs:QName('ldse:site-context'), $site, 'exact'),
            cts:or-query((
                cts:element-query(xs:QName('titan-collection'), cts:and-query(())),
                cts:element-query(xs:QName('collection'), cts:and-query(()))
            ))
        ))
    )/*
};

declare function cf:get-collections-by-asset-id-in-language(
    $lang as xs:string,
    $site as xs:string,
    $asset-id as xs:string?
) as element()* {
    cts:search(fn:collection(),
        cts:and-query((
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), $lang, 'exact'),
            cts:element-value-query(xs:QName('ldse:site-context'), $site, 'exact'),
            cts:element-value-query(xs:QName('item'), $asset-id, 'exact')
        ))
    )/*
};

declare function cf:get-actions(
    $site as xs:string,
    $status as xs:string
) as element(actions)* {
    cts:search(/actions,
        cts:and-query((
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('status'), $status, 'exact'),
            cts:element-value-query(xs:QName('ldse:site-context'), $site, 'exact')
        ))
    )
};

declare function cf:get-site-sub-nav(
    $site as xs:string,
    $status as xs:string,
    $locale as xs:string
) as element(sub-nav)? {
    cts:search(/sub-nav,
        cts:and-query((
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('status'), $status, 'exact'),
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), $locale, 'exact'),
            cts:element-value-query(xs:QName('ldse:site-context'), $site, 'exact')
        ))
    )
};

declare function cf:get-component-content-by(
    $lang as xs:string,
    $id as xs:string,
    $site as xs:string
) as element()* {
    cts:search(fn:collection(),
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), $lang, 'exact'),
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('id'), $id, 'exact'),
            cts:element-value-query(xs:QName('ldse:site-context'), $site, 'exact')
        ))
    )/*
};

declare function cf:get-custom-page-by-id-and-lang(
    $id as xs:string,
    $lang as xs:string
) as element()* {
    cts:search(/custom-page,
        cts:and-query((
            cts:directory-query('/preview/', 'infinity'),
            cts:and-query((
                cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('id'), $id, 'exact'),
                cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), $lang, 'exact')
            ))
        ))
    )
};
