xquery version "1.0-ml";

module namespace report = "http://lds.org/code/shared/lds-edit/reportFunctions";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../modules/utility-functions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../modules/ldse-core.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../modules/ldse-settings.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare option xdmp:mapping "true";

declare function getReport($name as xs:string) as element(report)? {
    cts:search(/report,
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-value-query(xs:QName('report'), xs:QName('name'), $name, 'exact')
        ))
    )
};

declare function verifyBreakDowns($breakDownParams as xs:string, $breakdowns as element(break-down)*) as xs:string {
    fn:string-join(
        for $breakdown as xs:string in fn:tokenize($breakDownParams, ',')
        where $breakdowns[@name eq $breakdown] or $breakdown eq 'type'
        return ($breakdown),
        ','
    )
};

declare function getBuckets($report as element(report)) as element(bucket)* {
    $report/bucket
};


declare function getBreakdowns($report as element(report)) as element(break-down)* {
    $report/break-down
};

declare function getQNames($report as element(report)) as xs:string* {
    $report/QNames/QName
};

declare function wordCount($docs as element()*) as xs:unsignedLong {
    xs:unsignedLong(
        fn:count(
            cts:tokenize($docs)[
                typeswitch (.) case $token as cts:word return fn:true()
                default return ( fn:false() )
            ]
        )
    )
};


declare function getMetricsByQuery($query as cts:query* ) as element(metrics) {
    let $results as xs:anyAtomicType* :=
        cts:element-attribute-values(xs:QName("ldse:document"), xs:QName('words'), (), ("any", "unchecked"),
            $query
        )
    let $words as xs:unsignedLong := xs:unsignedLong(cts:sum($results))
    let $count as xs:unsignedLong := cts:count($results)
   (: let $words := cts:search(xdmp:document-properties(),
                   cts:document-fragment-query($query), 'unfiltered'
                  )/prop:properties/prop:words
    let $sum := xs:unsignedLong(fn:sum($words)) :)
    return (
        <metrics>
            <count>{$count}</count>
            <words>{$words}</words>
            <tgp>{wordsToTGP($words)}</tgp>
        </metrics>
    )
};

declare function wordsToTGP($words as xs:unsignedLong) as xs:double {
    $words div 286
};

declare function buildQuery($query as item()*, $values as xs:string*, $QNames as xs:string*) as cts:query* {
   cts:query(
    replaceQueryVariables($query, $QNames, $values)
   )
};

(: Replaces any variables found in a cts:text and cts:element :)
declare function replaceQueryVariables($nodes as item()*, $QNames as xs:string*, $values as xs:string*) as item()* {
    for $n as item() in $nodes
    return (
        typeswitch ($n)
        case text() return ($n)
        case element(cts:text) return (
            if ( xs:string($n) eq '$value' ) then (
                for $value as xs:string in $values
                return (
                    element cts:text { $value }
                )
            ) else ($n)
        )
        case element(cts:uri) return (
            if ( xs:string($n) eq '$value' ) then (
                for $value as xs:string in $values
                return (
                    element cts:uri { $value }
                )
            ) else ($n)
        )
        case element(cts:element) return (
            if ( fn:string($n) eq '$root-QName' ) then (
                for $QName as xs:string in $QNames
                return (
                    element cts:element { $QName }
                )
            ) else ($n)
        )
        default return element { fn:node-name($n) } { $n/@*, replaceQueryVariables($n/node(), $QNames, $values) }
    )
};

declare function combineQueries($query1 as cts:query*, $query2 as cts:query*) as cts:query* {
    cts:and-query((
        $query1, $query2
    ))
};

declare function buildBreakdownRow( $break-down as element(break-down) ) as element(tr)* {
    element tr {
        attribute data-level { $break-down/@level },
        attribute class {
            if ($break-down/@level eq 1) then ("open") else ("close")
        },
        element td {
            element span {
                attribute class { fn:concat('ml',$break-down/@level) },
                if ( fn:exists($break-down/break-down) ) then (
                    element a {
                        attribute href {"#"},
                        attribute class {"breakdown sprite list icon"},
                        'breakdown'
                    }
                ) else (),
                xs:string($break-down/@title)
            }
        },
        element td {
            attribute class {"words"},
            fn:format-number(xs:unsignedLong($break-down/metrics/words), '#,##0')
        },
        element td {
            attribute class {"tgp"},
            fn:format-number(xs:double($break-down/metrics/tgp), '#,##0.00')
        },
        element td {
            attribute class {"count"},
            fn:format-number(xs:unsignedLong($break-down/metrics/count), '#,##0')
        }
    },
    if ( fn:exists($break-down/break-down) ) then (
        buildBreakdownRow( $break-down/break-down )
    ) else ()
};


declare function buildBreakdownExport( $break-down as element(break-down) ) as element(row)* {
    element row {
        element BREAK-DOWN { fn:concat(addSpaces(xs:int($break-down/@level)), $break-down/@title) },
        element WORDS { xs:unsignedLong($break-down/metrics/words) },
        element TGP { xs:double($break-down/metrics/tgp) },
        element COUNT { xs:unsignedLong($break-down/metrics/count) }
    },
    if ( fn:exists($break-down/break-down) ) then (
        buildBreakdownExport( $break-down/break-down )
    ) else ()
};



