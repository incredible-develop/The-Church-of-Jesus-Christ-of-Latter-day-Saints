xquery version "1.0-ml";

module namespace json="http://marklogic.com/json";

declare default function namespace "http://www.w3.org/2005/xpath-functions";
declare option xdmp:mapping "true";

(:This is a :)

declare function json:obj($keyValues as xs:string*) as xs:string {
    concat("{",
        string-join($keyValues, ","),
    "}")
};
declare function json:escapedKeyValue($key as xs:string, $value as xs:string?) as xs:string {
    concat( json:stringEscape($key), ':', json:stringEscape($value) )
};
declare function json:keyValue($key as xs:string, $value as xs:string?) as xs:string {
    concat('"', $key, '":"', $value,'"')
};
declare function json:keyEscapedValue($key as xs:string, $value as item()?) as xs:string {
    concat('"', $key, '":', json:stringEscape($value) )
};

declare function json:keyObject($key as xs:string, $value as xs:string) as xs:string {
    concat(xdmp:to-json-string($key), ':', $value,'')
};

declare function json:keyValueObject($key as xs:string, $value as item()) as xs:string {
    concat('"', $key, '":', xdmp:to-json-string($value) )
};

(:All items in the array do not needed to be quote...:)
declare function json:arr($items as item()*) as xs:string {
    concat("[", 
        string-join($items,","),
    "]")
};
(:This will quote all items into the array:)
declare function json:arrq($items as item()*) as xs:string {
    json:arr( for $item as item() in $items return xdmp:to-json-string(string($item)))
};
declare function json:escapeString($item as xs:string) as xs:string {
    fn:replace(xdmp:to-json-string($item), '^"(.*)"$', '$1')
};
declare function json:escapeItem($item as item()?) as xs:string{
    fn:replace(xdmp:to-json-string(string($item)), '^"(.*)"$', '$1')
};

(: without quotes :)
declare function json:numberEscape( $item as item() ) as xs:string {
    fn:replace(xdmp:to-json-string(xdmp:quote($item)), '^"(.*)"$', '$1')
};

(: with quotes :)
declare function json:stringEscape( $item as item() ) as xs:string {
    xdmp:to-json-string(xdmp:quote($item))
};

(:Retrieves JSON from the string or already escaped JSON:)
declare function json:retrieve-json($json as item()*) as item()*{

  typeswitch($json)
   case xs:string return 
        if($json = "") then () 
        else (json:retrieve-json(xdmp:from-json($json)))
   default return $json
};

declare function json:xml-json($node as element()) as xs:string {
    json:obj((
        json:process-xml($node)
    ))
};

declare function json:process-xml( $node as item() ) as xs:string {
    let $name as xs:string := fn:local-name($node)
    return(
        if ($node/@array = "true" or ($node/*)[1]/fn:local-name(.) = ($node/*)[2]/fn:local-name(.) ) then (
            json:keyObject($name, 
                json:arrq($node/*)
            )
        ) else if ( fn:exists($node/@quote) ) then (
            json:keyEscapedValue($name, xdmp:quote($node))
        
        ) else if ( fn:exists($node/*) ) then (
            json:keyObject($name, 
                json:obj((
                    json:process-xml($node/*)
                ))
            )     
        ) else (
            json:keyEscapedValue($name, fn:string($node))
        )
    )
};

declare function json:xml-json-enhanced($node as element()) as xs:string {
    json:obj((
        json:process-xml-enhanced($node)
    ))
};

declare function json:process-xml-enhanced( $node as item() ) as xs:string {
    let $name as xs:string := fn:local-name($node)
    return (
        if ($node/@array = "true" or ($node/*)[1]/fn:local-name(.) = ($node/*)[2]/fn:local-name(.) ) then (
            json:keyObject($name,
                json:arrq-enhanced($node/*)
            )
        ) else if ( fn:exists($node/@quote) ) then (
            json:keyEscapedValue($name, xdmp:quote($node))
        
        ) else if ( fn:exists($node/*) ) then (
            json:keyObject($name,
                json:obj((
                    json:process-xml-enhanced($node/*)
                ))
            )
        ) else (
            json:keyEscapedValue($name, fn:string($node))
        )
    )
};

(:This will quote all items into the array:)
declare function json:arrq-enhanced($items as item()*) {
    json:arr-enhanced(
        json:arrq-thing($items)
    )
};


(:All items in the array do not need to be quote...:)
declare function json:arr-enhanced($items as item()*) {
    xdmp:to-json($items)
};

declare function json:arrq-thing($items as item()*) {
    for $item as item() in $items
    return (
        typeswitch ($item)
        case element() return (
            if ( fn:exists($item/element()) ) then ( 
                if ( fn:exists($item/attribute()) ) then (
                    json:obj((
                        json:arr((
                            for $attribute in $item/attribute() 
                            return ( json:obj((fn:local-name($attribute), xs:string($attribute))) ),
                            json:obj((json:arrq-thing($item/element())))
                        ))
                    ))
                ) else (
                    json:obj((json:arrq-thing($item/element())))
                )
            ) else (
                json:keyEscapedValue(fn:local-name($item), fn:string($item))
            )
        )
        default return ()
    )
};