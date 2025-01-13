xquery version "1.0-ml";

import module namespace tf = 'http://lds.org/code/modules/titan-functions' at '../../modules/titan-functions.xqy';

(:declare variable $term as xs:string := xdmp:get-request-field('term');
declare variable $page as xs:int? := xs:int(xdmp:get-request-field('page', '1'));
declare variable $selected as xs:int? := xs:int(xdmp:get-request-field('selected', '1'));
declare variable $type as xs:string? := xdmp:get-request-field('type');
declare variable $rows as xs:int := xs:int(xdmp:get-request-field('rows', '20'));:)
declare variable $path as xs:string? := xdmp:get-request-field('path');

tf:get-children-results($path)