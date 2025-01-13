xquery version "1.0-ml";

module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions";

import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";
import module namespace mem = "http://lds.org/code/shared/common/memory-update" at "/shared/common/util/inMemoryUpdate.xqy";
import module namespace security = "http://lds.org/code/shared/common/security/security-functions" at "/shared/common/security/securityFunctions.xqy";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";

import module namespace convert = "http://lds.org/code/shared/lds-edit/ldse-meta-convert" at "/modules/ldse-meta-convert.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "/modules/utility-functions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "/modules/ldse-core.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "/modules/ldse-settings.xqy";
import module namespace correlation = "http://lds.org/code/shared/lds-edit/correlation" at "/correlation/modules/correlation-functions.xqy";
import module namespace translation = "http://lds.org/code/shared/lds-edit/translationFunctions" at "/translation/modules/translationFunctions.xqy";
import module namespace document = "http://lds.org/code/shared/lds-edit/document-functions" at "/modules/document-functions.xqy";
import module namespace site = "http://lds.org/code/shared/lds-edit/custom/ldse-site-core" at "/custom/lds-edit/ldse-site-core.xqy";


declare namespace its = "http://www.w3.org/2005/11/its";
declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace hldse = "http://lds.org/code/lds-edit/history";
declare option xdmp:mapping "true";

declare variable $USERNAME as xs:string? := ac:getUserName();
declare variable $USERDISPLAYNAME as xs:string? := get-user-display-name($USERNAME);
declare variable $SITE as xs:string? := xdmp:get-request-field('site')[. != ''];
declare variable $USERID as xs:string? := ac:getPersonId();
declare variable $CURRENTDATE as xs:dateTime := fn:current-dateTime();

declare variable $commonAttributes as attribute()* := (
    attribute date {$CURRENTDATE},
    attribute username {$USERNAME},
    attribute userid {$USERID}
);

declare function get-user-display-name($username as xs:string?) as xs:string?
{
    (cts:search(/ldse:contributor,
        cts:and-query(
        	(
	            core:get-filter-query(),
	            cts:element-value-query(
	            	xs:QName('ldse:name'),
	            	$username,
	            	('unstemmed','case-insensitive')
	            )
        	)
        )
    )/ldse:name/@display[fn:not(. = "")],
    $username)[1]
};

(:~
    Overwrites the username and userid pulled off the WAM headers.
    Should only be used for Unit testing and tasks that are user less like the from-translation trigger.

    @param $username - The new username
    @param $userid - Then new userid

    @return () as empty-sequence()
:)
declare function set-user($username as xs:string, $userid as xs:string) as empty-sequence() {
    let $sets as item()* := (
        xdmp:set($USERNAME, $username),
        xdmp:set($USERID, $userid)
    )
    return ( () )
};

(:~
    Returns the current ldse-meta aftering updating last-modified but no other updates will occur
    @param $file - The current document

    @return $ldse-meta as element(ldse:ldse-meta)
:)
declare function get-meta(
    $file as element()
) as element(ldse:ldse-meta) {
    get-meta($file, (), (), (), ())
};

