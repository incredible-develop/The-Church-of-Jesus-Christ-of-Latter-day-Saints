xquery version "1.0-ml";

module namespace history = "http://lds.org/code/shared/lds-edit/history/history";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "/modules/ldse-meta.xqy";
import module namespace mem = "http://lds.org/code/shared/common/memory-update" at "/shared/common/util/inMemoryUpdate.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "/modules/ldse-core.xqy";
import module namespace spawn = "http://lds.org/code/shared/lds-edit/function-apply" at "/invoke/function-apply.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "/modules/utility-functions.xqy";
import module namespace json = "http://marklogic.com/json" at "/modules/fasterjson.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "/modules/ldse-settings.xqy";
import module namespace security = "http://lds.org/code/shared/common/security/security-functions" at "/shared/common/security/securityFunctions.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "/modules/access-control-functions.xqy";
import module namespace correlation = "http://lds.org/code/shared/lds-edit/correlation" at "/correlation/modules/correlation-functions.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace hldse = "http://lds.org/code/lds-edit/history";
declare namespace cldse = "http://lds.org/code/lds-edit/correlation";

declare option xdmp:mapping "true";

declare variable $currentUser as xs:string? := ac:getUserName();
declare variable $values as element(values) := (
    <values>
        <value icon="ldse-icon-globe" type="translation-ready">Content marked as requiring translation</value>
        <value icon="ldse-icon-globe" type="translation-approved">Content approved to be sent to translation</value>
        <value icon="ldse-icon-globe" type="translation-sent">Content sent to translation</value>
        <value icon="ldse-icon-globe" type="translation-returned">Content returned from translation</value>
        <value icon="ldse-icon-globe" type="translation-reviewed">Content reviewed</value>
        <value icon="ldse-icon-globe" type="translation-not-ready" class="red">Content not ready for translation</value>
        <value icon="ldse-icon-globe" type="translation-removed">Content removed from translation</value>
        <value icon="ldse-icon-edit" type="document-created">Content created</value>
        <value icon="ldse-icon-edit" type="document-edited">Content edited</value>
        <value icon="ldse-icon-send" type="document-published" class="green">Content published successfully</value>
        <value icon="ldse-icon-unpublish" type="document-unpublished" class="red">Content unpublished</value>
        <value icon="ldse-icon-ko-remove" type="document-removed" class="red">Content removed</value>
        <value icon="ldse-icon-trash" type="document-deleted">Content deleted</value>
        <value icon="ldse-icon-comments" type="comment"></value>
		<value icon="ldse-icon-review" type="submission-submitted">Content submitted</value>
		<value icon="ldse-icon-revert" type="submission-returned">Content submission returned</value>
		<value icon="ldse-icon-clock" type="scheduled-publish">Scheduled to be published</value>
		<value icon="ldse-icon-clock" type="scheduled-unpublish">Scheduled to be unpublished</value>
		<value icon="ldse-icon-clock" type="scheduled-publish-removed">Schedule published removed</value>
        <value icon="ldse-icon-clock" type="scheduled-unpublish-removed">Schedule unpublished removed</value>
		<value icon="ldse-icon-edit" type="document-uri-changed"/>

        <value icon="ldse-icon-globe" type="page-translation-ready">Page marked as requiring translation</value>
        <value icon="ldse-icon-globe" type="page-translation-approved">Page approved to be sent to translation</value>
        <value icon="ldse-icon-globe" type="page-translation-sent">Page sent to translation</value>
        <value icon="ldse-icon-globe" type="page-translation-returned">Page returned from translation</value>
        <value icon="ldse-icon-globe" type="page-translation-reviewed">Page reviewed</value>
        <value icon="ldse-icon-globe" type="page-translation-not-ready" class="red">Page not ready for translation</value>
        <value icon="ldse-icon-globe" type="page-translation-removed">Page removed from translation</value>
        <value icon="ldse-icon-edit" type="page-document-created">Page created</value>
        <value icon="ldse-icon-edit" type="page-document-edited">Page edited</value>
        <value icon="ldse-icon-send" type="page-document-published" class="green">Page published successfully</value>
        <value icon="ldse-icon-unpublish" type="page-document-unpublished" class="red">Page unpublished</value>
        <value icon="ldse-icon-ko-remove" type="page-document-removed" class="red">Page removed</value>
        <value icon="ldse-icon-trash" type="page-document-deleted">Page deleted</value>
		<value icon="ldse-icon-review" type="page-submission-submitted">Page submitted</value>
		<value icon="ldse-icon-revert" type="page-submission-returned">Page Submission Returned</value>
		<value icon="ldse-icon-edit" type="page-document-uri-changed"/>

        <value icon="ldse-icon-legal" type="correlation-sent">Content sent to Cor-IP / Cor-Eval.</value>
        <value icon="ldse-icon-legal" type="correlation-errorsending">Error while sending Content Cor-IP / Cor-Eval.</value>
        <value icon="ldse-icon-legal" type="correlation-incorrelation">Content accepted by Cor-IP / Cor-Eval.</value>
        <value icon="ldse-icon-legal" type="correlation-approved" class="green"/>
        <value icon="ldse-icon-legal" type="correlation-declined" class="red">Cor-IP / Cor-Eval declined recieved.</value>
        <value icon="ldse-icon-versions" type="version-restore">Previous version was restored from:</value>
		<value icon="ldse-icon-flag" type="following" class="hidden"/>
		<value icon="ldse-icon-review" type="sensitive-approved-sensitive" class="">Stakeholder has approved item to be published.</value>
		<value icon="ldse-icon-send" type="sensitive-sent-for-approval" class="">Sent for approval to stakeholder</value>
		<value icon="ldse-icon-check1" type="sensitive-marked-sensitive" class="">Marked as sensitive</value>
		<value icon="ldse-icon-x" type="sensitive-marked-not-sensitive" class="">Marked as not sensitive</value>
    </values>
);

declare variable $funct as xdmp:function := xdmp:function(xs:QName("history:build-events"));

declare function history:update($doc as item(), $mode as xs:string) as empty-sequence() {
    if ($settings:history-enabled and fn:exists($doc/ldse:ldse-meta) and $mode eq $settings:history-mode) then (
        spawn:spawn($funct, $mode, $doc, $mode)
    ) else ()
};

declare function history:build-events($doc as item(), $mode as xs:string) as item()* {
    let $id as xs:string := xs:string($doc/ldse:ldse-meta/ldse:document/@id)
    let $locale as xs:string := xs:string($doc/ldse:ldse-meta/ldse:document/@locale)
    let $hist-doc as element(hldse:history)? := history:get-history($id, $locale)
    let $hist-node as item() :=  history:get-updated-history($doc, $id, $locale, $hist-doc, ())
    return (
        history:save-history($doc, $locale, $id, $hist-doc, $hist-node)
    )
};

