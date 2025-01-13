xquery version "1.0-ml";

module namespace cloneSearch = "http://lds.org/code/shared/lds-edit/cloneSearch";

import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";

import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "/modules/ldse-meta.xqy";
import module namespace json = "http://marklogic.com/json" at "/modules/fasterjson.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "/modules/ldse-settings.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "/modules/ldse-core.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "/modules/utility-functions.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";
import module namespace sp = "http://lds.org/code/modules/site-properties" at '/modules/site-properties.xqy';
import module namespace tw = "http://lds.org/code/shared/lds-edit/translation-workflow" at "/translation/modules/translation-workflow.xqy";
import module namespace tranSettings = "http://lds.org/code/shared/lds-edit/translation-settings" at "/translation/modules/translation-settings.xqy";
import module namespace snip = "http://lds.org/code/shared/lds-edit/snipFunction" at "/translation/modules/jsonSnippet.xqy";

declare namespace html = "http://www.w3.org/1999/xhtml";
declare namespace xhtml = "http://www.w3.org/1999/xhtml";
declare namespace its = "http://www.w3.org/2005/11/its";
declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace s = "http://www.w3.org/2009/xpath-functions/analyze-string";
declare option xdmp:mapping "true";

declare variable $columnXML as element(ldse:columns) := $tranSettings:columns;
declare variable $DEFAULT-SORT as xs:string? := ();
declare variable $DEFAULT-SORT-DIRECTION as xs:string? := ();
declare variable $site-param as xs:string? := xdmp:get-request-field('site');
declare variable $curr-site as xs:string? := if (fn:contains($site-param, '|')) then
                                                fn:substring-before(xdmp:get-request-field('site'), '|')
                                             else $site-param;
declare variable $curr-lang as xs:string? := if (fn:contains($site-param, '|')) then
                                                fn:substring-after(xdmp:get-request-field('site'), '|')
                                             else xdmp:get-request-field('lang');


declare function siteSelect($default as xs:boolean) as element(option)* {

        for $supportedLanguage in cts:search(/supportedLanguages, cts:directory-query('/preview/', 'infinity'))
        for $lang in $supportedLanguage/language/@key
        let $site := $supportedLanguage/@site/fn:string()
        let $result := $site||'|'||$lang
        where ($site) and ac:has-permission('ldse:edit-doc', $lang, '', $site)
        order by $site, $lang
        return (
            <option value="{ $result }">{
            if ( ($default) and $curr-site = $site and $curr-lang eq $lang) then ( attribute selected { 'selected' } ) else (),
                $result
            }</option>
        )
        (:)
        return  (
            <option value="{ $site }">{
                if ( ($default) and $curr-site = $site) then ( attribute selected { 'selected' } ) else (),
                $site
            }</option>
        )
:)
};

declare function getOptions($filterQuery as cts:query*, $useFacets as xs:boolean) as element(search:options){
    getOptions($filterQuery, $useFacets, "0")
};

