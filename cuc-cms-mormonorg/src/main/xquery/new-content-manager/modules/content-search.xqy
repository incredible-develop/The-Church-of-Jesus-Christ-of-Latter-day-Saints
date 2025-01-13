xquery version "1.0-ml";

module namespace content-search = "http://lds.org/code/shared/lds-edit/new-content-manager/content-search";

import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";

import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "/modules/ldse-meta.xqy";
import module namespace json = "http://marklogic.com/json" at "/modules/fasterjson.xqy";
import module namespace snip = "http://lds.org/code/shared/lds-edit/new-content-manager/json-snippet" at "/new-content-manager/modules/json-snippet.xqy";
import module namespace content-workflow = "http://lds.org/code/shared/lds-edit/new-content-manager/content-workflow" at "/new-content-manager/modules/content-workflow.xqy";
import module namespace content-settings = "http://lds.org/code/shared/lds-edit/new-content-manager/content-settings" at "/new-content-manager/modules/content-settings.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "/modules/ldse-settings.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "/modules/ldse-core.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "/modules/utility-functions.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";
import module namespace security = "http://lds.org/code/shared/common/security/security-functions" at "/shared/common/security/securityFunctions.xqy";

declare namespace html = "http://www.w3.org/1999/xhtml";
declare namespace xhtml = "http://www.w3.org/1999/xhtml";
declare namespace its = "http://www.w3.org/2005/11/its";
declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace hldse = "http://lds.org/code/lds-edit/history";
declare namespace s = "http://www.w3.org/2009/xpath-functions/analyze-string";
declare option xdmp:mapping "true";

declare variable $columnXML as element(ldse:columns) := $content-settings:columns;
declare variable $DEFAULT-SORT as xs:string? := ();
declare variable $DEFAULT-SORT-DIRECTION as xs:string? := ();
declare variable $USERNAME as xs:string? := fn:lower-case(ac:getUserName());

declare function content-search:getOptions($filterQuery as cts:query*, $useFacets as xs:boolean) as element(search:options){
	getOptions($filterQuery, $useFacets, "0")
};

(:Generates options needed based on the user, sorting, and if they are needed:)
declare function content-search:getOptions($filterQuery as cts:query*, $useFacets as xs:boolean, $pageNum as xs:string) as element(search:options){
    let $selectedStatus as xs:string? := xdmp:get-request-field("status")
    let $transResults as element(search:transform-results)? :=
        if ($content-workflow:steps[@name = $selectedStatus]/search:transform-results) then (
			<transform-results xmlns="http://marklogic.com/appservices/search">
			{
     			$content-workflow:steps[@name = $selectedStatus]/search:transform-results/(@* | node()),
     			<param>
     				<pageNum>{$pageNum}</pageNum>
     			</param>
			}
			</transform-results>
        ) else ()
    return
     <options xmlns="http://marklogic.com/appservices/search">
        <search-option>unfiltered</search-option>
        {
            if(fn:exists($transResults))then($transResults)
            else(
                 <transform-results apply="all-default-json" ns="http://lds.org/code/shared/lds-edit/new-content-manager/json-snippet"
                       at="/new-content-manager/modules/json-snippet.xqy">
                        <param>
                       	    <pageNum>{$pageNum}</pageNum>
                        </param>
			     </transform-results>
            )
        }
       {
       if($useFacets) then(
            <constraint name="locales">
                <range type="xs:string" facet="true">
                  <attribute ns="" name="locale"/>
                  <element ns="http://lds.org/code/lds-edit" name="document"/>
                </range>
            </constraint>
        ) else(
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
				content-search:getSortOrderOption(
					if($ascending)
					then "ascending"
					else "descending"
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
   </options>
};

declare function content-search:userFilter($users as xs:string*, $selectedStatus as xs:string?) as cts:query?{
    let $elementName as xs:string? := content-settings:getUserElementNameByStatus($selectedStatus)
    let $ns as xs:string :=
        if ( $selectedStatus = "comments" ) then (
            "hldse:"
        ) else ( "ldse:" )

    return
        if(fn:exists($users) and $elementName) then(
            cts:element-attribute-value-query(
               (
                   xs:QName(fn:concat($ns, $elementName))
               ),
               xs:QName("username"),
               for $user as xs:string in $users
               return(fn:concat("*",$user,"*")),
               ("wildcarded"))
         ) else ()
};


declare function content-search:uriFilter($uris as xs:string*, $status as xs:string?) as cts:query?{
       if( fn:exists($uris) ) then(
           cts:or-query((
               for $URI as xs:string in $uris
               let $uri as xs:string := util:clean-db-uri(fn:concat($settings:shared-prefix, '/', $URI))
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
                               if ( $status = "comments" ) then (
                                    xs:QName("hldse:document")
                               ) else (
                                    xs:QName("ldse:document")
                               ),
                               xs:QName("uri"),
                               "=",
                               "/",
                               "collation=http://marklogic.com/collation/"
                       )
                   ) else (
                       cts:and-query((
                           cts:element-attribute-range-query(
                               if ( $status = "comments" ) then (
                                    xs:QName("hldse:document")
                               ) else (
                                    xs:QName("ldse:document")
                               ),
                               xs:QName("uri"),
                               ">=",
                               ($uri, $URI),
                               "collation=http://marklogic.com/collation/"
                           ),
                           cts:element-attribute-range-query(
                               if ( $status = "comments" ) then (
                                    xs:QName("hldse:document")
                               ) else (
                                    xs:QName("ldse:document")
                               ),
                               xs:QName("uri"),
                               "<=",
                               (fn:concat($uri, "~"), fn:concat($URI, "~")),
                               "collation=http://marklogic.com/collation/"
                           )
                       ))
                    )
               )
           ))
           (: cts:element-attribute-value-query(
               xs:QName("ldse:document"),
               xs:QName("uri"),
               for $uri as xs:string in $uris
               return(fn:concat($settings:shared-prefix,"/",$uri,"*"),fn:concat("/",$uri,"*")),
               ("wildcarded","unstemmed")) :)
       ) else()

};
declare function content-search:languageFilter($locales as xs:string*, $status as xs:string?) as cts:query?{
      if( fn:exists($locales) ) then (
           cts:element-attribute-range-query(
               if ( $status = "comments" ) then (
                    xs:QName("hldse:document")
               ) else (
                    xs:QName("ldse:document")
               ),
               xs:QName("locale"), "=", $locales ) (:
           cts:element-attribute-value-query(
                xs:QName("ldse:document"),
                xs:QName("locale"),
                $locale,
                "exact",
            ):)
       ) else ()
};

