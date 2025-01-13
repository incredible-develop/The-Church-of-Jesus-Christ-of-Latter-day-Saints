xquery version "1.0-ml";

module namespace cf = "http://lds.org/code/shared/lds-edit/collections/functions";

import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../modules/ldse-core.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../modules/ldse-settings.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "../../modules/ldse-meta.xqy";
import module namespace cw = "http://lds.org/code/shared/lds-edit/content/content-workflow" at "../../content/modules/content-workflow.xqy";
import module namespace ice = "http://lds.org/code/shared/lds-edit/iceFunction" at "../../ice/modules/iceFunctions.xqy";
import module namespace json = "http://marklogic.com/json" at "../../modules/fasterjson.xqy";
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../modules/access-control-functions.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../modules/utility-functions.xqy";
import module namespace pf = "http://lds.org/code/lds-edit/publishing-functions" at "../../modules/publishing-functions.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";

declare option xdmp:mapping "true";

declare variable $referer := xdmp:get-request-field('referer');

declare function cf:status(
    $file as element()
) as xs:string? {
    let $override as empty-sequence() := cw:set-permissions-override(fn:true())
	let $statuses as xs:string* := cf:recurse-step-queries(cw:get-steps(), ldsemeta:get-document-id($file), ())
    let $override as empty-sequence() := cw:set-permissions-override(fn:false())
	return (
		if("Scheduled Publish" = $statuses) then (
            "Schedule Publish"
		) else if ( "Scheduled Un-Publish" = $statuses ) then (
            "Schedule Un-Publish" 
        ) else ( $statuses[1], "Draft" )[1]
	)
};

declare function cf:status-icon(
    $status as xs:string
) as xs:string* {
	if ( $status = "Created" ) then (
	   "collection-created", "ldse-icon-paper"
    ) else if ( $status = "Submitted" ) then (
        "collection-submitted", "ldse-icon-check2"
    ) else if ( $status = "Draft" ) then (
        "collection-draft", "ldse-icon-edit"
    ) else if ( $status = "Published" ) then (
        "collection-published", "ldse-icon-send"
    ) else if ( $status = "Un-Published" ) then (
        "collection-unpublished", "ldse-icon-unpublish"
    ) else if ( $status = "Modified" ) then (
        "collection-modified", "ldse-icon-ko-warning"
    ) else if ( $status = ("Schedule Publish", "Schedule Un-Publish") ) then (
        "collection-scheduled", "ldse-icon-clock"
    ) else ( "collection-draft", "ldse-icon-edit" )
};

declare private function cf:recurse-step-queries(
    $steps as element(ldse:step)*,
    $id as xs:string,
    $statuses as xs:string*
) as xs:string* {
	if ( fn:count($steps) > 0 ) then (
		let $step as element(ldse:step) := $steps[1]
		let $query as cts:query := cw:get-step-query($step)
		let $included-in-query as xs:boolean :=
			fn:exists(
				cts:search(/,
					cts:and-query((
						$query,
						cf:filter-query(),
						cts:element-attribute-value-query(xs:QName("ldse:document"), xs:QName("id"), $id, "exact")
					))
				)
			)
		let $statuses as xs:string* := ($statuses, if($included-in-query) then $step/@title/fn:string(.) else ())
		return (
            cf:recurse-step-queries($steps[2 to fn:last()], $id, $statuses)
        )
		
	) else ( $statuses )
};

declare function cf:filter-query() as cts:query {
	cts:and-query((
		core:get-filter-query(),
		cts:not-query(
			cts:element-query(xs:QName("custom-page"), cts:and-query( () ))
		)
	))
};