(:Generates options needed based on the user, sorting, and if they are needed:)
declare function getOptions($filterQuery as cts:query*, $useFacets as xs:boolean, $pageNum as xs:string) as element(search:options){
    (:) let $selectedStatus as xs:string? := xdmp:get-request-field("status")[. ne '']
    let $transResults as element(search:transform-results)? :=
        if($tw:steps[@name = $selectedStatus]/search:transform-results)
        then
            <transform-results xmlns="http://marklogic.com/appservices/search">
                {
                    $tw:steps[@name = $selectedStatus]/search:transform-results/(@* | node()),
                    <param>
                        <pageNum>{$pageNum}</pageNum>
                    </param>
                }
            </transform-results>
        else ()
    return :)
        <options xmlns="http://marklogic.com/appservices/search">
            <search-option>unfiltered</search-option>
            {
                (:)    if(fn:exists($transResults))then($transResults)
                else:)(
                    <transform-results apply="default-json" ns="http://lds.org/code/shared/lds-edit/snipFunction" at="/translation/modules/jsonSnippet.xqy" >
                        <param>
                            <pageNum>{$pageNum}</pageNum>
                        </param>
                    </transform-results>
                )
            }
      (:      <constraint name="cid">
                <value>
                    <element ns="http://lds.org/code/lds-edit" name="translation-returned"/>
                    <attribute ns="" name="component-id"/>
                </value>
            </constraint>
        :)
            {
                (:)  if($useFacets) then(
                    <constraint name="locales">
                        <range type="xs:string" facet="true">
                            <attribute ns="" name="locale"/>
                            <element ns="http://lds.org/code/lds-edit" name="document"/>
                        </range>
                    </constraint>
                ) else:)
                (
                    <return-facets>false</return-facets>
                )
            }
            <additional-query>
                {

                    $filterQuery
                }
            </additional-query>
            {
                let $ascending as xs:boolean := xdmp:get-request-field("ascending","true") = "true"
                return
                    getSortOrderOption(
                        if($ascending) then ("ascending") else("descending")
                    )
            }

            <!-- Add Case Insensitivity -->
            <term>
                <term-option>case-insensitive</term-option>
                <term-option>diacritic-insensitive</term-option>
                <term-option>punctuation-insensitive</term-option>
                <term-option>whitespace-insensitive</term-option>
                <term-option>wildcarded</term-option>
                <term-option>unstemmed</term-option>
            </term>
            <return-metrics>false</return-metrics>
            <return-qtext>false</return-qtext>
            <return-query>true</return-query>
            <debug>true</debug>
        </options>
};
(:)
declare function getTranslationMetaNode() as cts:query{
    cts:element-attribute-range-query(
        xs:QName("ldse:translation-event"),
        xs:QName("status"),
        "!=",
        ""
    )
};
:)
(:Searches for the component-id:)
(:)
declare function pdFilter($component-id as xs:string) as cts:query{
    cts:element-attribute-value-query(
        xs:QName("ldse:translation-returned"),
        xs:QName("component-id"),
        fn:concat($component-id,"*")
        ,            ("wildcarded","punctuation-insensitive")
    )
};
:)
(:)
declare function buildSiteSelect() as element(select) {
    <select>{
        for $site as xs:string in $sp:all-sites
        where ac:has-permission('ldse:edit-doc', '', '', $site)
        order by $site
        return (
            <option value="{ $site }">{
                if ( $curr-site = $site ) then ( attribute selected { 'selected' } ) else (),
                $site
            }</option>
        )
    }</select>
};
:)
declare function uriFilter($uris as xs:string*) as cts:query?{
    let $log := xdmp:log("$uris ==> "||fn:string-join($uris, ','))
    let $result :=
    if(fn:exists($uris)) then(
        cts:or-query((
            for $URI as xs:string in $uris
            let $uri as xs:string := fn:concat($settings:shared-prefix,'/', $URI)
            where $URI ne ''
            return (
                if ( $URI = 'rice') then (
                    cts:element-query(xs:QName('resources'),
                        cts:and-query((
                            cts:element-query(xs:QName('name'), cts:and-query( () )),
                            cts:element-query(xs:QName('application'), cts:and-query( () ))
                        ))
                    )
                ) else if ($URI = 'home-page') then (
                    cts:element-attribute-range-query(
                        xs:QName("ldse:document"),
                        xs:QName("uri"),
                        "=",
                        "/",
                        "collation=http://marklogic.com/collation/"
                    )
                ) else (
                    cts:element-attribute-value-query(xs:QName("ldse:document"), xs:QName("uri"), fn:concat("*",$URI,"*"), ("punctuation-insensitive","wildcarded"), 1),
                    cts:element-query(xs:QName('resources'),
                        cts:and-query((cts:element-value-query(xs:QName('name'), fn:concat("*",$URI,"*"), ("punctuation-insensitive","wildcarded"), 1),
                                       cts:element-query(xs:QName('application'), cts:and-query( () ))
                        )))
                )
            )
        ))
    ) else()
    let $log := xdmp:log("$result ==> "||xdmp:quote($result))
    return $result
};

