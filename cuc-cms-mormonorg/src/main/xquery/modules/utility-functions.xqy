xquery version "1.0-ml";

module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions";

import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace mem = "http://lds.org/code/shared/common/memory-update" at "/shared/common/util/inMemoryUpdate.xqy";
import module namespace c = "http://lds.org/code/shared/common/common-functions" at "/shared/common/commonFunctions.xqy";
import module namespace library = "http://lds.org/code/shared/lds-edit/supported-languages" at "../supported-languages/modules/library.xqy";
(: LDS-EDIT Imports :)
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "ldse-core.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "ldse-settings.xqy";
import module namespace cf = "http://lds.org/code/lds-edit/content-admin/content-functions" at "/content-admin/modules/content-functions.xqy";
import module namespace json = "http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace jsonb = "http://marklogic.com/xdmp/json";
declare namespace its = "http://www.w3.org/2005/11/its";
declare namespace xhtml = "http://www.w3.org/1999/xhtml";

declare option xdmp:mapping "true";

declare variable $DEPRECATED as empty-sequence() := util:deprecated(());

declare variable $request-map as map:map := map:map();

declare variable $locale as xs:string? := util:js-number-escape(util:declare-locale());
declare variable $host as xs:string? := util:declare-host();
declare variable $protocol as xs:string? := util:get-protocol();
declare variable $ldse-settings as element(ldse:ldse-settings) := $core:ldse-settings;

declare function util:declare-host() as xs:string? {
    let $host as xs:string? := xdmp:get-request-header("host")
    let $protocol as xs:string? := util:get-protocol()
    let $full as xs:string := fn:concat($protocol, "://", $host)
    where $host != ""
    return ( $full )
};

declare function util:add-no-cache-header() as empty-sequence() {
    xdmp:add-response-header("Pragma", "no-cache"),
    xdmp:add-response-header("Cache-Control", "no-cache"),
    xdmp:add-response-header("Expires", "0")
};

declare function util:declare-locale() as xs:string {
    let $locale as xs:string? := util:sanitize-input(xdmp:get-request-field("locale", "")[1])
    let $lang as xs:string? := fn:replace(util:sanitize-input(xdmp:get-request-field("lang", $locale)[1]),"[^A-Za-z-]","")
    let $country as xs:string? := fn:replace(util:sanitize-input(xdmp:get-request-field("country", "")[1]),"[^A-Za-z]","")
    return ( if ($country ne '') then (fn:concat($lang, "-", $country)) else ($lang) )
};

declare function util:get-protocol() as xs:string {
    (xdmp:get-request-header("X-Forwarded-Scheme")[ . ne ""], "http")[1]
};

declare function util:set-server-field($key as xs:string, $value as item()*) as item()* {
    xdmp:set-server-field($key, $value)
};

declare function util:get-server-field($key as xs:string) as item()* {
    xdmp:get-server-field($key)
};

declare function util:get-server-field($key as xs:string, $default as item()*) as item()* {
    xdmp:get-server-field($key, $default)
};

declare function util:http-post($url as xs:string, $options as element()?) as item()* {
    util:http-post($url, $options, ())
};

declare function util:http-put($url as xs:string, $options as element()?) as item()* {
    util:http-put($url, $options, ())
};

declare function util:http-put($url as xs:string, $options as element()?, $data as item()?) as item()* {
    xdmp:http-put($url, $options, $data)
};

declare function util:http-post($url as xs:string, $options as element()?, $data as item()?) as item()* {
    xdmp:http-post($url, $options, $data)
};

declare function util:http-get($url as xs:string, $options as element()?) as item()* {
    xdmp:http-get($url, $options)
};

declare function util:login($username as xs:string, $password as xs:string?) as xs:boolean {
    util:login($username, $password, fn:false())
};

declare function util:login($username as xs:string, $password as xs:string?, $set-session as xs:boolean?) as xs:boolean {
    xdmp:login($username, $password, $set-session)
};

declare function util:unpath($xml as node(), $path as xs:string) as item()* {
    $xml/xdmp:unpath($path)
};

declare function util:value($xml as node(), $path as xs:string) as item()* {
    $xml/xdmp:value($path)
};

(:~
    Escapes characters of the provided string.
    @param $unescaped The string whos chars need escaping
    @return the provided string with escaped chars.
~:)
declare function util:sanitize-input($chars as xs:string?) as xs:string? {
    fn:replace($chars,"[\]\[<>{}\\();:%\+]","")
};

declare function util:remove-special-chars($string as xs:string) {
    fn:replace($string, '[^a-zA-Z0-9-_]', '')
};

declare function util:clean-file-name($file-name as xs:string) as xs:string{
    let $clean as xs:string := util:sanitize-uri($file-name)
    let $clean as xs:string := fn:replace($clean,'[/]','-')
    return $clean
};

