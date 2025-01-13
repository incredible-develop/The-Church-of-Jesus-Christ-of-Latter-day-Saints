xquery version "1.0-ml";

import module namespace resource = "http://lds.org/code/shared/lds-edit/fast-i18n" at "../modules/fast-i18n.xqy";

(:declare variable $hidden-resources as map:map? := resource:get-hidden-resources();:)
declare variable $locale as xs:string := ( xdmp:get-request-field('locale'), 'eng' )[1];
declare variable $key as xs:string := xdmp:get-request-field('key');

resource:get-string-ice-json($locale, $key)