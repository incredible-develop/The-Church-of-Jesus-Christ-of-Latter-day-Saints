xquery version "1.0-ml";

module namespace convert = "http://lds.org/code/shared/lds-edit/ldse-meta-convert";

import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "ldse-meta.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "utility-functions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "ldse-core.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace its = "http://www.w3.org/2005/11/its";
declare namespace meta = "http://lds.org/schema/meta/base/v1";
declare option xdmp:mapping "true";


declare variable $site as xs:string := $core:site;

declare function get-id($file as element()) as xs:string? {
    if ($file/@id ne '') then (
        xs:string($file/@id)
    ) else if ($file/search-meta/source ne '') then (
        xs:string($file/search-meta/source)
    ) else if (fn:node-name($file) eq xs:QName('resources')) then (
        fn:concat($file/name, '-', $file/@locale)
    ) else if (fn:node-name($file) eq xs:QName('channels')) then (
        fn:concat($file/@name, '-', $file/@locale)
    ) else (
        (: If you store the id in another place then add another else if :)
    )
};

declare function get-uri($file as element()) as xs:string? {
    if ($file/@uri ne '') then (
        xs:string($file/@uri)
    ) else if ($file/@page ne '') then (
        xs:string($file/@page)
    ) else if ($file/meta:meta/meta:uri ne '') then (
        xs:string( ($file/meta:meta/meta:uri[. ne ''])[1] )
    ) else if ($file/meta/uri ne '') then (
        xs:string( ($file/meta/uri[. ne ''])[1] )
    ) else (
        (: If you store the uri in another place then add another else if :)
    )
};

declare function get-status($file as element()) as xs:string? {
    if ($file/@status ne '') then (
        xs:string($file/@status)
    ) else (
        'preview'
       (: If you store the status in another place then add another else if :) 
    )
};

declare function get-locale($file as element()) as xs:string? {
    if ($file/@locale ne '') then (
        xs:string($file/@locale)
    ) else if ($file/@lang ne '') then (
        xs:string($file/@lang)
    ) 
    
    (: Keep as fn:string(), xs:string tries to cast @xml:lang as a xs:language and errors if it is empty:)
    else if (fn:string($file/@xml:lang) ne '') then ( 
        fn:string($file/@xml:lang)
    ) 
    
    else if ($file/locale ne '') then (
        xs:string($file/locale)
    ) else (
        (: If you store the locale in another place then add another else if :) 
    )
};

declare function get-source($file as element(), $locale as xs:string?) as xs:string {
    if ($file/@source ne '') then (
        xs:string($file/@source)
    ) else (
        if ( fn:contains($locale, '-') ) then (
           fn:substring-after($locale, '-')
        ) else (
            'chq'
        )
    )
};

declare function date-to-dateTime($date as xs:date) as xs:dateTime {
    xs:dateTime( $date, xs:time('00:00:00') )
};

declare function get-dateTime($date as xs:string) as xs:dateTime {
    if ($date castable as xs:dateTime) then (
        xs:dateTime($date)
    ) else if ($date castable as xs:date) then (
        date-to-dateTime(xs:date($date))
    ) else (
        if ( fn:contains($date, 'T') ) then (
            let $date as xs:string := fn:substring-before($date, 'T')
            return (
                if ($date castable as xs:date) then (
                    date-to-dateTime(xs:date($date))
                ) else (
                    fn:current-dateTime()
                )
            )
        ) else (
            fn:current-dateTime()
        )
    )
};

declare function build-document($file as element()) as element(ldse:document) {
    let $id as xs:string? := get-id($file)
    let $uri as xs:string? := get-uri($file)
    let $locale as xs:string? := get-locale($file)
    let $status as xs:string? := get-status($file)
    let $source as xs:string? := get-source($file, $locale)
    let $wordTgp as item()+ := ldsemeta:_get-word-tgp($file)
    return (
        <document xmlns="http://lds.org/code/lds-edit">{
            attribute id { $id },
            attribute locale { $locale },
            attribute uri { $uri },
            attribute status { $status },
            attribute site { $site },
            attribute source { $source },
            attribute words { $wordTgp[1] },
            attribute tgp { $wordTgp[2] }
        }</document>
    )
};

declare function build-created($file as element()) as element(ldse:created) {
    <created xmlns="http://lds.org/code/lds-edit">{
        (: attribute date { }, Date is unknown:)
        attribute username { "lds-edit" }, (: Actual user unknown :) 
        attribute userid { "" }
    }</created>
};