(:~ this really just replaces chars so it's not truly escaping :)
declare function util:escape-chars($unescaped as xs:string?) as xs:string? {
    util:sanitize-input($unescaped)
};

(: escapes string that will be outputed within javascript: WITHOUT wrapping quotes :)
declare function util:js-number-escape($item as item()?) as xs:string {
    let $string as xs:string := fn:string($item)
    let $length as xs:int := fn:string-length($string)
    let $escaped as xs:string := xdmp:to-json-string($string)
    let $unquoted as xs:string := fn:substring($escaped, 2, $length)
    return (
        $unquoted
    )
};

(: escapes string that will be outputed within javascript: WITH wrapping quotes:)
declare function util:js-string-escape($string as xs:string?) as xs:string {
    xdmp:to-json-string($string)
};

declare function util:sanitize-uri($uri as xs:string) as xs:string {
    let $clean as xs:string := xdmp:diacritic-less($uri)
    let $clean as xs:string := util:sanitize-input($clean)
    let $clean as xs:string := fn:replace($clean, fn:codepoints-to-string((91,63,8220,8221,8217,34,35,42,44,46,38,39,93)), '')
    let $clean as xs:string := fn:replace($clean, '(^\s+|ldquo|rdquo|\s+$)', '')
    let $clean as xs:string := fn:replace($clean, '\s+', '-')
    let $clean as xs:string := fn:lower-case($clean)
    let $clean as xs:string := fn:replace($clean, '(—)|(–)|(&#x2013;)|(&#8211;)|(#x2014;)|(#8212;)','-')
    return $clean
};

(:~
    Escapes characters of the provided string except ().
    @param $unescaped The string whos chars need escaping
    @return the provided string with escaped chars.
~:)
declare function util:escape-chars-except-parens($unescaped as xs:string?) as xs:string? {
    fn:replace($unescaped,"[\]\[<>{}\\;%\+]","")
};

declare function util:split-locale-param(
    $locale as xs:string
) as xs:string {
    let $locale as xs:string := util:js-number-escape($locale)
    let $country as xs:string? := get-country-from-locale($locale)
    return (
        if ($country ne '') then (fn:concat('?lang=',util:get-lang-from-locale($locale),"&amp;country=",$country)) else (fn:concat('?lang=',$locale))
    )
};

declare function util:update-site-param(
    $params as xs:string?,
    $site as xs:string
) as xs:string {
    if ( fn:contains($params, 'site=') ) then (
        util:get-site-param-and-update($params, $site)
    ) else if ( util:string-exists($params) ) then (
        '?lang=eng&amp;site=' || $site
    ) else ( $params || '&amp;site=' || $site )
};

declare function util:get-site-param-and-update(
    $params as xs:string,
    $site as xs:string
) as xs:string {
    for $param as xs:string in fn:tokenize($params, '&amp;')
    where fn:starts-with($param, 'site=')
    return (
        fn:replace($params, $param, 'site=' || $site)
    )
};

declare function util:get-lang-from-locale($locale as xs:string) as xs:string {
    fn:replace($locale, "-.*", "")
};

declare function util:get-country-from-locale($locale as xs:string) as xs:string? {
    fn:substring-after($locale, '-')
};

declare function util:is-country($locale as xs:string) as xs:boolean {
    fn:contains($locale, '-')
};

declare function util:is-not-country($locale as xs:string) as xs:boolean {
    fn:not( util:is-country($locale) )
};

declare variable $languages as element(language)* := cts:search(/languages/language, cts:and-query(( () )) );
declare variable $language-map as map:map := util:build-language-map();
declare function util:build-language-map() as map:map {
    let $map as map:map := map:map()
    let $_  as empty-sequence() :=
        for $language as element(language) in $languages
        return (
            map:put($map, fn:concat($language/@key, $core:mode), xs:string($language/englishName))
        )
   return (
        $map
   )
};

(:~
    Returns the language name that matches the specified locale
    @param $lang
    @return Full language name (example: english)
~:)
declare function util:get-full-language-name-by-locale(
    $lang as xs:string
) as xs:string? {
    map:get($language-map, fn:concat($lang, $core:mode))
};

(:~
    Returns the language xml that matches the specified locale
    @param $lang
    @return language xml
~:)
declare function util:get-language-by-locale(
    $lang as xs:string
) as element(language)? {
    cts:search(/languages/language[@key = $lang],
        core:get-filter-query()
    )
};


(:~
    Retrieves the url for the specified service
    @param $service the service for which we are getting the url
    @return url as string
:)
declare function util:get-service-url(
    $service as xs:string
) as xs:string? {
    let $mode-root as xs:string := core:get-mode-root()
    let $key as xs:string := fn:concat($service, "-", $mode-root)
    let $url as xs:string? := map:get($request-map, $key)
    return (
        if (fn:exists($url)) then (
            $url
        ) else (
            let $url as xs:string? :=
                ($settings:environmentConfig/services/service[@name eq $service],"")[1]
            return (
                $url,
                map:put($request-map, $key, $url)
            )
        )
    )

};

(: Returns all current country and area locales :)
declare function util:get-country-locales() as xs:string* {
    let $sites as element(site)* := $country-sites
    let $locales as xs:string* :=
        for $site as element(site) in $sites
        return fn:concat($site/language/@key,'-', $site/@key)
    return $locales
};


declare variable $country-sites as element(site)* := util:get-country-sites();
(: Returns all country/area site files :)
declare function util:get-country-sites() as element(site)* {
    cts:search(/site,
        core:get-filter-query()
    )
};

(: Returns country/area site file by lang and id :)
declare function util:get-country-site-by-id(
    $lang as xs:string,
    $id as xs:string
) as element(site)? {
    cts:search(/site,
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-value-query(xs:QName('site'), xs:QName('key'), $id, 'exact'),
            cts:element-attribute-value-query(xs:QName('language'), xs:QName('key'), $lang, 'exact')
        ))
    )
};

