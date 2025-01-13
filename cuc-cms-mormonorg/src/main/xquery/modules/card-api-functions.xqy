xquery version "1.0-ml";

module namespace caf = 'http://lds.org/code/modules/card-api-functions';

import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module namespace gct = 'http://lds.org/code/transforms/gl-card-transform' at '../transforms/gl-card-transform.xqy';
import module namespace security = "http://lds.org/code/shared/common/security/security-functions" at "/shared/common/security/securityFunctions.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "utility-functions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "ldse-settings.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "ldse-core.xqy";

declare function caf:getCardById(
    $cardId as xs:string,
    $lang as xs:string
) as element(card)? {
    cts:search(/card, 
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-value-query(xs:QName("card"), xs:QName("id"), $cardId || '-' || $lang, 'exact')
        ))
    )
};

declare function caf:get-card-json(
    $params-in as map:map?,
    $cardId as xs:string
) {
    (: Card ID was passed only return the one card :)
    let $lang as xs:string := ( map:get($params-in, 'lang'), xdmp:get-request-field('lang') )[1]
    let $cardNode as element(card) := caf:getCardById($cardId, $lang)
    (: process the card to an object to return as json :)
    let $cardObject as object-node() := gct:perform-transform($cardNode, $params-in)
    let $json := 
        object-node {
            'payload': $cardObject
        }
    return (
        xdmp:to-json(util:removeNullsFromJSON(xdmp:from-json($json)))
    )
};

declare function caf:get-cards-json(
    $params-in as map:map?
) {
    let $user-file as item()* := caf:get-user-file(security:getAccountId())[2]/node()
    let $interested-tags as xs:string* := $user-file/payload
    let $limit as xs:int := xs:int(( map:get($params-in, 'limit'), 25 )[1])
    let $offset as xs:int := xs:int(( map:get($params-in, 'offset'), 1 )[1])
    let $inject as xs:int? := xs:int(map:get($params-in, 'inject'))
    let $inject-count as xs:int? := if ( fn:exists($inject) ) then ( fn:floor($limit div $inject) ) else ( 0 )
    let $new-limit as xs:int := $limit - $inject-count
    let $page as xs:int := 
        if ( $offset = 1 ) then (
            1
        ) else ( fn:floor($offset div $new-limit) )
    let $injected-tiles-position := ( 1 to $inject-count )
    let $injected-tile-response as element(card)* := 
        if ( $inject > 0 ) then (
            caf:get-injected-cards-in-order($params-in)
        ) else ()
    let $injected-map as map:map := map:map()
    let $injected-tiles as element(card)* := 
        for $tile-position in $injected-tiles-position
        let $tile as element(card)? := $injected-tile-response[$tile-position]
        return (
            if ( fn:exists($tile) ) then (
                $tile
            ) else ( 
                let $map-count as xs:int := ( map:get($injected-map, 'count'), 1 )[1]
                let $put := map:put($injected-map, 'count', $map-count + 1)
                let $tile := $injected-tile-response[$map-count]
                return (
                    if ( fn:exists($tile) ) then (
                        $tile
                    ) else ( 
                        let $put := map:put($injected-map, 'count', 1)
                        return $injected-tile-response[1]
                    )
                )
            )
        )
    let $response as element(search:response) := caf:get-cards($params-in, $interested-tags, $offset, $limit, $inject-count, $new-limit)
    let $total-left as xs:int := 
        if ( $response/@total/xs:int(.) <= $offset + $new-limit ) then (
            $response/@total/xs:int(.) - ( $offset - 1 )
        ) else ( $new-limit )
    let $cards as element(card)* := $response/search:result/card
    let $cards-with-injected as element(card)* := caf:inject-injected-cards($injected-tiles, $inject, $cards, $total-left)
    let $card-json := util:removeNullsFromJSON(gct:perform-transform($cards-with-injected, $params-in))
    let $next-url as xs:string? := caf:get-next-page-url($params-in, $response/@total, $new-limit, $offset)
    let $json := 
        object-node {
            'type': 'cards',
            'total': $response/@total/xs:int(.),
            'next': object-node {
                'url': fn:string($next-url),
                'offset': if ( fn:exists($next-url) ) then ( $offset + $new-limit ) else ( '' )
            },
            'limit': $limit,
            'offset': $offset,
            'payload': array-node { $card-json }
        }
    return (
        xdmp:to-json(util:removeNullsFromJSON(xdmp:from-json($json)))
    )
};

