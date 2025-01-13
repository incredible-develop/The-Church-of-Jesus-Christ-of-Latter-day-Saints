xquery version "1.0-ml";

module namespace func = "http://lds.org/code/shared/lds-edit/function-apply";

(: LDS-EDIT Imports :)
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../modules/ldse-core.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../modules/ldse-settings.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace eval = "xdmp:eval";
declare option xdmp:mapping "true";

declare variable $invokeLocation as xs:string := "invoker.xqy";
declare variable $queryLocation as xs:string := "invoker-query.xqy";

declare function func:invoke-required($target-mode as xs:string) as xs:boolean {
    if ($core:mode = $target-mode) then (
        fn:false()
    ) else (
        fn:true() (: settings:get-mode-database($core:mode) != settings:get-mode-database($target-mode) :)
    )
};

declare function func:target-mode-port($mode as xs:string) as xs:integer? {
    settings:get-mode-port($mode)
};

declare function func:perform-invoke($location as xs:string, $params as map:map, $options as element()?) as item()* {
   xdmp:invoke($location, (xs:QName("params"), $params), $options)  
};

declare function func:perform-spawn($location as xs:string, $params as map:map, $options as element()?) as item()*{
   xdmp:spawn($location, (xs:QName("params"), $params), $options)  
};

(:~
    Wrapper arround xdmp:apply and func:invoke
    @param $fn - function to apply or invoke
    @param $target-mode 
    @p1 - @$p9
    return item()*
~:)

declare function func:apply($fn as xdmp:function, $target-mode as xs:string) as item()* {
    if (func:invoke-required($target-mode)) then (
        func:invoke($fn, $target-mode)
    ) else (
        xdmp:apply($fn)
    )
};

declare function func:apply($fn as xdmp:function, $target-mode as xs:string, $p1 as item()*) as item()* {
    if (func:invoke-required($target-mode)) then (
        func:invoke($fn, $target-mode, $p1)
    ) else (
        xdmp:apply($fn, $p1)
    )
};

declare function func:apply($fn as xdmp:function, $target-mode as xs:string, $p1 as item()*, $p2 as item()*) as item()* {
    if (func:invoke-required($target-mode)) then (
        func:invoke($fn, $target-mode, $p1, $p2)
    ) else (
        xdmp:apply($fn, $p1, $p2)
    )
};

declare function func:apply($fn as xdmp:function, $target-mode as xs:string, $p1 as item()*, $p2 as item()*, $p3 as item()*) as item()* {
    if (func:invoke-required($target-mode)) then (
        func:invoke($fn, $target-mode, $p1, $p2, $p3)
    ) else (
        xdmp:apply($fn, $p1, $p2, $p3)
    )
};

declare function func:apply($fn as xdmp:function, $target-mode as xs:string, $p1 as item()*, $p2 as item()*, $p3 as item()*, $p4 as item()*) as item()* {
    if (func:invoke-required($target-mode)) then (
        func:invoke($fn, $target-mode, $p1, $p2, $p3, $p4)
    ) else (
        xdmp:apply($fn, $p1, $p2, $p3, $p4)
    )
};

declare function func:apply($fn as xdmp:function, $target-mode as xs:string, $p1 as item()*, $p2 as item()*, $p3 as item()*, $p4 as item()*, $p5 as item()*) as item()* {
    if (func:invoke-required($target-mode)) then (
        func:invoke($fn, $target-mode, $p1, $p2, $p3, $p4, $p5)
    ) else (
        xdmp:apply($fn, $p1, $p2, $p3, $p4, $p5)
    )
};

declare function func:apply($fn as xdmp:function, $target-mode as xs:string, $p1 as item()*, $p2 as item()*, $p3 as item()*, $p4 as item()*, $p5 as item()*, $p6 as item()*) as item()* {
    if (func:invoke-required($target-mode)) then (
        func:invoke($fn, $target-mode, $p1, $p2, $p3, $p4, $p5, $p6)
    ) else (
        xdmp:apply($fn, $p1, $p2, $p3, $p4, $p5, $p6)
    )
};

declare function func:apply($fn as xdmp:function, $target-mode as xs:string, $p1 as item()*, $p2 as item()*, $p3 as item()*, $p4 as item()*, $p5 as item()*, $p6 as item()*, $p7 as item()*) as item()* {
    if (func:invoke-required($target-mode)) then (
        func:invoke($fn, $target-mode, $p1, $p2, $p3, $p4, $p5, $p6, $p7)
    ) else (
        xdmp:apply($fn, $p1, $p2, $p3, $p4, $p5, $p6, $p7)
    )
};

