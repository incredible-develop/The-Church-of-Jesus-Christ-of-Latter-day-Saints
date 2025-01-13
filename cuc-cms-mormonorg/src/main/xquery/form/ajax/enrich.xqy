xquery version "1.0-ml";

import module namespace enrich = "http://lds.org/code/shared/lds-edit/enrich" at "../../enrich/enrich-functions.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "../../modules/ldse-meta.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../modules/ldse-core.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../modules/utility-functions.xqy";

declare option xdmp:mapping "true";
declare option xdmp:output "method = html";

let $id as xs:string := xdmp:get-request-field('id')
let $locale as xs:string := xdmp:get-request-field('locale')

let $lang as xs:string := util:get-lang-from-locale($locale)

let $file as element() := ldsemeta:get-file-by($id, $locale, (), ())

let $enrich as element(enrich) := enrich:get-enrich-data($file, fn:true())

return (
    xdmp:set-response-content-type("text/html; charset=utf-8"),
    
    <div class="ldse-section--body ldse-enrich-section ldse-form clearfix">
       <input type="hidden" name="ldse-document-enriched" value="true"/>
       <div class="ldse-enrich-text-container">
        <div class="ldse-enrich-text">{ $enrich/text/node() }</div> 
       </div>

       <div class="ldse-enrich-sidebar">
            
            <h4>Entities</h4>
            {
                if ( fn:exists($enrich/entities/person-entity) ) then (
                    <h5>People</h5>,
                    <ul class="ldse-enrich-list">{
                        for $term as element(person-entity) at $i in $enrich/entities/person-entity
                        let $text as xs:string := xs:string($term)
                        let $active as xs:boolean := fn:not($term/@active = "false")
                        let $disabled-class as xs:string? := if ( fn:not($active) ) then ( "enrich-disabled" ) else ()
                        let $meta-data as element(enrich:person)? := enrich:get-meta-data('person', $text, $lang)
                        let $url as xs:string? := xs:string($meta-data/enrich:url)
                        return (
                            <li>
                                <div class="enrich-list-form {$disabled-class}">
                                    <input type="checkbox" name="ldse-person" class="ldse-icon-x" value="{ $i }" data-enrichClass="ldse-enrich-person-{$i}" id="ldse-enrich-person-{$i}">{
                                        if ($active) then (
                                            attribute checked { "checked"}
                                        ) else ()
                                    }</input>
                                    <label for="ldse-enrich-person-{$i}">&nbsp;</label>
                                    <span class="enrich-color ldse-enrich-person-{$i} ldse-enrich-bkg">&nbsp;</span>
                                    <span class="enrich-list-name">{ $text }</span>
                                </div>
                                <div class="enrich-list-form-info">
                                    <h6>Number of times "{$text}" found</h6>
                                    <span class="enrich-number">{ xs:string($term/@count) }</span>
                                    {
                                        if ( fn:exists($url) ) then (
                                            <h6>Assigned SEO Link:</h6>,
                                            <p><a href="{$url}">{$url}</a></p>
                                        ) else (),
                                        for $data as element() in $meta-data/* except $meta-data/(enrich:name|enrich:url)
                                        let $name as xs:string := fn:concat(fn:local-name($data), ':')
                                        return (
                                            <h6>{ $name }</h6>,
                                            <p>{ $data/node() }</p>
                                        )
                                    }
                                </div>
                            </li>
                        )
                    }</ul>
                ) else ()
            }
            {
                if ( fn:exists($enrich/entities/organization-entity) ) then (
                    <h5>Organizations</h5>,
                    <ul class="ldse-enrich-list">{
                        for $term as element(organization-entity)   at $i in $enrich/entities/organization-entity
                        let $text as xs:string := xs:string($term)
                        let $active as xs:boolean := fn:not($term/@active = "false")
                        let $disabled-class as xs:string? := if ( fn:not($active) ) then ( "enrich-disabled" ) else ()
                        let $meta-data as element(enrich:organization)? := enrich:get-meta-data('organization', $text, $lang)
                        let $url as xs:string? := xs:string($meta-data/enrich:url)
                        return (
                            <li>
                                <div class="enrich-list-form {$disabled-class}">
                                    <input type="checkbox" name="ldse-organization" class="ldse-icon-x" value="{ $i }" data-enrichClass="ldse-enrich-organization-{$i}" id="ldse-enrich-organization-{$i}">{
                                        if ($active) then (
                                            attribute checked { "checked"}
                                        ) else ()
                                    }</input>
                                    <label for="ldse-enrich-organization-{$i}">&nbsp;</label>
                                    <span class="enrich-color ldse-enrich-organization-{$i} ldse-enrich-bkg">&nbsp;</span>
                                    <span class="enrich-list-name">{ $text }</span>
                                </div>
                                <div class="enrich-list-form-info">
                                    <h6>Number of times "{$text}" found</h6>
                                    <span class="enrich-number">{ xs:string($term/@count) }</span>
                                    {
                                        if ( fn:exists($url) ) then (
                                            <h6>Assigned SEO Link:</h6>,
                                            <p><a href="{$url}">{$url}</a></p>
                                        ) else (),
                                        for $data as element() in $meta-data/* except $meta-data/(enrich:name|enrich:url)
                                        let $name as xs:string := fn:concat(fn:local-name($data), ':')
                                        return (
                                            <h6>{ $name }</h6>,
                                            <p>{ $data/node() }</p>
                                        )
                                    }
                                </div>
                            </li>
                        )
                    }</ul>
                ) else ()
            }
            {
                if ( fn:exists($enrich/entities/role-entity) ) then (
                    <h5>Roles</h5>,
                    <ul class="ldse-enrich-list">{
                        for $term as element(role-entity)  at $i in $enrich/entities/role-entity
                        let $text as xs:string := xs:string($term)
                        let $active as xs:boolean := fn:not($term/@active = "false")
                        let $disabled-class as xs:string? := if ( fn:not($active) ) then ( "enrich-disabled" ) else ()
                        let $meta-data as element(enrich:role)? := enrich:get-meta-data('role', $text, $lang)
                        let $url as xs:string? := xs:string($meta-data/enrich:url)
                        return (
                            <li>
                                <div class="enrich-list-form {$disabled-class}">
                                    <input type="checkbox" name="ldse-role" class="ldse-icon-x" value="{ $i }" data-enrichClass="ldse-enrich-role-{$i}" id="ldse-enrich-role-{$i}">{
                                        if ($active) then (
                                            attribute checked { "checked"}
                                        ) else ()
                                    }</input>
                                    <label for="ldse-enrich-role-{$i}">&nbsp;</label>
                                    <span class="enrich-color ldse-enrich-role-{$i} ldse-enrich-bkg">&nbsp;</span>
                                    <span class="enrich-list-name">{ $text }</span>
                                </div>
                                <div class="enrich-list-form-info">
                                    <h6>Number of times "{$text}" found</h6>
                                    <span class="enrich-number">{ xs:string($term/@count) }</span>
                                    {
                                        if ( fn:exists($url) ) then (
                                            <h6>Assigned SEO Link:</h6>,
                                            <p><a href="{$url}">{$url}</a></p>
                                        ) else (),
                                        for $data as element() in $meta-data/* except $meta-data/(enrich:name|enrich:url)
                                        let $name as xs:string := fn:concat(fn:local-name($data), ':')
                                        return (
                                            <h6>{ $name }</h6>,
                                            <p>{ $data/node() }</p>
                                        )
                                    }
                                </div>
                            </li>
                        )
                    }</ul>
                ) else ()
            }
            {
                if ( fn:exists($enrich/entities/location-entity) ) then (
                    <h5>Locations</h5>,
                    <ul class="ldse-enrich-list">{
                        for $term as element(location-entity) at $i in $enrich/entities/location-entity
                        let $text as xs:string := xs:string($term)
                        let $active as xs:boolean := fn:not($term/@active = "false")
                        let $disabled-class as xs:string? := if ( fn:not($active) ) then ( "enrich-disabled" ) else ()
                        let $meta-data as element(enrich:location)? := enrich:get-meta-data('location', $text, $lang)
                        let $url as xs:string? := xs:string($meta-data/enrich:url)
                        return (
                            <li>
                                <div class="enrich-list-form {$disabled-class}">
                                    <input type="checkbox" name="ldse-location" class="ldse-icon-x" value="{ $i }" data-enrichClass="ldse-enrich-location-{$i}" id="ldse-enrich-location-{$i}">{
                                        if ($active) then (
                                            attribute checked { "checked"}
                                        ) else ()
                                    }</input>
                                    <label for="ldse-enrich-location-{$i}">&nbsp;</label>
                                    <span class="enrich-color ldse-enrich-location-{$i} ldse-enrich-bkg">&nbsp;</span>
                                    <span class="enrich-list-name">{ $text }</span>
                                </div>
                                <div class="enrich-list-form-info">
                                    <h6>Number of times "{$text}" found</h6>
                                    <span class="enrich-number">{ xs:string($term/@count) }</span>
                                    {
                                        if ( fn:exists($url) ) then (
                                            <h6>Assigned SEO Link:</h6>,
                                            <p><a href="{$url}">{$url}</a></p>
                                        ) else (),
                                        for $data as element() in $meta-data/* except $meta-data/(enrich:name|enrich:url)
                                        let $name as xs:string := fn:concat(fn:local-name($data), ':')
                                        return (
                                            <h6>{ $name }</h6>,
                                            <p>{ $data/node() }</p>
                                        )
                                    }
                                </div>
                            </li>
                        )
                    }</ul>
                ) else ()
            }
            <h4>Keywords</h4>
                <ul class="ldse-enrich-list">
                    {(:<li>
                        <div class="enrich-list-form">
                            <input type="checkbox" checked="" id="ldse-keyword-active1" name="ldse-keyword" class="ldse-icon-x" value="true" data-enrichClass="ldse-enrich-keyword-1" />
                            <span class="enrich-color ldse-enrich-keyword-1 ldse-enrich-bkg">&nbsp;</span>
                            <span class="enrich-list-name">President</span>
                        </div>
                        <div class="enrich-list-form-info">
                            <h6>Number of Keyword "presidency" found</h6>
                            <span class="enrich-number">27</span>
    
                            <h6>Assigned SEO Link:</h6>
                            <p>http://mormon.org/faq/ward-stake-branch</p>
    
                            <h6>Hours:</h6>
                            <p>Monday 7:30am - 4:00pm</p>
                            <p>Tuesday - Friday 7:30am - 4:00pm</p>
                            <p>Closed Sunday</p>
                        </div>
                    </li>:)}
                    {
                        for $term as element(term) at $i in $enrich/terms/term
                        let $text as xs:string := xs:string($term)
                        let $active as xs:boolean := fn:not($term/@active = "false")
                        let $disabled-class as xs:string? := if ( fn:not($active) ) then ( "enrich-disabled" ) else ()
                        let $meta-data as element(enrich:keyword)? := enrich:get-meta-data('keyword', $text, $lang)
                        let $url as xs:string? := xs:string($meta-data/enrich:url)
                        let $link-class as xs:string? := if ( fn:exists($url) ) then ( "ldse-icon-link" ) else ()
                        return (
                            <li>
                                <div class="enrich-list-form {$disabled-class}">
                                    <input type="checkbox" name="ldse-keyword" class="ldse-icon-x" value="{ $i }" data-enrichClass="ldse-enrich-keyword-{$i}" id="ldse-enrich-keyword-{$i}">{
                                        if ($active) then (
                                            attribute checked { "checked"}
                                        ) else ()
                                    }</input>
                                    <label for="ldse-enrich-keyword-{$i}">&nbsp;</label>
                                    <span class="enrich-color ldse-enrich-keyword-{$i} ldse-enrich-bkg {$link-class}">&nbsp;</span>
                                    <span class="enrich-list-name">{ $text }</span>
                                </div>
                                <div class="enrich-list-form-info">
                                    <h6>Number of times "{$text}" found</h6>
                                    <span class="enrich-number">{ xs:string($term/@count) }</span>
                                    {
                                        if ( fn:exists($url) ) then (
                                            <h6>Assigned SEO Link:</h6>,
                                            <p><a href="{$url}">{$url}</a></p>
                                        ) else ()
                                    }
                                </div>
                            </li>
                        )
                    }
                </ul>
            <h4>Related Articles</h4>
            <ul class="ldse-enrich-list">{
                for $match as element(match) at $i in $enrich/related/match
                let $title as xs:string := $match/@title
                let $url as xs:string := $match/@url
                let $active as xs:boolean := $match/@active = "true"
                let $disabled-class as xs:string? := if ( fn:not($active) ) then ( "enrich-disabled" ) else ()
                return (
                    <li>
                        <div class="enrich-list-form {$disabled-class}">
                            <input type="checkbox" name="ldse-related" class="ldse-icon-x" value="{ $i }" id="ldse-enrich-related-{$i}">{
                                if ($active) then (
                                    attribute checked { "checked"}
                                ) else ()
                            }</input>
                            <label for="ldse-enrich-related-{$i}">&nbsp;</label>
                            <span class="enrich-list-name">{$title}</span>
                        </div>
                        <div class="enrich-list-form-info">
                            <h6>Link:</h6>
                            <p><a href="{$url}">{$url}</a></p>
                        </div>
                    </li>  
                )
            }</ul>  
         <h4>Phrases</h4>
                <ul class="ldse-enrich-list--simple">
                    {
                        for $phrase as element(phrase) in $enrich/phrases/phrase
                        return (
                            <li>{xs:string($phrase)}</li>
                        )
                    }
                </ul>
            <h4>Concepts</h4>
                <ul class="ldse-enrich-list--simple">
                    {
                        for $concept as element(concept) in $enrich/concepts/concept
                        return (
                            <li>{xs:string($concept/@label)}</li>
                        )
                    }
                </ul>
       </div>
    </div>
)