(:~
    Retrieves the the countries xml for in a specific language and defaults back to english
    @param $locale - language
    @return $countries as element(countries)?
:)
declare function util:get-countries(
    $locale as xs:string
) as element(countries)? {
    let $locale as xs:string := util:get-lang-from-locale($locale)
    let $countries as element(countries)? :=
        cts:search(/countries,
            cts:and-query((
                core:get-filter-query(),
                cts:element-attribute-value-query(xs:QName('countries'), xs:QName('locale'), $locale, 'exact')
            ))
        )
    let $countries as element(countries)? :=
        if ( fn:exists($countries) ) then ($countries) else (
            cts:search(/countries,
                cts:and-query((
                    core:get-filter-query(),
                    cts:element-attribute-value-query(xs:QName('countries'), xs:QName('locale'), 'eng', 'exact')
                ))
            )
        )
    return $countries
};

(:~
   (Public) Generates a unique id that is 20 digits long with
    -[locale] appended. (example: 12345678901234567890-eng).

    @param $lang The locale of the desired id.

    @return A string representing the 24 character generated id.
:)

declare function util:generate-unique-id() as xs:string {
    util:generate-unique-id(())
};

declare function util:generate-unique-id(
    $lang as xs:string?
) as xs:string {
    let $hash as xs:string :=
        xs:string(
            xdmp:hash64(
                fn:concat(
                    xs:string(xdmp:host()),
                    xs:string(fn:current-dateTime()),
                    xs:string(xdmp:random())
                )
            )
        )
    return fn:string-join( (util:pad-string($hash, 20, fn:false()), $lang), '-')
};

(:~
    (Public) Takes a string and pads it be a string of the
    specified amount by appending zeroes to the end or by removing
    n characters from the end of the string if it is longer than the
    specified length.

    @param $string The string to get padded.
    @param $length Integer specifying the final length of the string.
    @param $padLeft Whether or not to add the padding to the left, if fn:false() then pads right

    @return A string of the specified length.
:)
declare function util:pad-string(
    $string as xs:string,
    $length as xs:integer,
    $pad-left as xs:boolean
) as xs:string {
    if (fn:string-length($string) = $length) then (
        $string
    ) else if (fn:string-length($string) < $length) then (
        if ($pad-left) then (
            util:pad-string(fn:concat("0", $string), $length, $pad-left)
        ) else (
            util:pad-string(fn:concat($string, "0"), $length, $pad-left)
        )
   ) else (
        fn:substring($string, 1, $length)
    )
};


(:~
    Sends an e-mail message

    @param $toEmail Recipient email address(es)
    @param $toName Recipient name(s)
    @param $subject The subject of the email
    @param $body The email message as text
    @param $fromEmail Sender's email address
    @param $fromName Sender's name
    @param $attachments Attachments in the following xml format:
                        <attachment>
                            <file-name>{name of attachment}</file-name>
                            <content-type>{content type }</content-type>
                            <content base64="true|false">{optional base64 encoding of attachment}</content>
                        </attachment>

    @return empty-sequence on success, error node otherwise
~:)
declare function util:send-email-with-attachments(
    $to-email as xs:string,
    $to-name as xs:string?,
    $subject as xs:string?,
    $body as xs:string?,
    $from-email as xs:string,
    $from-name as xs:string?,
    $attachments as element(attachment)*
) as item()* {
    let $new-line as xs:string := "&#13;&#10;"
    let $boundary as xs:string := fn:concat("boundary", xdmp:random())
    let $content-type as xs:string := fn:concat("multipart/mixed; boundary=",$boundary)
    return (
        try {
            xdmp:email(
                <em:Message xmlns:em="URN:ietf:params:email-xml:" xmlns:rf="URN:ietf:params:rfc822:">
                    <rf:subject>{$subject}</rf:subject>
                    <rf:from>
                        <em:Address>
                            <em:name>{$from-name}</em:name>
                            <em:adrs>{$from-email}</em:adrs>
                        </em:Address>
                    </rf:from>
                    <rf:to>
                        <em:Address>
                            <em:name>{$to-name}</em:name>
                            <em:adrs>{$to-email}</em:adrs>
                        </em:Address>
                    </rf:to>
                    <rf:content-type>{$content-type}</rf:content-type>
                    <em:content xml:space="preserve">{
                        fn:string-join((
                                "--", $boundary, $new-line, $new-line, $body, $new-line,
                                for $a as element(attachment) in $attachments
                                return (
                                    fn:concat("--",$boundary,$new-line,"Content-Type: ",$a/content-type,$new-line,
                                              "Content-Disposition: attachment; filename=",$a/file-name,$new-line,
                                              if ($a/content/@base64 eq "true") then (
                                                fn:concat("Content-Transfer-Encoding: base64", $new-line)
                                              ) else (),
                                              $new-line, $a/content, $new-line
                                    )
                                ),
                                "--",$boundary,"--", $new-line)
                        ,'')
                    }</em:content>
                </em:Message>
            )
        } catch($exception) {
            if ( fn:not($settings:environment = ("prod", "PROD")) ) then (
                xdmp:rethrow()
            ) else (
               <result>undeliverable</result>
           )
        }
    )
};

declare function util:send-email(
    $to-email as xs:string,
    $to-name as xs:string?,
    $subject as xs:string?,
    $body as item()?,
    $from-email as xs:string,
    $from-name as xs:string?
) as item()* {
    try {
        xdmp:email(
        <em:Message xmlns:em="URN:ietf:params:email-xml:" xmlns:rf="URN:ietf:params:rfc822:">
            <rf:subject>{$subject}</rf:subject>
            <rf:from>
                <em:Address>
                    <em:name>{$from-name}</em:name>
                    <em:adrs>{$from-email}</em:adrs>
                </em:Address>
            </rf:from>
            <rf:to>
                <em:Address>
                    <em:name>{$to-name}</em:name>
                    <em:adrs>{$to-email}</em:adrs>
                </em:Address>
            </rf:to>
            <em:content xml:space="preserve">{$body}</em:content>
        </em:Message>)
    } catch($exception) {
        if ( fn:not($settings:environment = ("prod", "PROD")) ) then (
            xdmp:rethrow()
        ) else (
           <result>undeliverable</result>
       )
    }
};