declare function func:apply($fn as xdmp:function, $target-mode as xs:string, $p1 as item()*, $p2 as item()*, $p3 as item()*, $p4 as item()*, $p5 as item()*, $p6 as item()*, $p7 as item()*, $p8 as item()*) as item()* {
    if (func:invoke-required($target-mode)) then (
        func:invoke($fn, $target-mode, $p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8)
    ) else (
        xdmp:apply($fn, $p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8)
    )
};

declare function func:apply($fn as xdmp:function, $target-mode as xs:string, $p1 as item()*, $p2 as item()*, $p3 as item()*, $p4 as item()*, $p5 as item()*, $p6 as item()*, $p7 as item()*, $p8 as item()*, $p9 as item()*) as item()* {
    if (func:invoke-required($target-mode)) then (
        func:invoke($fn, $target-mode, $p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9)
    ) else (
        xdmp:apply($fn, $p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9)
    )
};

declare function func:invoke($fn as xdmp:function, $target-mode as xs:string)
as item()* {
    let $params as map:map :=  func:params($fn, $target-mode)
    let $options as element(eval:options) := func:options($params,<options xmlns="xdmp:eval"><isolation>different-transaction</isolation></options>)
    return (
        func:perform-invoke($invokeLocation,$params,$options)
    )
};

declare function func:invoke($fn as xdmp:function, $target-mode as xs:string, $p1 as item()*)
as item()* {
    let $params as map:map :=  func:params($fn, $target-mode, $p1)
    let $options as element(eval:options) := func:options($params,<options xmlns="xdmp:eval"><isolation>different-transaction</isolation></options>)
    return (
        func:perform-invoke($invokeLocation,$params,$options)
    )
};

declare function func:invoke($fn as xdmp:function, $target-mode as xs:string, $p1 as item()*,$p2 as item()*)
as item()* {
    let $params as map:map :=  func:params($fn, $target-mode, $p1, $p2)
    let $options as element(eval:options) := func:options($params,<options xmlns="xdmp:eval"><isolation>different-transaction</isolation></options>)
    return (
        func:perform-invoke($invokeLocation,$params,$options)
    ) 
};

declare function func:invoke($fn as xdmp:function, $target-mode as xs:string, $p1 as item()*,$p2 as item()*,$p3 as item()*)
as item()* {
    let $params as map:map :=  func:params($fn, $target-mode, $p1, $p2, $p3)
    let $options as element(eval:options) := func:options($params,<options xmlns="xdmp:eval"><isolation>different-transaction</isolation></options>)
    return (
        func:perform-invoke($invokeLocation,$params,$options)
    )
};

declare function func:invoke($fn as xdmp:function, $target-mode as xs:string, $p1 as item()*,$p2 as item()*,$p3 as item()*,$p4 as item()*)
as item()* {
    let $params as map:map :=  func:params($fn, $target-mode, $p1, $p2, $p3, $p4)
    let $options as element(eval:options) := func:options($params,<options xmlns="xdmp:eval"><isolation>different-transaction</isolation></options>)
    return (
        func:perform-invoke($invokeLocation,$params,$options)
    )
};

declare function func:invoke($fn as xdmp:function, $target-mode as xs:string, $p1 as item()*,$p2 as item()*,$p3 as item()*,$p4 as item()*,$p5 as item()*)
as item()* {
    let $params as map:map :=  func:params($fn, $target-mode, $p1, $p2, $p3, $p4, $p5)
    let $options as element(eval:options) := func:options($params,<options xmlns="xdmp:eval"><isolation>different-transaction</isolation></options>)
    return (
        func:perform-invoke($invokeLocation,$params,$options)
    )
};

declare function func:invoke($fn as xdmp:function, $target-mode as xs:string, $p1 as item()*,$p2 as item()*,$p3 as item()*,$p4 as item()*,$p5 as item()*,$p6 as item()*)
as item()* {
    let $params as map:map :=  func:params($fn, $target-mode, $p1, $p2, $p3, $p4, $p5, $p6)
    let $options as element(eval:options) := func:options($params,<options xmlns="xdmp:eval"><isolation>different-transaction</isolation></options>)
    return (
        func:perform-invoke($invokeLocation,$params,$options)
    ) 
};

