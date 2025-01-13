xquery version "1.0-ml";

import module namespace history = "http://lds.org/code/shared/lds-edit/history/history" at "../../history/history.xqy";

declare option xdmp:mapping "true";

xdmp:set-response-content-type('application/json'),
history:save-comments()