declare function addSpaces($level as xs:int) as xs:string? {
    fn:string-join(
        for $i as xs:int in 1 to ($level - 1) * 10
        return ('&nbsp;'),
        ''
    )
};

declare function getGeneratedReport($report as element(report), $breakDowns as xs:string) as element(generated-report) {
    let $generated-report as element(generated-report)? :=
        cts:search(/generated-report,
            cts:and-query((
                core:get-filter-query(),
                cts:element-attribute-value-query(xs:QName('generated-report'), xs:QName('date'), xs:string(fn:current-date()), 'exact'),
                cts:element-attribute-value-query(xs:QName('generated-report'), xs:QName('report-name'), $report/@name, 'exact'),
                cts:element-attribute-value-query(xs:QName('generated-report'), xs:QName('breakdowns'), $breakDowns, 'exact')
            ))
        )[1]
    return (
        if (fn:exists($generated-report)) then (
            $generated-report
        ) else (
            generateReport($report, $breakDowns)
        )
    )

};

declare function generateReport($report as element(report), $breakDowns as xs:string) as element(generated-report) {
    let $xml as element(generated-report) :=
        element generated-report {
            attribute report-name {$report/@name},
            attribute breakdowns {$breakDowns},
            attribute date {fn:current-date()},
            buildGeneratedBreakdowns(
                getBuckets($report),
                getBreakdowns($report),
                getQNames($report),
                fn:tokenize($breakDowns, ',')
                , 1, ()
            )
        }

    let $date as xs:date := fn:current-date()
    let $year as xs:integer? := fn:year-from-date($date)
    let $month as xs:integer? := fn:month-from-date($date)
    let $monthText as xs:string := if ($month < 10) then ( fn:concat("0", xs:string($month)) ) else ( xs:string($month) )
    let $day as xs:integer? := fn:day-from-date($date)
    let $dayText as xs:string := if ($day < 10) then ( fn:concat("0", xs:string($day)) ) else ( xs:string($day) )
    let $fileName as xs:string := fn:substring-before(util:generate-unique-id('eng'), '-')
    let $documentURI as xs:string := core:build-db-path("", "", $fileName, $xml, <options><path>{fn:concat(xs:string($year),"/",$monthText,"/",$dayText)}</path></options>)
    let $save as item()* := core:save-file($documentURI, $xml, ())
    return $xml
};

declare function buildGeneratedBreakdowns(
    $buckets as element(bucket)+,
    $allBreakdowns as element(break-down)*,
    $QNames as xs:string*,
    $breakDownNames as xs:string*,
    $level as xs:int*,
    $currentQuery as cts:query*) as element(break-down)*
{
        let $name as xs:string? := $breakDownNames[$level]
        let $breakdown as element(break-down)? := $allBreakdowns[@name eq $name]
        let $currentQuery as cts:query* :=
            if (fn:empty($currentQuery)) then (
                    cts:element-query(
                        for $QName as xs:string in $QNames
                        return (xs:QName($QName)),
                        cts:and-query(())
                    ),
                    if ($settings:manage-shared) then (
                        cts:directory-query(
                            (fn:concat('/preview/', $core:site, '/content/'),
                             fn:concat('/published/', $core:site, '/content/'),
                             '/preview/shared/', '/published/shared/'),
                             'infinity')
                    ) else (
                        cts:directory-query(
                            (fn:concat('/preview/', $core:site, '/content/'),
                             fn:concat('/published/', $core:site, '/content/')),
                             'infinity')
                    )
            ) else ($currentQuery)
        where fn:exists($name)
        return (
            if ($name eq 'type') then (
                for $bucket as element(bucket) in $buckets
                let $query as cts:query* := cts:query($bucket/query/*)
                let $newQuery as cts:query* := combineQueries($currentQuery, $query)
                let $metrics as element(metrics) := getMetricsByQuery($newQuery)
                let $words as xs:unsignedLong := xs:unsignedLong($metrics/words)
                let $count as xs:unsignedLong := xs:unsignedLong($metrics/count)
                let $value as xs:string := $bucket/@name
                where $count ne 0
                order by $words descending
                return (
                    element break-down {
                        attribute name {$name},
                        attribute level {$level},
                        attribute value {$value},
                        attribute title {$value},
                        $metrics,
                        buildGeneratedBreakdowns($buckets, $allBreakdowns, $QNames, $breakDownNames, $level + 1, ($currentQuery, $query))
                    }
                )
            ) else (
                for $value as element(value) in $breakdown/values/value
                let $title as xs:string := if ($value/@title ne '') then ($value/@title) else ($value)
                let $value as xs:string := $value
                let $query as cts:query* := buildQuery($breakdown/query/*, $value, $QNames)
                let $newQuery as cts:query* := combineQueries($currentQuery, $query)
                let $metrics as element(metrics) := getMetricsByQuery($newQuery)
                let $words as xs:unsignedLong := xs:unsignedLong($metrics/words)
                let $count as xs:unsignedLong := xs:unsignedLong($metrics/count)
                where $count ne 0
                order by $words descending
                return (
                    element break-down {
                        attribute name {$name},
                        attribute level {$level},
                        attribute value {$value},
                        attribute title {$title},
                        $metrics,
                        buildGeneratedBreakdowns($buckets, $allBreakdowns, $QNames, $breakDownNames, $level + 1, ($currentQuery, $query))
                    }
                )
            )
        )
};