declare function func:invoke($fn as xdmp:function, $target-mode as xs:string, $p1 as item()*,$p2 as item()*,$p3 as item()*,$p4 as item()*,$p5 as item()*,$p6 as item()*,$p7 as item()*)
as item()* {
    let $params as map:map :=  func:params($fn, $target-mode, $p1, $p2, $p3, $p4, $p5, $p6, $p7)
    let $options as element(eval:options) := func:options($params,<options xmlns="xdmp:eval"><isolation>different-transaction</isolation></options>)
    return (
        func:perform-invoke($invokeLocation,$params,$options)
    )
};

declare function func:invoke($fn as xdmp:function, $target-mode as xs:string, $p1 as item()*,$p2 as item()*,$p3 as item()*,$p4 as item()*,$p5 as item()*,$p6 as item()*,$p7 as item()*,$p8 as item()*)
as item()* {
    let $params as map:map :=  func:params($fn, $target-mode, $p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8)
    let $options as element(eval:options) := func:options($params,<options xmlns="xdmp:eval"><isolation>different-transaction</isolation></options>)
    return (
        func:perform-invoke($invokeLocation,$params,$options)
    )
};

declare function func:invoke($fn as xdmp:function, $target-mode as xs:string, $p1 as item()*,$p2 as item()*,$p3 as item()*,$p4 as item()*,$p5 as item()*,$p6 as item()*,$p7 as item()*,$p8 as item()*,$p9 as item()*)
as item()* {
    let $params as map:map :=  func:params($fn, $target-mode, $p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9)
    let $options as element(eval:options) := func:options($params,<options xmlns="xdmp:eval"><isolation>different-transaction</isolation></options>)
    return (
        func:perform-invoke($invokeLocation,$params,$options)
    )
};

(: SPAWN FUNCTIONS :)
declare function func:spawn($fn as xdmp:function, $target-mode as xs:string)
as item()* {
    let $params as map:map :=  func:params($fn, $target-mode)
    let $options as element(eval:options) := func:options($params,())
    return (
        func:perform-spawn($invokeLocation,$params,$options)
    )
};

declare function func:spawn($fn as xdmp:function, $target-mode as xs:string, $p1 as item()*)
as item()* {
    let $params as map:map :=  func:params($fn, $target-mode, $p1)
    let $options as element(eval:options) := func:options($params,())
    return (
        func:perform-spawn($invokeLocation,$params,$options)
    )
};

declare function func:spawn($fn as xdmp:function, $target-mode as xs:string, $p1 as item()*,$p2 as item()*)
as item()* {
    let $params as map:map :=  func:params($fn, $target-mode, $p1, $p2)
    let $options as element(eval:options) := func:options($params,())
    return (
        func:perform-spawn($invokeLocation,$params,$options)
    ) 
};

declare function func:spawn($fn as xdmp:function, $target-mode as xs:string, $p1 as item()*,$p2 as item()*,$p3 as item()*)
as item()* {
    let $params as map:map :=  func:params($fn, $target-mode, $p1, $p2, $p3)
    let $options as element(eval:options) := func:options($params,())
    return (
        func:perform-spawn($invokeLocation,$params,$options)
    )
};

declare function func:spawn($fn as xdmp:function, $target-mode as xs:string, $p1 as item()*,$p2 as item()*,$p3 as item()*,$p4 as item()*)
as item()* {
    let $params as map:map :=  func:params($fn, $target-mode, $p1, $p2, $p3, $p4)
    let $options as element(eval:options) := func:options($params,())
    return (
        func:perform-spawn($invokeLocation,$params,$options)
    )
};

declare function func:spawn($fn as xdmp:function, $target-mode as xs:string, $p1 as item()*,$p2 as item()*,$p3 as item()*,$p4 as item()*,$p5 as item()*)
as item()* {
    let $params as map:map :=  func:params($fn, $target-mode, $p1, $p2, $p3, $p4, $p5)
    let $options as element(eval:options) := func:options($params,())
    return (
        func:perform-spawn($invokeLocation,$params,$options)
    )
};

declare function func:spawn($fn as xdmp:function, $target-mode as xs:string, $p1 as item()*,$p2 as item()*,$p3 as item()*,$p4 as item()*,$p5 as item()*,$p6 as item()*)
as item()* {
    let $params as map:map :=  func:params($fn, $target-mode, $p1, $p2, $p3, $p4, $p5, $p6)
    let $options as element(eval:options) := func:options($params,())
    return (
        func:perform-spawn($invokeLocation,$params,$options)
    ) 
};

