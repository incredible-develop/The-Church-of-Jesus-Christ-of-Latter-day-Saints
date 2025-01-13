xquery version "1.0-ml";

import module namespace pretty = "http://lds.org/code/shared/common/pretty-print" at "/shared/common/util/pretty-print.xqy";

import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../../modules/utility-functions.xqy";
import module namespace ldsemeta = "http://lds.org/code/shared/lds-edit/meta-functions" at "../../../modules/ldse-meta.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../../modules/access-control-functions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../../modules/ldse-settings.xqy";

declare boundary-space preserve;
declare option xdmp:mapping "true";

declare variable $lang as xs:string := util:escape-chars(xdmp:get-request-field("lang", "eng"));
declare variable $country as xs:string? := util:escape-chars(xdmp:get-request-field("country", ""));
declare variable $pre-locale as xs:string := if ($country ne '') then (fn:concat($lang, '-', $country)) else ($lang);

declare variable $id as xs:string? := util:escape-chars(xdmp:get-request-field("id", ""));
declare variable $locale as xs:string := util:escape-chars(xdmp:get-request-field("locale", $pre-locale));

declare variable $file as element() := ldsemeta:get-file-by($id, $locale, (), ())[1];

    if (ac:has-permission('ldse:view-xml', $locale, '')) then (
        xdmp:set-response-content-type( "text/html" ),
        <div class="view-xml" style="height: 420px; width: 900px; overflow:auto;">
            <link rel="stylesheet" type="text/css" media="all" href="{$settings:shared-prefix}/ice/resources/styles/screen.css" />
            <style type="text/css">
                .element {{ color:#000096 }}
                .attr {{ color:#F5844C;
                         margin-left: 5px;
                         display: inline-block;
                 }}
                .attr .value {{ color:#993300}}
                .attr .namespace {{ color:#0099CC }}
                .comment {{ color:darkgreen }}
                .element-wrapper {{ margin-left: 10px;}}
                .highlight {{ background-color: rgb(255,255,0) }}
            </style>
            <span class="location">Location: {xdmp:node-uri($file)}</span>
            <div style="width: 2000px;">{
                pretty:print($file)
            }</div>
        </div>
    ) else ()