declare function history:remove-comment($id as xs:string, $locale as xs:string, $remove-id as xs:string) as empty-sequence() {
    let $hist-doc as element(hldse:history) := history:get-history($id, $locale)
    return (
        if ( ac:has-permission("ldse:remove-comment","","") ) then (
            xdmp:node-delete($hist-doc/hldse:events/hldse:comment[@id = $remove-id])
        ) else (
            xdmp:node-delete($hist-doc/hldse:events/hldse:comment[@id = $remove-id and @username = $currentUser])
        )
    )
};

declare function history:save-history($doc as item(), $locale as xs:string, $id as xs:string, $hist-doc as element(hldse:history)?, $hist-node as element(hldse:history)) as item()*  {
    let $doc-uri as xs:string? := xs:string($doc/ldse:ldse-meta/ldse:document/@uri)
    let $mode as xs:string := core:get-mode()
    let $hist-doc-location as xs:string := (
        core:build-db-path($doc-uri, $locale, $id, ($hist-doc,$hist-node)[1], <options><file-prefix>{xs:string($doc/@type)}</file-prefix></options>)
    )
    return (
        core:save-file($mode, $hist-doc-location, $hist-node, $hist-doc)
    )
};

declare function history:get-updated-history($doc as item(), $id as xs:string, $locale as xs:string, $hist-doc as element(hldse:history)?, $new-events as item()*) as item() {
    let $events as item()* := (
(:       	history:correlation($doc, $hist-doc),:)
       	history:version-restored($doc, $hist-doc),
       	history:translation-removed($doc, $hist-doc),
       	history:translation-not-ready($doc, $hist-doc),
       	history:translation-reviewed($doc, $hist-doc),
       	history:translation-returned($doc, $hist-doc),
       	history:translation-sent($doc, $hist-doc),
       	history:translation-approved($doc, $hist-doc),
       	history:translation-ready($doc, $hist-doc),
       	history:document-deleted($doc, $hist-doc),
       	history:document-removed($doc, $hist-doc),
       	history:document-unpublished($doc, $hist-doc),
       	history:document-published($doc, $hist-doc),
       	history:document-created($doc, $hist-doc),
       	history:submit-sensitive-approval($doc, $hist-doc),
       	history:sensitive-item-approved($doc, $hist-doc),
       	history:marked-as-not-sensitive($doc, $hist-doc),
       	history:marked-as-sensitive($doc, $hist-doc),
       	history:submission-submitted($doc, $hist-doc),
       	history:submission-returned($doc, $hist-doc),
       	history:scheduled-published($doc, $hist-doc),
       	history:scheduled-unpublished($doc, $hist-doc),
       	history:uri-changed($doc, $hist-doc)
    )
    let $core-events as item()* := core:history($doc, $hist-doc)
    let $events as item()* :=
        if ( fn:exists($events) ) then (
            $events,
            $core-events
        ) else (
            history:document-edited($doc, $hist-doc),
            $events,
            $core-events
        )
    let $hist-node as item() := (
        <history xmlns="http://lds.org/code/lds-edit/history">{
            attribute id {$id},
            attribute locale { $locale },
            element current { util:renamespace($doc/ldse:ldse-meta, 'http://lds.org/code/lds-edit/history') },
            element events {
                $new-events,
                $events,
                $hist-doc/hldse:events/*
            }
        }</history>
    )

    return (
        $hist-node
    )
};

declare function history:add-comment-event($id as xs:string, $locale as xs:string, $date as xs:dateTime, $username as xs:string, $userid as xs:string?, $comment as xs:string) as item()* {
    let $doc as element() := ldsemeta:get-file-by($id, $locale, (), ())
    let $new-comment as element(hldse:comment) :=
        <comment xmlns="http://lds.org/code/lds-edit/history" username="{$username}" userid="{$userid}" date="{$date}" id="{$username}-{$date}">
            {$comment}
        </comment>
    let $hist-doc as element(hldse:history)? := history:get-history($id, $locale)
    let $new-history as element(hldse:history) := history:get-updated-history($doc, $id, $locale, $hist-doc, $new-comment)
    return history:save-history($doc, $locale, $id, $hist-doc, $new-history)
};

declare function history:submit-sensitive-approval($doc as element(), $hist-doc as element(hldse:history)?) as item()* {
    let $type as xs:string := history:type-switch($doc, "sensitive")
    let $status as xs:string := "sent-for-approval"
    let $sensitive-node as element()? := $doc/ldse:ldse-meta/ldse:sensitive
    let $username as xs:string? := $sensitive-node/@username
    let $userid as xs:string? := $sensitive-node/@userid
    let $date as xs:string? := $sensitive-node/@last-changed
    let $approved as xs:string? := $sensitive-node/@needs-approval
    let $approval-sent as xs:string? := $sensitive-node/@approval-sent
    let $sensitive as xs:string? := $sensitive-node/@status
    let $hist-doc-sensitive as element()? := $hist-doc/hldse:current/hldse:ldse-meta/hldse:sensitive
    let $hist-doc-approval-sent as xs:string? := $hist-doc-sensitive/@approval-sent
    return (
        if ( fn:not($hist-doc-approval-sent = $approval-sent) and $approval-sent = "yes" and fn:exists($hist-doc-sensitive) and $sensitive = "yes" ) then (
            history:build-event($doc, $type, $status, $username, $userid, $date)
        ) else ()
    )
};

declare function history:sensitive-item-approved($doc as element(), $hist-doc as element(hldse:history)?) as item()* {
    let $type as xs:string := history:type-switch($doc, "sensitive")
    let $status as xs:string := "approved-sensitive"
    let $sensitive as xs:string? := $doc/ldse:ldse-meta/ldse:sensitive/@status
    let $username as xs:string? := $doc/ldse:ldse-meta/ldse:sensitive/@username
    let $userid as xs:string? := $doc/ldse:ldse-meta/ldse:sensitive/@userid
    let $date as xs:string? := $doc/ldse:ldse-meta/ldse:sensitive/@last-changed
    let $needs-approval as xs:string? := $doc/ldse:ldse-meta/ldse:sensitive/@needs-approval
    let $hist-doc-sensitive as element()? := $hist-doc/hldse:current/hldse:ldse-meta/hldse:sensitive
    let $hist-doc-sensitive-status as xs:string? := $hist-doc-sensitive/@status
    let $hist-doc-approved as xs:string? := $hist-doc-sensitive/@needs-approval
    return (
        if ( fn:not($needs-approval = $hist-doc-approved) and $needs-approval = "no" and fn:exists($hist-doc-sensitive) and $sensitive = "yes" ) then (
            history:build-event($doc, $type, $status, $username, $userid, $date)
        ) else ()
    )
};

declare function history:marked-as-sensitive($doc as element(), $hist-doc as element(hldse:history)?) as item()* {
    let $type as xs:string := history:type-switch($doc, "sensitive")
    let $status as xs:string := "marked-sensitive"
    let $username as xs:string? := $doc/ldse:ldse-meta/ldse:sensitive/@username
    let $userid as xs:string? := $doc/ldse:ldse-meta/ldse:sensitive/@userid
    let $date as xs:string? := $doc/ldse:ldse-meta/ldse:sensitive/@last-changed
    let $sensitive as xs:string? := $doc/ldse:ldse-meta/ldse:sensitive/@status
    let $hist-doc-sensitive-status as xs:string? := $hist-doc/hldse:current/hldse:ldse-meta/hldse:sensitive/@status
(:    let $hist-doc-sensitive as xs:string? := $hist-doc/hldse:current/hldse:ldse-meta/hldse:sensitive:)
    return (
        if ( fn:not($sensitive = $hist-doc-sensitive-status) and $sensitive = "yes" ) then (
            history:build-event($doc, $type, $status, $username, $userid, $date)
        ) else ()
    )
};

declare function history:marked-as-not-sensitive($doc as element(), $hist-doc as element(hldse:history)?) as item()* {
    let $type as xs:string := history:type-switch($doc, "sensitive")
    let $status as xs:string := "marked-not-sensitive"
    let $sensitive as xs:string? := $doc/ldse:ldse-meta/ldse:sensitive/@status
    let $hist-doc-sensitive as element()? := $hist-doc/hldse:current/hldse:ldse-meta/hldse:sensitive
    let $hist-doc-sensitive-status as xs:string? := $hist-doc-sensitive/@status
    return (
        if ( fn:not($sensitive = $hist-doc-sensitive-status) and $sensitive = "no" and fn:exists($hist-doc-sensitive) ) then (
            history:build-event($doc, $type, $status)
        ) else ()
    )
};

declare function history:submission-submitted($doc as element(), $hist-doc as element(hldse:history)?) as element()? {
    let $type as xs:string := history:type-switch($doc, "submission")
    let $status as xs:string := "submitted"
    let $current-status as xs:string? := xs:string(ldsemeta:get-submission-status($doc))
    let $hist-doc-status as xs:string? := xs:string($hist-doc/hldse:current/hldse:ldse-meta/hldse:submission/@status)
    return
        if ( $current-status eq "submitted" and fn:not($current-status = $hist-doc-status) ) then (
            history:build-event($doc, $type, $status)
        ) else ()
};

declare function history:submission-returned($doc as element(), $hist-doc as element(hldse:history)?) as element()? {
    let $type as xs:string := history:type-switch($doc, "submission")
    let $status as xs:string := "returned"
    let $current-status as xs:string? := ldsemeta:get-returned-dateTime($doc)
    let $hist-doc-status as xs:string? := $hist-doc/hldse:current/hldse:ldse-meta/hldse:submission/@returned
    return
        if ( fn:exists($current-status) and fn:not($current-status = $hist-doc-status) ) then (
            history:build-event($doc, $type, $status)
        ) else ()
};

declare function history:document-created($doc as element(), $hist-doc as element(hldse:history)?) as element()? {
    let $type as xs:string := history:type-switch($doc, "document")
    let $status as xs:string := "created"

    return (
        if ( fn:empty($hist-doc) ) then (
            history:build-event($doc, $type, $status)
        ) else ()
    )
};

declare function history:document-edited($doc as element(), $hist-doc as element(hldse:history)?) as element()? {
    let $type as xs:string := history:type-switch($doc, "document")
    let $status as xs:string := "edited"
    let $username as xs:string? := xs:string($doc/ldse:ldse-meta/ldse:last-modified/@username)
    let $userid as xs:string? := xs:string($doc/ldse:ldse-meta/ldse:last-modified/@userid)
    let $modified-date as xs:string? := xs:string($doc/ldse:ldse-meta/ldse:last-modified/@date)
    let $created-date as xs:string? := xs:string($doc/ldse:ldse-meta/ldse:created/@date)
    let $last-modified-date as xs:string? := xs:string($hist-doc/hldse:current/hldse:ldse-meta/hldse:last-modified/@date)
    let $doc-status as xs:string? := xs:string($doc/ldse:ldse-meta/ldse:document/@status)
    let $hist-doc-status as xs:string? := xs:string($hist-doc/hldse:current/hldse:ldse-meta/hldse:document/@status)
    let $hist-doc-username as xs:string? := xs:string($hist-doc/hldse:current/hldse:ldse-meta/hldse:last-modified/@username)
    let $first-event as element(hldse:document-edited)? := ($hist-doc/hldse:events/*[1])[fn:node-name(.) = xs:QName('hldse:document-edited') and @username = $username]
    let $first-event as element(hldse:document-edited)? :=
        if ( fn:exists($first-event) and fn:minutes-from-duration(xs:dateTime($modified-date) - xs:dateTime($first-event/@date)) > 10 ) then (
            (: first event too old :)
        ) else (
            $first-event
        )

    return (
        if (fn:exists($hist-doc) and fn:not($modified-date = $created-date) and fn:not($modified-date = $last-modified-date) and fn:empty($first-event)) then (
            history:build-event($doc, $type, $status, $username, $userid, $modified-date)
        ) else ()
    )
};

declare function history:document-published($doc as element(), $hist-doc as element(hldse:history)?) as element()? {
    let $type as xs:string := history:type-switch($doc, "document")
    let $status as xs:string := "published"
    let $doc-status as xs:string? := xs:string($doc/ldse:ldse-meta/ldse:document/@status)
    let $last-modified-date as xs:string? := xs:string($hist-doc/hldse:current/hldse:ldse-meta/hldse:last-modified/@date)
    let $hist-doc-status as xs:string? := xs:string($hist-doc/hldse:current/hldse:ldse-meta/hldse:document/@status)
    let $current-publish as element(ldse:publish-date)? := $doc/ldse:ldse-meta/ldse:publish-date[1]
    let $history-publish as element(hldse:publish-date)? := $hist-doc/hldse:current/hldse:ldse-meta/hldse:publish-date[1]
    return (
        if ( fn:exists($current-publish) and ( fn:empty($history-publish) or fn:not($current-publish/@date = $history-publish/@date ) ) ) then (
            history:build-event($doc, $type, $status)
        ) else ()
    )
};

declare function history:uri-changed($doc as element(), $hist-doc as element(hldse:history)?) as element()?
{
    let $type as xs:string := history:type-switch($doc, "document")
    let $status as xs:string := "uri-changed"
    let $doc-uri as xs:string? := xs:string($doc/ldse:ldse-meta/ldse:document/@uri)
    let $last-modified-date as xs:string? := xs:string($hist-doc/hldse:current/hldse:ldse-meta/hldse:last-modified/@date)
    let $hist-doc-uri as xs:string? := xs:string($hist-doc/hldse:current/hldse:ldse-meta/hldse:document/@uri)
    let $message as xs:string := fn:concat("Url changed from: ", $hist-doc-uri, "!LINE-BREAK!to: ", $doc-uri)

    return
        if (fn:exists($hist-doc-uri) and fn:not($doc-uri = $hist-doc-uri))
        then history:build-event($doc, $type, $status, $message)
        else ()
};

declare function history:document-unpublished($doc as element(), $hist-doc as element(hldse:history)?) as element()? {
    let $type as xs:string := history:type-switch($doc, "document")
    let $status as xs:string := "unpublished"
    let $doc-status as xs:string? := xs:string($doc/ldse:ldse-meta/ldse:document/@status)
    let $hist-doc-status as xs:string? := xs:string($hist-doc/hldse:current/hldse:ldse-meta/hldse:document/@status)
    let $current-unpublish as element(ldse:unpublish-date)? := $doc/ldse:ldse-meta/ldse:unpublish-date[1]
    let $history-unpublish as element(hldse:unpublish-date)? := $hist-doc/hldse:current/hldse:ldse-meta/hldse:unpublish-date[1]
    return (
        if ( fn:exists($current-unpublish) and ( fn:empty($history-unpublish) or fn:not($current-unpublish/@date = $history-unpublish/@date) ) ) then (
            history:build-event($doc, $type, $status)
        ) else ()
    )
};

declare function history:document-removed($doc as element(), $hist-doc as element(hldse:history)?) as element()? {
    let $type as xs:string := history:type-switch($doc, "document")
    let $status as xs:string := "removed"
    let $doc-status as xs:string? := xs:string($doc/ldse:ldse-meta/ldse:document/@status)
    let $hist-doc-status as xs:string? := xs:string($hist-doc/hldse:current/hldse:ldse-meta/hldse:document/@status)

    return (
        if (xs:string($doc/ldse:ldse-meta/ldse:document/@status) eq "remove-from-page" and fn:not($doc-status = $hist-doc-status)) then (
            history:build-event($doc, $type, $status)
        ) else ()
    )
};

declare function history:document-deleted($doc as element(), $hist-doc as element(hldse:history)?) as element()? {
    let $type as xs:string := history:type-switch($doc, "document")
    let $status as xs:string := "deleted"

    return (
        if (xs:string($doc/ldse:ldse-meta/ldse:document/@status) eq "delete") then (
            history:build-event($doc, $type, $status)
        ) else ()
    )
};

declare function history:translation-ready($doc as element(), $hist-doc as element(hldse:history)?) as element()? {
    let $type as xs:string := history:type-switch($doc, "translation")
    let $status as xs:string := "ready"
    let $event-status as xs:string? := xs:string($doc/ldse:ldse-meta/ldse:translation-event/@status)
    let $hist-doc-status as xs:string? := xs:string($hist-doc/hldse:current/hldse:ldse-meta/hldse:translation-event/@status)

    return (
        if ($event-status eq "ready" and fn:not($event-status = $hist-doc-status)) then (
            history:build-event($doc, $type, $status)
        ) else ()
    )
};

declare function history:translation-approved($doc as element(), $hist-doc as element(hldse:history)?) as element()? {
    let $type as xs:string := history:type-switch($doc, "translation")
    let $status as xs:string := "approved"
    let $event-status as xs:string? := xs:string($doc/ldse:ldse-meta/ldse:translation-event/@status)
    let $hist-doc-status as xs:string? := xs:string($hist-doc/hldse:current/hldse:ldse-meta/hldse:translation-event/@status)

    return (
        if ($event-status eq "approved" and fn:not($event-status = $hist-doc-status)) then (
            history:build-event($doc, $type, $status)
        ) else ()
    )
};

declare function history:translation-sent($doc as element(), $hist-doc as element(hldse:history)?) as element()? {
    let $type as xs:string := history:type-switch($doc, "translation")
    let $status as xs:string := "sent"
    let $event-status as xs:string? := xs:string($doc/ldse:ldse-meta/ldse:translation-event/@status)
    let $hist-doc-status as xs:string? := xs:string($hist-doc/hldse:current/hldse:ldse-meta/hldse:translation-event/@status)

    return (
        if ($event-status eq "sent" and fn:not($event-status = $hist-doc-status)) then (
            history:build-event($doc, $type, $status)
        ) else ()
    )
};

declare function history:translation-returned($doc as element(), $hist-doc as element(hldse:history)?) as element()* {
    let $type as xs:string := history:type-switch($doc, "translation")
    let $status as xs:string := "returned"
    let $event-status as xs:string? := xs:string($doc/ldse:ldse-meta/ldse:translation-event/@status)
    let $hist-doc-status as xs:string? := xs:string($hist-doc/hldse:current/hldse:ldse-meta/hldse:translation-event/@status)

    return (
        if ($event-status eq "returned" and fn:not($event-status = $hist-doc-status)) then (
            history:build-event($doc, $type, $status)
        ) else ()
    )
};

declare function history:translation-reviewed($doc as element(), $hist-doc as element(hldse:history)?) as element()? {
    let $type as xs:string := history:type-switch($doc, "translation")
    let $status as xs:string := "reviewed"
    let $event-status as xs:string? := xs:string($doc/ldse:ldse-meta/ldse:translation-event/@status)
    let $hist-doc-status as xs:string? := xs:string($hist-doc/hldse:current/hldse:ldse-meta/hldse:translation-event/@status)

    return (
        if ($event-status eq "reviewed" and fn:not($event-status = $hist-doc-status)) then (
            history:build-event($doc, $type, $status)
        ) else ()
    )
};

declare function history:translation-not-ready($doc as element(), $hist-doc as element(hldse:history)?) as element()? {
    let $type as xs:string := history:type-switch($doc, "translation")
    let $status as xs:string := "not-ready"
    let $event-status as xs:string? := xs:string($doc/ldse:ldse-meta/ldse:translation-event/@status)
    let $hist-doc-status as xs:string? := xs:string($hist-doc/hldse:current/hldse:ldse-meta/hldse:translation-event/@status)

    return (
        if ($event-status eq "not-ready" and fn:not($event-status = $hist-doc-status)) then (
            history:build-event($doc, $type, $status)
        ) else ()
    )
};

declare function history:translation-removed($doc as element(), $hist-doc as element(hldse:history)?) as element()? {
    let $type as xs:string := history:type-switch($doc, "translation")
    let $status as xs:string := "removed"
    let $event-status as xs:string? := xs:string($doc/ldse:ldse-meta/ldse:translation-event/@status)
    let $hist-doc-status as xs:string? := xs:string($hist-doc/hldse:current/hldse:ldse-meta/hldse:translation-event/@status)

    return (
        if ($event-status eq "removed" and fn:not($event-status = $hist-doc-status)) then (
            history:build-event($doc, $type, $status)
        ) else ()
    )
};

declare function history:correlation($doc as element(), $hist-doc as element(hldse:history)?) as element()? {
    let $username as xs:string := ldsemeta:get-last-modified($doc)/@username
    let $userid as xs:string := ldsemeta:get-last-modified($doc)/@userid
    let $date as xs:string := ldsemeta:get-last-modified($doc)/@date
    let $event-status as xs:string? := xs:string(ldsemeta:get-correlation-status($doc))
    let $hist-doc-status as xs:string? := xs:string($hist-doc/hldse:current/hldse:ldse-meta/hldse:correlation/@status)
    let $ldse-meta as element()? := ldsemeta:get-ldse-meta($doc)
    let $is-english as xs:boolean := ldsemeta:_isEnglish($ldse-meta)

    return
        if(fn:not($event-status = $hist-doc-status))
        then
			if($event-status eq "Sending" and $is-english)
			then history:build-event($doc, "correlation", "sent", $username, $userid, $date)

			else if($event-status eq "Error Sending" and $is-english)
			then history:build-event($doc, "correlation", "errorsending", $username, $userid, $date)

			else if($event-status eq "In Correlation" and $is-english)
			then history:build-event($doc, "correlation", "incorrelation", $username, $userid, $date)

			else if($event-status eq "Approved")
			then
				if($is-english)
				then
					let $doc-id as xs:string? := ldsemeta:get-document-id($doc)
					let $correlation-document as element(cldse:correlation)? := correlation:get-correlation-document-from-db($doc-id)
					let $ip-approval as xs:string? := $correlation-document/IpReport/ApprovalNumber/xs:string(.)
					let $eval-approval as xs:string? := $correlation-document/IpReport/EvalApprovalNumber/xs:string(.)
					let $ip-message as xs:string? := if ( fn:exists($ip-approval) ) then fn:concat("Content approved from Cor-Ip: ", $ip-approval) else ()
					let $eval-message as xs:string? := if ( fn:exists($eval-approval) ) then fn:concat("Content approved from Cor-Eval: ", $eval-approval) else ()
					let $message as xs:string? := fn:string-join(($ip-message, $eval-message), "!LINE-BREAK!")

					let $_ as empty-sequence() :=
						(:~ Loop through all translated documents and record Approval Numbers from English document ~:)
						spawn:spawn(xdmp:function(xs:QName("history:correlation-update-translated-files-spawn")), core:get-mode(), $doc)

					return history:build-event($doc, "correlation", "approved", $username, $userid, $date, $message)

				else
            		let $event as element(hldse:correlation-approved)? := history:get-last-eng-correlation-approval-event($doc, $hist-doc)
            		(:let $_ as empty-sequence() := spawn:spawn(xdmp:function(xs:QName("history:correlation-remove-node")), core:get-mode(), $doc):)
            		where fn:exists($event)
            		return
            			history:build-event(
            				"correlation",
            				"approved",
            				$event/@username/fn:string(.),
            				$event/@userid/fn:string(.),
            				$event/@date/fn:string(.),
            				$event/fn:string(.)
            			)

			else if($event-status eq "Declined" and $is-english)
			then history:build-event($doc, "correlation", "declined", $username, $userid, $date)

			else ()

		else ()
};

declare function history:has-correlation-approval-event($doc as element()) as xs:boolean
{
	let $doc-id as xs:string := ldsemeta:get-document-id($doc)
	let $locale as xs:string := ldsemeta:get-document-locale($doc)
	let $hist-doc as element(hldse:history)? := history:get-history($doc-id, $locale)

	return
		fn:not(fn:empty($hist-doc/hldse:events/hldse:correlation-approved))
};

declare function history:has-correlation-incorrelation-event($doc as element()) as xs:boolean
{
	let $doc-id as xs:string := ldsemeta:get-document-id($doc)
	let $locale as xs:string := ldsemeta:get-document-locale($doc)
	let $hist-doc as element(hldse:history)? := history:get-history($doc-id, $locale)

	return
		fn:not(fn:empty($hist-doc/hldse:events/hldse:correlation-incorrelation))
};

declare function history:correlation-remove-node($doc as element()) as empty-sequence()
{
	(:Get document from database because the passed in doc is disconnected from the database and fails in the core:document-replace function:)
	let $doc as item() := ldsemeta:get-file-by(ldsemeta:get-document-id($doc), (), (), ())
	let $ldsemeta as element(ldse:ldse-meta) := ldsemeta:get-ldse-meta($doc)

	let $new-ldsemeta as element(ldse:ldse-meta) :=
		element {fn:node-name($ldsemeta)}
		{
			$ldsemeta/@*,
			$ldsemeta/node() except $ldsemeta/ldse:correlation
		}

	let $new-doc as element() :=
		element {fn:node-name($doc)}
		{
			$doc/@*,
			$new-ldsemeta,
			$doc/node() except $doc/ldse:ldse-meta
		}

	return core:document-replace($doc, $new-doc)
};

declare function history:correlation-update-translated-files-spawn($doc as element()) as empty-sequence()
{
	let $eng-ldsemeta as element(ldse:ldse-meta) := ldsemeta:get-ldse-meta($doc)
	for $tf as element() in ldsemeta:get-translated-files(ldsemeta:get-document-id($doc))
		let $tf-ldsemeta as element(ldse:ldse-meta) := ldsemeta:get-ldse-meta($tf)
		let $new-tf-ldsemeta as element(ldse:ldse-meta) := ldsemeta:get-meta($tf)

		let $new-tf-ldsemeta as element(ldse:ldse-meta) :=
			element {fn:node-name($new-tf-ldsemeta)} {
				$new-tf-ldsemeta/@*,
				$new-tf-ldsemeta/node() except $new-tf-ldsemeta/ldse:correlation,
				$eng-ldsemeta/ldse:correlation
			}

		let $new-tf as element() := mem:node-replace($tf-ldsemeta, $new-tf-ldsemeta)/*

	return core:document-replace($tf, $new-tf)
};

declare function history:get-last-eng-correlation-approval-event($doc as element(), $hist-doc as element(hldse:history)?) as element(hldse:correlation-approved)?
{
	let $id as xs:string? := ldsemeta:get-document-id($doc)
	let $eng-hist-doc as element(hldse:history)? := history:get-history(ldsemeta:get-document-id(ldsemeta:get-file-in-locale($doc, "eng")), "eng")

	let $last-eng-correlation-approval-event as element(hldse:correlation-approved)? :=
		(for $event as element(hldse:correlation-approved) in $eng-hist-doc/hldse:events/hldse:correlation-approved
		order by xs:dateTime($event/@date) descending
		return $event)[1]

	let $last-translation-correlation-approval-event as element(hldse:correlation-approved)? :=
		(for $event as element(hldse:correlation-approved) in $hist-doc/hldse:events/hldse:correlation-approved
		order by xs:dateTime($event/@date) descending
		return $event)[1]

	return
		if(fn:not($last-eng-correlation-approval-event/@date = $last-translation-correlation-approval-event/@date))
		then $last-eng-correlation-approval-event
		else ()
};

declare function history:version-restored($doc as element(), $hist-doc as element(hldse:history)?) as element()? {
    let $type as xs:string := "version"
    let $status as xs:string := "restore"
    let $hist-doc-restored as element(hldse:restored)? := $hist-doc/hldse:current/hldse:ldse-meta/hldse:restored
    let $doc-restored as element(ldse:restored)? := $doc/ldse:ldse-meta/ldse:restored
    let $username as xs:string? := xs:string($doc-restored/@username)
    let $userid as xs:string? := xs:string($doc-restored/@userid)
    let $date as xs:string? := xs:string($doc-restored/@date)
    let $version as xs:string? := xs:string($doc-restored/@version)

    return (
        if (fn:exists($doc-restored) and fn:not($date = $hist-doc-restored/@date) and fn:not($version = $hist-doc-restored/@version)) then (
            history:build-event($hist-doc, $type, $status, $version, $username, $userid, $date)
        ) else ()
    )
};

declare function history:scheduled-published($doc as element(), $hist-doc as element(hldse:history)?) as element()? {
    let $type as xs:string := "scheduled"
    let $status as xs:string := "publish"
    let $remove-status as xs:string := "publish-removed"

    let $doc-status as xs:string? := xs:string($doc/ldse:ldse-meta/ldse:document/@status)
    let $scheduled-publish as element(ldse:schedule-publish)? := $doc/ldse:ldse-meta/ldse:schedule-publish[1]
    let $username as xs:string? := xs:string($scheduled-publish/@username)
    let $userid as xs:string? := xs:string($scheduled-publish/@userid)
    let $scheduled-date as xs:dateTime? := xs:dateTime($scheduled-publish/@dateTime)

    let $history-scheduled-publish as element(hldse:schedule-publish)? := $hist-doc/hldse:current/hldse:ldse-meta/hldse:schedule-publish[1]
    let $history-scheduled-date as xs:dateTime? := xs:dateTime($history-scheduled-publish/@dateTime)
    return (
        if ( fn:exists($history-scheduled-publish) and fn:empty($scheduled-publish) and fn:not($doc-status = "publish")) then (
            (: Schedule Published Removed :)
            history:build-event($doc, $type, $remove-status)
        ) else if ( fn:exists($scheduled-publish) and fn:empty($history-scheduled-publish) ) then (
            (: Scheduled published :)
            history:build-event($doc, $type, $status, fn:format-dateTime($scheduled-date, "[D01] [MN,*-3] [Y0001] [h]:[m01] [PN]", "en", (), ()) )
        ) else if ( fn:exists($scheduled-publish) and fn:exists($history-scheduled-publish) and fn:not($scheduled-date = $history-scheduled-date) ) then (
            (: Scheduled published :)
            history:build-event($doc, $type, $status, fn:format-dateTime($scheduled-date, "[D01] [MN,*-3] [Y0001] [h]:[m01] [PN]", "en", (), ()) )
        ) else ()
    )
};

declare function history:scheduled-unpublished($doc as element(), $hist-doc as element(hldse:history)?) as element()? {
    let $type as xs:string := "scheduled"
    let $status as xs:string := "unpublish"
    let $remove-status as xs:string := "unpublish-removed"

    let $doc-status as xs:string? := xs:string($doc/ldse:ldse-meta/ldse:document/@status)
    let $scheduled-unpublish as element(ldse:schedule-unpublish)? := $doc/ldse:ldse-meta/ldse:schedule-unpublish[1]
    let $username as xs:string? := xs:string($scheduled-unpublish/@username)
    let $userid as xs:string? := xs:string($scheduled-unpublish/@userid)
    let $scheduled-date as xs:dateTime? := xs:dateTime($scheduled-unpublish/@dateTime)

    let $history-scheduled-unpublish as element(hldse:schedule-unpublish)? := $hist-doc/hldse:current/hldse:ldse-meta/hldse:schedule-unpublish[1]
    let $history-scheduled-date as xs:dateTime? := xs:dateTime($history-scheduled-unpublish/@dateTime)

    return (
        if ( fn:exists($history-scheduled-unpublish) and fn:empty($scheduled-unpublish) and fn:not($doc-status = "unpublish")) then (
            (: Schedule unublished Removed :)
            history:build-event($doc, $type, $remove-status)
        ) else if ( fn:exists($scheduled-unpublish) and fn:empty($history-scheduled-unpublish) ) then (
            (: Scheduled unpublished :)
            history:build-event($doc, $type, $status, fn:format-dateTime($scheduled-date, "[D01] [MN,*-3] [Y0001] [h]:[m01] [PN]", "en", (), ()))
        ) else if ( fn:exists($scheduled-unpublish) and fn:exists($history-scheduled-unpublish) and fn:not($scheduled-date = $history-scheduled-date) ) then (
            (: Scheduled unpublished :)
            history:build-event($doc, $type, $status, fn:format-dateTime($scheduled-date, "[D01] [MN,*-3] [Y0001] [h]:[m01] [PN]", "en", (), ()))
        ) else ()
    )
};

declare function history:build-follow-event($id as xs:string, $locale as xs:string, $date as xs:dateTime, $username as xs:string, $userid as xs:string) as element()? {
    let $doc as element() := ldsemeta:get-file-by($id, $locale, (), ())
    let $type as xs:string := 'following'
    let $status as xs:string := 'follow'
    let $following as element(hldse:following) :=
        <following xmlns="http://lds.org/code/lds-edit/history" username="{$username}" userid="{$userid}" date="{$date}" id="{fn:concat($username, '-', $userid)}" email="{ac:getPersonEmail()}"/>
    let $hist-doc as element(hldse:history)? := history:get-history($id, $locale)
    let $new-history as element(hldse:history) := history:get-updated-history($doc, $id, $locale, $hist-doc, $following)
    return history:save-history($doc, $locale, $id, $hist-doc, $new-history)
};

declare function history:remove-follow-event($id as xs:string, $locale as xs:string, $username as xs:string) as empty-sequence() {
    let $hist-doc as element(hldse:history) := history:get-history($id, $locale)
    return (
        if ( fn:exists($hist-doc) ) then (
            xdmp:node-delete($hist-doc/hldse:events/hldse:following[@username = $username])
        ) else ()
    )
};

declare function history:build-event(
    $doc as element(),
    $type as xs:string,
    $status as xs:string
) as element()? {
    history:build-event($doc, $type, $status, ())
};

declare function history:build-event(
    $doc as element(),
    $type as xs:string,
    $status as xs:string,
    $message as xs:string?
) as element()? {
    history:build-event($doc, $type, $status, $message, (), (), ())
};

declare function history:build-event(
    $doc as element(),
    $type as xs:string,
    $status as xs:string,
    $username as xs:string?,
    $userid as xs:string?,
    $date as xs:string?
) as element()? {
    history:build-event($doc, $type, $status, (), (), (), ())
};

declare function history:build-event(
    $doc as element(),
    $type as xs:string,
    $status as xs:string,
    $message as xs:string?,
    $username as xs:string?,
    $userid as xs:string?,
    $date as xs:string?
) as element()? {
    element { fn:QName("http://lds.org/code/lds-edit/history", fn:concat($type, '-', $status)) } {
        ( $username, $doc/ldse:ldse-meta/ldse:last-modified/@username, $currentUser )[1],
        ( $userid, $doc/ldse:ldse-meta/ldse:last-modified/@userid )[1],
        ( $date, $doc/ldse:ldse-meta/ldse:last-modified/@date )[1],
        $message
    }
};

declare function history:get-history(
    $id as xs:string,
    $locale as xs:string
) as element(hldse:history)? {
    if (fn:not($id = "") and fn:not($locale = "")) then (
        cts:search(/hldse:history,
            cts:and-query((
                core:get-filter-query(),
                cts:element-attribute-value-query(xs:QName("hldse:history"),xs:QName("id"),($id),'exact'),
                cts:element-attribute-value-query(xs:QName("hldse:history"),xs:QName("locale"),($locale),'exact')
            ))
        )[1]
    ) else ()
};

declare function history:build-event-template() as element(script) {
    <script class="handlebars-template" id="historyEventsTemplate" type="text/x-handlebars-template">
        {{{{#each events}}}}
            <div class="ldse-history-entry">
                <span class="ldse-history-entry-icon">
                    <span class="{{{{history-icon}}}} ldse-icon ldse-history-entry-icon" />
                </span>
                <span class="ldse-fancy-date">
                    <span class="ldse-fancy-date-day">{{{{day}}}}</span>
                    <span class="ldse-fancy-date-month">{{{{month}}}}</span>
                    <span class="ldse-fancy-date-year">{{{{year}}}}</span>
                </span>
                <span class="ldse-history-entry-details">
                    <span class="ldse-history-entry-info">
                        <span>{{{{time}}}}</span>
                        <span>{{{{name}}}}</span>
                    </span>
                    <span class="ldse-history-entry-text {{{{class}}}}">{{{{text}}}}</span>
                </span>
            </div>
        {{{{/each}}}}
    </script>
};

declare function history:build-text-template() as element(script) {
	<script class="handlebars-template" id="historyEventsTextTemplate" type="text/x-handlebars-template">
		{{{{#each lines}}}}
			<span>{{{{this}}}}</span>
		{{{{/each}}}}
	</script>
};

declare function history:build-history-section() as item()* {
    let $pageIndex as xs:int := 1
    let $pageSize as xs:int := 25
    return (
        <section id="history-info" class="ldse-section ldse-summary cf" style="display: none;">
            <header class="ldse-section--header">
                <h2>History</h2>
                <div class="ldse-pagination">
                    <span id="historyPageLengths" class="ldse-pagination--shownum">Show
                        {
                            for $value as xs:int in  (10, 25, 50, 100)
                            return(
                                if($pageSize eq $value) then (
                                    <span><a data-count="{$value}" onclick="H.changePageSize({$value})">{$value}</a></span>
                                ) else(
                                    <span><a data-count="{$value}" href="#d" onclick="H.changePageSize({$value})">{$value}</a></span>
                                )
                              )
                         }
                    </span>
                    <a id="historyPrevious" href="#d" class="ldse-icon-ko-tri-left ldse-icon" onclick="H.previousPage()">&lt; </a>
                    <span id="pageTotal">&nbsp; Page <span id="historyCurPage">{$pageIndex}</span> of <span id="historyMaxPage">{$pageSize}</span> &nbsp;</span>
                    <a id="historyNext" href="#d" class="ldse-icon-ko-tri-right ldse-icon" onclick="H.nextPage()"> &gt;</a>
                </div>
            </header>
            <div class="ldse-section--body ldse-fullbleed" id="history-list">Loading History</div>
        </section>
    )
};

declare function history:build-history-scripts() as item()* {
    let $pageIndex as xs:int := 1
    let $pageSize as xs:int := 25

    return (
        <script type="text/javascript">
            H.page = { util:js-number-escape($pageIndex)};
            H.pageLength = {util:js-number-escape($pageSize)};
            H.events = {{}};

			comment.page = {util:js-number-escape($pageIndex)};
			comment.pageLength = {util:js-number-escape($pageSize)};
			comment.comments = {{}};
		</script>,
        history:build-event-template(),
        history:build-comment-template(),
        history:build-text-template()
    )
};
declare function history:build-comment-section($id as xs:string, $locale as xs:string, $uri as xs:string) as item()* {
	let $pageIndex as xs:int := 1
	let $pageSize as xs:int := 25
	return (
		<section id="comments-section" class="ldse-section ldse-summary ldse-clearfix" style="display:none;">
			<header class="ldse-section--header">
				<h2>Comments</h2>
				<span class="ldse-pagination">
					<span class="ldse-pagination--shownum">Show
						{
							for $value as xs:int in (10, 25, 50, 100)
							return (
								if ( $pageSize = $value ) then (
								    <span><a data-count="{$value}" onclick="comment.changePageSize({$value})">{$value}</a></span>
								) else (
									<span><a data-count="{$value}" href="#d" onclick="comment.changePageSize({$value})">{$value}</a></span>
								)
							)
						}
				    </span>
				    <a id="commentPrevious" href="#d" class="ldse-icon-ko-tri-left ldse-icon" onclick="comment.previousPage()">&lt;</a>
				    <span class="ldse-pagination--pages" id="pageTotal">&nbsp; Page <span id="commentCurrentPage"></span> of <span id="commentMaxPage"></span> &nbsp;</span>
				    <a id="commentNext" href="#d" class="ldse-icon-ko-tri-right ldse-icon" onclick="comment.nextPage()">&gt;</a>
				</span>
			</header>
			<div class="ldse-section--body ldse-form">
				<div id="new-comment" class="ldse-clearfix">
			    	<textarea id="commentsBox" data-id="{$id}" onkeyup="comment.toggleAddCommentButton()" data-locale="{$locale}" data-uri="{$uri}"></textarea>
				    <button id="addComment" disabled="disabled" class="ldse-button primary ldse-icon-comments-2" onclick="comment.saveComment(); return false;">Add Comment</button>
				</div>
				<div id="commentslist">Loading Comments</div>
			</div>
		</section>
	)
};

declare function history:build-comment-template() as element(script) {
    <script class="handlebars-template" id="commentTemplate" type="text/x-handlebars-template">
    	{{{{#each comments}}}}
	        <div class="ldse-history-entry ldse-comment" id="{{{{commentId}}}}">
	            <span class="ldse-fancy-date">
	                <span class="ldse-fancy-date-day">{{{{day}}}}</span>
	                <span class="ldse-fancy-date-month">{{{{month}}}}</span>
	                <span class="ldse-fancy-date-year">{{{{year}}}}</span>
	            </span>
	            <span class="ldse-history-entry-details">
	                <span class="ldse-history-entry-info">
	                    <span>{{{{time}}}}</span>
	                    <span>{{{{name}}}}</span>
	                </span>
	                <span class="ldse-history-entry-text {{{{class}}}}">{{{{comment}}}}</span>
	            </span>
    			{{{{#if showRemove}}}}
    			<button class="ldse-comment-delete ldse-toggle-content ldse-button ldse-icon-trash ldse-icon" onclick="comment.trashCan(this); return false;"></button>
    			{{{{else}}}}
    			{{{{/if}}}}
	        </div>
    	{{{{/each}}}}
    </script>
};

declare function history:type-switch(
    $doc as element(),
    $type as xs:string
) as xs:string {
	typeswitch($doc)
	case element(custom-page) return fn:concat("page-", $type)
	default return $type
};

declare function history:save-comments() as item()* {
    let $username as xs:string := ac:getUserName()
    let $userid as xs:string? := ac:getPersonId()
    let $id as xs:string := xdmp:get-request-field("id")
    let $locale as xs:string := xdmp:get-request-field("locale")
    let $comment as xs:string? := xdmp:get-request-field("comments")
    let $date as xs:dateTime := fn:current-dateTime()
    let $save as item()* := history:add-comment-event($id, $locale, $date, $username, $userid, $comment)
    return (
        object-node {
        	'username': $username,
        	'name': core:get-contributor-name($username),
        	'comment': $comment,
            'day': xs:string(fn:day-from-dateTime($date)),
            'month': fn:format-dateTime($date, "[MN,*-3]"),
            'year': xs:string(fn:year-from-dateTime($date)),
            'weekday': fn:format-dateTime($date, "[FNn,*-3]"),
            'time': fn:format-dateTime($date, "[h]:[m01] [PN]"),
        	'showRemove': "true",
        	'commentId': fn:concat($username, "-", $date)
        }
    )
};

declare function history:get-file-history-json(
    $id as xs:string?,
    $locale as xs:string?
) {
    let $history as element(hldse:history)? := history:get-history($id, $locale)
    let $json :=
        array-node {
            for $event as element() in $history/hldse:events/*[fn:not(fn:local-name(.) = 'following')]
            let $user as xs:string := xs:string($event/@username)
            let $name as xs:string := core:get-contributor-name($user)
            let $date as xs:dateTime := xs:dateTime($event/@date)
            let $day as xs:string := xs:string(fn:day-from-dateTime($date))
            let $month as xs:string := fn:format-dateTime($date, "[MN,*-3]")
            let $year as xs:string := xs:string(fn:year-from-dateTime($date))
            let $weekday as xs:string := fn:format-dateTime($date, "[FNn,*-3]")
            let $time as xs:string := fn:format-dateTime($date, "[h]:[m01] [PN]")
            let $node-name as xs:string := fn:local-name($event)
            let $this-value as item()* := $values/value[@type eq $node-name]
            let $icon as xs:string? := $this-value/@icon
            let $class as xs:string? := $this-value/@class
            let $text as element(span)? := <span class="ldse-history-entry-text">{fn:string-join(($this-value, $event/text()), ' ')}</span>
            order by $date descending

            return (
                object-node {
                    'username': fn:string($user),
                    'name': fn:string($name),
                    'day': fn:string($day),
                    'month': fn:string($month),
                    'year': fn:string($year),
                    'weekday': fn:string($weekday),
                    'time': fn:string($time),
                    'history-icon': fn:string($icon),
                    'text': fn:string($text),
                    'class': fn:string($class)
                }
            )
        }

    return (
        xdmp:from-json($json)
    )
};

declare function history:get-file-comment-json(
    $currentUser as xs:string?,
    $id as xs:string?,
    $locale as xs:string?
) {
    let $history as element(hldse:history)? := history:get-history($id, $locale)
    let $comments as element()* := $history/hldse:events/hldse:comment
    let $json :=
        array-node {
            for $comment as element(hldse:comment) at $index in $comments
            let $text as xs:string := fn:data($comment)
            let $user as xs:string := xs:string($comment/@username)
            let $name as xs:string := core:get-contributor-name($user)
            let $date as xs:dateTime := xs:dateTime($comment/@date)
            let $day as xs:string := xs:string(fn:day-from-dateTime($date))
            let $month as xs:string := fn:format-dateTime($date, "[MN,*-3]")
            let $year as xs:string := xs:string(fn:year-from-dateTime($date))
            let $weekday as xs:string := fn:format-dateTime($date, "[FNn,*-3]")
            let $time as xs:string := fn:format-dateTime($date, "[h]:[m01] [PN]")
            let $indexString as xs:string := xs:string($index)
            let $showRemove as xs:string? :=
                if ( $user eq $currentUser or ac:has-permission("ldse:remove-comment","","") ) then (
                    "true"
                ) else ("false")
            return (
                object-node {
                    'username': $user,
                    'name': $name,
                    'comment': fn:string($comment),
                    'day': $day,
                    'month': $month,
                    'year': $year,
                    'weekday': $weekday,
                    'time': $time,
                    'index': $indexString,
                    'showRemove': $showRemove,
                    'commentId': fn:concat($user, "-", $date)
                }
            )
        }

    return xdmp:from-json($json)
};