declare function build-publish-date($file as element()) as element(ldse:publish-date)? {
    let $orig as element()? := $file/*:publishDate
    where fn:exists($orig)
    return (
        let $username as xs:string? := $orig/@user
        let $date as xs:dateTime := get-dateTime(xs:string($orig))
        return (
            <publish-date xmlns="http://lds.org/code/lds-edit">{
                attribute date { $date },
                attribute username { $username },
                attribute userid {""}
            }</publish-date>
        )        
    )
};

declare function build-unpublish-date($file as element()) as element(ldse:unpublish-date)? {
    let $orig as element()? := $file/*:unpublishDate
    where fn:exists($orig)
    return (
        let $username as xs:string? := $orig/@user
        let $date as xs:dateTime := get-dateTime(xs:string($orig))
        return (
            <unpublish-date xmlns="http://lds.org/code/lds-edit">{
                attribute date { $date },
                attribute username { $username },
                attribute userid {""}
            }</unpublish-date>
        )        
    )
};
                
declare function build-scheduled-publish($file as element()) as element(ldse:scheduled-publish)? {
    let $orig as element()? := $file/*:futurePublish
    where fn:exists($orig)
    return (
        let $username as xs:string? := $orig/@user
        let $date as xs:string := $orig/@date
        let $time as xs:string := $orig/@time
        let $dateTime as xs:dateTime := get-dateTime(xs:string($orig))
        return (
            <scheduled-publish xmlns="http://lds.org/code/lds-edit">{
                attribute date { $date },
                attribute time { $time },
                attribute dateTime { $dateTime },
                attribute username { $username },
                attribute userid {""}
            }</scheduled-publish>
        )        
    )
};

declare function build-form-options($file as element()) as element(ldse:form-options)? {
    let $orig as element(form-options)? := $file/*:form-options
    where fn:exists($orig)
    return (
        <form-options xmlns="http://lds.org/code/lds-edit">{
            $orig/*
        }</form-options>
    )
};

declare function build-last-modified() as element(ldse:last-modified) {
    <last-modified xmlns="http://lds.org/code/lds-edit">{
        attribute date { fn:current-dateTime() },
        attribute username {"lds-edit"},
        attribute userid {""}
    }</last-modified>   
};

declare function build-translation-returned($date as xs:string?, $component-id as xs:string?, $locale as xs:string?) as element(ldse:translation-returned) {
    <translation-returned xmlns="http://lds.org/code/lds-edit">{
        attribute date { $date },
        attribute component-id { $component-id } ,
        attribute locale { $locale }
    }</translation-returned>  
};

declare function build-translation-not-ready($from-event as element()) as element(ldse:translation-not-ready)? {
    let $not-ready as element()? := $from-event/*:not-ready
    where fn:exists($not-ready)
    return (
        let $date as xs:string := $not-ready/@date
        let $username as xs:string := $not-ready/@user
        let $reason as xs:string? := xs:string($not-ready)
        where $date castable as xs:dateTime
        return (
            <translation-not-ready xmlns="http://lds.org/code/lds-edit">{
                attribute date { $date },
                attribute reason { $reason },
                attribute username { $username },
                attribute userid {""}
            }</translation-not-ready>
        )    
    )
};

declare function build-translation-remove($from-event as element()) as element(ldse:translation-removed)? {
    <translation-removed xmlns="http://lds.org/code/lds-edit">{
        (: attribute date { $date }, Date unknown :)
        attribute username { 'lds-edit' },
        attribute userid {""}
    }</translation-removed>
};

declare function build-translation-reviewed($file as element(), $from-event as element()) as element(ldse:translation-reviewed)? {
    let $publishDate as element()? := $file/*:publishDate
    where $publishDate
    return (
        <translation-reviewed xmlns="http://lds.org/code/lds-edit">{
            if ( fn:exists($publishDate) and xs:string($publishDate) castable as xs:dateTime ) then (
                attribute date { get-dateTime( xs:string($publishDate) ) }
            ) else (),            
            attribute username { xs:string($publishDate/@user) },
            attribute userid {""}
        }</translation-reviewed>
    )
};

declare function get-translation-status($file-locale as xs:string?, $to-event as element()?, $from-event as element()?) as xs:string? {
    let $to-status as xs:string? := $to-event/@status
    let $from-status as xs:string? := $from-event/@status
    return (
        if ($file-locale eq 'eng' and  $from-status eq ('completed', 'ready-for-review') ) then (
                'returned'
        ) else if ( $from-status eq 'remove-from-page' ) then (
            'remove'
        ) else if ( fn:exists($from-event/*:not-ready) and $from-status ne 'completed') then (
            'not-ready'
        ) else if ($from-status eq 'ready-for-review') then (
            'returned'
        ) else if ($from-status eq 'completed') then (
            'reviewed'
        ) else if ($to-status eq 'ready-for-translation') then (
            'ready'
        ) else if ($to-status eq 'sent-to-translation') then (
            'sent'
        ) else ()       
    )    
};

declare function build-translation-event($file as element()) as element(ldse:translation-event)? {
    let $event-group as element()? := ($file/*:workflow)[1]/*:event-group
    let $to-event as element()? := $event-group/*:event[@name eq 'to-translation']
    let $from-event as element()? := $event-group/*:event[@name eq 'from-translation']
    let $file-locale as xs:string? := get-locale($file)
    let $status as xs:string? := get-translation-status($file-locale, $to-event, $from-event)
    let $log as empty-sequence() := if (fn:exists($event-group) and $status eq '') then (xdmp:log($event-group)) else ()
    let $sent-date as xs:dateTime := 
        if ($to-event/date/@value castable as xs:dateTime) then (
            xs:dateTime($to-event/date/@value)
        ) else (
            fn:current-dateTime() (: Real date unknown, but we know it is ready today :)
        )
    where fn:exists($event-group)
    return (
        <translation-event xmlns="http://lds.org/code/lds-edit">{
            attribute status { $status },
            if ( fn:exists($to-event) ) then (
                if ($to-event/@status eq 'ready-for-translation') then (
                    element translation-ready {
                        attribute date { fn:current-dateTime() },  (: Real date unknown, but we know it is ready today :)
                        attribute username {"lds-edit"}, (: User unknown :)
                        attribute userid {""}
                    }
                ) else if ($to-event/@status eq 'sent-to-translation') then (
                    
                    element translation-ready {
                        attribute date { fn:current-dateTime() },  (: Real date unknown, but we know it is ready today :)
                        attribute username {"lds-edit"}, (: User unknown :)
                        attribute userid {""}
                    },
                    element translation-sent {
                        attribute translation-id { fn:replace(xs:string($to-event/*:translation-id), ' ', '-') },
                        attribute date { $sent-date },
                        attribute username {"lds-edit"}, (: Username unknown :)
                        attribute userid { xs:string($to-event/*:lds-account-id) }
                    }
                ) else ()
            ) else (),
            if ( fn:exists($from-event) ) then (
                if ($from-event/@status eq 'ready-for-review') then (
                    if ($file-locale eq 'eng') then (
                        for $locale as element() in $from-event/*:locales/*:locale
                        return (
                            build-translation-returned( xs:string($locale/@date), xs:string($from-event/@component-id), xs:string($locale) )
                        )
                    ) else (
                        build-translation-returned( xs:string(($from-event/*:locales/*:locale/@date)[1]), xs:string($from-event/@component-id), xs:string(($from-event/*:locales/*:locale/@locale)[1]) )
                    ),
                    build-translation-not-ready($from-event)
                ) else if ($from-event/@status eq 'completed') then (
                    if ($file-locale eq 'eng') then (
                        for $locale as element() in $from-event/*:locales/*:locale
                        return (
                            build-translation-returned( xs:string($locale/@date), xs:string($from-event/@component-id), xs:string($locale) )
                        )
                    ) else (
                       build-translation-returned( xs:string(($from-event/*:locales/*:locale/@date)[1]), xs:string($from-event/@component-id), xs:string(($from-event/*:locales/*:locale/@locale)[1]) )
                    ),
                    build-translation-not-ready($from-event),
                    build-translation-reviewed($file, $from-event)
                ) else if ($from-event/@status eq 'remove-from-page') then (
                    build-translation-returned( xs:string(($from-event/*:locales/*:locale/@date)[1]), xs:string($from-event/@component-id), xs:string(($from-event/*:locales/*:locale/@locale)[1]) ),
                    build-translation-not-ready($from-event),
                    build-translation-remove($from-event)
                ) else (

                )
            ) else ()
        }</translation-event>
    )
};

declare function buildMeta($file as element()) as element(ldse:ldse-meta) {
    <ldse-meta its:translate="no" xmlns="http://lds.org/code/lds-edit" xmlns:its="http://www.w3.org/2005/11/its">{
        build-document($file),
        build-created($file),
        build-last-modified(),
        build-publish-date($file),
        build-unpublish-date($file),
        build-scheduled-publish($file),
        build-translation-event($file),
        build-form-options($file)
    }</ldse-meta>  
};
