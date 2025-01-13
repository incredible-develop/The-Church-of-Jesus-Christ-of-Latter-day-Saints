xquery version "1.0-ml";

import module namespace ff = "http://lds.org/code/shared/lds-edit/file-functions" at "../modules/file-functions.xqy";

declare variable $directory as xs:string := xdmp:get-request-field('directory');

ff:delete-content($directory)