declare function caf:inject-injected-cards(
    $injected-tiles as element(card)*,
    $inject as xs:int?,
    $cards as element(card)*,
    $total-left as xs:int
) as element(card)* {
    let $card-map as map:map := map:map()
    let $inject as empty-sequence() := 
        for $injected-tile at $i in $injected-tiles
        let $inject-interval as xs:int := $i * $inject
        let $previous-results as element(card)* := map:get($card-map, 'cards')
        let $items as element(card)* := 
            if ( fn:exists($previous-results) ) then (
                $previous-results
            ) else ( $cards )
        let $ignore as xs:boolean := $inject-interval * $i > ( $total-left * $inject-interval )
        where fn:not($ignore)
        return (
            let $results as element(card)* := 
                if ( fn:exists($previous-results) ) then (
                    fn:insert-before($items, $inject-interval, $injected-tiles[$i])
                ) else ( fn:insert-before($cards, $inject-interval, $injected-tiles[$i]) )
            return map:put($card-map, 'cards', $results)
        )
    let $cards-in-map as element(card)* := map:get($card-map, 'cards')
    return (
        if ( fn:exists($cards-in-map) ) then (
            $cards-in-map
        ) else ( $cards )
    )
};

declare function caf:get-next-page-url(
    $params-in as map:map,
    $response-total as xs:int,
    $new-limit as xs:int,
    $offset as xs:int
) {
    let $query-params as xs:string* := fn:string-join(caf:get-query-params($params-in), '&amp;')
    let $curr-url as xs:string? := map:get($params-in, 'requestUrl')
    let $new-offset as xs:int := $offset + $new-limit
    return (
        if ( $response-total >= ( $new-limit + $offset ) ) then (
            core:get-front-end-host() || $settings:shared-prefix || fn:substring-before($curr-url, '.xqy') || '?' || $query-params || '&amp;offset=' || $new-offset
        ) else ()
    )
};

declare function caf:get-query-params(
    $params-in as map:map?
) {
    for $key as xs:string in map:keys($params-in)
    where fn:not($key = ( 'requestUrl', 'offset' ))
    return (
        for $value as xs:string at $i in map:get($params-in, $key)
        return $key || '=' || map:get($params-in, $key)[$i]
    )
};

declare function caf:get-user-file(
    $username as xs:string
) as item()* {
    util:http-get($settings:personalization-service || '/api/v1/personalization/tags?accountId=' || $username, ())
};

declare function caf:get-user-interested-tags(
    $topic-interest as object-node()
) as xs:string {
    $topic-interest
};

declare function caf:get-injected-cards-in-order(
    $params-in as map:map?
) as element(card)* {
    for $injected-tile in caf:get-injected-cards($params-in)
    order by $injected-tile/channel-vessels/channel-vessel/channel/@start-date descending
    return $injected-tile
};

declare function caf:get-injected-cards(
    $params-in as map:map?
) as element(card)* {
    cts:search(/card, 
        cts:and-query(( 
            core:get-filter-query(),
            cts:element-attribute-value-query(xs:QName('card'), xs:QName("lang"), map:get($params-in, 'lang'), "exact"),
            cts:element-value-query(xs:QName('card-type'), 'injected', 'exact'),
            cts:element-attribute-range-query(xs:QName('channel'), xs:QName('start-date'), '<=', fn:current-date()),
            cts:or-query((
                cts:element-attribute-range-query(xs:QName('channel'), xs:QName('end-date'), '>', fn:string(fn:current-date())),
                cts:element-attribute-range-query(xs:QName('channel'), xs:QName('end-date'), '=', '')
            ))
        ))
    )
};