(:~
    Returns the current ldse-meta aftering updating last-modified, document and status elements or generates a new default meta
    Will update the meta to match the vaues you passed in for $id, $locale, $uri, $status
    @param $file - The current document
    @param $id - The id of the document
    @param $locale - The locale of the document
    @param $uri - The uri of the document
    @param $status - The status of the document ('preview, 'publish', 'unpublish', 'delete', 'remove')

    @return $ldse-meta as element(ldse:ldse-meta)
:)
declare function get-meta(
    $file as element(),
    $id as xs:string?,
    $locale as xs:string?,
    $uri as xs:string?,
    $status as xs:string?
) as element(ldse:ldse-meta) {
    get-meta($file, $id, $locale, $uri, $status, ())
};

declare function get-meta(
    $file as element(),
    $id as xs:string?,
    $locale as xs:string?,
    $uri as xs:string?,
    $status as xs:string?,
    $action as xs:string?
) as element(ldse:ldse-meta) {
    let $existing as element(ldse:ldse-meta)? := get-ldse-meta($file)/_remove-context(.)
    return (
        let $ldse-meta as element(ldse:ldse-meta) :=
            if ( fn:exists($existing) ) then (
                _update-document($file, _update-lastmodified($existing), $id, $locale, $uri, $status)
            ) else (
                _build-default-meta($file, $id, $locale, $uri, $status)
            )
        return (
            update-status($ldse-meta, $status, $action)
        )
    )
};

(:~
    Updates the status elements based of the status passed in

    @param $ldse-meta - The lds-meta element
    @param $status - The status of the document ('preview, 'publish', 'unpublish', 'delete', 'remove-from-page')

    @return $ldse-meta as element(ldse:ldse-meta)
:)

declare function update-status(
    $ldse-meta as element(ldse:ldse-meta),
    $status as xs:string?
) as element(ldse:ldse-meta) {
    update-status($ldse-meta, $status, ())
};

declare function update-status(
    $ldse-meta as element(ldse:ldse-meta),
    $status as xs:string?,
    $action as xs:string?
) as element(ldse:ldse-meta) {
    if ( $status = 'publish' or ( $status = 'preview' and $action = 'ldse:publish' ) ) then (
        let $ldse-meta as element(ldse:ldse-meta) := _remove-context($ldse-meta)
        (: Remove unpublish-date, schedule-publish, and publish-date :)
        let $removeNodes as element()* := $ldse-meta/(ldse:unpublish-date|ldse:schedule-publish|ldse:publish-date)
        let $ldse-meta as element(ldse:ldse-meta) := if (fn:exists($removeNodes)) then (mem:node-delete($removeNodes)) else ($ldse-meta)
        (: Insert new publish date :)
        let $ldse-meta as element(ldse:ldse-meta) := mem:node-insert-child($ldse-meta, _build-publish-date())
        (: Mark Reviewed :)
        let $ldse-meta as element(ldse:ldse-meta) := translation-mark-complete($ldse-meta)
        return (
            $ldse-meta
        )
    ) else if ($status eq 'unpublish') then (
        let $ldse-meta as element(ldse:ldse-meta) := _remove-context($ldse-meta)
        (: Remove unpublish-date and publish-date :)
        let $removeNodes as element()* := $ldse-meta/(ldse:unpublish-date|ldse:schedule-unpublish|ldse:publish-date)
        let $ldse-meta as element(ldse:ldse-meta) := if (fn:exists($removeNodes)) then (mem:node-delete($removeNodes)) else ($ldse-meta)
        (: Insert new unpublish date :)
        let $ldse-meta as element(ldse:ldse-meta) := mem:node-insert-child($ldse-meta, _build-unpublish-date())
        return (
            $ldse-meta
        )
    ) else if ($status eq 'remove-from-page') then (
        let $ldse-meta as element(ldse:ldse-meta) := _remove-context($ldse-meta)
        (: Remove unpublish-date and publish-date :)
        let $removeNodes as element()* := $ldse-meta/(ldse:unpublish-date|ldse:schedule-publish|ldse:schedule-unpublish|ldse:publish-date)
        let $ldse-meta as element(ldse:ldse-meta) := if (fn:exists($removeNodes)) then (mem:node-delete($removeNodes)) else ($ldse-meta)
        (: Insert new unpublish date :)
        let $ldse-meta as element(ldse:ldse-meta) := mem:node-insert-child($ldse-meta, _build-unpublish-date())
        return (
            $ldse-meta
        )
    ) else (
        (: No Action needed :)
        $ldse-meta
    )
};

declare function version-restored($ldse-meta as element(ldse:ldse-meta), $version as xs:string) as element(ldse:ldse-meta) {
    let $ldse-meta as element(ldse:ldse-meta) := _remove-context($ldse-meta)
    let $existing as element(ldse:restored)? := $ldse-meta/ldse:restored
    let $new as element(ldse:restored) :=
        <restored xmlns="http://lds.org/code/lds-edit">{
            attribute username {$USERNAME},
            attribute userid {$USERID},
            attribute date {$CURRENTDATE},
            attribute version {$version}
        }</restored>
    return (
        if ( fn:exists($existing) ) then (
            mem:node-replace($existing, $new)
        ) else (
            mem:node-insert-child($ldse-meta, $new)
        )
    )
};

(:~
    Inserts a scheduled-publish element into meta

    @param $ldse-meta - The lds-meta element
    @param $date - date to be published
    @param $time - time to be published

    @return $ldse-meta as element(ldse:ldse-meta)
:)
declare function schedule-publish($ldse-meta as element(ldse:ldse-meta), $date as xs:date, $time as xs:time) as element(ldse:ldse-meta) {
    let $ldse-meta as element(ldse:ldse-meta) := _remove-context($ldse-meta)
    let $existing as element(ldse:schedule-publish)? := $ldse-meta/ldse:schedule-publish
    let $new as element(ldse:schedule-publish) := _build-schedule-publish($date, $time)
    return (
        if ( fn:exists($existing) ) then (
            mem:node-replace($existing, $new)
        ) else (
            mem:node-insert-child($ldse-meta, $new)
        )
    )
};

(:~
    Removes the scheduled-publish element from the meta

    @param $ldse-meta - The lds-meta element

    @return $ldse-meta as element(ldse:ldse-meta)
:)
declare function remove-schedule-publish($ldse-meta as element(ldse:ldse-meta)) as element(ldse:ldse-meta) {
    let $ldse-meta as element(ldse:ldse-meta) := _remove-context($ldse-meta)
    let $existing as element(ldse:schedule-publish)? := $ldse-meta/ldse:schedule-publish
    return (
        if ( fn:exists($existing) ) then (
            mem:node-delete($existing)
        ) else (
           $ldse-meta
        )
    )
};

(:~
    Inserts a scheduled-publish element into meta

    @param $ldse-meta - The lds-meta element
    @param $date - date to be published
    @param $time - time to be published

    @return $ldse-meta as element(ldse:ldse-meta)
:)
declare function schedule-unpublish($ldse-meta as element(ldse:ldse-meta), $date as xs:date, $time as xs:time) as element(ldse:ldse-meta) {
    let $ldse-meta as element(ldse:ldse-meta) := _remove-context($ldse-meta)
    let $existing as element(ldse:schedule-unpublish)? := $ldse-meta/ldse:schedule-unpublish
    let $new as element(ldse:schedule-unpublish) := _build-schedule-unpublish($date, $time)
    return (
        if ( fn:exists($existing) ) then (
            mem:node-replace($existing, $new)
        ) else (
            mem:node-insert-child($ldse-meta, $new)
        )
    )
};

(:~
    Removes the scheduled-publish element from the meta

    @param $ldse-meta - The lds-meta element

    @return $ldse-meta as element(ldse:ldse-meta)
:)
declare function remove-schedule-unpublish($ldse-meta as element(ldse:ldse-meta)) as element(ldse:ldse-meta) {
    let $ldse-meta as element(ldse:ldse-meta) := _remove-context($ldse-meta)
    let $existing as element(ldse:schedule-unpublish)? := $ldse-meta/ldse:schedule-unpublish
    return (
        if ( fn:exists($existing) ) then (
            mem:node-delete($existing)
        ) else (
           $ldse-meta
        )
    )
};

(:~
    Removes the publish-date element from the meta

    @param $ldse-meta - The lds-meta element

    @return $ldse-meta as element(ldse:ldse-meta)
:)
declare function remove-publish-date($ldse-meta as element(ldse:ldse-meta)) as element(ldse:ldse-meta) {
    let $ldse-meta as element(ldse:ldse-meta) := _remove-context($ldse-meta)
    let $existing as element(ldse:publish-date)? := $ldse-meta/ldse:publish-date
    return (
        if ( fn:exists($existing) ) then (
            mem:node-delete($existing)
        ) else (
           $ldse-meta
        )
    )
};

(:~
    Inserts a form-options element into meta

    @param $ldse-meta - as element(ldse:ldse-meta)
    @param $form-options - as element(form-options)

    @return $ldse-meta as element(ldse:ldse-meta)
:)
declare function add-form-options($ldse-meta as element(ldse:ldse-meta), $form-options as element(ldse:form-options)) as element(ldse:ldse-meta) {
    let $ldse-meta as element(ldse:ldse-meta) := _remove-context($ldse-meta)
    let $existsing as element(ldse:form-options)? := $ldse-meta/ldse:form-options
    return (
        if ( fn:exists($existsing) ) then (
            mem:node-replace($existsing, $form-options)
        ) else (
            mem:node-insert-child($ldse-meta, $form-options)
        )
    )
};

(: *********************************
       TRANSLATION EVENT UPDATES
   ********************************* :)

(:~
    removes the translation-event element from a english document
    @param $ldse-meta - The lds-meta element
    @return $ldse-meta as element(ldse:ldse-meta)
:)
declare function translation-remove-ready($ldse-meta as element(ldse:ldse-meta)) as element(ldse:ldse-meta) {
    let $ldse-meta as element(ldse:ldse-meta) := _remove-context($ldse-meta)
    let $event as element(ldse:translation-event)? := $ldse-meta/ldse:translation-event[@status eq 'ready']
    return (
        if ( fn:exists($event) and _isEnglish($ldse-meta) ) then (
            mem:node-delete($event)
        ) else (
            $ldse-meta
        )
    )
};


declare function translation-remove-not-ready($ldse-meta as element(ldse:ldse-meta)) as element(ldse:ldse-meta){
    let $ldse-meta as element(ldse:ldse-meta) := _remove-context($ldse-meta)
        let $event as element(ldse:translation-event)? := $ldse-meta/ldse:translation-event
        let $new-event as element(ldse:translation-event) :=
        <translation-event xmlns="http://lds.org/code/lds-edit">{
            attribute status {"returned"},
            $event/*[fn:not( self::ldse:translation-not-ready )]
        }</translation-event>

        return (

            if (fn:exists($event)) then (
            mem:node-replace($event, $new-event)
            ) else (
            mem:node-insert-child($ldse-meta, $new-event)
            )

        )
};

declare function translation-mark-ready($ldse-meta as element(ldse:ldse-meta)) as element(ldse:ldse-meta) {
    translation-mark-ready($ldse-meta, ())
};

(:~
    updates the translation-event to be mark ready
    @param $ldse-meta - The lds-meta element
    @param $langs = The languages to translate to
    @return $ldse-meta as element(ldse:ldse-meta)
:)
declare function translation-mark-ready($ldse-meta as element(ldse:ldse-meta), $langs as xs:string*) as element(ldse:ldse-meta) {
    let $ldse-meta as element(ldse:ldse-meta) := _remove-context($ldse-meta)
    let $event as element(ldse:translation-event)? := $ldse-meta/ldse:translation-event
    let $new-event as element(ldse:translation-event) :=
        <translation-event xmlns="http://lds.org/code/lds-edit">{
            attribute status {"ready"},
            element translation-ready {
                $commonAttributes,
                for $lang as xs:string in $langs
                return (
                    element locale { $lang }
                )
            }
        }</translation-event>
    return (
        if (_isEnglish($ldse-meta)) then (
            if (fn:exists($event)) then (
                mem:node-replace($event, $new-event)
            ) else (
                mem:node-insert-child($ldse-meta, $new-event)
            )
        ) else (
            $ldse-meta
        )
    )
};
(:Updates the meta node based on information that is passed in:)
declare function update-correlation-status($ldse-meta as element(ldse:ldse-meta), $cor-status as xs:string?, $status as xs:string, $status-date-time as xs:dateTime, $sent-date-time as xs:dateTime?, $is-modified as xs:boolean) as element(ldse:ldse-meta)?
{
    let $ldse-meta as element(ldse:ldse-meta) := _remove-context($ldse-meta)
    let $old-correlation-element as element(ldse:correlation)? := $ldse-meta/ldse:correlation
    let $new-correlation-element as element(ldse:correlation) :=
    	<ldse:correlation>
    	{
    		attribute cor-status {$cor-status},
    		attribute status {$status},
    		attribute status-date {$status-date-time},
    		if(fn:exists($sent-date-time)) then attribute sent-date {$sent-date-time} else (),
    		attribute username {$USERNAME},
    		attribute userid {$USERID},
    		attribute is-modified {$is-modified}
    	}
    	</ldse:correlation>

    return
       if ($old-correlation-element)
       then mem:node-replace($old-correlation-element, $new-correlation-element)
	else mem:node-insert-child($ldse-meta, $new-correlation-element)
};

(:Updates the meta node based on information that is passed in:)
declare function rm-update-status($ldse-meta as element(ldse:ldse-meta),
        $status as xs:string, $product-review-id as xs:string?,$json as item()) as element(ldse:ldse-meta) {
    let $ldse-meta as element(ldse:ldse-meta) := _remove-context($ldse-meta)
    let $ip as element(ldse:ip-correlation)? := $ldse-meta/ldse:ip-correlation
    let $new-ip as element(ldse:ip-correlation) :=
        <ldse:ip-correlation status="{$status}" ip-report='{xdmp:to-json-string($json)}' date="{$CURRENTDATE}" username="{$USERNAME}" userid="{$USERID}" product-review-id="{$product-review-id}"/>
    return (
        if (fn:exists($ip)) then (
            mem:node-replace($ip, $new-ip)
        ) else (
            mem:node-insert-child($ldse-meta, $new-ip)
        )
    )
};
(:~
    updates the translation-event to be mark sent
    @param $ldse-meta - The lds-meta element
    @return $ldse-meta as element(ldse:ldse-meta)
:)
declare function translation-mark-sent($ldse-meta as element(ldse:ldse-meta), $translation-id as xs:string) as element(ldse:ldse-meta) {
    let $ldse-meta as element(ldse:ldse-meta) := _remove-context($ldse-meta)
    let $event as element(ldse:translation-event)? := $ldse-meta/ldse:translation-event
    let $new-event as element(ldse:translation-event) :=
        <translation-event xmlns="http://lds.org/code/lds-edit">{
            attribute status {"sent"},
            $event/*[fn:not( self::ldse:translation-sent )],
            element translation-sent {
                attribute translation-id {$translation-id},
                $commonAttributes
            }
        }</translation-event>
    return (
        if (_isEnglish($ldse-meta)) then (
            if (fn:exists($event)) then (
                mem:node-replace($event, $new-event)
            ) else (
                mem:node-insert-child($ldse-meta, $new-event)
            )
        ) else (
            $ldse-meta
        )
    )
};

(:~
    updates the translation-event to be mark returned,

    @param $ldse-meta - The lds-meta element
    @param $zip-name - The name of the zip the item was returned in
    @return $ldse-meta as element(ldse:ldse-meta)
:)
declare function translation-mark-returned($ldse-meta as element(ldse:ldse-meta), $component-id as xs:string, $locale as xs:string) as element(ldse:ldse-meta) {
    let $ldse-meta as element(ldse:ldse-meta) := _remove-context($ldse-meta)
    let $event as element(ldse:translation-event)? := $ldse-meta/ldse:translation-event
    let $new-event as element(ldse:translation-event) :=
        <translation-event xmlns="http://lds.org/code/lds-edit">{
            attribute status {"returned"},
            $event/*[fn:not( self::ldse:translation-returned )],
            element translation-returned {
                attribute date { $CURRENTDATE },
                attribute component-id {$component-id},
                attribute locale {$locale}
            }
        }</translation-event>
    return (
        if (fn:exists($event)) then (
            mem:node-replace($event, $new-event)
        ) else (
            mem:node-insert-child($ldse-meta, $new-event)
        )
    )
};

(:~
    updates the translation-event to be mark not-ready,

    @param $ldse-meta - The lds-meta element
    @param $reason - The reason the item is not-ready
    @return $ldse-meta as element(ldse:ldse-meta)
:)
declare function translation-mark-notready($ldse-meta as element(ldse:ldse-meta), $reason as xs:string) as element(ldse:ldse-meta) {
    let $ldse-meta as element(ldse:ldse-meta) := _remove-context($ldse-meta)
    let $event as element(ldse:translation-event)? := $ldse-meta/ldse:translation-event
    let $new-event as element(ldse:translation-event) :=
        <translation-event xmlns="http://lds.org/code/lds-edit">{
            attribute status {"not-ready"},
            $event/*[fn:not( self::ldse:translation-not-ready )],
            element translation-not-ready {
                $commonAttributes,
                attribute reason {$reason}
            }
        }</translation-event>
    return (
        if (fn:exists($event)) then (
            mem:node-replace($event, $new-event)
        ) else (
            mem:node-insert-child($ldse-meta, $new-event)
        )
    )
};

(:~
    updates the translation-event to be mark remove,
    Allows files not to be published and marked reviewed, but removed from the from-translation page.

    @param $ldse-meta - The lds-meta element
    @return $ldse-meta as element(ldse:ldse-meta)
:)
declare function translation-mark-removed($ldse-meta as element(ldse:ldse-meta)) as element(ldse:ldse-meta) {
    let $ldse-meta as element(ldse:ldse-meta) := _remove-context($ldse-meta)
    let $event as element(ldse:translation-event)? := $ldse-meta/ldse:translation-event
    let $new-event as element(ldse:translation-event) :=
        <translation-event xmlns="http://lds.org/code/lds-edit">{
            attribute status {"removed"},
            $event/*[fn:not( self::ldse:translation-removed )],
            element translation-removed {
                $commonAttributes
            }
        }</translation-event>
    return (
        if (fn:exists($event)) then (
            mem:node-replace($event, $new-event)
        ) else (
            mem:node-insert-child($ldse-meta, $new-event)
        )
    )
};

(:~
    Updates the translation-event to be mark complete
    An Item can only be marked complete if its not Enlish and has a translation-event

    @param $ldse-meta - The lds-meta element
    @return $ldse-meta as element(ldse:ldse-meta)
:)
declare function translation-mark-complete($ldse-meta as element(ldse:ldse-meta)) as element(ldse:ldse-meta) {
    if ( fn:exists($ldse-meta/ldse:translation-event) and _notEnglish($ldse-meta) ) then (
        let $ldse-meta as element(ldse:ldse-meta) := _remove-context($ldse-meta)
        let $event as element(ldse:translation-event)? := $ldse-meta/ldse:translation-event
        let $new-event as element(ldse:translation-event) :=
            <translation-event xmlns="http://lds.org/code/lds-edit">{
                attribute status {"complete"},
                $event/*[fn:not( self::ldse:translation-complete )],
                element translation-complete {
                    $commonAttributes
                }
            }</translation-event>
        return (
            if (fn:exists($event)) then (
                mem:node-replace($event, $new-event)
            ) else (
                mem:node-insert-child($ldse-meta, $new-event)
            )
        )
    ) else (
        (: No Action needed :)
        $ldse-meta
    )
};

(: Mark English Documents :)
declare function translation-eng-mark(
    $ldse-meta as element(ldse:ldse-meta),
    $status as xs:string,
    $node-name as xs:string
) as element(ldse:ldse-meta) {
    translation-mark($ldse-meta, $status, $node-name, (), fn:true())
};

(: Mark English Documents :)
declare function translation-eng-mark(
    $ldse-meta as element(ldse:ldse-meta),
    $status as xs:string,
    $node-name as xs:string,
    $childNodes as node()*
) as element(ldse:ldse-meta) {
    translation-mark($ldse-meta, $status, $node-name, $childNodes, fn:true())
};

(: Mark Non-English Documents :)
declare function translation-mark(
    $ldse-meta as element(ldse:ldse-meta),
    $status as xs:string,
    $node-name as xs:string
) as element(ldse:ldse-meta)  {
    translation-mark($ldse-meta, $status, $node-name, (), fn:false())
};

(: Mark Non-English Documents :)
declare function translation-mark(
    $ldse-meta as element(ldse:ldse-meta),
    $status as xs:string,
    $node-name as xs:string,
    $childNodes as node()*,
    $allow-eng as xs:boolean
) as element(ldse:ldse-meta)  {
    if ( _notCountry($ldse-meta) and ( $allow-eng or _notEnglish($ldse-meta) ) ) then (
        let $ldse-meta as element(ldse:ldse-meta) := _remove-context($ldse-meta)
        let $local-name as xs:string := functx:substring-after-if-contains($node-name, ':')
        let $QName as xs:QName := xs:QName( fn:concat("ldse:", $local-name) )
        let $event as element(ldse:translation-event)? := $ldse-meta/ldse:translation-event
        let $new-event as element(ldse:translation-event) :=
            <translation-event xmlns="http://lds.org/code/lds-edit">{
                attribute status {$status},
                $event/*[fn:not( fn:node-name(.) eq $QName )],
                element { $local-name } {
                    $commonAttributes,
                    $childNodes
                }
            }</translation-event>
        return (
            if (fn:exists($event)) then (
                mem:node-replace($event, $new-event)
            ) else (
                mem:node-insert-child($ldse-meta, $new-event)
            )
        )
    ) else (
        (: No Action needed :)
        $ldse-meta
    )
};

declare function translation-remove(
    $ldse-meta as element(ldse:ldse-meta),
    $new-status as xs:string,
    $node-name as xs:string
) as element(ldse:ldse-meta) {
    if ( _notCountry($ldse-meta) ) then (
        let $ldse-meta as element(ldse:ldse-meta) := _remove-context($ldse-meta)
        let $local-name as xs:string := functx:substring-after-if-contains($node-name, ':')
        let $QName as xs:QName := xs:QName( fn:concat("ldse:", $local-name) )
        let $event as element(ldse:translation-event)? := $ldse-meta/ldse:translation-event
        let $new-event as element(ldse:translation-event) :=
            <translation-event xmlns="http://lds.org/code/lds-edit">{
                attribute status {$new-status},
                $event/*[fn:not( fn:node-name(.) eq $QName )]
            }</translation-event>
        return (
            if (fn:exists($event)) then (
                mem:node-replace($event, $new-event)
            ) else (
                mem:node-insert-child($ldse-meta, $new-event)
            )
        )
    ) else (
        (: No Action needed :)
        $ldse-meta
    )
};

(: Removes the whole translation-event node :)
declare function translation-delete(
    $ldse-meta as element(ldse:ldse-meta)
) as element(ldse:ldse-meta) {
    if ( _notCountry($ldse-meta) ) then (
        let $ldse-meta as element(ldse:ldse-meta) := _remove-context($ldse-meta)
        let $event as element(ldse:translation-event)? := $ldse-meta/ldse:translation-event
        return (
            if (fn:exists($event)) then (
                mem:node-delete($event)
            ) else (
                $ldse-meta
            )
        )
    ) else (
        (: No Action needed :)
        $ldse-meta
    )
};


(: If this function is called by a task that doesn't have wam headers then set-user should be called before calling this function :)
(:~
    Updates the a english translation-event to be mark returned, only if the status is 'sent',
    @param $eng-id - eng id of the file
    @param $zip-name - zip file name
    @return $ldse-meta as element(ldse:ldse-meta)
:)
declare function translation-update-english-returned($englishFile as element(), $component-id as xs:string, $locale as xs:string) as empty-sequence() {
    let $addReturnToHistory as empty-sequence() := ()
    where $englishFile/ldse:ldse-meta/ldse:translation-event/@status eq 'sent'
    return (
        let $ldse-meta as element(ldse:ldse-meta) := get-ldse-meta($englishFile)/_remove-context(.)
        let $ldse-meta as element(ldse:ldse-meta) := translation-mark-returned($ldse-meta, $component-id, $locale)
        return (
            core:document-replace($englishFile/ldse:ldse-meta, $ldse-meta)
        )
    )
};
(: END OF TRANSLATION EVENT UPDATES :)


declare function get-translated-files-in-preview(
    $ldse:document as element(ldse:document)
) as element()* {
	let $id as xs:string := $ldse:document/@id/fn:string()
	let $id-value as xs:string := fn:replace($id, "^(.*)-.*$", "$1")
	return
		if ( $id-value ne $ldse:document/@id/fn:string() ) then (
			cts:search(/*,
				cts:and-query((
				    core:get-filter-query(),
					cts:element-attribute-value-query(xs:QName("ldse:document"), xs:QName("id"), fn:concat("*", $id-value, "*"), ("wildcarded","unstemmed")),
					cts:not-query(
						cts:element-attribute-value-query(xs:QName("ldse:document"), xs:QName("id"), $id, "exact")
					)
				)),
                "unfiltered"
            )
        ) else ()
};

declare function get-translated-files(
    $id as xs:string
) as element()* {
	let $id-value as xs:string := fn:replace($id, "^(.*)-.*$", "$1")

	return (
		if ( $id-value and fn:not($id-value = "") ) then (
			cts:search(fn:collection(),
				cts:and-query((
				    core:get-filter-query(),
					cts:element-attribute-value-query( xs:QName("ldse:document"), xs:QName("id"), fn:concat($id-value, "-*"), ("wildcarded", "unstemmed") ),
					cts:not-query(
						cts:element-attribute-value-query(xs:QName("ldse:document"), xs:QName("id"), $id, "exact")
					)
				)), "unfiltered"
			)/*
		) else ()
	)
};

declare function get-file-by(
    $id as xs:string?,
    $locale as xs:string?,
    $uri as xs:string?,
    $status as xs:string?
) as element()? {
    get-file-by($id, $locale, $uri, $status, ())
};

declare function get-file-by(
    $id as xs:string?,
    $locale as xs:string?,
    $uri as xs:string?,
    $status as xs:string?,
    $site as xs:string?
) as element()? {
    let $passed-values as xs:boolean := ($id, $locale, $uri, $status) != ""
    let $file as element()? :=
        if ( $passed-values ) then (
            cts:search(/*,
                cts:and-query((
                    core:get-filter-query(),
                    if ($id ne '') then (
                        cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('id'), $id, 'exact')
                    ) else (),
                    if ($uri ne '') then (
                        cts:element-attribute-range-query(xs:QName('ldse:document'), xs:QName('uri'), '=', $uri, "collation=http://marklogic.com/collation/")
                    ) else (),
                    if ($locale ne '') then (
                        cts:element-attribute-range-query(xs:QName('ldse:document'), xs:QName('locale'), '=', $locale, "collation=http://marklogic.com/collation/")
                    ) else (),
                    if ($status ne '') then (
                        cts:element-attribute-range-query(xs:QName('ldse:document'), xs:QName('status'), '=', $status, "collation=http://marklogic.com/collation/")
                    ) else (),
                    if ( fn:exists($site[. != '']) ) then (
                        cts:or-query((
                            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('site'), $site, 'exact'),
                            cts:element-value-query(xs:QName('ldse:site-context'), $site, 'exact')
                        ))
                    ) else ()
                ))
            )[1]
        ) else ()
    return (
        if (fn:exists($file) or fn:not($passed-values)) then ($file) else (
            get-file-by-old($id, $locale, $uri, $status)
        )
    )
};

declare function get-files-by(
    $id as xs:string*,
    $locale as xs:string*,
    $uri as xs:string*,
    $status as xs:string*
) as element()* {
    get-files-by($id, $locale, $uri, $status, ())
};

declare function get-files-by(
    $id as xs:string*,
    $locale as xs:string*,
    $uri as xs:string*,
    $status as xs:string*,
    $site as xs:string?
) as element()* {
    let $passed-values as xs:boolean := ($id, $locale, $uri, $status) != ""
    let $files as element()* :=
        if ( $passed-values ) then (
            cts:search(/*,
                cts:and-query((
                    core:get-filter-query(),
                    if ($id ne '') then (
                        cts:or-query((
                            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('id'), $id, 'exact'),
                            cts:element-value-query(xs:QName('name'), $id, 'exact')
                        ))
                    ) else (),
                    if ($uri ne '') then (
                        cts:or-query((
                        cts:element-attribute-range-query(xs:QName('ldse:document'), xs:QName('uri'), '=', $uri, "collation=http://marklogic.com/collation/"),
                        cts:element-value-query(xs:QName('name'), $id, 'exact')
                        ))                        
                    ) else (),
                    if ($locale ne '') then (
                        cts:element-attribute-range-query(xs:QName('ldse:document'), xs:QName('locale'), '=', $locale, "collation=http://marklogic.com/collation/")
                    ) else (),
                    if ($status ne '') then (
                        cts:element-attribute-range-query(xs:QName('ldse:document'), xs:QName('status'), '=', $status, "collation=http://marklogic.com/collation/")
                    ) else (),
                    if ( fn:exists($site[. != '']) ) then (
                        cts:or-query((
                            cts:element-attribute-value-query(xs:QName('resources'), xs:QName('site'), $site, 'exact'),
                            cts:element-value-query(xs:QName('ldse:site-context'), $site, 'exact')
                        ))
                    ) else ()
                ))
            )
        ) else ()
    return (
        if (fn:exists($files) or fn:not($passed-values)) then ($files) else (
            get-files-by-old($id, $locale, $uri, $status)
        )
    )
};

declare function get-file-by-id($id as xs:string?) as item()? {
    cts:search(/*,
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('id'), $id, "exact")
        )),
        "unfiltered"
    )[1]
};

declare function get-parent-file-by-child-id (
    $id as xs:string?,
    $uri as xs:string?,
    $locale as xs:string?,
    $site as xs:string?
) as item()? {
    let $searchParent as xs:string? :=
                cts:uris("", (),
                        cts:and-query((
                            core:get-filter-query(),
                            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('uri'), $uri, 'exact'),
                            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('locale'), $locale, 'exact'),
                            cts:element-value-query(xs:QName('ldse:site-context'), $site, 'exact'),
                            cts:word-query($id)
                        ))
                    )
    return (
        if(fn:exists($searchParent)) then (
            fn:doc($searchParent)
        ) else ()
    )
};

(:~
    Searchs for the same file in a different locale

    @param $file
    @param $locale - locale to search in
    @return $ldse-meta as element(ldse:ldse-meta)

:)
declare function get-file-in-locale($file as element(), $locales as xs:string*) as element()* {
    let $rootQName as xs:QName? := fn:node-name($file)
    let $id as xs:string := get-document-id($file)
    let $id-number as xs:string := fn:tokenize($id, '-')[1]
    let $uri as xs:string? := get-document-uri($file)
    let $newId as xs:string* :=
        for $locale as xs:string in $locales
        return (
            fn:concat($id-number, '-', $locale)
        )
    let $otherFile as element()* :=
        if ( fn:exists($newId) ) then (
            cts:search(/*,
                cts:and-query((
                    core:get-filter-query(),
                    cts:element-query($rootQName,
                        cts:and-query((
                            cts:element-attribute-value-query(xs:QName('ldse:document'), xs:QName('id'), $newId, ('exact')),
                            cts:element-attribute-range-query(xs:QName('ldse:document'), xs:QName('uri'), '=', $uri, "collation=http://marklogic.com/collation/"),
                            cts:element-attribute-range-query(xs:QName('ldse:document'), xs:QName('locale'), '=', $locales, "collation=http://marklogic.com/collation/")
                        ))
                    )
                ))
            )
        ) else ()
    return ($otherFile)
};


(: This should only be used if getFileBy was unable to locate the file using the new meta. :)
declare function get-file-by-old($id as xs:string?, $locale as xs:string?, $uri as xs:string?, $status as xs:string?) as element()? {
    let $roots as xs:QName* := $settings:root-qnames
    return (
        cts:search(/*,
            cts:and-query((
                core:get-filter-query(),
                if ($id ne '') then (
                    cts:or-query((
                        cts:element-attribute-value-query($roots, xs:QName('id'), $id, ("exact")),
                        cts:element-query(xs:QName('search-meta'),
                            cts:element-value-query(xs:QName('source'), $id, ("exact"))
                        )
                    ))
                 ) else (),
                 if ($uri ne '') then (
                     cts:or-query((
                         cts:element-attribute-value-query($roots, xs:QName('uri'), $uri, ("exact")),
                         cts:element-attribute-value-query($roots, xs:QName('page'), $uri, ("exact"))
                     ))
                 ) else (),
                 if ($locale ne '') then (
                     cts:element-attribute-value-query($roots, xs:QName('locale'), $locale, ("exact"))
                 ) else (),
                 if ($status ne '') then (
                     cts:element-attribute-value-query($roots, xs:QName('status'), $status, ("exact"))
                 ) else ()
            ))
        )[1]
    )
};

(: This should only be used if getFilesBy was unable to locate the file using the new meta. :)
declare function get-files-by-old($id as xs:string*, $locale as xs:string*, $uri as xs:string*, $status as xs:string*) as element()* {
    let $roots as xs:QName* := $settings:root-qnames
    return (
        cts:search(/*,
            cts:and-query((
                core:get-filter-query(),
                if ($id ne '') then (
                    cts:or-query((
                        cts:element-attribute-value-query($roots, xs:QName('id'), $id, ("exact")),
                        cts:element-query(xs:QName('search-meta'),
                            cts:element-value-query(xs:QName('source'), $id, ("exact"))
                        )
                    ))
                 ) else (),
                 if ($uri ne '') then (
                     cts:or-query((
                         cts:element-attribute-value-query($roots, xs:QName('uri'), $uri, ("exact")),
                         cts:element-attribute-value-query($roots, xs:QName('page'), $uri, ("exact"))
                     ))
                 ) else (),
                 if ($locale ne '') then (
                     cts:element-attribute-value-query($roots, xs:QName('locale'), $locale, ("exact"))
                 ) else (),
                 if ($status ne '') then (
                     cts:element-attribute-value-query($roots, xs:QName('status'), $status, ("exact"))
                 ) else ()
            ))
        )
    )
};

(: INTERNAL USE FUNCTIONS :)
(:~
    Returns true or false if the locale contains a hypen (-),  if the locale contains a hypen its consider country site content.

    @param $ldse-meta - The lds-meta element
    @return $notCountry as xs:boolean
:)
declare function _notCountry($ldse-meta as element(ldse:ldse-meta)) as xs:boolean {
    fn:not( fn:contains($ldse-meta/ldse:document/@locale, '-') )
};

(:~
    Returns true or false if the locale is not equal to 'eng'

    @param $ldse-meta - The lds-meta element
    @return $notEnglish as xs:boolean
:)
declare function _notEnglish($ldse-meta as element(ldse:ldse-meta)) as xs:boolean {
    fn:not( _isEnglish($ldse-meta) )
};

(:~
    Returns true or false if the locale equals 'eng'

    @param $ldse-meta - The lds-meta element
    @return $notEnglish as xs:boolean
:)
declare function _isEnglish($ldse-meta as element(ldse:ldse-meta)) as xs:boolean {
    $ldse-meta/ldse:document/@locale eq 'eng'
};

(:~
    Removes the document contents form the ldse-meta node so that if you called fn:root($ldse-meta)it will returned ldse-meta and not the document

    @param $ldse-meta - The lds-meta element
    @return $notEnglish as xs:boolean
:)
declare function _remove-context($ldse-meta as element(ldse:ldse-meta)) as element(ldse:ldse-meta) {
    util:clone($ldse-meta)
};

declare function _get-word-count($file as element()*) as xs:unsignedLong {
    xs:unsignedLong(
        fn:count(
            cts:tokenize(util:get-translated-words($file))[. instance of cts:word]
        )
    )
};

(: Returns a sequence, (words, tgp) :)
declare function _get-word-tgp($file as element()) as item()+ {
    let $words as xs:unsignedLong := _get-word-count($file)
    let $tgp as xs:double := fn:round-half-to-even(xs:double($words div 286), 4)
    return (
        $words, $tgp
    )
};

declare function _build-document($file as element(), $id as xs:string?, $locale as xs:string?, $uri as xs:string?, $status as xs:string?) as element(ldse:document) {
    let $wordsTGP as item()+ := _get-word-tgp($file)
    let $site as xs:string? := site:get-ldse-settings-by-port()/@application
    let $source as xs:string := get-document-source($file)
    let $id as xs:string? := if ($id ne '') then ($id) else (get-document-id($file))
    let $locale as xs:string? := if ($locale ne '') then ($locale) else (get-document-locale($file))
    let $uri as xs:string? := if ($uri ne '') then ($uri) else (get-document-uri($file))
    let $status as xs:string? := if ($status ne '') then ($status) else (get-document-status($file))
    let $title as xs:string? := core:get-title($file)
    let $type as xs:string? := core:get-type($file)
    return (
        <document xmlns="http://lds.org/code/lds-edit">{
            attribute id { $id },
            attribute locale { $locale },
            attribute uri { $uri },
            attribute status { $status },
            attribute site { $site },
            attribute source { $source },
            attribute words { $wordsTGP[1] },
            attribute tgp { $wordsTGP[2] },
            attribute env { $settings:environment },
            attribute title { $title },
            attribute type { $type }
        }</document>
    )
};

declare function _update-document($file as element(), $ldse-meta as element(ldse:ldse-meta), $id as xs:string?, $locale as xs:string?, $uri as xs:string?, $status as xs:string?) as element(ldse:ldse-meta) {
    let $ldse-meta as element(ldse:ldse-meta) := _remove-context($ldse-meta)
    let $document as element(ldse:document)? := $ldse-meta/ldse:document
    let $new as element(ldse:document) := _build-document($file, $id, $locale, $uri, $status)
    return (
        if (fn:exists($document)) then (
            mem:node-replace($document, $new)
        ) else (
            mem:node-insert-child($ldse-meta, $new)
        )
    )
};

declare function update-document-source($ldse-meta as element(ldse:ldse-meta)) as element(ldse:ldse-meta) {
    let $ldse-meta as element(ldse:ldse-meta) := _remove-context($ldse-meta)
    let $locale as xs:string? := $ldse-meta/ldse:document/@locale
    let $source as attribute() :=
        attribute source {
            if ( fn:contains($locale, '-') ) then (
               fn:substring-after($locale, '-')
            ) else (
                'chq'
            )
        }
    return (
        mem:node-replace($ldse-meta/ldse:document/@source, $source)
    )
};

declare function _update-lastmodified($ldse-meta as element(ldse:ldse-meta)) as element(ldse:ldse-meta) {
    let $ldse-meta as element(ldse:ldse-meta) := _remove-context($ldse-meta)
    let $existing as element(ldse:last-modified)? := $ldse-meta/ldse:last-modified
    let $update as element(ldse:last-modified) := _build-lastmodified()
    return (
        if (fn:exists($existing)) then (
            mem:node-replace($existing, $update)
        ) else (
            mem:node-insert-child($ldse-meta, $update)
        )
    )
};

declare function _build-unpublish-date() as element(ldse:unpublish-date) {
    <unpublish-date xmlns="http://lds.org/code/lds-edit">{
        $commonAttributes
    }</unpublish-date>
};

declare function _build-publish-date() as element(ldse:publish-date) {
    <publish-date xmlns="http://lds.org/code/lds-edit">{
        $commonAttributes
    }</publish-date>
};

declare function _build-lastmodified() as element(ldse:last-modified) {
    <last-modified xmlns="http://lds.org/code/lds-edit">{
        $commonAttributes
    }</last-modified>
};

declare function _build-created() as element(ldse:created) {
    <created xmlns="http://lds.org/code/lds-edit">{ $commonAttributes }</created>
};

declare function _build-schedule-publish($date as xs:date, $time as xs:time) as element(ldse:schedule-publish) {
    <schedule-publish xmlns="http://lds.org/code/lds-edit">{
        attribute username {$USERNAME},
        attribute userid {$USERID},
        attribute date {$date},
        attribute time {$time},
        attribute dateTime {fn:dateTime($date, $time)}
    }</schedule-publish>
};

declare function _build-schedule-unpublish($date as xs:date, $time as xs:time) as element(ldse:schedule-unpublish) {
    <schedule-unpublish xmlns="http://lds.org/code/lds-edit">{
        attribute username {$USERNAME},
        attribute userid {$USERID},
        attribute date {$date},
        attribute time {$time},
        attribute dateTime {fn:dateTime($date, $time)}
    }</schedule-unpublish>
};

declare function _build-default-meta($file as element(), $id as xs:string?, $locale as xs:string?, $uri as xs:string?, $status as xs:string?) as element(ldse:ldse-meta) {
    <ldse-meta xmlns="http://lds.org/code/lds-edit">{
        attribute its:translate {"no"},
        _build-document($file, $id, $locale, $uri, $status),
        build-form-options($file),
        _build-created(),
        _build-lastmodified()
    }</ldse-meta>
};

(: *********************************
        ldsemeta is functions
   ********************************* :)
declare function is-published($file as element()?) as xs:boolean {
    fn:exists(get-publish-date($file))
};

(: *********************************
       XPATH Functions
   ********************************* :)

declare function get-ldse-meta($file as element()) as element(ldse:ldse-meta)? {
    $file/ldse:ldse-meta
};

(: XPATH ldse:document:)
declare function get-ldse-document($file as element()) as element(ldse:document)? {
    $file/ldse:ldse-meta/ldse:document
};

declare function get-document-id($file as element()) as xs:string? {
    let $id as xs:string? := $file/ldse:ldse-meta/ldse:document/@id
    return (
        if ($id ne '') then ($id) else (convert:get-id($file))
    )
};

declare function get-document-locale($file as element()) as xs:string? {
    let $locale as xs:string? := $file/ldse:ldse-meta/ldse:document/@locale
    return (
        if ($locale ne '') then ($locale) else (convert:get-locale($file))
    )
};

declare function get-document-source($file as element()) as xs:string {
    let $source as xs:string? := $file/ldse:ldse-meta/ldse:document/@source
    return (
        if ($source ne '') then ($source) else (convert:get-source($file, get-document-locale($file)))
    )
};

declare function get-document-site($file as element()) as xs:string? {
    let $site as xs:string? := $file/ldse:ldse-meta/ldse:document/@site
    return (
        if ($site ne '') then ($site) else ($core:site)
    )
};

declare function get-document-uri($file as element()) as xs:string? {
     get-document-uri($file, fn:false())
};

declare function get-document-uri($file as element(), $remove-hash as xs:boolean) as xs:string? {
     let $uri as xs:string? := $file/ldse:ldse-meta/ldse:document/@uri
     let $uri as xs:string? := if ($uri ne '') then ($uri) else (convert:get-uri($file))
     return (
         if ($remove-hash) then (
             fn:replace($uri, '(#.*)', '')
         ) else (
            $uri
         )
     )
};

declare function get-history-document-uri($file as element()) as xs:string? {
     get-history-document-uri($file, fn:false())
};

declare function get-history-document-uri($file as element(), $remove-hash as xs:boolean) as xs:string? {
     let $uri as xs:string? := $file/hldse:current/hldse:ldse-meta/hldse:document/@uri
     let $uri as xs:string? := if ($uri ne '') then ($uri) else (convert:get-uri($file))
     return (
         if ($remove-hash) then (
             fn:replace($uri, '(#.*)', '')
         ) else (
            $uri
         )
     )
};

declare function get-document-status($file as element()) as xs:string? {
     let $status as xs:string? := $file/ldse:ldse-meta/ldse:document/@status
     return (
         if ($status ne '') then ($status) else (convert:get-status($file))
     )
};

declare function get-document-words($file as element()) as xs:unsignedLong? {
     let $words as xs:unsignedLong? := $file/ldse:ldse-meta/ldse:document/@words/xs:unsignedLong(.)
     return (
         if ( fn:exists($words) ) then ( $words ) else ( _get-word-count($file) )
     )
};

declare function get-document-tgp($file as element()) as xs:double? {
     let $tgp as xs:double? := $file/ldse:ldse-meta/ldse:document/ldse:document/@tgp/xs:double(.)
     return (
         if ( fn:exists($tgp) ) then ( $tgp ) else ( fn:round-half-to-even(xs:double(get-document-words($file) div 286), 4) )
     )
};

(: XPATH ldse:publish-date :)

declare function get-publish-date($file as element()) as element(ldse:publish-date)? {
    $file/ldse:ldse-meta/ldse:publish-date
};

(: XPATH ldse:publish-date :)

declare function get-unpublish-date($file as element()) as element(ldse:unpublish-date)? {
    $file/ldse:ldse-meta/ldse:unpublish-date
};

(: XPATH ldse:created-date :)

declare function get-created-date($file as element()) as element(ldse:created)? {
    $file/ldse:ldse-meta/ldse:created
};

(: XPATH ldse:last-modified :)

declare function get-last-modified($file as element()) as element(ldse:last-modified)? {
    $file/ldse:ldse-meta/ldse:last-modified
};

declare function get-last-modified-date($file as element()) as xs:dateTime?
{
	let $last-modified-element as element(ldse:last-modified)? := get-last-modified($file)
	let $last-modified-date as xs:string? := $last-modified-element/@date/fn:string(.)[. ne ""]
	return
		if($last-modified-date castable as xs:dateTime)
		then xs:dateTime($last-modified-date)
		else ()
};

(: XPATH ldse:scheduled-publish :)

declare function get-schedule-publish($file as element()) as element(ldse:schedule-publish)? {
    $file/ldse:ldse-meta/ldse:schedule-publish
};

declare function get-schedule-publish-date($file as element()) as xs:dateTime?
{
	let $sp as element(ldse:schedule-publish)? := get-schedule-publish($file)
	return
		if($sp/@dateTime castable as xs:dateTime)
		then xs:dateTime($sp/@dateTime)
		else ()
};

(: XPATH ldse:scheduled-unpublish :)

declare function get-schedule-unpublish($file as element()) as element(ldse:schedule-unpublish)? {
    $file/ldse:ldse-meta/ldse:schedule-unpublish
};

declare function get-schedule-unpublish-date($file as element()) as xs:dateTime?
{
	let $sup as element(ldse:schedule-unpublish)? := get-schedule-unpublish($file)
	return
		if($sup/@dateTime castable as xs:dateTime)
		then xs:dateTime($sup/@dateTime)
		else ()
};

(: XPATH ldse:translation-event :)
declare function get-translation-event($file as element()) as element(ldse:translation-event)? {
    $file/ldse:ldse-meta/ldse:translation-event
};

declare function get-translation-event-status($file as element()) as xs:string? {
    $file/ldse:ldse-meta/ldse:translation-event/@status
};

declare function get-translation-ready($file as element()) as element(ldse:translation-ready)? {
    $file/ldse:ldse-meta/ldse:translation-event/ldse:translation-ready
};

declare function get-translation-sent($file as element()) as element(ldse:translation-sent)? {
    $file/ldse:ldse-meta/ldse:translation-event/ldse:translation-sent
};

declare function get-translation-returned($file as element()) as element(ldse:translation-returned)? {
    ($file/ldse:ldse-meta/ldse:translation-event/ldse:translation-returned)[1]
};

declare function get-translation-not-ready($file as element()) as element(ldse:translation-not-ready)? {
    $file/ldse:ldse-meta/ldse:translation-event/ldse:translation-not-ready
};

declare function get-translation-reviewed($file as element()) as element(ldse:translation-reviewed)? {
    $file/ldse:ldse-meta/ldse:translation-event/ldse:translation-reviewed
};

(: XPATH ldse:form-options :)
declare function get-form-options($file as element()) as element(form-options)? {
    (util:strip-namespaces($file/ldse:ldse-meta/ldse:form-options), $file/form-options)[1]
};

declare function build-form-options($file as element()) as element(ldse:form-options)? {
    ($file/ldse:ldse-meta/ldse:form-options, util:renamespace($file/form-options, "http://lds.org/code/lds-edit"))[1]
};

declare function get-correlation($file as element()) as element(ldse:correlation)? {
    $file/ldse:ldse-meta/ldse:correlation
};

declare function get-correlation-status-date($file as element()) as xs:dateTime? {
	let $status-date as xs:string? := get-correlation($file)/@status-date/fn:string(.)
	return
		if($status-date castable as xs:dateTime)
		then xs:dateTime($status-date)
		else ()
};

declare function get-correlation-sent-date($file as element()) as xs:dateTime? {
	let $sent-date as xs:string? := get-correlation($file)/@sent-date/fn:string(.)
	return
		if($sent-date castable as xs:dateTime)
		then xs:dateTime($sent-date)
		else ()
};

declare function get-correlation-user($file as element()) as xs:string? {
    get-correlation($file)/@username/xs:string(.)
};

declare function get-correlation-status($file as element()) as xs:string? {
    get-correlation($file)/@status/xs:string(.)
};

declare function get-correlation-status-or-default($file as element()) as xs:string {
	typeswitch($file)
		case element(custom-page) return "Not Eligible"
		default return (get-correlation-status($file), "Not Sent")[1]
};

declare function get-correlation-cor-status($file as element()) as xs:string? {
    get-correlation($file)/@cor-status/xs:string(.)
};

declare function get-correlation-class-hint($file as element()) as xs:string {
	fn:lower-case(fn:replace(get-correlation-status-or-default($file), " ", ""))
};

declare function correlation-can-send($file as element()) as xs:boolean
{
	let $status as xs:string? := get-correlation-status($file)

	return
		if($correlation:correlation-settings/ldse:exception-site = "true")
		then fn:false()

		else if($status = "Error Sending")
		then fn:true()

		else if($status = "In Correlation")
		then fn:false()

		else
			(
				ac:has-permission('ldse:correlation-send', '', '')
				and
				(
					submission-submitted($file)
					or fn:not(is-submission($file))
				)
				and
				(
					(
						$status eq ("Declined", "Approved")
						and get-correlation-is-modified($file)
					)
					or $status = "Not Sent"
					or fn:not($status)
				)
			)
};

declare function correlation-can-publish($file as element()?) as xs:boolean
{
	let $cor-status as xs:string? := get-correlation-cor-status($file)
	return
		if(
			$correlation:correlation-settings/ldse:exception-site = "true"
			or fn:not($settings:correlation-enabled)
		)
		then fn:true()

		else if(fn:not(fn:exists($file)))
		then fn:false()

		else if(_isEnglish(get-ldse-meta($file)))
		then
			if(ac:has-permission('ldse:correlation-prepublisher', '', ''))
			then fn:true()

			else if(fn:not(get-correlation-is-modified($file)))
			then
				if($cor-status = "Approved")
				then fn:true()
				else fn:false()

			else fn:false()

		else fn:true()
};

declare function collection-manager-correlation-can-publish($file as element()?) as xs:boolean
{
	fn:exists($file)
	and $correlation:correlation-settings/ldse:exception-site eq "true"
	or fn:not($settings:correlation-enabled)
	or _notEnglish(get-ldse-meta($file))
	or (
		(fn:not(get-correlation-is-modified($file)) and get-correlation-status($file) eq "Approved")
	)
};

declare function get-correlation-is-modified($file as element()?) as xs:boolean
{
	get-correlation($file)/@is-modified eq "true" or fn:not($file)
};

declare function static-status($file as element()) as xs:string? {
	let $status as xs:string? := get-document-status($file)
	let $is-submission as xs:boolean := is-submission($file)
	let $submission-submitted as xs:boolean := submission-submitted($file)

    return (
    	if($is-submission and fn:not($submission-submitted))
    	then "created"

    	else if($is-submission and $submission-submitted and fn:not(submission-edited($file)) and fn:not(get-submission-date($file) < get-last-modified-date($file)))
    	then "submitted"

    	else if ($status eq "preview") then (
            if (fn:exists(get-schedule-publish($file))) then (
                "modified"
            ) else ("draft")
        ) else if ($status eq "publish") then (
            "published"
        ) else if ($status eq "remove-from-page") then (
            "removed"
        ) else if ($status eq "unpublish") then (
            "unpublished"
        ) else ($status)
    )
};

declare function get-document-title($file as element()) as xs:string? {
	let $title as xs:string? := $file/ldse:ldse-meta/ldse:document/@title

	let $title as xs:string? :=
		if ( fn:exists($title[fn:not(. = "")]) and fn:exists($title))
		then $title
		else core:get-title($file)

	let $title as xs:string? :=
		if ( fn:exists($title[fn:not(. = "")]) and fn:exists($title))
		then fn:replace($title, "^Page.xml \(\)$", "Page.xml")
		else $title

	return $title
};

declare function get-document-type($file as element()) as xs:string? {
    let $type as xs:string? := $file/ldse:ldse-meta/ldse:document/@type
    return (
        if ( fn:exists($type) ) then (
            $type
        ) else (
            core:get-type($file)
        )
    )
};

declare function get-history-document-type($file as element()) as xs:string? {
    let $type as xs:string? := $file/hldse:current/hldse:ldse-meta/hldse:document/@type
    return (
        if ( fn:exists($type) ) then (
            $type
        ) else (
            core:get-type($file)
        )
    )
};

declare function get-history-document-title($file as element()) as xs:string? {
    let $title as xs:string? := $file/hldse:current/hldse:ldse-meta/hldse:document/@title
    return (
        if (fn:exists($title)) then (
            $title
        ) else (
            core:get-title($file)
        )
    )
};

declare function is-modified($file as element()) as xs:boolean
{
	let $published-date as xs:dateTime? := get-publish-date($file)/@date
	let $modified-date as xs:dateTime? := get-last-modified-date($file)
	return
		if(fn:exists($published-date) and fn:exists($modified-date))
		then
			$modified-date > $published-date
		else fn:false()
};

declare function get-translation-star($file as element()) as xs:string {
    let $star as xs:string? := $file/ldse:ldse-meta/ldse:translation-event/ldse:translation-ready/@star
    return
        if ( $star = "true" ) then (
            "starred"
        ) else ("")
};

declare function get-root-string(
    $uri as xs:string
) as xs:string {
    let $uri as xs:string:= functx:replace-first($uri, ($settings:shared-prefix[. ne ''], '/')[1], '')
    return (
        if (fn:contains($uri, '/')) then (
            fn:substring-before($uri, '/')
        ) else if ($uri eq '') then (
           'home-page'
        ) else (
            $uri
        )
    )
};

declare function is-submission($file as element()?) as xs:boolean
{
	fn:exists(get-submission($file))
};

declare function get-submission($file as element()?) as element(ldse:submission)?
{
	get-ldse-meta($file)/ldse:submission
};

declare function get-creator($file as element()?) as xs:string?
{
	get-ldse-meta($file)/ldse:created/@username/fn:string(.)
};

declare function get-modifier($file as element()?) as xs:string?
{
	get-ldse-meta($file)/ldse:last-modified/@username/fn:string(.)
};

declare function get-modifier-id($file as element()?) as xs:string?
{
	get-ldse-meta($file)/ldse:last-modified/@userid/fn:string(.)
};
declare function user-created-file($file as element()?) as xs:boolean
{
	$USERNAME = ldsemeta:get-creator($file)
};

declare function get-submission-status($file as element()?) as xs:string?
{
	get-submission($file)/@status/fn:string(.)
};

declare function submission-submitted($file as element()?) as xs:boolean
{
	get-submission-status($file) = "submitted"
};

declare function submission-edited($file as element()) as xs:boolean
{
	get-submission($file)/@edited = "true"
};

declare function get-submission-date($file as element()?) as xs:dateTime?
{
	let $date as xs:string? := get-submission($file)/@date/fn:string(.)
	return
		if($date castable as xs:dateTime)
		then xs:dateTime($date)
		else ()
};

declare function get-returned-dateTime($file as element()?) as xs:dateTime?
{
	let $date as xs:string? := get-submission($file)/@returned/fn:string(.)
	return
		if($date castable as xs:dateTime)
		then xs:dateTime($date)
		else ()
};

declare function get-submitted-by($file as element()?) as xs:string?
{
	get-submission($file)[@status = "submitted"]/@username/fn:string(.)
};

declare function update-submission-status($file as element(), $status as xs:string, $edited as xs:boolean) as element()?
{
	update-submission-status($file, $status, $edited, fn:false())
};

declare function update-submission-status($file as element(), $status as xs:string, $edited as xs:boolean, $return as xs:boolean) as element()?
{
	update-submission-status($file, $status, $edited, $return, fn:current-dateTime())
};

declare function update-submission-status($file as element(), $status as xs:string, $edited as xs:boolean, $return as xs:boolean, $status-date-time as xs:dateTime) as element()
{
	let $ldse-meta as element(ldse:ldse-meta) := get-ldse-meta($file)
    let $old-submission-element as element(ldse:submission)? := get-submission($file)
	let $submission-element as element(ldse:submission) :=
		<submission xmlns="http://lds.org/code/lds-edit" status="{$status}" date="{$status-date-time}">
		{
			attribute username {$USERNAME},
			attribute userid {$USERID},
			if($edited)
			then attribute edited {"true"}
			else (),
			if($return)
			then attribute returned {fn:current-dateTime()}
			else ()
		}
		</submission>

    return
		if( fn:exists($old-submission-element) )
		then mem:node-replace($old-submission-element, $submission-element)
		else mem:node-insert-child($ldse-meta, $submission-element)
};

declare function get-seo($file as element()) as element(ldse:seo)?
{
	$file/ldse:ldse-meta/ldse:seo
};

declare function get-seo-score($file as element()) as xs:string
{
	(get-seo($file)/ldse:score/@result, "not_scored")[1]
};

declare function update-seo-score($file as element(), $score as element(ldse:score)) as element()
{
	let $ldse-meta as element(ldse:ldse-meta) := get-ldse-meta($file)
    let $seo-element as element(ldse:seo)? := get-seo($file)
    let $seo-score-element as element(ldse:score)? := $seo-element/ldse:score

	let $new-seo-score-element as element(ldse:score) :=
		<score xmlns="http://lds.org/code/lds-edit" date="{fn:current-dateTime()}" username="{$USERNAME}" userid="{$USERID}" result="{$score/ldse:score}">
		{
			$score/element()
		}
		</score>

	let $new-seo-element as element(ldse:seo) :=
		<seo xmlns="http://lds.org/code/lds-edit">
		{
			$seo-element/@*,
			$seo-element/node() except $seo-element/ldse:score,
			$new-seo-score-element
		}
		</seo>

    return
		if( fn:exists($seo-element) )
		then mem:node-replace($seo-element, $new-seo-element)
		else mem:node-insert-child($ldse-meta, $new-seo-element)
};

declare function is-not-sensitive($file as element()) as xs:boolean {
    let $sensitive-element as element()? := get-sensitive($file)
    return (
        $sensitive-element/@status = "no" or fn:empty($sensitive-element/@status) or $sensitive-element/@status = ""
    )
};

declare function is-approved($file as element()) as xs:boolean {
    get-sensitive($file)/@needs-approval = "no"
};

declare function get-sensitive($file as element()) as element(ldse:sensitive)? {
    get-ldse-meta($file)/ldse:sensitive
};

declare function update-sensitive-meta(
    $ldse-meta as element(),
    $sensitive as xs:string?,
    $stakeholder as xs:string?,
    $request as xs:string?,
    $approval-sent as xs:string?,
    $status as xs:string?,
    $other-stakeholders as xs:string*
) as item() {
    let $curr-sensitive-element as element(ldse:sensitive)? := $ldse-meta/ldse:sensitive
    let $stakeholder-uname as xs:string? :=
        if ( $stakeholder ) then (
            fn:lower-case($stakeholder)
        ) else (
            $curr-sensitive-element/@stakeholder
        )
    let $sensitive-element as element(ldse:sensitive) :=
        if ( $sensitive = "no" ) then (
            <sensitive xmlns="http://lds.org/code/lds-edit"> {
                attribute status { $sensitive },
                attribute username { $USERNAME },
                attribute userid { $USERID },
                attribute last-changed { fn:current-dateTime() },
                if ( fn:not($other-stakeholders = "") and fn:exists($other-stakeholders) ) then (
                    <emails>
                        {
                            for $name as xs:string in $other-stakeholders
                            return (
                                <email name="{$name}"/>
                            )
                        }
                    </emails>
                ) else (
                    $curr-sensitive-element/ldse:emails
                )
            }</sensitive>
        ) else (
            <sensitive xmlns="http://lds.org/code/lds-edit"> {
                attribute status { ($sensitive, $curr-sensitive-element/@status)[1] },
                attribute username { $USERNAME },
                attribute userid { $USERID },
                attribute last-changed { fn:current-dateTime() },
                attribute stakeholder { ($stakeholder, $curr-sensitive-element/@stakeholder)[1] },
                attribute needs-approval { if ( $status = "ldse:publish" ) then ( "yes" ) else ( ($request, "yes")[1] ) },
                attribute approval-sent { ($approval-sent, $curr-sensitive-element/@approval-sent, "no")[1] },
                if ( ( $curr-sensitive-element/@needs-approval = "no" or $request = "no" ) and fn:not($status = "ldse:publish") ) then ( attribute approval-date { ($curr-sensitive-element/@approval-date, fn:current-dateTime())[1] } ) else (),
                if ( fn:not($other-stakeholders = "") and fn:exists($other-stakeholders) ) then (
                    <emails>
                        {
                            for $name as xs:string in $other-stakeholders
                            return (
                                <email name="{$name}"/>
                            )
                        }
                    </emails>
                ) else (
                    $curr-sensitive-element/ldse:emails
                )
            } </sensitive>
        )
    let $ldse-meta as item() :=
        if ( $curr-sensitive-element and
             (fn:not($curr-sensitive-element/@status = $sensitive) or
             $stakeholder != $curr-sensitive-element/@stakeholder or
             $approval-sent != $curr-sensitive-element/@approval-sent or
             $curr-sensitive-element/@needs-approval != $request or
             ( fn:exists($other-stakeholders) and fn:not($other-stakeholders = "")) )
        ) then (
            mem:node-replace($ldse-meta/ldse:sensitive, $sensitive-element)
        ) else if ( fn:empty($curr-sensitive-element) ) then (
            mem:node-insert-child($ldse-meta, $sensitive-element)
        ) else (
            $ldse-meta
        )
    return (
        $ldse-meta
    )
};

declare function update-sensitive(
    $file as element(),
    $sensitive as xs:string?,
    $stakeholder as xs:string?,
    $request as xs:string?,
    $approval-sent as xs:string?,
    $action as xs:string?,
    $other-stakeholders as xs:string*
) as item() {
    let $curr-sensitive-element as element(ldse:sensitive)? := $file/ldse:ldse-meta/ldse:sensitive
    let $stakeholder-uname as xs:string? :=
        if ( $stakeholder ) then (
            fn:lower-case($stakeholder)
        ) else (
            $curr-sensitive-element/@stakeholder
        )
    let $sensitive-element as element(ldse:sensitive) :=
        if ( $sensitive = "no" ) then (
            <sensitive xmlns="http://lds.org/code/lds-edit"> {
                attribute status { $sensitive },
                attribute username { $USERNAME },
                attribute userid { $USERID },
                attribute last-changed { fn:current-dateTime() },
                if ( fn:not($other-stakeholders = "") and fn:exists($other-stakeholders) ) then (
                    <emails>
                        {
                            for $name as xs:string in $other-stakeholders
                            return (
                                <email name="{$name}"/>
                            )
                        }
                    </emails>
                ) else (
                    $curr-sensitive-element/ldse:emails
                )
            }</sensitive>
        ) else (
            <sensitive xmlns="http://lds.org/code/lds-edit"> {
                attribute status { ($sensitive, $curr-sensitive-element/@status)[1] },
                attribute username { $USERNAME },
                attribute userid { $USERID },
                attribute last-changed { fn:current-dateTime() },
                attribute stakeholder { $stakeholder-uname },
                attribute needs-approval { if ( $action = "ldse:publish" ) then ( "yes" ) else ( ($request, "yes")[1] ) },
                attribute approval-sent { ($approval-sent, $curr-sensitive-element/@approval-sent, "no")[1] },
                if ( ( $curr-sensitive-element/@needs-approval = "no" or $request = "no" ) and fn:not($action = "ldse:publish") ) then ( attribute approval-date { ($curr-sensitive-element/@approval-date, fn:current-dateTime())[1] } ) else (),
                if ( fn:not($other-stakeholders = "") and fn:exists($other-stakeholders) ) then (
                    <emails>
                        {
                            for $name as xs:string in $other-stakeholders
                            return (
                                <email name="{$name}"/>
                            )
                        }
                    </emails>
                ) else (
                    $curr-sensitive-element/ldse:emails
                )
            } </sensitive>
        )
    let $file as item() :=
        if ( $curr-sensitive-element and
             ( fn:not($curr-sensitive-element/@status = $sensitive) or
             $stakeholder != $curr-sensitive-element/@stakeholder or
             $approval-sent != $curr-sensitive-element/@approval-sent or
             $curr-sensitive-element/@needs-approval != $request or
             ( fn:exists($other-stakeholders) and fn:not($other-stakeholders = "")) )
        ) then (
            mem:node-replace($file/ldse:ldse-meta/ldse:sensitive, $sensitive-element)
        ) else if ( fn:empty($curr-sensitive-element) ) then (
            mem:node-insert-child($file/ldse:ldse-meta, $sensitive-element)
        ) else (
            $file
        )
    return (
        $file
    )
};

declare function update-sensitive-file(
    $file as element(),
    $sensitive as xs:string?,
    $stakeholder as xs:string?,
    $request as xs:string?,
    $approval-sent as xs:string?,
    $action as xs:string?,
    $other-stakeholders as xs:string*
) as element() {
    if ( fn:exists($file/ldse:ldse-meta) ) then (
        let $new-file as item() := update-sensitive($file, $sensitive, $stakeholder, $request, $approval-sent, $action, $other-stakeholders)
        let $new-file as item() := mem:node-replace($file, $new-file)
        return (
            $new-file/*
        )
    ) else ( $file )
};

declare function update-sensitive-collection-file(
    $file as element(),
    $sensitive as xs:string?,
    $stakeholder as xs:string?,
    $request as xs:string?,
    $approval-sent as xs:string?,
    $action as xs:string?,
    $other-stakeholders as xs:string*
) as element() {
    if ( fn:exists($file/ldse:ldse-meta) ) then (
        let $new-file as item() := update-sensitive($file, $sensitive, $stakeholder, $request, $approval-sent, $action, $other-stakeholders)
        let $new-file as item() := mem:node-replace($file, $new-file)
        return (
            $new-file
        )
    ) else ( $file )
};