declare function content-search:parseDate($date as xs:string) as xs:dateTime{
    xs:dateTime(fn:concat($date,"T00:00:00"))
};


declare function content-search:dateRangeQuery($elementName as xs:string, $status as xs:string?) as cts:query{
    let $from as xs:dateTime? :=  parseDate(xdmp:get-request-field("startDate")[. ne ''])
    let $to as xs:dateTime?   :=  parseDate(xdmp:get-request-field("endDate")[. ne ''])
    return
    cts:and-query(
        (
        if(fn:exists($from)) then (
            cts:element-attribute-range-query(
               if ( $status = "comments" ) then (
                    fn:QName("http://lds.org/code/lds-edit/history",$elementName)
               ) else (
                    fn:QName("http://lds.org/code/lds-edit",$elementName)
               ),
               xs:QName("date"),
               ">=",
               $from)
       ) else (),
        if(fn:exists($to)) then (
            cts:element-attribute-range-query(
               if ( $status = "comments" ) then (
                    fn:QName("http://lds.org/code/lds-edit/history",$elementName)
               ) else (
                    fn:QName("http://lds.org/code/lds-edit",$elementName)
               ),
               xs:QName("date"),
               "<",
               $to + xs:dayTimeDuration("P1D"))
        ) else ()
   )

    )
};

declare function content-search:followingFilter($following as xs:boolean) as cts:query? {
    if ( $following ) then (
        let $ids as xs:string* :=
            cts:element-attribute-values(xs:QName('hldse:document'), xs:QName('id'), (), (),
                cts:and-query((
                    core:get-filter-query(),
                    cts:element-attribute-range-query(xs:QName('hldse:following'), xs:QName('username'), '=', $USERNAME)
                ))
            )[fn:not( . = "")]
        return (
            if ( fn:empty($ids) ) then (
                cts:element-attribute-value-query( xs:QName('ldse:document'), xs:QName('id'), $ids, 'exact')
            ) else (
                cts:or-query( () )
            )
        )
    ) else ()
};