declare function caf:get-cards(
    $params-in as map:map?,
    $interested-tags as xs:string*,
    $offset as xs:int,
    $limit as xs:int,
    $inject as xs:int,
    $new-limit as xs:int
) as element(search:response) {
    let $lang as xs:string? := map:get($params-in, 'lang')
    let $only-interested as xs:boolean := map:get($params-in, 'interested') = 'true'
    let $tags as xs:string* := map:get($params-in, 'tags')[. != '']
    let $types as xs:string* := map:get($params-in, 'types')[. != '']
    let $options as element(search:options) := 
        <options xmlns="http://marklogic.com/appservices/search">
            <searchable-expression>/card</searchable-expression>
            <constraint name="contentType">
                <range type="xs:string" collation="http://marklogic.com/collation/" facet="true">
                    <element name="content-type" />
                </range>
            </constraint>
            <additional-query>
                {
                    cts:and-query((
                        core:get-filter-query(),
                        cts:element-attribute-value-query(xs:QName('card'), xs:QName("lang"), $lang, "exact", 0),
                        cts:element-attribute-value-query(xs:QName('card'), xs:QName("type"), 'card', "exact", 0),
                        if ( $only-interested ) then (
                            cts:or-query((
                                cts:element-attribute-value-query(xs:QName('tag'), xs:QName('id'), $interested-tags, 'exact'),
                                cts:element-value-query(xs:QName('priority'), 'true', 'exact')
                            ))
                        ) else (
                            cts:boost-query(
                                cts:and-query((
                                    if ( fn:exists($tags) ) then (
                                        for $tag in $tags
                                        return cts:element-attribute-value-query(xs:QName('tag'), xs:QName('id'), $tag, 'exact')
                                    ) else ()
                                )),
                                (cts:element-attribute-value-query(xs:QName('tag'), xs:QName('id'), $interested-tags, 'exact', 5.0),
                                cts:element-value-query(xs:QName('priority'), 'true', 'exact', 2.0))
                            )
                        ),
                        if ( fn:exists($types) ) then (
                            cts:element-value-query(xs:QName('card-type'), $types, 'exact')
                        ) else (),
                        cts:element-attribute-range-query(xs:QName('channel'), xs:QName('start-date'), '<=', fn:current-date(), ( 'score-function=reciprocal', 'slope-factor=0.5' ), 0.1),
                        cts:or-query((
                            cts:element-attribute-range-query(xs:QName('channel'), xs:QName('end-date'), '>', fn:string(fn:current-date())),
                            cts:element-attribute-range-query(xs:QName('channel'), xs:QName('end-date'), '=', '')
                        )),
                        cts:not-query(
                            cts:element-value-query(xs:QName('card-type'), 'injected', 'exact')
                        )
(:                        cts:element-value-query(xs:QName("ldse:site-context"), $site, "exact"):)
                    ))
                }
            </additional-query>
            <search-option>relevance-trace</search-option>
            <return-results>true</return-results>
            <transform-results apply="raw"/>
            <return-facets>true</return-facets>
            <term>
                <empty apply="all-results"/>
                <term-option>case-insensitive</term-option>
                <term-option>diacritic-insensitive</term-option>
                <term-option>punctuation-insensitive</term-option>
                <term-option>whitespace-insensitive</term-option>
                <term-option>lang={$lang}</term-option>
            </term>
{(:            <sort-order type="xs:date" direction="descending">
                <element name="channel" />
                <attribute name="start-date"/>
            </sort-order>:)}
            { 
                if ( $only-interested ) then (
                    <sort-order direction="descending">
                        <element name="channel" />
                        <attribute name="start-date"/>
                    </sort-order>,
                    <sort-order type="xs:dateTime" direction="descending">
                        <element name="created" ns="http://lds.org/code/lds-edit" />
                        <attribute name="date"/>
                    </sort-order>
                ) else ( 
                    <sort-order direction="descending">
                        <score/>
                    </sort-order>
                )
            }
        </options>
    let $results := search:search('', $options, $offset, $new-limit)
    return $results
};

declare function caf:get-injected-cards(
    $params-in as map:map?,
    $inject as xs:int,
    $offset as xs:int,
    $limit as xs:int
) as element(search:response) {
    let $lang := map:get($params-in, 'lang')
    let $options as element(search:options) := 
        <options xmlns="http://marklogic.com/appservices/search">
            <searchable-expression>/card</searchable-expression>
            <additional-query>
                {
                    cts:and-query((
                        core:get-filter-query(),
                        cts:element-attribute-value-query(xs:QName('card'), xs:QName("lang"), $lang, "exact"),
                        cts:element-attribute-value-query(xs:QName('card'), xs:QName("type"), 'card', "exact"),
                        cts:element-attribute-range-query(xs:QName('channel'), xs:QName('start-date'), '<=', fn:current-date(), ( 'score-function=reciprocal', 'slope-factor=0.5' )),
                        cts:or-query((
                            cts:element-attribute-range-query(xs:QName('channel'), xs:QName('end-date'), '>', fn:string(fn:current-date())),
                            cts:element-attribute-range-query(xs:QName('channel'), xs:QName('end-date'), '=', '')
                        )),
                        cts:element-value-query(xs:QName('card-type'), 'injected', 'exact')
(:                        cts:element-value-query(xs:QName("ldse:site-context"), $site, "exact"):)
                    ))
                }
            </additional-query>
            <search-option>relevance-trace</search-option>
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
{(:            <sort-order type="xs:date" direction="descending">
                <element name="channel" />
                <attribute name="start-date"/>
            </sort-order>:)}
            <sort-order direction="descending">
                <score/>
            </sort-order>
        </options>
    let $results := search:search('', $options, $offset, $limit)
    return $results
};
