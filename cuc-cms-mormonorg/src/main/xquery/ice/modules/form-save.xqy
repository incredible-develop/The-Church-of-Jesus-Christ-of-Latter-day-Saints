xquery version "1.0-ml";

module namespace formSave = "http://lds.org/code/shared/lds-edit/form-save";

import module namespace file-query = "http://lds.org/code/shared/lds-edit/file-query" at "file-query.xqy";
import module namespace form = "http://lds.org/code/shared/lds-edit/dynamicForms" at "dynamicForms.xqy";
import module namespace ice = "http://lds.org/code/shared/lds-edit/iceFunction" at "iceFunctions.xqy";
import module namespace json = "http://lds.org/code/shared/common/json/json-functions" at "/shared/common/json/jsonFunctions.xqy";
import module namespace faster-json = "http://marklogic.com/json" at "../../modules/fasterjson.xqy";
import module namespace cc = "http://lds.org/code/shared/lds-edit/clear-cache-functions" at "../../clear-cache/modules/clear-cache-functions.xqy";
import module namespace search="http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../modules/access-control-functions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../modules/ldse-settings.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "../../modules/ldse-meta.xqy";
import module namespace correlation = "http://lds.org/code/shared/lds-edit/correlation" at "../../correlation/modules/correlation-functions.xqy";
import module namespace func = "http://lds.org/code/shared/lds-edit/function-apply" at "../../invoke/function-apply.xqy";
import module namespace mem = "http://lds.org/code/shared/common/memory-update" at "/shared/common/util/inMemoryUpdate.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../modules/utility-functions.xqy";
import module namespace brightcove = "http://lds.org/code/shared/lds-edit/brightcove/brightcove-service" at "../../brightcove/brightcove-service.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../modules/ldse-core.xqy";
import module namespace security = "http://lds.org/code/shared/common/security/security-functions" at "/shared/common/security/securityFunctions.xqy";
import module namespace category = "http://lds.org/code/shared/lds-edit/category-functions" at "../../modules/category-functions.xqy";
import module namespace ls = "http://lds.org/code/shared/lds-edit/lang-sync" at "../../modules/lang-sync.xqy";
import module namespace site = "http://lds.org/code/shared/lds-edit/custom/ldse-site-core" at "../../custom/lds-edit/ldse-site-core.xqy";
declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace cldse = "http://lds.org/code/lds-edit/correlation";
declare namespace lsldse = "http://lds.org/code/lds-edit/lang-sync";
declare namespace sync-meta-spawn = "http://lds.org/code/shared/lds-edit/sync-meta-spawn";
declare namespace handle-correlation = "http://lds.org/code/shared/lds-edit/handle-correlation";

declare variable $locale as xs:string := form:getVariable('locale');
declare variable $action as xs:string := form:getVariable('action');
declare variable $status as xs:string := form:getVariable('status');
declare variable $uri as xs:string? := form:getVariable('uri');
declare variable $site as xs:string? := form:getVariable('site');
declare variable $current-site as xs:string? := xdmp:get-request-field('site');
declare variable $formName as xs:string? := ( form:getVariable('form'), xdmp:get-request-field('form') )[1];
declare variable $ajax as xs:boolean := xdmp:get-request-field("ajax","") eq "true";
declare variable $buildMap as empty-sequence() := form:buildParamMap();
declare variable $return-submission as xs:boolean := xs:boolean(xdmp:get-request-field("return-submission", "false"));