declare function func:spawn($fn as xdmp:function, $target-mode as xs:string, $p1 as item()*,$p2 as item()*,$p3 as item()*,$p4 as item()*,$p5 as item()*,$p6 as item()*,$p7 as item()*)
as item()* {
    let $params as map:map :=  func:params($fn, $target-mode, $p1, $p2, $p3, $p4, $p5, $p6, $p7)
    let $options as element(eval:options) := func:options($params,())
    return (
        func:perform-spawn($invokeLocation,$params,$options)
    ) 
};

declare function func:spawn($fn as xdmp:function, $target-mode as xs:string, $p1 as item()*,$p2 as item()*,$p3 as item()*,$p4 as item()*,$p5 as item()*,$p6 as item()*,$p7 as item()*,$p8 as item()*)
as item()* {
    let $params as map:map :=  func:params($fn, $target-mode, $p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8)
    let $options as element(eval:options) := func:options($params,())
    return (
        func:perform-spawn($invokeLocation,$params,$options)
    ) 
};

declare function func:spawn($fn as xdmp:function, $target-mode as xs:string, $p1 as item()*,$p2 as item()*,$p3 as item()*,$p4 as item()*,$p5 as item()*,$p6 as item()*,$p7 as item()*,$p8 as item()*,$p9 as item()*)
as item()* {
    let $params as map:map :=  func:params($fn, $target-mode, $p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9)
    let $options as element(eval:options) := func:options($params,())
    return (
        func:perform-spawn($invokeLocation,$params,$options)
    ) 
};


(: ************************************************
                  HELPER FUNCTIONS
   ************************************************ :)
declare function func:params($fn as xdmp:function, $target-mode as xs:string
) as map:map {
    let $map as map:map := map:map()
    let $puts as item()* := (
                map:put($map, "fn", $fn),
                map:put($map, "mode", $target-mode),
                map:put($map, "port", func:target-mode-port($target-mode)),
                map:put($map, "c", 0)
    )
    return $map
};

declare function func:params($fn as xdmp:function, $target-mode as xs:string, $p1 as item()*
) as map:map {
    let $map as map:map := map:map()
    let $puts as item()* := (
                map:put($map, "fn", $fn),
                map:put($map, "mode", $target-mode),
                map:put($map, "port", func:target-mode-port($target-mode)),
                map:put($map, "c", 1),
                map:put($map, "p1", $p1)
    )
    return $map
};

declare function func:params($fn as xdmp:function, $target-mode as xs:string, $p1 as item()*,$p2 as item()*
) as map:map {
    let $map as map:map := map:map()
    let $puts as item()* := (
                map:put($map, "fn", $fn),
                map:put($map, "mode", $target-mode),
                map:put($map, "port", func:target-mode-port($target-mode)),
                map:put($map, "c", 2),
                map:put($map, "p1", $p1),
                map:put($map, "p2", $p2)
    )
    return $map
};

declare function func:params($fn as xdmp:function, $target-mode as xs:string, $p1 as item()*,$p2 as item()*,$p3 as item()*
) as map:map {
    let $map as map:map := map:map()
    let $puts as item()* := (
                map:put($map, "fn", $fn),
                map:put($map, "mode", $target-mode),
                map:put($map, "port", func:target-mode-port($target-mode)),
                map:put($map, "c", 3),
                map:put($map, "p1", $p1),
                map:put($map, "p2", $p2),
                map:put($map, "p3", $p3)
    )
    return $map
};

declare function func:params($fn as xdmp:function, $target-mode as xs:string, $p1 as item()*,$p2 as item()*,$p3 as item()*,$p4 as item()*
) as map:map {
    let $map as map:map := map:map()
    let $puts as item()* := (
                map:put($map, "fn", $fn),
                map:put($map, "mode", $target-mode),
                map:put($map, "port", func:target-mode-port($target-mode)),
                map:put($map, "c", 4),
                map:put($map, "p1", $p1),
                map:put($map, "p2", $p2),
                map:put($map, "p3", $p3),
                map:put($map, "p4", $p4)
    )
    return $map
};

declare function func:params($fn as xdmp:function, $target-mode as xs:string, $p1 as item()*,$p2 as item()*,$p3 as item()*,$p4 as item()*,$p5 as item()*
) as map:map {
    let $map as map:map := map:map()
    let $puts as item()* := (
                map:put($map, "fn", $fn),
                map:put($map, "mode", $target-mode),
                map:put($map, "port", func:target-mode-port($target-mode)),
                map:put($map, "c", 5),
                map:put($map, "p1", $p1),
                map:put($map, "p2", $p2),
                map:put($map, "p3", $p3),
                map:put($map, "p4", $p4),
                map:put($map, "p5", $p5)
    )
    return $map
};

