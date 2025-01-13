xquery version "1.0-ml";

module namespace util-functs = "http://lds.org/code/register/util-functs";

declare namespace http = "xdmp:http";

declare function util-functs:http-post(
    $url as xs:string,
    $options as element()
) {
    util-functs:http-post($url, $options, ())
};

declare function util-functs:http-post(
    $url as xs:string,
    $options as element(),
    $data
) {
    xdmp:http-post($url, $options, $data)
};

declare function util-functs:http-get(
    $url as xs:string,
    $options as element()
) {
    xdmp:http-get($url, $options)
};