declare function formSave:formSave(
    $sync-meta as xs:string?,
    $categoryName as xs:string*,
    $is-submission as xs:boolean
) as item()* {
    let $_form as element(ldse:formTemplate) := form:getFormTemplate($formName)
    let $form  as element(ldse:formTemplate) := site:add-standardized-fields-to-iceform($_form)
    let $file as element()? := form:getRootFile($form)
    let $has-permission as xs:boolean :=
        ( if ($action = "edit") then (
            ac:has-permission('ldse:edit-doc', $locale, $uri, $current-site)
            or ac:has-permission('ldse:edit-submission', $locale, $uri, $current-site)
        ) else if ($action = "add") then (
            ac:has-permission('ldse:add-doc', $locale, $uri, $current-site)
            or ac:has-permission('ldse:add-submission', $locale, $uri, $current-site)
        ) else ( fn:false() ) )
        and ( fn:exists($current-site) or $form/@requires-site = 'false' )

    (: Get the name of the image path node :)
    let $image-path-name as xs:string? := form:getVariable('image-path-node')
    let $forceRedirect as xs:string :=
        if ( $status = "ldse:delete") then (
            "true"
        ) else (
            ($form/ldse:force-redirect[. != ""], "false")[1]
        )
    let $locale := if((fn:name($form) eq "formTemplate") and (fn:exists($form/ldse:structure/ldse:sub-site))) then ( "eng" ) else ( $locale )
    let $id as xs:string :=
    	if ( $action eq 'add' or fn:empty($file) ) then (
    	   form:newId($locale)
    	) else ( form:getVariable('id') )
(:    let $category as item()* := if ( fn:not($form/@name != "category") ) then ( category:updateCategory($categoryName, $id, $site, $locale) ) else ():)
    return (
    	if ($has-permission ) then (
    		let $newXml as element() := form:buildNewXml($status, $file, $form, $id)
    		let $newXml as element() := ice:stripUrlsProcess($newXml)
            let $newXml as element() :=
                if (fn:name($newXml) eq "sub-site") then (
                    let $newXmlLocale := mem:node-replace($newXml/@locale, (attribute locale {$locale} ))
                    let $newXmlLang := mem:node-replace($newXmlLocale/@xml:lang, (attribute {xs:QName("xml:lang")} {$locale}))
                    let $newXmlDocumentLocale := mem:node-replace($newXmlLang/ldse:ldse-meta/ldse:document/@locale, (attribute locale {$locale} ))
                    return $newXmlDocumentLocale
                ) else ( $newXml )
    		let $lang-sync as item()* :=
    		  if ( $settings:versification = 'true' or ( ( $uri = $settings:versification-uris or fn:starts-with($uri, $settings:versification-uris) ) and fn:not($uri = $settings:not-versification-uris) ) and $locale = 'eng' ) then (
    		      formSave:update-lang-sync($file, $newXml, $id)
    	      ) else ()

    		(: build ldsemeta:correlation node :)
    (:		let $send-to-correlation as xs:boolean := xdmp:get-request-field("send-to-correlation") = "true" and  ldsemeta:_isEnglish(ldsemeta:get-ldse-meta($newXml))
    		let $newXml as empty-sequence() := formSave:update-correlation($newXml, $send-to-correlation) :)

    		let $newXml as element() := if ( $is-submission ) then ( formSave:set-submission-status($newXml) ) else ( $newXml )
    		let $save-path as item()* := form:saveFile($file, $newXml, $form)

    		let $applyExtraPayload as item()* := formSave:apply-extra-payload()

    		let $publish-items as item()* :=
                if ( $status = ( 'ldse:publish', 'ldse:unpublish' ) and fn:exists($form//ldse:dynamic-form-ref/node()/@auto-publish-ref) ) then (
                    formSave:publish-refs($file, $newXml, $form)
                ) else ()

            let $publish-all-items as item()* :=
                if ($status = 'ldse:publish-all') then (
                    formSave:publish-all-files($file, fn:true())
                ) else ()
    		(: call the clear cache functionality if we are publishing or unpublishing :)
    		let $uris as element(uris) := element uris { element uri {$uri} }

    		let $clearCache as item()* :=
    			if ($status eq ('ldse:publish', 'ldse:unpublish', 'ldse:publish-all'))
    			then cc:clearCache($uris, $site, $locale, ())
    			else ()
    		let $newXml as element()? := if ( fn:exists($newXml//node()[@translation = "ready"]) ) then ( mem:node-delete($newXml//node()/@translation[. = 'ready']) ) else ( $newXml )
    		let $handle-sync-meta as empty-sequence() :=
    			if(fn:not($status = "ldse:delete") and $sync-meta) then (
    				let $from-id as xs:string := $id
    				let $form-name as xs:string := $formName
    				return
    					if($from-id and $form-name) then (
    						let $from-xml as item()* := $newXml
    						let $to-xmls as element()* := ldsemeta:get-translated-files-in-preview($from-xml//ldse:document)
    						let $to-uris as xs:string* := for $to-xml as element() in $to-xmls return xdmp:node-uri($to-xml)
    						let $uris-map as map:map := map:map()
    						let $no-op as empty-sequence() := map:put($uris-map, "uris", $to-uris)
    						return func:spawn(xdmp:function(xs:QName("sync-meta-spawn:spawn"), "/modules/sync-meta-spawn.xqy"), "preview", $uris-map, $form-name, $id, $locale, $ldsemeta:USERNAME, $ldsemeta:USERID)
    					) else ()
    			) else()

    (:		let $handle-correlation as empty-sequence() := formSave:handle-correlation($status, $newXml) :)
            let $redirect as xs:string? := form:redirect($file, $newXml, $form)
            let $video-xml as element()? :=
                if ( fn:empty($newXml/ldse:ldse-meta/ldse:brightcove-service) and brightcove:is-video($newXml) ) then (
                    func:spawn(xdmp:function(xs:QName("brightcove:save-video-information")), "preview", $id, $locale)
                ) else ()
    		return (
    		  xdmp:set-response-code(200, "OK"),
    		  xdmp:set-response-content-type('application/json'),
              if ($ajax) then (
                    let $doc-title as element(ldse:document-title)? := $form/ldse:document-title
                    let $title as xs:string? :=
                        if ( fn:exists($doc-title) ) then (
                            form:dynamicXpath($newXml, $doc-title/text())
                        ) else (
                            fn:normalize-space(ldsemeta:get-document-title($newXml))
                        )
                    return (
                        json:serializeSet((
                            element id { ldsemeta:get-document-id($newXml) },
                            element title { $title },
                            if ( fn:exists($image-path-name) ) then (
                                let $image-path-qname as xs:QName := xs:QName($image-path-name)
                                return $newXml//*[fn:node-name(.) eq $image-path-qname]
                            ) else (),

                            element search {
                                search:snippet(
                                    $newXml,
                                    search:parse("*"),
                                    <transform-results apply="snippet" xmlns="http://marklogic.com/appservices/search">
                                        <per-match-tokens>30</per-match-tokens>
                                        <max-matches>4</max-matches>
                                        <max-snippet-chars>200</max-snippet-chars>
                                        <preferred-elements>
                                            <element name="title"/>
                                            <element name="description"/>
                                            <element name="p" ns="http://www.w3.org/1999/xhtml"/>
                                            <element name="p"/>
                                            <element name="div" ns="http://www.w3.org/1999/xhtml"/>
                                            <element name="div"/>
                                        </preferred-elements>
                                    </transform-results>
                                )/search:match[1]/xs:string(.)
                            }
                        ))
                    )
                ) else (
                    faster-json:obj((
                        faster-json:keyEscapedValue("success", "true"),
                        faster-json:keyEscapedValue("id", $id),
                        faster-json:keyObject("forceRedirect", if ( fn:exists($forceRedirect) ) then ( $forceRedirect ) else ("") ),
                        faster-json:keyEscapedValue("redirect", if ( fn:exists($redirect) ) then ( $redirect ) else ( fn:concat($settings:shared-prefix, "/") ) ),
                        faster-json:keyEscapedValue("uri", if ( fn:exists( $uri ) ) then ( $uri ) else ( fn:concat($settings:shared-prefix, "/") ))
                    ))
                )
    		)
    	) else (
            faster-json:obj((
                faster-json:keyEscapedValue("success", "false")
            ))
        )
    )
};


declare function formSave:apply-extra-payload( ) as item()* {
    if ($action eq "edit") then (
        let $payload-action as xs:string? := xdmp:get-request-field("extra-payload-action")
        let $rawPayload as xs:string? := xdmp:get-request-field("extra-payload")
        return
            if ($payload-action and $rawPayload) then (
                if ($payload-action eq "delete") then (
                    let $payload as xs:string* := fn:tokenize($rawPayload, ",")
                    let $applyPayload as xs:string* :=
                        for $payloadItemId in fn:distinct-values($payload)
                        let $file as element()? := ldsemeta:get-file-by-id($payloadItemId)
                        let $deleteFile as item()* := core:preform-action-and-update("ldse:delete", $file)
                        return $payloadItemId
                    return ( )
                ) else ( )
            ) else ( )
    ) else ( )
};

declare function formSave:set-submission-status($newXml as element()) {
    let $current-status as xs:string? := ldsemeta:get-submission-status($newXml)
    return (
    	if ( fn:empty($current-status) ) then (
    	   ldsemeta:update-submission-status($newXml, "created", fn:false())
    	) else if( $return-submission ) then (
    	   ldsemeta:update-submission-status($newXml, "created", fn:false(), fn:true())
    	) else if ( $current-status = "created" ) then (
    		if ( $status = "ldse:submitted" ) then (
                ldsemeta:update-submission-status($newXml, "submitted", fn:false() )
    		) else ( $newXml )
    	) else if ( fn:not($status = ("ldse:submitted", "ldse:created")) ) then (
    		let $status as xs:string := ldsemeta:get-submission-status($newXml)
    		return ldsemeta:update-submission-status($newXml, $status, fn:true())
    	) else ( $newXml )
    )
};

declare function formSave:publish-refs($file as element()?, $newXml as element(), $form as xs:string) as item()* {
    let $content-refs as xs:string* := fn:distinct-values($newXml//node()[@auto-publish-ref = 'true']/fn:string())
    for $item as xs:string in $content-refs
    let $content-item as element() := ldsemeta:get-file-by($item, $locale, (), ())
    return (
        formSave:publish-item($content-item)
    )
};

declare function formSave:publish-item($file as element()) {
    core:update-file($status, xdmp:node-uri($file), core:action-transform($status, $file), $file, ())
};

declare function formSave:update-lang-sync($file as element(), $newXml as element(), $id as xs:string) {
    let $update-sync as item()* := ls:update-lang-sync($file, $newXml, $id)
    return ()
};

declare function formSave:publish-all-files(
    $files as element()*,
    $isRoot as xs:boolean
) as item()* {
    for $file as element() in $files
    let $childIDNode := $file//element()[@fetch-data = "true"]/..
    let $_ as element()* :=
        if ( $childIDNode ) then (
            for $childID in $childIDNode/*
            return formSave:publish-all-files(ldsemeta:get-file-by($childID, $locale, (), ()), fn:false())
        ) else ()
    return (
        if ( fn:not($isRoot) ) then (
            formSave:publish-item($file)
        ) else ()
    )
};

(: Currently not being used but might be needed in the future if correlation is integrated :)
(:declare function formSave:handle-correlation(
    $status as xs:string,
    $newXml as element()
) as item()* {
    if ( fn:not($status = "ldse:delete") and $settings:correlation-enabled  and  ldsemeta:_isEnglish(ldsemeta:get-ldse-meta($newXml)) and xdmp:get-request-field("correlation-save", "true") ne "false") then (
    	let $values-map as map:map := correlation:get-values-map()
    	let $data-map as map:map := map:get($values-map, "data-map")
    	let $correlation-document-uri as xs:string := map:get($data-map, "correlation-document-uri")
    	let $correlation-document as element(cldse:correlation) := correlation:get-correlation-document($data-map)
    	let $set-data-map as empty-sequence() := map:put($data-map, "IpReport", $correlation-document/IpReport)
    	let $new-correlation-document as element(cldse:correlation) := correlation:get-new-correlation-document($data-map)
    	let $set-data-map as empty-sequence() := map:delete($data-map, "IpReport")
    	let $set-data-map as empty-sequence() := map:delete($data-map, "send-to-correlation")

    	let $new-correlation-document as element(cldse:correlation) :=
    		element {fn:node-name($new-correlation-document)}
    		{
    			$new-correlation-document/@* except $new-correlation-document/@last-modified,
    			attribute {"last-modified"} {fn:current-dateTime()},
    			$new-correlation-document/node() except ($new-correlation-document/cldse:data-map, $new-correlation-document/cldse:correlation-elements),
    			<data-map xmlns="http://lds.org/code/lds-edit/correlation">{$data-map}</data-map>,
    			correlation:get-correlation-elements($values-map)
    		}

    	let $save as empty-sequence() := core:save-file($correlation-document-uri, $new-correlation-document, $correlation-document)

    	return
    		if($send-to-correlation) then (
    			func:spawn(xdmp:function(xs:QName("handle-correlation:spawn"), "/correlation/modules/handle-correlation-spawn.xqy"), "preview", $correlation-document-uri, (), $id, $locale)
    		) else ()
    ) else ()
};:)

(:declare function formSave:update-correlation(
    $newXml as element(),
    $send-to-correlation as xs:boolean
) as element() {
    if ( $settings:correlation-enabled and  ldsemeta:_isEnglish(ldsemeta:get-ldse-meta($newXml)) ) then (
    	let $correlation-status as xs:string? :=
    		if($send-to-correlation)
    		then "Sending"
    		else (ldsemeta:get-correlation-status($file), "Not Sent")[1]

    	let $correlation-status-date as xs:dateTime := (ldsemeta:get-correlation-status-date($newXml), fn:current-dateTime())[1]
    	let $correlation-sent-date as xs:dateTime? := if($send-to-correlation) then fn:current-dateTime() else ldsemeta:get-correlation-sent-date($newXml)
    	let $correlation-no-new-content as xs:boolean := xs:boolean(xdmp:get-request-field("correlation-no-new-content", "false"))

    	let $correlation-modified as xs:boolean :=
    		if(fn:not($action = "add"))
    		then
    			let $current-is-modified as xs:boolean := ldsemeta:get-correlation-is-modified($newXml)
    			return fn:not($correlation-no-new-content) and fn:not($send-to-correlation) and correlation:has-changes($current-is-modified, $correlation-status)
    		else fn:false()

    	let $correlation-cor-status as xs:string? :=
    		if(ldsemeta:get-correlation-cor-status($newXml) = "Approved")
    		then "Approved"
    		else ()

    	let $new-ldse-meta as element(ldse:ldse-meta) := ldsemeta:update-correlation-status(ldsemeta:get-ldse-meta($newXml), $correlation-cor-status, $correlation-status, $correlation-status-date, $correlation-sent-date, $correlation-modified)
    	let $new-doc as element() := mem:node-replace($newXml/ldse:ldse-meta, $new-ldse-meta)/*
    	return (
    	   $new-doc
        )
    ) else ( $newXml )
};:)