declare function languageFilter($locales as xs:string*) as cts:query?{

    if(fn:exists($locales)) then(
        cts:element-attribute-range-query(
            xs:QName("ldse:document"),
            xs:QName("locale"),
            "=",
            $locales
        )
    )else()
};

declare function parseDate($date as xs:string) as xs:dateTime{
    xs:dateTime(fn:concat($date,"T00:00:00"))
};

declare function siteFilter(
    $site as xs:string?
) as cts:query? {
    cts:or-query((
        cts:element-value-query(xs:QName('ldse:site-context'), $site, 'exact'),
        cts:element-attribute-value-query(xs:QName('resources'), xs:QName('site'), $site, 'exact')
    ))
};

declare function typeFilter() as cts:query? {
    cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('type'), ('resources', 'custom-page'), 'exact')
};
(:)
declare function dateRangeQuery($elementName as xs:string) as cts:query{
    let $from as xs:dateTime? :=  parseDate(xdmp:get-request-field("startDate")[. ne ''])
    let $to as xs:dateTime?   :=  parseDate(xdmp:get-request-field("endDate")[. ne ''])
    return
        cts:and-query(
            (
                if(fn:exists($from)) then (
                    cts:element-attribute-range-query(
                        fn:QName("http://lds.org/code/lds-edit",$elementName),
                        xs:QName("date"),
                        ">=",
                        $from)
                ) else (),
                if(fn:exists($to)) then (
                    cts:element-attribute-range-query(
                        fn:QName("http://lds.org/code/lds-edit",$elementName),
                        xs:QName("date"),
                        "<",
                        $to + xs:dayTimeDuration("P1D"))
                ) else ()
            )

        )
};
:)
declare function getSortOrderOption($direction as xs:string) as element(search:sort-order)?{
    let $columnId as xs:string? := (xdmp:get-request-field("columnId")[fn:not(. = ("undefined", ""))],$DEFAULT-SORT,"")[1]

    let $direction as xs:string? :=
        if ( fn:exists(xdmp:get-request-field("columnId")[fn:not(. = "undefined")]) )
        then $direction
        else $DEFAULT-SORT-DIRECTION

    let $sortable as element(search:sort-order)? := $columnXML/ldse:column[@id eq $columnId]/search:sort-order
    return(
        if(fn:exists($sortable)) then(
            <sort-order xmlns="http://marklogic.com/appservices/search" direction="{$direction}">
                {$sortable/@type,
                $sortable/@collation,
                $sortable/*}
            </sort-order>
        )
        else()
    )
};

declare function jsonAdditional() as xs:string {
    let $files-map as map:map := map:map()
    let $file-ids := xdmp:get-request-field("id[]")[. ne '']
    let $additional as xs:string* := fn:tokenize(xdmp:get-request-field("additions"),',')[. ne '']
    let $status as xs:string := xdmp:get-request-field("status")
    let $action as xs:string := xdmp:get-request-field("action")
    let $step as element(ldse:step) := tw:get-step-by-name($status)
    let $action-element as element() := tw:get-action-from-step($step, $action)
    let $permission as xs:string := ($step/ldse:permission, $action-element/ldse:permission)[1]
    let $otherLocales as xs:string* := ac:locales-by-permission($permission)(:[. ne 'eng']:)
    return (
        if (fn:exists($additional) and fn:exists($file-ids)) then (
            let $files as element()+ := ldsemeta:get-files-by($file-ids, (), (), ())
            return (
                json:obj((
                    json:keyObject("languageFiles", json:obj((
                        if ($additional eq "language") then (
                            for $file as element() in $files
                            let $id as xs:string := ldsemeta:get-document-id($file)
                            let $locale as xs:string := ldsemeta:get-document-locale($file)
                            let $locales as xs:string* := $otherLocales(:[. ne $locale]:)
                            let $langFiles as element()* := ldsemeta:get-file-in-locale($file, $locales)
                            where fn:exists($langFiles)
                            return (
                                json:keyObject($id,
                                    json:arr((
                                        for $file as element() in ((:$file,:) $langFiles)
                                        let $uri as xs:string? := ldsemeta:get-document-uri($file, fn:true())
                                        let $locale as xs:string? := ldsemeta:get-document-locale($file)
                                        let $has-permission as xs:boolean := ac:has-permission($permission, $locale, $uri)
                                        where $has-permission
                                        order by $locale eq "eng" descending, $locale
                                        return (
                                            snip:json-all($file, (), ())
                                        )
                                    ))
                                )
                            )
                        ) else ()
                    ))),
                    json:keyObject("referenceFiles",
                        if ($additional eq ("translation", "translations") ) then (
                            let $uris as xs:string* := fn:distinct-values( ldsemeta:get-document-uri($files, fn:true()) )[. ne '']
                            (: Find any Page Files :)
                            let $pageUris as xs:string* := ldsemeta:get-document-uri($files[self::custom-page])
                            let $pUris as xs:string* := $uris[fn:not(. = $pageUris)]
                            let $pages as element(custom-page)* := getPageFilesByUris($pUris)
                            (: Find any Collection Files :)
                            let $collectionUris as xs:string* := ldsemeta:get-document-uri($files[self::collection])
                            let $cUris as xs:string* := $uris[fn:not(. = $collectionUris)]
                            let $collections as element(collection)* := getCollectionsByUris($cUris)
                            (: Find any Referenced Files in collection Files :)
                            let $refIds as xs:string* := ($files[self::collection], $collections)/items/item[fn:not(. = $file-ids)]
                            let $referencedFiles as element()* :=
                                if (fn:exists($refIds)) then (
                                    ldsemeta:get-files-by($refIds, 'eng', (), ())
                                ) else ()
                            let $other-references as element()* :=
                                cts:search(fn:collection(),
                                    cts:and-query((
                                        cts:or-query((
                                            for $file as element() in $files
                                            return cts:element-value-query(xs:QName(fn:local-name($file)), $file/@id/xs:string(.), 'exact')
                                        ))
                                    ))
                                )/*
                            return (
                                json:arr((
                                    for $file as element() in ($pages, $collections, $referencedFiles, $other-references)
                                    let $uri as xs:string? := ldsemeta:get-document-uri($file, fn:true())
                                    let $locale as xs:string? := ldsemeta:get-document-locale($file)
                                    let $has-permission as xs:boolean := ac:has-permission($permission, $locale, $uri)
                                    let $file-id as xs:string := ( $file/@id, ldsemeta:get-document-id($file) )[1]
                                    where $has-permission and fn:not($file-id = map:keys($files-map))
                                    order by $locale eq "eng" descending, $locale
                                    return (
                                        snip:json-all($file, (), ()), map:put($files-map, $file-id, $file-id)
                                    )
                                ))
                            )
                        ) else if ($additional eq ("teasers", "teaser")) then (
                            json:obj((
                                for $file as element() in $files[fn:not(self::teaser)]
                                let $id as xs:string := ldsemeta:get-document-id($file)
                                let $teaserRefs as element(teaser)* :=
                                    getReferencingTeasers($otherLocales, ldsemeta:get-document-uri($file))
                                where fn:exists($teaserRefs)
                                return (
                                    json:keyObject($id,
                                        json:arr((
                                            for $file as element() in $teaserRefs
                                            let $uri as xs:string? := ldsemeta:get-document-uri($file, fn:true())
                                            let $locale as xs:string? := ldsemeta:get-document-locale($file)
                                            let $has-permission as xs:boolean := ac:has-permission($permission, $locale, $uri)
                                            where $has-permission
                                            order by $locale eq "eng" descending, $locale
                                            return (
                                                snip:json-all($file, (), ())
                                            )
                                        ))
                                    )
                                )
                            ))
                        ) else ()
                    )
                ))
            )
        ) else (
            '{"languageFiles":[],"referenceFiles":[]}'
        )
    )
};

declare function getPageFilesByUris( $uris as xs:string*) as element(custom-page) *{
    cts:search(/custom-page,
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('uri'), $uris, ('exact')),
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), 'eng', ('exact'))
        ))
    )
};

declare function getCollectionsByUris($uris as xs:string*) as element(collection)* {
    cts:search(/collection,
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('uri'), $uris, ('exact')),
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), 'eng', ('exact'))
        ))

    )
};

declare function getReferencingTeasers($locale as xs:string, $fileUrl as xs:string) as element(teaser)* {
    cts:search(/teaser,
        cts:and-query((
            core:get-filter-query(),
            cts:or-query((
                cts:element-value-query(xs:QName('url'),$fileUrl,('exact')),
                cts:element-attribute-word-query((xs:QName('a'),xs:QName('xhtml:a')), xs:QName('href'), $fileUrl, ('exact'))
            )),
            cts:element-attribute-range-query(xs:QName('ldse:document'), xs:QName('locale'), '=', $locale, "collation=http://marklogic.com/collation/")
        ))
    )
};

declare function jsonSearch($renderSummary as xs:boolean) as xs:string{
    search(fn:false(), $renderSummary)[1]
};
(: Returns Json String and Locale & Status facets :)
declare function pageSearch() as item()*{
    search(fn:true(), fn:false())
};

declare function set-default-sort($status as xs:string?) as xs:string?
{
    let $step as element(ldse:step)? := tw:get-step-by-name($status)
    return (
        xdmp:set($DEFAULT-SORT, $step/ldse:default-sort/fn:string(.)),
        xdmp:set($DEFAULT-SORT-DIRECTION, $step/ldse:default-sort/@direction/fn:string(.))
    )
};

declare function getFilterQuery() as cts:query{
        cts:and-query((
            core:get-filter-query(),
            typeFilter(),
            (:) getTranslationMetaNode(),:)
            uriFilter(xdmp:get-request-field("uris[]")[. ne '']),
            languageFilter($curr-lang),
            siteFilter($curr-site)
        ))
};

declare function getAllDocsByFilters() as element()*{
    cts:search(/*,searchParse(),"unfiltered")
};

(: Returns the cts:query used by the search :)
declare function searchParse() as cts:query?{
    cts:and-query( (cts:query(search:parse(xdmp:get-request-field("searchString",""))),
    getFilterQuery())
    )
};
(:If we are generating facets then we no longer need results:)
declare private function search($generateFacets as xs:boolean,$renderSummary as xs:boolean) as item() {
    let $pageIndex as xs:int := xs:int(xdmp:get-request-field("pageIndex","1"))
    let $pageSize as xs:int := if($generateFacets) then 1 else xs:int(xdmp:get-request-field("pageSize","25"))
    let $selectedStatus as xs:string? := xdmp:get-request-field("status")[. ne '']
    let $analyzedQuery as element() := fn:analyze-string(
        xdmp:get-request-field("searchString",""),
        "pd\S+","i"
    )
    let $searchQuery as xs:string := (fn:string($analyzedQuery/*:non-match),"")[1]
    let $pdQuery as xs:string? := fn:string($analyzedQuery/*:match)
    let $filterQuery as cts:query := getFilterQuery()
    let $searchResponse as element(search:response)* := search:search("",
        getOptions($filterQuery, $generateFacets, xs:string($pageIndex)), ($pageIndex - 1) * $pageSize + 1, $pageSize)
    let $totalPagesFound as xs:int := $searchResponse/@total
    let $summary as xs:string := if($renderSummary) then (
        generateSummary(
            cts:and-query((
                cts:query($searchResponse/search:query/*),
                $filterQuery
            )),
            $selectedStatus)
    ) else ('""')
    return
        (
            if($generateFacets) then
                ($searchResponse/search:facet[1])
            else (
                json:arr((
                    $summary,
                    json:arr($searchResponse/search:result/fn:string(.)),
                    fn:string(fn:ceiling($totalPagesFound div $pageSize)),
                    fn:string($pageIndex),
                    fn:string($totalPagesFound)
                ))
            )
        )
};

declare function buildStatusSelect() as element(select) {
    <select>
        <option value="">Show All</option>
        {
            for $step as element(ldse:step) in $tw:steps
            return (
                <option value="{ fn:string($step/@name) }">{ fn:string($step/@title) }</option>
            )
        }</select>
};

(:Generates the summary for the page
    if query is empty then it will generate the summary
    for all documents:)
declare function generateSummary($query as cts:query?,$selectedStatus as xs:string?) as xs:string{
    json:arr(
        generateQueryStep($tw:steps,$query,$selectedStatus)
    )
};

(:Generates a tile that has the summary information in it for the column-name passed in:)
declare function generateQueryStep(
    $step as element(ldse:step),
    $query as cts:query?,
    $selectedStatus as xs:string?
) as xs:string? {
    let $combinedQuery as cts:query := combineQueries(tw:get-step-query($step),$query)
    return (
        if(fn:empty($selectedStatus) or $selectedStatus eq $step/@name) then(
            json:obj((
                json:keyValue("title",fn:string($step/@title)),
                json:keyValue("name",fn:string($step/@name)),
                json:keyValue("docs",docs($combinedQuery)),
                json:keyValue("words", words($combinedQuery)),
                json:keyValue("oldest",oldest($combinedQuery, $step/@element))
            ))

        )else()
    )

};
declare function docs(
    $category-query as cts:query
) as xs:string{
    fn:string(
        xdmp:estimate(
            cts:search(fn:collection(),
                $category-query,
                ("unfiltered","unchecked")
            )
        )
    )
};

declare function words(
    $category-query as cts:query
) as xs:string {
    fn:string(
        cts:sum(
            cts:element-attribute-values(
                xs:QName("ldse:document"),
                xs:QName("words"),
                (),
                ("document","concurrent", "unchecked"),
                $category-query
            )
        )
    )
};

declare function oldest(
    $category-query as cts:query+,
    $element as xs:string?
) as xs:string? {
    let $element as xs:string :=
        if ($element = "") then (
            "ldse:last-modified"
        ) else if ( fn:contains($element, ':') ) then (
            $element
        ) else (
            fn:concat('ldse:', $element)
        )
    return (
        formatDate(
            cts:element-attribute-values(
                xs:QName($element),
                xs:QName("date"),
                (),("document","concurrent","unchecked", "ascending", "limit=1"), $category-query
            )[1]
        )
    )
};

declare function formatDate(
    $dateTime as xs:anySimpleType
) as xs:string {
    fn:substring(fn:string($dateTime),1,10)
};

declare function combineQueries(
    $query1 as cts:query,
    $query2 as cts:query?
) as cts:query {
    cts:and-query(($query1,$query2))
};

declare function buildSiteUriAndResourceSelect($site as xs:string) as element (option)* {
    let $sites := for $site as xs:string in $site
    where ac:has-permission('ldse:edit-doc', '', '', $site)
    order by $site
    return $site

    let $pages := for $site in $sites
    for $page in cts:search(/custom-page,
        cts:and-query((
            cts:directory-query('/preview/', 'infinity'),
            cts:element-value-query(xs:QName('ldse:site-context'), $site),
            cts:element-attribute-value-query(xs:QName('custom-page'),xs:QName('locale'), 'eng')
        ))
    )/@uri
    order by $site, $page
    return element data {attribute site {$site},
    attribute type {'page'},
    fn:concat($page, ' | page | ',$site)}

    let $bundles := for $site in $sites
    for $bundle in cts:search(/resources,
        cts:and-query((
            cts:directory-query('/preview/', 'infinity'),
            cts:element-attribute-value-query(xs:QName('resources'),xs:QName('site'), $site, 'exact'),
            cts:element-attribute-value-query(xs:QName('resources'),xs:QName('locale'), 'eng', 'exact')
        ))  )
    order by $site, $bundle
    return element data {attribute site {$site},
    attribute type {'bundle'},
    fn:concat($bundle/name/fn:string(), ' | bundle | ',$site)}

    let $data := ($pages, $bundles)

    return
        for $i in $data
        order by $i/@site, $i/@type descending
        return (
            <option value="{ $i }">{
                $i
            }</option>
        )

};