declare function content-search:getSortOrderOption($direction as xs:string) as element(search:sort-order)?{
  let $columnId as xs:string? := (xdmp:get-request-field("columnId")[fn:not(. = ("undefined", ""))],$DEFAULT-SORT,"")[1]

  let $direction as xs:string? :=
  	if(xdmp:get-request-field("columnId")[fn:not(. = "undefined")])
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

declare function content-search:jsonAdditional() as xs:string {
    ""
    (:let $file-ids as xs:string+ := xdmp:get-request-field("id[]")[. ne '']
    let $additional as xs:string* := fn:tokenize(xdmp:get-request-field("additions"),',')[. ne '']
    let $status as xs:string := xdmp:get-request-field("status")
    let $action as xs:string := xdmp:get-request-field("action")
    let $step as element(ldse:step) := content-workflow:get-step-by-name($status)
    let $action-element as element() := content-workflow:get-action-from-step($step, $action)
    let $permission as xs:string := ($step/ldse:permission, $action-element/ldse:permission)[1]
    let $otherLocales as xs:string* := ac:locales-by-permission($permission)[. ne 'eng']
    return (
       if (fn:exists($additional)) then (
           let $files as element()+ := ldsemeta:get-files-by($file-ids, (), (), ())
           return (
               json:obj((
                   json:keyObject("languageFiles", json:obj((
                        if ($additional eq "language") then (
                            for $file as element() in $files
                            let $id as xs:string := ldsemeta:get-document-id($file)
                            let $locale as xs:string := ldsemeta:get-document-locale($file)
                            let $locales as xs:string* := $otherLocales[. ne $locale]
                            let $langFiles as element()* := ldsemeta:get-file-in-locale($file, $locales)
                            where fn:exists($langFiles)
                            return (
                                json:keyObject($id,
                                   json:arr((
                                       for $file as element() in $langFiles
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
                               (\: Find any Page Files :\)
                               let $pageUris as xs:string* := ldsemeta:get-document-uri($files[self::custom-page])
                               let $pUris as xs:string* := $uris[fn:not(. = $pageUris)]
                               let $pages as element(custom-page)* := getPageFilesByUris($pUris)
                               (\: Find any Collection Files :\)
                               let $collectionUris as xs:string* := ldsemeta:get-document-uri($files[self::collection])
                               let $cUris as xs:string* := $uris[fn:not(. = $collectionUris)]
                               let $collections as element(collection)* := getCollectionsByUris($cUris)
                               (\: Find any Referenced Files in collection Files :\)
                               let $refIds as xs:string* := ($files[self::collection], $collections)/items/item[fn:not(. = $file-ids)]
                               let $referencedFiles as element()* := if (fn:exists($refIds)) then (
                                   ldsemeta:get-files-by($refIds,'eng',(),())
                               ) else ()
                               return (
                                   json:arr((
                                       for $file as element() in ($pages, $collections, $referencedFiles)
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
    ):)
};

declare function content-search:getPageFilesByUris( $uris as xs:string*) as element(custom-page) *{
    cts:search(/custom-page,
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('uri'), $uris, ('exact')),
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), 'eng', ('exact'))
        ))
    )
};

declare function content-search:getCollectionsByUris($uris as xs:string*) as element(collection)* {
    cts:search(/collection,
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('uri'), $uris, ('exact')),
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), 'eng', ('exact'))
        ))

    )
};

declare function content-search:getReferencingTeasers($locale as xs:string, $fileUrl as xs:string) as element(teaser)* {
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

declare function content-search:jsonSearch($generate-facets as xs:boolean, $renderSummary as xs:boolean) as xs:string? {
    content-search:search($generate-facets, $renderSummary)[1]
};
(: Returns Json String and Locale & Status facets :)
declare function content-search:pageSearch() as item()* {
    content-search:search(fn:true(), fn:false())
};

declare function content-search:set-default-sort($status as xs:string?) as xs:string?
{
	let $step as element(ldse:step)? := content-workflow:get-step-by-name($status)
	return (
		xdmp:set($DEFAULT-SORT, $step/ldse:default-sort/fn:string(.)),
		xdmp:set($DEFAULT-SORT-DIRECTION, $step/ldse:default-sort/@direction/fn:string(.))
	)
};

declare function content-search:getFilterQuery($status as xs:string?, $pdQuery as xs:string?) as cts:query{
    let $selectedStatus as xs:string? := ($status, xdmp:get-request-field("status")[. ne ''])[1]
    let $dateElementName as xs:string? := content-settings:getDateElementNameByStatus($selectedStatus)

	let $_ as empty-sequence() := content-search:set-default-sort($selectedStatus)

    let $statusFilter as cts:query* :=
        if(fn:empty($selectedStatus))
        then content-workflow:get-all-step-queries()
        else content-workflow:get-query($status)

    let $query as cts:query* :=
        if($selectedStatus = 'comments')
        then
                cts:and-query((
                   core:get-filter-query(),
                   content-search:dateRangeQuery($dateElementName, $selectedStatus),
                   content-search:userFilter(xdmp:get-request-field("users")[. ne ''], $selectedStatus),
                   content-search:languageFilter(xdmp:get-request-field("locales")[. ne ''], $selectedStatus),
                   content-search:uriFilter(xdmp:get-request-field("uris")[. ne ''], $selectedStatus),
                   content-search:followingFilter(xdmp:get-request-field("following") = "true"),
                   $statusFilter
                ))
		else
            cts:and-query((
                core:get-filter-query(),
                $statusFilter,
                content-search:no-images(),
                content-search:has-ldse-meta(),
                content-search:no-custom-pages(),
                content-search:dateRangeQuery($dateElementName, $selectedStatus), (:Each filter should have its own function that function maps:)
                content-search:uriFilter(xdmp:get-request-field("uris")[. ne ''], $selectedStatus),
                content-search:userFilter(xdmp:get-request-field("users")[. ne ''], $selectedStatus),
                content-search:languageFilter(xdmp:get-request-field("locales")[. ne ''], $selectedStatus),
                content-search:followingFilter(xdmp:get-request-field("following") = "true"),
	            cts:or-query(
	            	(ac:query-permission('ldse:edit-doc'),
	            	ac:query-permission('ldse:edit-submission'))
	            )
            ))
	return $query
};

declare function content-search:getAllDocsByFilters() as element()*{
     cts:search(/*,searchParse(),"unfiltered")
};

(: Returns the cts:query used by the search :)
declare function content-search:searchParse() as cts:query?{
    cts:and-query((
        cts:query(search:parse(xdmp:get-request-field("searchString",""))),
        getFilterQuery((),())
    ))
};
(:If we are generating facets then we no longer need results:)
declare private function content-search:search($generateFacets as xs:boolean, $renderSummary as xs:boolean) as item()? {
    let $pageIndex as xs:int := xs:int(xdmp:get-request-field("pageIndex","1"))
    let $pageSize as xs:int := xs:int( xdmp:get-request-field("pageSize", "25") )
    let $querySize as xs:int := 100
    let $selectedStatus as xs:string? := xdmp:get-request-field("status")[. ne '']
    let $selected-locale as item()* := xdmp:get-request-field("locales")[. ne '']
    let $the-users as item()* := xdmp:get-request-field("users[]")[. ne '']
    let $search-value as item()* := xdmp:get-request-field("searchString")[. ne '']
    let $analyzedQuery as element() := fn:analyze-string(
        xdmp:get-request-field("searchString",""),
        "pd\S+","i"
        )
    let $searchQuery as xs:string := (fn:string($analyzedQuery/s:non-match),"")[1]
    let $pdQuery as xs:string? := fn:string($analyzedQuery/s:match)
    let $filterQuery as cts:query? := content-search:getFilterQuery($selectedStatus, $pdQuery)
    let $searchResponse as element(search:response)* :=
            search:search(
                $searchQuery,
                content-search:getOptions($filterQuery, $generateFacets, xs:string($pageIndex)), ($pageIndex - 1) * $querySize + 1, $querySize
            )
    let $totalPagesFound as xs:int? := $searchResponse/@total

    let $summary as xs:string* :=
        if($renderSummary) then (
	        content-search:generateSummary(
	            cts:and-query((
	                cts:query($searchResponse/search:query/*),
	                $filterQuery
	            )),
	            $selectedStatus)
        ) else ('""')

    return (
        json:arr((
            $summary,
            json:arr($searchResponse/search:result/fn:string(.)),
            json:obj((
                json:escapedKeyValue("pages", fn:string(fn:ceiling($totalPagesFound div $pageSize))),
        	    json:escapedKeyValue("index", fn:string($pageIndex)),
        	    json:escapedKeyValue("items", fn:string($totalPagesFound))
            )),
            if ( $generateFacets ) then (
                json:arr(
                    for $locale as xs:string in $searchResponse/search:facet[1]/search:facet-value/@name
                    return (
                        json:obj((
                            json:escapedKeyValue("value", $locale),
                            json:escapedKeyValue("label", $locale)
                        ))
                    )
                )
            ) else ()
    	))
    )
};

declare function content-search:buildStatusSelect() as element(select) {
    <select ng-change="changeStatus()" ng-model="status">
        <option value="">Show All</option>
    {
        for $step as element(ldse:step) in $content-workflow:steps
        return (
            <option value="{ xs:string($step/@name) }">{ xs:string($step/@title) }</option>
        )
    }</select>
};

(:Generates the summary for the page
    if query is empty then it will generate the summary
    for all documents:)
declare function content-search:generateSummary($query as cts:query?,$selectedStatus as xs:string?) as xs:string{
        json:arr(
            content-search:generateQueryStep($content-workflow:steps, $query, $selectedStatus)
        )
};

declare function content-search:change-query-namespace($query as item(), $namespace as xs:string, $prefix as xs:string) {
    typeswitch($query)
    case cts:query return ( content-search:change-query-namespace( element query { $query }/node(), $namespace, $prefix) )
    case text() return ( $query )
    case element(cts:element) return (
        if ($query/namespace::ldse) then (
            element { fn:node-name($query) } {
                namespace { $prefix } { $namespace },
                fn:replace($query/text(), 'ldse:', fn:concat($prefix, ':'))
            }
        ) else ( $query )
    )
    case element(cts:attribute) return (
        if ($query/namespace::ldse) then (
            element { fn:node-name($query) } {
                namespace { $prefix } { $namespace },
                fn:replace($query/text(), 'ldse:', fn:concat($prefix, ':'))
            }
        ) else ( $query )
    )
    default return (
        element { fn:node-name($query) } {
            $query/@*,
            content-search:change-query-namespace($query/node(), $namespace, $prefix)
        }
    )
};

(:Generates a tile that has the summary information in it for the column-name passed in:)
declare function content-search:generateQueryStep(
    $step as element(ldse:step),
    $query as cts:query?,
    $selectedStatus as xs:string?
) as xs:string? {
    let $step-title as xs:string := $step/@name
    let $query as cts:query? :=
        if ( $step/@name = 'comments' ) then (
            cts:query(content-search:change-query-namespace($query, "http://lds.org/code/lds-edit/history", "hldse"))
        ) else ( $query )
    let $combinedQuery as cts:query := content-search:combineQueries(content-workflow:get-step-query($step), $query)

    let $json as xs:string* :=
        json:obj((
            json:keyValue("title", xs:string($step/@title)),
            json:keyValue("name", $step-title),
            json:keyValue("docs", content-search:docs($combinedQuery)),
            json:keyValue("words", content-search:words($combinedQuery)),
            json:keyValue("oldest",content-search:oldest($combinedQuery, $step-title))
        ))
    return $json
};

declare function content-search:docs($category-query as cts:query) as xs:string{
    xs:string(
       xdmp:estimate(
            cts:search(fn:collection(),
                $category-query,
                ("unfiltered","unchecked")
            )
        )
    )
};

declare function content-search:words($category-query as cts:query) as xs:string {
    xs:string(
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

declare function content-search:oldest($category-query as cts:query+, $step-title as xs:string?) as xs:string?{
  formatDate(
       cts:element-attribute-values(
            if ( $step-title = 'draft' ) then (
                xs:QName("ldse:created")
            ) else if ( $step-title = 'modified' ) then (
                xs:QName("ldse:last-modified")
            ) else if ( $step-title = 'publish' ) then (
                xs:QName("ldse:publish-date")
            ) else if ( $step-title = 'unpublished' ) then (
                xs:QName("ldse:unpublish-date")
            ) else if ( $step-title = 'schedule-publish' ) then (
                xs:QName("ldse:schedule-publish")
            ) else if ( $step-title = 'schedule-unpublish' ) then (
                xs:QName("ldse:schedule-unpublish")
            ) else if ( $step-title = 'submission-created' ) then (
                xs:QName("ldse:created")
            ) else if ( $step-title = 'comments' ) then (
                xs:QName("hldse:comment")
            ) else if ( $step-title = 'submission-submitted' ) then (
                xs:QName("ldse:submission")
            ) else (
                xs:QName('ldse:last-modified')
            ),
            xs:QName("date"),
            (),
            ("document","concurrent","unchecked"),$category-query
        )[1]
   )
};

declare function content-search:formatDate($dateTime as xs:anySimpleType) as xs:string{
    fn:substring(xs:string($dateTime),1,10)
};

declare function content-search:combineQueries($query1 as cts:query,$query2 as cts:query?) as cts:query{
    cts:and-query(($query1,$query2))
};

declare function content-search:no-images() as cts:query {
    cts:not-query(
        cts:element-query(xs:QName('binary-content'), cts:and-query( () ))
    )
};

declare function content-search:no-custom-pages() as cts:query {
    cts:not-query(
        cts:element-query(xs:QName('custom-page'), cts:and-query( () ))
    )
};

declare function content-search:has-ldse-meta() as cts:query {
    cts:element-query(xs:QName('ldse:ldse-meta'),
        cts:and-query(
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('id'), '*', 'wildcarded')
        )
    )
};