declare function cf:update-files(
    $teasers as xs:string*,
    $newTeasers as xs:string*,
    $saveOrder as xs:boolean,
    $location as xs:string,
    $pageUri as xs:string,
    $action as xs:string
) as item()* {
    for $id as xs:string at $count in $teasers
    let $current-teaser as element() := ldsemeta:get-file-by($id, (), $pageUri, ())
    
    (: If page and location are equal its not really new. location can also be missing or empty:)
    let $isNew as xs:boolean := 
        $id = $newTeasers and 
        fn:not( $pageUri = $current-teaser/@page and 
            ( $location = $current-teaser/@location or $current-teaser/@location = "" or fn:empty($current-teaser/@location)
            )
        )
    let $sequenceElement as element(sequence)? := 
        if ( fn:exists($current-teaser/sequence) ) then (
            element sequence { 
                $current-teaser/sequence/@*,
                $count
            }
        ) else ()
    let $newSequence as attribute() := attribute sequence { fn:concat($count, "00") }
    (: don't update the meta information, otherwise the ice marker will always show up as orange. We are only changing sequence and don't want to ruin workflow for any other updates :)
    
    let $newId as xs:string := 
        if ( $isNew ) then ( 
            util:generate-unique-id($current-teaser/@locale) 
        ) else ( $current-teaser/@id )
    let $newTeaser as element() := 
        element { xs:QName(fn:local-name($current-teaser)) } {
            $current-teaser/@* except $current-teaser/(@sequence|@location|@id|@page),
            attribute location {$location},
            attribute id {$newId},
            attribute page {$pageUri},
            $newSequence,
            $sequenceElement,
            if ( $isNew ) then (
                let $newMeta as element(ldse:ldse-meta) := ldsemeta:get-meta($current-teaser, $newId, $current-teaser/@locale, $pageUri, "preview")
                return (
                    $newMeta,
                    $current-teaser/* except $current-teaser/(ldse:ldse-meta | sequence)
                )
            ) else (
               $current-teaser/* except $current-teaser/(sequence)
            )
        }
    let $db-path as xs:string := 
        if ($isNew) then ( 
            core:build-db-path($pageUri, $current-teaser/@locale, $newTeaser/@id, $current-teaser)
        ) else (
            xdmp:node-uri($current-teaser)
        )
    let $publishable as xs:boolean := pf:is-publishable($newTeaser, $pageUri)
    where if ( $action = "ldse:publish" ) then ( ldsemeta:collection-manager-correlation-can-publish($current-teaser) and $publishable ) else ( fn:true() )
    return (
        if ( $action = "ldse:publish" ) then (
            let $new-file as element() := ldsemeta:update-sensitive-collection-file($newTeaser, (), (), "yes", "no", $action, ())
            return (
                core:update-file($action, $db-path, core:action-transform($action, $new-file), $new-file , ())
            )
        ) else (
            core:update-file($action, $db-path, core:action-transform($action, $newTeaser), $newTeaser , ())
        )
    )
};

declare function cf:get-teasers(
    $teaserType as xs:string,
    $searchLocale as xs:string?,
    $ids as xs:string*
) as element()* {
    let $parse as element()? := 
        search:parse(
            xdmp:get-request-field("search"), 
            <options xmlns="http://marklogic.com/appservices/search">
                <term>
                    <term-option>case-insensitive</term-option>
                    <term-option>whitespace-insensitive</term-option>
                    <term-option>punctuation-insensitive</term-option>
                    <term-option>diacritic-insensitive</term-option>
                    <term-option>wildcarded</term-option>
                </term>
            </options>
        )
    return (
        if ( fn:exists($teaserType) ) then (
            cts:search(/*, 
                cts:and-query((
                    core:get-filter-query(),
                    cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), $searchLocale, 'exact'),
                    cts:not-query(
                        cts:element-attribute-value-query((xs:QName('teaser'),xs:QName('ldse:document')), xs:QName('id'), $ids, 'exact')
                    ),
                    cts:query($parse)
                ))
            )[@type = $teaserType]
        ) else (
            cts:search(fn:collection(), 
                cts:and-query((
                    core:get-filter-query(),
                    cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), $searchLocale, 'exact'),
                    cts:not-query(
                        cts:element-attribute-value-query((xs:QName('teaser'),xs:QName('ldse:document')), xs:QName('id'), $ids, 'exact')
                    ),
                    cts:query($parse)
                ))
            )/*
        )
    )
};

declare function cf:teaser-search(
    $teasers as element()*
) as xs:string* {
    xdmp:set-response-content-type("application/json"),
    json:arr(
        for $teaser as element() at $index in $teasers
        let $fileID as xs:string := ( $teaser/@id, "" )[1]
        let $title as xs:string := core:get-title($teaser)
        let $image as xs:string := ( core:get-display-uri(($teaser//thumbnail, $teaser//image, $teaser//archive-image, $teaser//@img, $teaser//img/@src)[1]), "" )[1]
        let $uri as xs:string := ldsemeta:get-document-uri($teaser, fn:true())
        let $options-xml as element()? := ldsemeta:get-form-options($teaser)
        let $options as xs:string := ( ice:csv-variables($options-xml), "" )[1]
        let $hasForm as xs:boolean := $options-xml/form != ""
        let $source as xs:string := ( ldsemeta:get-document-source($teaser), "" )[1]
        let $chq-protected as xs:boolean := ( $source eq "chq" and fn:contains($teaser/@locale, "-") )
        let $editable as xs:string := 
            if ( fn:not($chq-protected) and ac:has-permission("ldse:edit-doc", $teaser/@locale, $uri) and $hasForm ) then (
                "true"
            ) else ( "" )
            
        let $publishable as xs:string? := 
            if ( ac:has-permission('ldse:publish-doc', $teaser/@locale, $uri) ) then (
                "true"
            ) else ( "" )
            
        let $notApproved as xs:string? :=
            if ( fn:not(ldsemeta:correlation-can-publish($teaser)) ) then (
                "true"
            ) else ( "" )
        
        where fn:not($title = "")
        order by $title
        return (
            json:obj((
                json:escapedKeyValue('fileID', $fileID),
                json:escapedKeyValue('title', $title),
			    json:escapedKeyValue('type', $teaser/@type),
                json:escapedKeyValue('image', $image),
                json:escapedKeyValue('editable', $editable),
                json:escapedKeyValue('publishable', $publishable),
                json:escapedKeyValue('locale', $teaser/@locale),
                json:escapedKeyValue('sharedPrefix', $settings:shared-prefix),
                json:escapedKeyValue("uri", $uri),
                json:escapedKeyValue("option", $options),
                json:escapedKeyValue("referer", $referer),
                json:escapedKeyValue("file", $teaser),
                json:escapedKeyValue("notApproved", $notApproved)
            ))
        )
    )
};