declare function util:merge(
    $default as element()?,
    $delta as element()?
) as element() {
    let $extended as xs:string* := $delta/*/fn:local-name(.)
    return (
        element {fn:QName(fn:namespace-uri($default), fn:local-name($default))} {
            $default/@*,
            $delta/*,
            $default/* except $default/*[fn:local-name(.) = $extended]
        }
    )
};

declare function util:file-name(
    $file as item()
) as xs:string {
    typeswitch($file)
        case xs:string return functx:substring-after-last($file, "/")
        case text() return functx:substring-after-last($file, "/")
        default return functx:substring-after-last(xdmp:node-uri($file), "/")
};

declare function util:get-file-extension(
    $string as xs:string
) as xs:string? {
    functx:substring-after-last($string, ".")
};

declare function util:clean-db-uri(
    $uri as xs:string
) as xs:string? {
    fn:replace($uri, '[/\\]+', '/')
};

declare function util:escape-for-regex(
    $arg as xs:string?
)  as xs:string {
   fn:replace($arg, '(\.|\[|\]|\\|\||\-|\^|\$|\?|\*|\+|\{|\}|\(|\))','\\$1')
};

declare function util:deprecated(
    $message as xs:string*
) as empty-sequence() {
    if ($settings:environment != "prod") then (
      let $frame as element(error:frame)? :=
           try {
             fn:error((), 'DEP-STACK', 'error')
           } catch ($ex) {
             ($ex/error:stack/error:frame[error:operation])[2]
           }
       let $prev as element(error:frame)? := ($frame/following-sibling::error:frame[fn:not(fn:matches(error:uri, "^/shared/ldse/.*$"))])[1]
       let $msg as xs:string := fn:concat(
            "Deprecated function: ",
            $frame/error:operation,
            " referenced at ",
            $prev/error:uri,
            " line ",
            $prev/error:line
            )
       return (
            xdmp:trace('ldse-deprecated', ($msg, $message))
       )
   ) else ()
};

declare function util:get-root($xml as node()?) as node()? {
    let $root as node()? := fn:root($xml)
    return (
        typeswitch ($root)
        case document-node() return ( $root/* )
        default return ($root)
    )
};

declare function util:clone($node as item()) as item() {
    typeswitch ($node)
    case document-node() return ( document { $node } )
    case element() return ( element {fn:node-name($node)} {$node/@*, $node/node()} )
    case attribute() return ( attribute {fn:node-name($node)} {$node} )
    case comment() return ( comment { $node } )
    case text() return ( text { $node } )
    case map:map return (
        map:map() + $node
    )
    case xs:anyAtomicType return ( $node )
    default return ( $node )
};


declare function util:strip-namespaces($xml as item()*) as item()* {
    util:renamespace($xml, "")
};

declare function util:renamespace($xml as item()*, $ns as xs:string) as item()* {
   for $n as item() in $xml
    return (
        typeswitch ($n)
        case element() return element {fn:QName($ns, fn:local-name($n))} { $n/@*, util:renamespace($n/node(), $ns)}
        default return ( $n )
    )
};

declare function util:build-full-url($host as xs:string, $url as xs:string, $locale as xs:string) as xs:string? {
    let $parts as item()* := util:get-url-parts($url)
    let $url as xs:string :=
        if ($parts/domain != "") then (
            $url
        ) else (
            fn:concat($host, $url)
        )
    return (
        core:build-url($url, $locale, ())
    )
};

declare function util:convert-to-date-time($date as xs:string) as item()* {
    let $dateTime as item()* := if (fn:matches($date, "....-..-..T..:..:..?(\w+)")) then (
                                        xs:dateTime($date)
                                    ) else if (fn:matches($date, '([0-9]{4}-[0-9]{2}-[0-9]{2})(-[0-9]{2}:[0-9]{2})')) then (
                                        xs:dateTime(fn:replace($date,'([0-9]{4}-[0-9]{2}-[0-9]{2})(-[0-9]{2}:[0-9]{2})', '$1T00:00:00$2'))
                                    ) else if (fn:matches($date, "([0-9]{4}-[0-9]{2}-[0-9]{2})")) then (
                                        xs:dateTime(fn:concat($date, "T00:00:00"))
                                    ) else if (fn:matches($date, "../../....")) then (
                                        let $tokens as xs:string* := fn:tokenize($date, "/")
                                        return xs:dateTime(fn:concat($tokens[3], '-', $tokens[1], '-', $tokens[2], 'T00:00:00'))
                                    ) else ("invalid format")
    return $dateTime
};

(:~ Calculates the number of milliseconds from Jan 1st 1970 ~:)
declare function util:date-time-in-milliseconds($dateTime as xs:dateTime) as xs:double {
   util:date-time-in-seconds($dateTime) * 1000
};
(:~ Calculates the number of seconds from Jan 1st 1970 ~:)
declare function util:date-time-in-seconds($dateTime as xs:dateTime) as xs:double {
    xs:double(($dateTime - xs:dateTime('1970-01-01T00:00:00Z')) div xs:dayTimeDuration('PT1S'))
};

(:~ Converts dateTime to UTC dateTime ~:)
declare function util:utc-date-time($dateTime as xs:dateTime) as xs:dateTime {
    fn:adjust-dateTime-to-timezone($dateTime, xs:dayTimeDuration('-PT0H'))
};
(:~
    Returns the epoch time for the given date value. The epoch time is defined
    as "the number of seconds elapsed since midnight Coordinated Universal Time
    (UTC) of January 1, 1970, not counting leap seconds," or sometimes called
    "Unix time."  Date must be of type xs:dateTime so you will have to cast it
    if you just have a date

    @param $date The date time you wish to convert

    @return The epoch time for the specified date
:)

declare function util:epoch-time($date as xs:dateTime?)
as xs:unsignedLong?
{
    fn:round((xs:dateTime($date) - xs:dateTime("1970-01-01T00:00:00-00:00")) div xs:dayTimeDuration('PT1S'))
};

declare function util:map-xml($map as map:map) as element()* {
    util:map-xml(element map {$map}/*, "")
};

declare function util:map-xml($map-node as item(), $parent-name as xs:string) as item()* {
    typeswitch ($map-node)
    case element(jsonb:object) return (
        util:map-xml($map-node/node(), $parent-name)
    )
    case element(jsonb:entry) return (
        let $clean as xs:string := util:clean-element-name($map-node/@key)
        return
        element { $clean } { util:map-xml($map-node/node(), $clean) }
    )
    case element(jsonb:value) return (
        if ( fn:exists($map-node/@xsi:type) ) then (
            fn:data($map-node)
        ) else (
           util:map-xml($map-node/node(), $parent-name)
        )
    )
    case element(jsonb:array) return (
        let $name as xs:string :=
            if ( fn:ends-with($parent-name, 's') ) then (
                fn:substring($parent-name, 0, fn:string-length($parent-name))
            ) else ( $parent-name )
        for $n as element(jsonb:value) in $map-node/jsonb:value
        return (
            element { $name } {
                util:map-xml($n, $name)
            }
        )
    )
   case element(map:value) return (
        if ( fn:exists($map-node/@xsi:type[. != xs:QName("map:map")]) ) then (
            fn:data($map-node)
        ) else (
           util:map-xml($map-node/node(), $parent-name)
        )
    )
    case element (map:array) return (
        let $name as xs:string :=
            if ( fn:ends-with($parent-name, 's') ) then (
                fn:substring($parent-name, 0, fn:string-length($parent-name))
            ) else ( $parent-name )
        for $n as element(map:value) in $map-node/map:value
        return (
            element { $name } {
                util:map-xml($n, $name)
            }
        )
    )
    case element(map:entry) return (
        let $clean as xs:string := util:clean-element-name($map-node/@key)
        return
        if (fn:count($map-node/map:value) > 1) then (
            element { $clean } {
                util:map-xml(<map:array>{$map-node/node()}</map:array>, $clean)
            }
        ) else (
             element { $clean } { util:map-xml($map-node/node(), $clean) }
        )

    )
    case element(map:map) return (
        util:map-xml($map-node/node(), $parent-name)
    )
    default return (
        $map-node
    )
};

declare function util:clean-element-name($name as xs:string) as xs:string {
    fn:replace(fn:replace(fn:replace(fn:lower-case(xdmp:diacritic-less($name)), '[^a-z0-9_]' ,''), '_+', '_'), '^[0-9]+', '')
};

(:  Gets the final substring after final match  :)
declare function util:substring-after-last($arg as xs:string?, $delim as xs:string?) as xs:string {
   fn:replace($arg, fn:concat('^.*',escape-for-regex($delim)),'')
};


declare function util:string-exists($arg as item()*) as xs:boolean {
    fn:exists($arg) and fn:not($arg = "")
};

declare function util:substring-before-last($arg as xs:string?, $delim as xs:string?) as xs:string {
    if (fn:matches($arg, util:escape-for-regex($delim))) then (
        fn:replace($arg, fn:concat('^(.*)', util:escape-for-regex($delim),'.*'),'$1')
    ) else ('')
};

declare function util:get-stakeholder-email($stakeholder as xs:string) as xs:string? {
    let $user as element(ldse:contributor)? :=
        cts:search(/*,
            cts:and-query((
                core:get-filter-query(),
                cts:element-attribute-value-query(xs:QName("ldse:role"), xs:QName("name"), "stakeholder", "exact"),
                cts:element-value-query(xs:QName("ldse:name"), $stakeholder, "exact")
            ))
        )[1]
    for $role as element(ldse:role) in $user/ldse:roles/ldse:role
    where $role/@name = "stakeholder"
    return (
        $role/ldse:email/@email
    )
};

declare function util:get-other-stakeholders($emails as element(ldse:emails)) as xs:string* {
    for $user as element(ldse:email) in $emails/ldse:email
    return (
        $user/@name
    )
};

declare function util:get-stakeholder-emails($ldse-meta as element(ldse:ldse-meta)) as xs:string* {
    let $emails as element(ldse:emails)? := $ldse-meta/ldse:sensitive/ldse:emails
    for $stakeholder as xs:string in ($ldse-meta/ldse:sensitive/@stakeholder, util:get-other-stakeholders($emails))
    return (
        let $user as element(ldse:contributor)? :=
            cts:search(/*,
                cts:and-query((
                    core:get-filter-query(),
                    cts:element-attribute-value-query(xs:QName("ldse:role"), xs:QName("name"), "stakeholder", "exact"),
                    cts:element-value-query(xs:QName("ldse:name"), $stakeholder, "exact")
                ))
            )[1]
        for $role as element(ldse:role) in $user/ldse:roles/ldse:role
        where $role/@name = "stakeholder"
        return (
            $role/ldse:email/@email
        )
    )
};

declare function util:get-translated-words($xmls as item()*) as xs:string* {
    for $xml in $xmls
    return (
        typeswitch ($xml)
            case text() return (
                xs:string($xml)
            )
            case element() return (
                if ( fn:not(fn:local-name($xml) = "ldse:ldse-meta") ) then (
                    if ( fn:not($xml/@its:translate = "no") ) then (
                        util:get-translated-words($xml/node())
                    ) else ()
                ) else ()
            )
        default return ()
    )
};

declare function util:user($user as xs:string) {
    xdmp:user($user)
};

declare function util:quote-paras($root as element(), $paras as element()*, $index) {
    if ( fn:exists($paras) ) then (
        typeswitch($paras[1])
        case element() return (
            let $p as element() := element { fn:QName( 'http://www.w3.org/1999/xhtml', fn:local-name($paras[1])) } { xdmp:quote($paras[1]/node()) }
            let $path as xs:string := $paras[1]/xdmp:path(.)
            let $new-root as element()? := util:value($root, $path)
            let $root as element()? := if ( fn:exists($new-root) ) then ( mem:node-replace($new-root, $p)/* ) else ( $root )
            return (
                util:quote-paras($root, $paras except $paras[1], $index + 1)
            )
        )
        case text() return ( $paras )
        default return ()
    ) else (
        $root
    )
};

declare function util:remove-bad-html-characters($xml as element()) as element() {
    let $map as map:map := map:map()
    let $put as empty-sequence() := map:put($map, "newxml", xdmp:quote($xml))
    let $replacements as empty-sequence() :=
        for $pattern as xs:string in util:generate-bad-html-char-patterns()
        let $newxml as xs:string := map:get($map, "newxml")
        return (
            map:put($map, "newxml", fn:replace($newxml, $pattern, ''))
        )
    return (
        xdmp:unquote(map:get($map, "newxml"))/*
    )
};

declare function util:generate-bad-html-char-patterns() as xs:string* {
    for $i as xs:int in (127 to 159)
    return "&amp;#" || $i || ";"
};

declare function util:string-value(
    $item
) as xs:string {
    typeswitch($item)
    case $item as xs:string return ($item, "")[1]
    case $item as element() return ($item/xs:string(.), "")[1]
    default return ($item/xs:string(.), "")[1]
};

declare function util:boolean-value ($item) as xs:boolean {
    typeswitch($item)
    case $item as xs:boolean return if ($item eq fn:true() ) then fn:true() else fn:false()
    case $item as xs:string return if ($item eq 'true') then fn:true() else fn:false()
    case $item as element() return if ($item/fn:string() eq 'true') then fn:true() else fn:false()
    default return fn:false()
};

declare function util:get-url-with-lang(
    $url as xs:string,
    $params-in as map:map
) as xs:string {
    let $host as xs:string := map:get($params-in, 'host')
    let $suppresslangparam as xs:string? := map:get($params-in, 'suppresslangparam')
    let $lang-hosts as xs:string* := $settings:lang-hosts
    let $need-lang as xs:boolean? :=
            (for $lang-host as xs:string in $lang-hosts
            where fn:contains($url, $lang-host)
            return fn:true())[1]
    let $lang-param as xs:string? :=
        if ($suppresslangparam eq 'true' or contains(lower-case($url), 'missionaryreports.churchofjesuschrist.org')) then
            ()
        else if ($need-lang) then
                if ( fn:contains($url, '?') ) then
                    '&amp;lang=' || map:get($params-in, 'lang')
                else ( '?lang=' || map:get($params-in, 'lang') )
        else ()
    return
        if ( fn:starts-with($url, 'mailto:') ) then
            'mailto:' || fn:substring-after($url, 'mailto:')
        else if ( fn:starts-with($url, '#') ) then
            $url
        else if ( fn:contains($url, '?lang=none') or fn:contains($url, '&amp;lang=none') ) then
            let $data := if ( fn:starts-with($url, 'http') or fn:starts-with($url, '//') or fn:starts-with($url, '/') ) then (
                            fn:replace(fn:replace($url, 'lang=none', ''), '&amp;&amp;', '&amp;')
                          ) else '//' || fn:replace(fn:replace($url, 'lang=none', ''), '&amp;&amp;', '&amp;')
            return if (ends-with($data, '?')) then
                        replace($data, functx:escape-for-regex('?'), '')
                   else if (ends-with($data, '&amp;')) then
                        replace($data, functx:escape-for-regex('&amp;'), '')
                   else $data
        else if ( fn:contains($url, '?lang=') or fn:contains($url, '&amp;lang=') ) then
            if ( fn:starts-with($url, 'http') or fn:starts-with($url, '//') or fn:starts-with($url, '/') ) then
                $url
            else '//' || $url
        else if ( ( fn:starts-with($url, '/') and fn:not(fn:starts-with($url, '//')) ) and $need-lang ) then
            $url || $lang-param
        else if ( fn:starts-with($url, '//') or fn:starts-with($url, 'http') ) then
            $url || $lang-param
        else if ( fn:starts-with($url, '/') ) then
            $url || $lang-param
        else if ( $url = '' ) then
            $url
        else ( '//' || $url || $lang-param )

};

declare function util:get-root-uri(
    $uri as xs:string,
    $rules as element()*,
    $params as xs:int
) as element(rule)* {
    let $rule as element(rule)* := $rules/rule[( @path = $uri and @params = $params ) or ( @path = $uri and $params = 0 )]
    return (
        if ( $rule ) then (
            $rule
        ) else (
            let $new-uri as xs:string? := util:substring-before-last($uri, '/')
            where fn:exists($new-uri) and fn:not($new-uri = '')
            return util:get-root-uri($new-uri, $rules, $params + 1)
        )
    )
};

declare function util:words-to-camel-case(
    $string as xs:string?,
    $delim as xs:string
) as xs:string {
    let $new-string as xs:string := fn:replace($string, $delim, ' ')
    return functx:words-to-camel-case($new-string)
};

(: Deprecated functions :)

declare function util:getContext() as xs:string {
    $DEPRECATED,
    core:get-mode-root()
};


declare function util:getHost() as xs:string? {
    $DEPRECATED,
    $host
};

declare function util:getProtocol() as xs:string? {
    $DEPRECATED,
    $protocol
};

declare function util:getEnv($deprecated-context as xs:string) as xs:string? {
    $DEPRECATED,
    $settings:environment
};

declare function util:directory-query($deprecated-context as xs:string) as cts:query* {
    $DEPRECATED, core:get-filter-query()
};

declare function util:directory-query($deprecated-context as xs:string, $site as xs:string) as cts:query* {
    $DEPRECATED, core:get-filter-query()
};

declare function util:getQueryDirectory($deprecated-context as xs:string?) as xs:string? {
    $DEPRECATED,
    $settings:query-directory
};

declare function util:getLocale($deprecated-context as xs:string) as xs:string? {
    $DEPRECATED,
    $locale
};

declare function util:getSharedPrefix($deprecated-context as xs:string) as xs:string {
    $DEPRECATED,
    $settings:shared-prefix
};

declare function util:getSecurePrefix($deprecated-context as xs:string) as xs:string {
    $DEPRECATED,
    $settings:secure-prefix
};

declare function util:getCdnPath($deprecated-context as xs:string) as xs:string {
    $DEPRECATED,
    $settings:cdn-path
};

declare function util:getBcPath($deprecated-context as xs:string) as xs:string {
    $DEPRECATED,
    $settings:bc-path
};

declare function util:getBcsPath($deprecated-context as xs:string) as xs:string {
    $DEPRECATED,
    $settings:bcs-path
};

declare function util:getDisplayUri($uri as xs:string, $deprecated-context as xs:string, $site as xs:string) as xs:string {
    $DEPRECATED, util:get-display-uri($uri, core:get-mode-root(), $site)
};

declare function util:get-display-uri($uri as xs:string, $deprecated-context as xs:string, $site as xs:string) as xs:string {
    let $relativeUri as xs:string := if (fn:starts-with($uri, "/")) then ( fn:substring-after($uri, "/") ) else ( $uri )
    let $site as xs:string? := if ($site ne '') then ($site) else ($settings:shared-prefix)
    return (
        if (fn:contains($uri, '/bc/')) then (
          (: if it already contains bc, then just use the uri :)
          $uri
        ) else if ($site ne '') then (
           (: if we can identify which site it is, use the site :)
           fn:concat($site,'/bc/', $relativeUri)
        ) else (
           (: if no site, then use the ldsorg bc :)
           fn:concat("/bc/content/", $relativeUri)
        )
    )
};

declare function util:unquote($string as xs:string) as item()* {
    xdmp:unquote(fn:concat("<root>", $string, "</root>"))/root/node()
};

declare function util:get-url-parts($full-url as xs:string) as element(url-parts) {
    let $protocol as xs:string? := fn:replace(fn:substring-before($full-url, '//'), ':', '')
    let $hash as xs:string? :=
        if (fn:matches($full-url, '^[^#]*(#.*)$')) then (
            fn:replace($full-url, '^[^#]*(#.*)$', '$1')
        ) else ()
    let $params as xs:string? :=
        if (fn:matches($full-url, '^[^?#]*(\?[^#]*)(#.*)?$')) then (
          fn:replace($full-url, '^[^?#]*(\?[^#]*)(#.*)?$', '$1')
        ) else ()
    let $domain as xs:string? :=
        if ($protocol != "") then (
            fn:replace($full-url, '^.*//([^/#?]+)[/?#]?.*$', '$1')
        ) else if ( fn:starts-with($full-url, '/') ) then (
            ""
        ) else (
            fn:replace($full-url, '^([^/?#]+).*$', '$1')
        )
    let $cleaned-url as xs:string? :=
        if ($params != "") then (
            fn:substring-before($full-url, '?')
        ) else if ($hash != "") then (
            fn:substring-before($full-url, '#')
        ) else ( $full-url )

    let $uri as xs:string? :=
        if ($domain != '') then (
            fn:substring-after($cleaned-url, $domain)
        ) else (
            $cleaned-url
        )
    let $context as xs:string? := fn:replace($uri, '/([^/]+)[/]?.*', '$1')
    return
      <url-parts url="{$full-url}">
        <protocol>{ $protocol }</protocol>
        <domain>{ $domain[. != $full-url] }</domain>
        <uri>{ $uri }</uri>
        <context>{ $context }</context>
        <params>{ $params }</params>
        <hash>{ $hash }</hash>
      </url-parts>
};

declare function util:clean-url-params(
    $params as xs:string?
) as xs:string? {
    fn:string-join(fn:tokenize($params, "[?&amp;]")[. != ''], '&amp;')[. != '']
};

declare function util:contains($string as xs:string, $vals as xs:string*) as xs:string* {
    for $val as xs:string in $vals
    where fn:contains($string, $val)
    return (
        $val
    )
};

declare function util:number-value(
    $item
) {
    if ($item castable as xs:decimal) then (
        xs:decimal($item)
    ) else (
        null-node {}
    )
};

declare function util:removeNullsTypeCheck(
    $val
) {
    typeswitch($val)
        case $val as jsonb:object return (util:removeNullsFromJSON($val))
        case $val as map:map return (util:removeNullsFromJSON($val))
        case $val as jsonb:array return util:removeNullsFromJSONArray($val)
        case $val as xs:boolean return $val
        case $val as xs:string return $val
        case $val as xs:decimal return $val
        case $val as xs:double return $val
        case $val as xs:float return $val
        case $val as xs:time return $val
        case $val as xs:date return $val
        case $val as xs:dateTime return $val
        case $val as xs:untypedAtomic return xs:string($val)
        case $val as xs:anyAtomicType return xs:string($val)
        default return ()
};

declare function util:removeNullsFromJSON(
    $json as map:map
) as jsonb:object? {
    let $cleanJson := jsonb:object()
    let $keys := map:keys($json)
    let $update :=
        for $k in $keys
        let $val := map:get($json, $k)
        let $updatedVal := util:removeNullsTypeCheck($val)

        return (
            if (fn:exists($updatedVal)) then (
                if ($updatedVal instance of xs:string) then (
                    if (c:stringNotEmpty($updatedVal)) then (
                        map:put($cleanJson, $k, $updatedVal)
                    ) else ()
                ) else (
                    map:put($cleanJson, $k, $updatedVal)
                )
            ) else ()
        )
    return (
        if (fn:exists(map:keys($cleanJson))) then (
            $cleanJson
        ) else ()
    )
};

declare function util:removeNullsFromJSONArray(
    $jsonArray as jsonb:array
) as jsonb:array? {
    let $vals :=
        for $x in jsonb:array-values($jsonArray)
        return
            util:removeNullsTypeCheck($x)
    return (
        if (fn:exists($vals)) then (
            let $cleanArray := jsonb:array()
            let $push :=
                for $v in $vals
                return (
                    jsonb:array-push($cleanArray, $v)
                )
            return (
                $cleanArray
            )
        ) else ()
    )
};
(:~
    Takes the URI and converts it to the appropriate URI to run the displayImage.xqy code.  This new URI shows the image
    that resides in the MarkLogic database.

    @param $uri The URI in the database of the image
    @param $context The execution context (preview or published)
    @return the correct URI to display the image
~:)

declare function util:getDisplayUri($uri as xs:string, $deprecated-context as xs:string) as xs:string {
    $DEPRECATED,
    util:getDisplayUri($uri, $deprecated-context, "")
};

declare function getDisplayUri($uri as xs:string) as xs:string {
    $DEPRECATED,
    util:getDisplayUri($uri, util:getContext(), "")
};

declare function util:sanitizeInput($chars as xs:string?) as xs:string? {
    $DEPRECATED,
    util:sanitize-input($chars)
};

declare function util:cleanFileName($file-name as xs:string) as xs:string {
    $DEPRECATED,
    util:clean-file-name($file-name)
};

declare function util:escapeChars($unescaped as xs:string?) as xs:string? {
    $DEPRECATED,
    util:escape-chars($unescaped)
};

declare function util:sanitizeUri($uri as xs:string) as xs:string {
    $DEPRECATED,
    util:sanitize-uri($uri)
};

declare function util:escapeCharsExceptParens($unescaped as xs:string?) as xs:string? {
    $DEPRECATED,
    util:escape-chars-except-parens($unescaped)
};

declare function util:splitLocaleParam($locale as xs:string) as xs:string {
    $DEPRECATED,
    util:split-locale-param($locale)
};

declare function util:getLangFromLocale($locale as xs:string) as xs:string {
    $DEPRECATED,
    util:get-lang-from-locale($locale)
};

declare function util:getCountryFromLocale($locale as xs:string) as xs:string? {
    $DEPRECATED,
    util:get-country-from-locale($locale)
};

declare function util:getSite($deprecated-context as xs:string?) as xs:string? {
    $DEPRECATED,
    $core:site
};

declare function util:getLdseSettings($deprecated-context as xs:string?) as element(ldse:ldse-settings)? {
    $DEPRECATED,
    $settings:ldse-settings
};

declare function util:document-replace($existing as element()*, $new as element()*) as empty-sequence() {
    $DEPRECATED,
    core:document-replace($existing, $new)
};

declare function util:validLocale($site, $locale){
    let $siteLanguages := library:get-supported-languages-by-site($site)
    let $validLang := for $lang in $siteLanguages/language
                      where $lang/@key/fn:string() eq $locale
                      return $lang
    return fn:exists($validLang)
};

declare function util:validSite($site){
    let $validSite := for $s in cf:get-sub-sites()
                      where $s/name/fn:string() eq $site
                      return $s
    return fn:exists($validSite)
};


declare function util:cleanWsywig (
    $value as xs:string
) as xs:string {
    let $removeTags := fn:replace($value, "<.*?>", "")
    let $removeNewLines := fn:replace($removeTags, "&#10;", "")
    let $removeNBSpaces := fn:replace($removeNewLines, "&#160;", "")
    let $removeSpaces := fn:normalize-space($removeNBSpaces)
    return (
        $removeSpaces
    )
};

declare function get-states-list(
    $country-id as xs:string ) as element(){
         cts:search(/states,
         cts:element-value-query(xs:QName("id"), $country-id, 'exact'))/locations
};

declare function get-countries-list() as item ()* {
    let $path := $ldse-settings/ldse:default-country-list/text()
    let $countries := if (fn:doc($path)) then fn:doc($path)/node() else ()
    return json:transform-from-json($countries)
};