declare function func:params($fn as xdmp:function, $target-mode as xs:string, $p1 as item()*,$p2 as item()*,$p3 as item()*,$p4 as item()*,$p5 as item()*,$p6 as item()*
) as map:map {
    let $map as map:map := map:map()
    let $puts as item()* := (
                map:put($map, "fn", $fn),
                map:put($map, "mode", $target-mode),
                map:put($map, "port", func:target-mode-port($target-mode)),
                map:put($map, "c", 6),
                map:put($map, "p1", $p1),
                map:put($map, "p2", $p2),
                map:put($map, "p3", $p3),
                map:put($map, "p4", $p4),
                map:put($map, "p5", $p5),
                map:put($map, "p6", $p6)
    )
    return $map
};

declare function func:params($fn as xdmp:function, $target-mode as xs:string, $p1 as item()*,$p2 as item()*,$p3 as item()*,$p4 as item()*,$p5 as item()*,$p6 as item()*,$p7 as item()*
) as map:map {
    let $map as map:map := map:map()
    let $puts as item()* := (
                map:put($map, "fn", $fn),
                map:put($map, "mode", $target-mode),
                map:put($map, "port", func:target-mode-port($target-mode)),
                map:put($map, "c", 7),
                map:put($map, "p1", $p1),
                map:put($map, "p2", $p2),
                map:put($map, "p3", $p3),
                map:put($map, "p4", $p4),
                map:put($map, "p5", $p5),
                map:put($map, "p6", $p6),
                map:put($map, "p7", $p7)
    )
    return $map
};

declare function func:params($fn as xdmp:function, $target-mode as xs:string, $p1 as item()*,$p2 as item()*,$p3 as item()*,$p4 as item()*,$p5 as item()*,$p6 as item()*,$p7 as item()*,$p8 as item()*
) as map:map {
    let $map as map:map := map:map()
    let $puts as item()* := (
                map:put($map, "fn", $fn),
                map:put($map, "mode", $target-mode),
                map:put($map, "port", func:target-mode-port($target-mode)),
                map:put($map, "c", 8),
                map:put($map, "p1", $p1),
                map:put($map, "p2", $p2),
                map:put($map, "p3", $p3),
                map:put($map, "p4", $p4),
                map:put($map, "p5", $p5),
                map:put($map, "p6", $p6),
                map:put($map, "p7", $p7),
                map:put($map, "p8", $p8)
    )
    return $map
};

declare function func:params($fn as xdmp:function, $target-mode as xs:string, $p1 as item()*,$p2 as item()*,$p3 as item()*,$p4 as item()*,$p5 as item()*,$p6 as item()*,$p7 as item()*,$p8 as item()*,$p9 as item()*
) as map:map {
    let $map as map:map := map:map()
    let $puts as item()* := (
                map:put($map, "fn", $fn),
                map:put($map, "mode", $target-mode),
                map:put($map, "port", func:target-mode-port($target-mode)),
                map:put($map, "c", 9),
                map:put($map, "p1", $p1),
                map:put($map, "p2", $p2),
                map:put($map, "p3", $p3),
                map:put($map, "p4", $p4),
                map:put($map, "p5", $p5),
                map:put($map, "p6", $p6),
                map:put($map, "p7", $p7),
                map:put($map, "p8", $p8),
                map:put($map, "p9", $p9)
    )
    return $map
};

declare function func:options($params as map:map, $custom-options as element(eval:options)?) as element() {
    <options xmlns="xdmp:eval">{ 
            if ( fn:empty($custom-options/eval:database) ) then (
                <database>{ xdmp:database(settings:get-mode-database(map:get($params,'mode'))) }</database>
            ) else (),
            $custom-options/*
    }</options>  
};

declare function func:spawn-with-custom-options(
    $fn as xdmp:function,
    $target-mode as xs:string,
    $options as element(eval:options)?,
    $p1 as item()*,
    $p2 as item()*,
    $p3 as item()*
) as item()* {
    let $params as map:map := func:params($fn, $target-mode, $p1, $p2, $p3)
    let $options as element(eval:options) := func:options($params, $options)
    return (
        func:perform-spawn($invokeLocation, $params, $options)
    )
};
