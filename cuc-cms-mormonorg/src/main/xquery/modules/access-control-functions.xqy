xquery version "1.0-ml";

module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions";

import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "/modules/ldse-core.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "/modules/utility-functions.xqy";
import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "/modules/ldse-settings.xqy";
import module namespace ice = "http://lds.org/code/shared/lds-edit/iceFunction" at "/ice/modules/iceFunctions.xqy";
import module namespace library = "http://lds.org/code/shared/lds-edit/supported-languages" at "/supported-languages/modules/library.xqy";
import module namespace sp = "http://lds.org/code/modules/site-properties" at '/modules/site-properties.xqy';
import module namespace cf = "http://lds.org/code/lds-edit/content-admin/content-functions" at "/content-admin/modules/content-functions.xqy";
import module namespace security = "http://lds.org/code/shared/common/security/security-functions" at "/shared/common/security/securityFunctions.xqy";
import module namespace enc = "http://lds.org/code/shared/common/obfuscation/obfuscate-functions" at "/shared/common/obfuscation/obfuscateFunctions.xqy";
import module namespace okta = 'http://lds.org/code/cms/modules/okta-library' at "/modules/okta-library.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";

declare option xdmp:mapping "true";

declare variable $locale-key as xs:string := 'LoCaLeS';
declare variable $server-key as xs:string := 'ldse:user-permissions';
declare variable $users-map as map:map := util:get-server-field($server-key, map:map());
declare variable $user-permission-map as map:map := if (fn:exists($contributor)) then (ac:get-permission-map()) else (map:map());
declare variable $user-locale-map as map:map? := map:get($user-permission-map, $locale-key);
declare variable $user-role-map as map:map? := ac:build-role-map();
declare variable $request-map as map:map := map:map();
declare variable $contributor as element(ldse:contributor)? := core:get-contributor();
declare variable $ROLES as element(ldse:roles) := core:get-ldse-roles();
declare variable $no-users-exist as xs:boolean := fn:not(ac:users-exist());
declare variable $host as xs:string := fn:lower-case(xdmp:get-request-header("host"));
declare variable $isDevOpCMS as xs:boolean :=
    if (starts-with($host, 'cuc-') or
        starts-with($host, 'msadm-') or
        starts-with($host, 'localhost') ) then
           fn:true()
    else fn:false();
declare variable $MWUser as xs:string? := if ($isDevOpCMS) then 'ngiwb1' else ();

declare function ac:is-user() as xs:boolean {
    core:is-ldse-enabled() and
        (
            fn:exists($contributor)
            or
            $no-users-exist
        )
};

declare private function ac:get-permission-map() as map:map {
    let $db-uri as xs:string? := $contributor/xdmp:node-uri(.)
    let $user-name as xs:string := $contributor/ldse:name
    let $time-key as xs:string := fn:concat($user-name, "-timestamp")
    let $current-timestamp as xs:dateTime? := map:get($users-map, $time-key)
    let $current-map as map:map? := map:get($users-map, $user-name)
    let $user-timestamp as xs:dateTime? :=
        if ( $db-uri != "" ) then (
            xdmp:document-get-properties($db-uri, xs:QName("prop:last-modified"))/xs:dateTime(.)
        ) else ()
    let $roles-db-uri as xs:string? := xdmp:node-uri($ROLES)
    let $roles-timestamp as xs:dateTime? :=
        if (fn:exists($roles-db-uri)) then (
            xdmp:document-get-properties($roles-db-uri, xs:QName("prop:last-modified"))/xs:dateTime(.)
        ) else ()
    let $db-timestamp as xs:dateTime? :=
        if (fn:exists($user-timestamp) and fn:exists($roles-db-uri) and $roles-timestamp > $user-timestamp) then (
            $roles-timestamp
        ) else ( $user-timestamp )
    return (
        if ($current-timestamp = $db-timestamp and fn:exists($current-map) and fn:not($settings:is-local)) then (
            $current-map
        ) else (
            let $new-map as map:map := ac:build-permission-map()
            let $update as item()* :=
                if ( fn:exists($db-uri) ) then (
                    let $_ as item()* := ( map:put($users-map, $time-key, $db-timestamp), map:put($users-map, $user-name, $new-map) )
                    return ( util:set-server-field($server-key, $users-map) )
                ) else ()
            return (
                $new-map
            )
        )
    )
};

declare private function ac:build-permission-map() as map:map {
    let $map as map:map := map:map()
    let $_ as empty-sequence() :=
        for $contributor-role as element(ldse:role) in $contributor/ldse:roles/ldse:role[@name ne ""]
        let $role-name as xs:string := $contributor-role/@name
        let $role as element(ldse:role)* := $ROLES/ldse:role[@name = $role-name]
        let $require as element(ldse:require)* := $role/ldse:require
        let $permissions as xs:string* := ac:get-role-permissions($role-name, ())
        let $flatten-roles as xs:string* :=
            if ( fn:exists($require) ) then (
                for $access as element(ldse:access) in $contributor-role/ldse:access
                return (
                    ac:flatten-permission($role-name, $access, $require)
                )
            ) else (
                ac:flatten-permission($role-name, (), ())
            )
        order by fn:count($require) ascending, $require[1] ascending (: make sure global roles are first :)
        return (
            for $permission as xs:string in $permissions
            let $previous-flattened as xs:string* := map:get($map, $permission)
            let $not-global as xs:boolean := fn:not(ac:global-permission($previous-flattened[1]))
            let $flatten-permissions as xs:string* :=
                if ( $not-global ) then (
                    if ( fn:exists($require) ) then (
                        for $access as element(ldse:access) in $contributor-role/ldse:access
                        return (
                            ac:flatten-permission($permission, $access, $require)
                        )
                    ) else (
                        ac:flatten-permission($permission, (), ())
                    )
                ) else ()
            where $not-global
            return (
                map:put($map, $permission, ($previous-flattened, $flatten-permissions))
            )
        )
    let $_ as empty-sequence() := ac:build-locale-map($map)
    return (
        $map
    )
};

declare private function ac:build-role-map() as map:map {
    let $map as map:map := map:map()
    let $_ as empty-sequence() :=
        for $contributor-role as element(ldse:role) in $contributor/ldse:roles/ldse:role[@name ne ""]
        let $role-name as xs:string? := $contributor-role/@name
        let $role as element(ldse:role)* := $ROLES/ldse:role[@name = $role-name]
        let $require as element(ldse:require)* := $role/ldse:require
        let $inherited-roles as element(ldse:role)* := ac:get-inherited-roles($role, ())
        order by fn:count($require) ascending, $require[1] ascending (: make sure global roles are first :)
        return (
             for $r as element(ldse:role) in ($role, $inherited-roles)
             let $name as xs:string := $r/@name
             let $previous-flats as xs:string* := map:get($map, $name)
             let $flatten-roles as xs:string* :=
                if ( fn:exists($require) ) then (
                    for $access as element(ldse:access) in $contributor-role/ldse:access
                    return (
                        ac:flatten-role($name, $access, $require)
                    )
                ) else (
                    ac:flatten-role($name, (), ())
                )
             return (
                map:put($map, $name, ($previous-flats, $flatten-roles))
             )
        )
    return (
        $map
    )
};

declare private function ac:get-inherited-roles($role as element(ldse:role)*, $found-roles as element(ldse:role)*) as element(ldse:role)*{
    let $inherit-roles as element(ldse:role)* := $ROLES/ldse:role[@name = $role/ldse:inherit] except $found-roles
    return (
        if ( fn:exists($inherit-roles) ) then (
            ac:get-inherited-roles($inherit-roles, ($found-roles, $inherit-roles))
        ) else (
            $found-roles
        )
    )
};

declare private function ac:build-locale-map($user-map as map:map) as empty-sequence() {
    let $locale-map as map:map := map:map()
    let $_ as empty-sequence() :=
        for $contributor-role as element(ldse:role) in $contributor/ldse:roles/ldse:role[@name ne ""]
        let $role-name as xs:string := $contributor-role/@name
        let $role as element(ldse:role)* := $ROLES/ldse:role[@name = $role-name]
        let $is-global as xs:boolean := fn:empty( $role/ldse:require[. = "locale"] )
        return (
            for $permission as xs:string in ac:get-role-permissions($role-name, ())
            let $known-locales as xs:string* := map:get($locale-map, $permission)
            let $locales as xs:string* :=
                if ($is-global or $contributor-role/ldse:access/@locale = "ALL" or $known-locales = "ALL") then (
                    "ALL"
                ) else (
                    fn:distinct-values(($contributor-role/ldse:access/@locale, $known-locales))
                )
            return (
                map:put($locale-map, $permission, $locales)
            )
        )
    return (
        map:put($user-map, $locale-key, $locale-map)
    )
};


declare private function ac:get-role-permissions( $role-names as xs:string*, $loaded-roles as xs:string*) as xs:string* {
    let $names as xs:string* :=
        for $name as xs:string in $role-names
        where fn:not($name eq $loaded-roles)
        return $name
    let $role as element(ldse:role)* := $ac:ROLES/ldse:role[@name = $names]
    where fn:exists($role)
    return (
        fn:distinct-values((
            $role/ldse:permission,
            ac:get-role-permissions( $role/ldse:inherit, ($names, $loaded-roles))
        ))
    )
};

declare private function ac:flatten-permission(
    $permission as xs:string,
    $access as element(ldse:access)?,
    $require as element(ldse:require)*
) as xs:string {
    fn:string-join((
        'p[', $permission, ']',
        if ($require eq "uri") then (
           's[', $access/@section, ']',
           'u[', $access/@page, ']',
           'si[', $access/@site, ']'
        ) else (),
        if ($require eq "locale") then (
           'l[', $access/@locale, ']',
           'si[', $access/@site, ']'
        ) else ()
    ), '')
};

declare private function ac:flatten-role(
    $role as xs:string,
    $access as element(ldse:access)?,
    $require as element(ldse:require)*
) as xs:string {
    fn:string-join((
        'r[', $role, ']',
        if ($require eq "uri") then (
           's[', $access/@section, ']',
           'u[', $access/@page, ']',
           'si[', $access/@site, ']'
        ) else (),
        if ($require eq "locale") then (
           'l[', $access/@locale, ']',
           'si[', $access/@site, ']'
        ) else ()
    ), '')
};

declare private function ac:get-r(
    $flatten-permission as xs:string
) as xs:string? {
    fn:replace($flatten-permission, "^.*r\[([^\]]+)\].*$", "$1")[. ne $flatten-permission]
};

declare private function ac:get-p(
    $flatten-permission as xs:string
) as xs:string? {
    fn:replace($flatten-permission, "^.*p\[([^\]]+)\].*$", "$1")[. ne $flatten-permission]
};

declare private function ac:get-s(
    $flatten-permission as xs:string
) as xs:string? {
    fn:replace($flatten-permission, "^.*s\[([^\]]+)\].*$", "$1")[. ne $flatten-permission]
};

declare private function ac:get-si(
    $flatten-permission as xs:string
) as xs:string? {
    fn:replace($flatten-permission, "^.*si\[([^\]]+)\].*$", "$1")[. ne $flatten-permission]
};

declare private function ac:get-u(
    $flatten-permission as xs:string
) as xs:string? {
    fn:replace($flatten-permission, "^.*u\[([^\]]+)\].*$", "$1")[. ne $flatten-permission]
};

declare private function ac:get-l(
    $flatten-permission as xs:string
) as xs:string? {
    fn:replace($flatten-permission, "^.*l\[([^\]]+)\].*$", "$1")[. ne $flatten-permission]
};

declare private function ac:check-role(
    $role as xs:string,
    $flatten-role as xs:string
) as xs:boolean {
  fn:matches($flatten-role, fn:concat("^.*r\[", util:escape-for-regex($role) ,"\].*$"))
};

declare private function ac:global-permission(
    $flatten-permission as xs:string
) as xs:boolean {
    fn:matches($flatten-permission, "^p\[[^\]]+\]$")
};

declare private function ac:check-permission(
    $permission as xs:string,
    $flatten-permission as xs:string
) as xs:boolean {
  fn:matches($flatten-permission, fn:concat("^.*p\[", util:escape-for-regex($permission) ,"\].*$"))
};

declare private function ac:check-section(
    $uri as xs:string?,
    $flatten-permission as xs:string
) as xs:boolean {
    let $section as xs:string? := ac:get-s($flatten-permission)
    return (
        $uri = "" or
        ($section != "" and
        fn:matches($uri, fn:concat("^", util:escape-for-regex($section), ".*$")))
    )
};

declare private function ac:check-uri(
    $uri as xs:string?,
    $flatten-permission as xs:string
) as xs:boolean {
    $uri = "" or
    fn:matches($flatten-permission, fn:concat("^.*u\[", util:escape-for-regex($uri) ,"\].*$")) or
    fn:not( fn:matches($flatten-permission, "^.*u\[.+\].*$") )
};

declare private function ac:check-locale(
    $locale as xs:string?,
    $flatten-permission as xs:string
) as xs:boolean {
    $locale = "" or
    fn:matches($flatten-permission, fn:concat("^.*l\[", util:escape-for-regex($locale) ,"\].*$")) or
    ac:get-l($flatten-permission) = "ALL" or
    fn:not( fn:matches($flatten-permission, "^.*l\[[^\]]+\].*$") )
};

declare private function ac:check-site(
    $site as xs:string?,
    $flatten-permission as xs:string
) as xs:boolean {
    $site = "" or
    fn:matches($flatten-permission, fn:concat("^.*si\[", util:escape-for-regex($site) ,"\].*$")) or
    ac:get-si($flatten-permission) = "ALL" or
    fn:not( fn:matches($flatten-permission, "^.*si\[[^\]]+\].*$") )
};

declare private function ac:is-match(
    $permission as xs:string,
    $locale as xs:string?,
    $uri as xs:string?,
    $site as xs:string?,
    $flatten-permission as xs:string
) as xs:boolean {
    (
        ac:check-uri($uri, $flatten-permission) or
        ac:check-section($uri, $flatten-permission)
    ) and
    ac:check-site($site, $flatten-permission) and
    ac:check-locale($locale, $flatten-permission) and
    ac:check-permission($permission, $flatten-permission)
};

declare private function ac:is-role-match(
    $role as xs:string,
    $locale as xs:string?,
    $uri as xs:string?,
    $site as xs:string?,
    $flatten-role as xs:string
) as xs:boolean {
    (
        ac:check-uri($uri, $flatten-role) or
        ac:check-section($uri, $flatten-role)
    ) and
    ac:check-site($site, $flatten-role) and
    ac:check-locale($locale, $flatten-role) and
    ac:check-role($role, $flatten-role)
};

declare function ac:has-all-permissions(
    $permissions as xs:string+,
    $locale as xs:string?,
    $uri as xs:string?
) as xs:boolean {
    every $permission in $permissions satisfies has-permission($permission, $locale, $uri)
};

declare function ac:has-any-permissions(
    $permissions as xs:string+,
    $locale as xs:string?,
    $uri as xs:string?
) as xs:boolean {
    some $permission in $permissions satisfies has-permission($permission, $locale, $uri)
};

declare function ac:has-permission(
    $permission as xs:string,
    $locale as xs:string?,
    $uri as xs:string?
) as xs:boolean {
    ac:has-permission($permission, $locale, $uri, ())
};

declare function ac:has-permission(
    $permission as xs:string,
    $locale as xs:string?,
    $uri as xs:string?,
    $site as xs:string?
) as xs:boolean {
    if ($no-users-exist and $permission = 'ldse:grant-permissions') then (
        fn:true()
    ) else (
        let $locale as xs:string := ($locale, "")[1]
        let $uri as xs:string := ($uri, "")[1]
        let $site as xs:string := ($site, "")[1]
        let $key as xs:string := fn:concat("has-permission-", $permission, $locale, $uri, $site)
        let $value as xs:boolean? := map:get($request-map, $key)
        return (
            if ( fn:exists( $value ) ) then (
                $value
            ) else (
                let $value as xs:boolean := some $flatten-permission in map:get($user-permission-map, $permission) satisfies ac:is-match($permission, $locale, $uri, $site, $flatten-permission)
                return (
                    map:put($request-map, $key, $value),
                    $value
                )
            )
        )
    )
};

declare function ac:is-action-allowed(
    $action as xs:string,
    $locale as xs:string?,
    $uri as xs:string?
) as xs:boolean {
	let $permissions as xs:string* := settings:get-action-permission($action)
	return (
		if ( fn:exists($permissions) )
		then some $permission as xs:string in $permissions satisfies ac:has-permission($permission, $locale, $uri)
		else fn:true()
	)
};

declare function ac:is-action-allowed(
    $action as xs:string,
    $locale as xs:string?,
    $uri as xs:string?,
    $map as map:map?
) as xs:boolean {
	let $action-element as element(ldse:action)? := settings:get-action($action)
	return (
	    if ( fn:exists($action-element/ldse:checks/*) ) then (
	       ice:validate-checks(<ldse:and>{$action-element/ldse:checks/*}</ldse:and>, $map)
	    ) else fn:true()
    )
};

declare function ac:has-all-role(
    $roles as xs:string+,
    $locale as xs:string?,
    $uri as xs:string?,
    $site as xs:string?
) as xs:boolean {
    every $role in $roles satisfies has-role($role, $locale, $uri, $site)
};

declare function ac:has-any-role(
    $roles as xs:string+,
    $locale as xs:string?,
    $uri as xs:string?,
    $site as xs:string?
) as xs:boolean {
    some $role in $roles satisfies has-role($role, $locale, $uri, $site)
};

declare function ac:has-role(
    $role as xs:string,
    $locale as xs:string?,
    $uri as xs:string?
) as xs:boolean {
    ac:has-role($role, $locale, $uri, ())
};

declare function ac:has-role(
    $role as xs:string,
    $locale as xs:string?,
    $uri as xs:string?,
    $site as xs:string?
) as xs:boolean {
    let $key as xs:string := fn:concat("has-role-", $role, $locale, $uri, $site)
    let $value as xs:boolean? := map:get($request-map, $key)
    return (
        if ( fn:exists( $value ) ) then (
            $value
        ) else (
            let $value as xs:boolean := some $flatten-role in map:get($user-role-map, $role) satisfies ac:is-role-match($role, $locale, $uri, $site, $flatten-role)
            return (
                map:put($request-map, $key, $value),
                $value
            )
        )
    )
};

declare function ac:query-permission(
    $role-name as xs:string+
) as cts:query* {
    ac:query-permission($role-name, xs:QName('ldse:document'), xs:QName('locale'), xs:QName('ldse:document'), xs:QName('uri'))
};

declare function ac:query-permission(
    $permissions as xs:string+,
    $locale-element as xs:QName,
    $locale-attribute as xs:QName?,
    $uri-element as xs:QName,
    $uri-attribute as xs:QName?
) as cts:query* {
    let $key as xs:string := fn:concat('query-permission-', fn:string-join($permissions,','))
    let $query as cts:query* := map:get($request-map, $key)
    return (
        if ( fn:exists($query) ) then (
            $query
        ) else (
            let $query as cts:query* :=
                if ( some $permission in $permissions satisfies ac:global-permission(map:get($user-permission-map, $permission)[1]) ) then (
                    (: if one is global we don't need to continue :)
                    cts:and-query( () )
                ) else (
                    cts:or-query((
                        for $permission as xs:string in $permissions
                        return (
                            cts:or-query((
                                for $flatten-permission as xs:string in map:get($user-permission-map, $permission)
                                return ( query-flatten-permission($flatten-permission, $locale-element, $locale-attribute, $uri-element, $uri-attribute) )
                            ))
                        )
                    ))
                )
            return (
                $query,
                map:put($request-map, $key, $query)
            )
        )
    )
};

declare private function ac:query-flatten-permission(
    $flatten-permission as xs:string+,
    $locale-element as xs:QName,
    $locale-attribute as xs:QName?,
    $uri-element as xs:QName,
    $uri-attribute as xs:QName?
) as cts:query* {
    let $section as xs:string? := ac:get-s($flatten-permission)
    let $uri as xs:string? := ac:get-u($flatten-permission)
    let $locale as xs:string? := ac:get-l($flatten-permission)
    let $section-query as cts:query? :=
        if ( fn:exists($section) ) then (
            cts:and-query((
                ac:build-query($uri-element, $uri-attribute, $section, '>='),
                if ($section ne '/') then ( ac:build-query($uri-element, $uri-attribute, fn:concat($section, "~"), '<') ) else ()
            ))
        ) else ()
    let $uri-query as cts:query? :=
        if ( fn:exists($uri) ) then (
            build-query($uri-element, $uri-attribute, $uri, '=')
        ) else ()
    let $section-or-uri-query as cts:query? :=
        if ( fn:exists($section-query) and fn:exists($uri-query) ) then (
            cts:or-query(( $section-query, $uri-query ))
        ) else ( $section-query, $uri-query )
    let $locale-query as cts:query? :=
        if ( fn:exists($locale) and $locale != "ALL" ) then (
            build-query($locale-element, $locale-attribute, $locale, '=')
        ) else if ($locale = "ALL") then (
             cts:and-query(())
        ) else ()
    return (
        if ( fn:exists($locale-query) and fn:exists($section-or-uri-query) ) then (
            cts:and-query(($locale-query, $section-or-uri-query))
        ) else (
            $locale-query, $section-or-uri-query
        )
    )
};

declare private function ac:build-query(
    $element as xs:QName,
    $attribute as xs:QName?,
    $value as xs:string+,
    $operator as xs:string
) as cts:query {
    if (fn:exists($attribute)) then (
        cts:element-attribute-range-query($element, $attribute, $operator, $value, "collation=http://marklogic.com/collation/")
    ) else (
        cts:element-range-query($element, $operator, $value, "collation=http://marklogic.com/collation/")
    )
};

(: Returns all the locales you have access to :)
declare function ac:locales() as xs:string* {
    fn:distinct-values(
        for $permission as xs:string in map:keys($user-locale-map)
        return (
            ac:locales-by-permission($permission)
        )
    )
};

(: Returns all locales you the permission for :)
declare function ac:locales-by-permission(
    $permission as xs:string
) as xs:string* {
    let $locales as xs:string* := map:get($user-locale-map, $permission)
    return (
        if ( $locales = "ALL" ) then (
            core:get-all-locales()
        ) else ( $locales )
    )
};

declare function ac:flexible-field-locales(
) as xs:string* {
    distinct-values(
        for $i in ac:site-locales-by-permission("ldse:publish-doc")
        let $locale := substring-after($i, '|')
        order by $locale
        return $locale
    )
};

(: Returns all site and locales you have the permission for :)
declare function ac:site-locales-by-permission(
    $permission as xs:string,
    $pageId as xs:string
) as xs:string* {
    let $template := cf:get-preview-content-by-id($pageId)/ldse:ldse-meta/ldse:form-options/ldse:templateId/fn:string()
    let $flatten-permissions := map:get($user-permission-map, $permission)
    let $isSuperUser := $contributor/ldse:roles/ldse:role/@name/fn:string() eq 'super'
    return if ($isSuperUser) then
               for $site in  sp:get-site-properties(())
               let $siteId := $site/@site/fn:string()
               for $lang in  library:get-supported-languages-by-site($siteId)/language/@key/fn:string()
               where $site/admin-pages/nav/section/page/@id/fn:string() eq $template
               order by $siteId, $lang
               return fn:concat($siteId, ' | ', $lang)
            else
                fn:distinct-values(
                    for $i in $flatten-permissions
                    let $site := fn:replace($i, "^.*si\[([^\]]+)\].*$", "$1")[. ne $i]
                    let $lang := fn:replace($i, "^.*l\[([^\]]+)\].*$", "$1")[. ne $i]
                    return if ($site eq 'ALL') then
                                for $_site in sp:get-site-properties(())
                                let $siteName := $_site/@site/fn:string()
                                where $_site/admin-pages/nav/section/page/@id/fn:string() eq $template
                                return if ($lang eq 'ALL') then
                                          for $_lang in library:get-supported-languages-by-site($siteName)/language/@key/fn:string()
                                          order by $lang
                                          return fn:concat($siteName, ' | ', $_lang)
                                       else
                                          fn:concat($siteName, ' | ', $lang)
                           else
                                if (sp:get-site-properties($site)/admin-pages/nav/section/page/@id/fn:string() eq $template) then
                                     if ($lang eq 'ALL') then
                                        for $i in  library:get-supported-languages-by-site($site)/language/@key/fn:string()
                                        return fn:concat($site, ' | ', $i)
                                     else
                                        fn:concat($site, ' | ', $lang)
                                else ()
                )
};

declare function ac:site-locales-by-permission(
    $permission as xs:string
) as xs:string* {
    let $flatten-permissions := map:get($user-permission-map, $permission)
    let $isSuperUser := $contributor/ldse:roles/ldse:role/@name/fn:string() eq 'super'
    let $allSites := for $site in sp:get-site-properties(())
                     order by $site/@site/fn:string()
                     return $site
    return
        if ($isSuperUser) then
            for $site in $allSites
            let $siteId := $site/@site/fn:string()
            let $_supported-languages := for $i in library:get-supported-languages-by-site($siteId)/language/@key/fn:string()
                                         order by $i
                                         return $i
            let $supported-languages :=
                if (fn:count($_supported-languages) > 1) then
                    ('all', $_supported-languages)
                else $_supported-languages
            return for $lang in ($supported-languages)
                   order by $siteId
                   return fn:concat($siteId, ' | ', $lang)
        else
            fn:distinct-values(
                for $i in $flatten-permissions
                let $site := fn:replace($i, "^.*si\[([^\]]+)\].*$", "$1")[. ne $i]
                let $lang := fn:replace($i, "^.*l\[([^\]]+)\].*$", "$1")[. ne $i]
                return
                    if ($site eq 'ALL') then
                        for $_site in $allSites
                        let $siteName := $_site/@site/fn:string()
                        let $_supported-languages := for $i in library:get-supported-languages-by-site($siteName)/language/@key/fn:string()
                                                     order by $i
                                                     return $i
                        let $supported-languages :=
                            if (fn:count($_supported-languages) > 1) then
                                ('all', $_supported-languages)
                            else $_supported-languages
                        return if ($lang eq 'ALL') then
                            for $_lang in $supported-languages
                            return fn:concat($siteName, ' | ', $_lang)
                        else
                            fn:concat($siteName, ' | ', $lang)
                    else
                        if ($lang eq 'ALL') then
                            let $_supported-languages := library:get-supported-languages-by-site($site)/language/@key/fn:string()
                            let $supported-languages :=
                                if (fn:count($_supported-languages) > 1) then
                                    ('all', $_supported-languages)
                                else $_supported-languages
                            return for $i in $supported-languages
                                   return fn:concat($site, ' | ', $i)
                        else
                            fn:concat($site, ' | ', $lang)
            )
};

declare function ac:users-exist() as xs:boolean {
    xdmp:estimate(/ldse:contributor) > 0
};

declare function ac:authRequired($site as xs:string) as element()? {
    cts:search(/ldse:authorization/ldse:user,
        cts:and-query((
            cts:element-attribute-value-query(xs:QName('ldse:user'),xs:QName('site'), $site, 'exact'),
            cts:element-attribute-value-query(xs:QName('ldse:user'),xs:QName('auth-only'), 'true', 'exact')
        ))
    )
};

declare function ac:isAuthorized($credential as xs:string) as element()? {
    cts:search(/ldse:authorization/ldse:user, cts:element-value-query(xs:QName('ldse:user'), enc:encrypt($credential), 'exact'))
};

declare function ac:getUserName() as xs:string? {
     if ($isDevOpCMS) then
         $MWUser
     else
         if ($okta:okta-active) then
             okta:okta-user-info(xdmp:get-session-field('id_token'), 'preferred__username')
         else security:getUsername()
};

declare function ac:getPersonName() as xs:string? {
    if ($isDevOpCMS) then
        for $contributor in core:get-contributor($MWUser)
        return $contributor/ldse:name/@display
    else if ($okta:okta-active) then
        okta:okta-user-info(xdmp:get-session-field('id_token'), 'displayName')
    else security:getPersonName()
};

declare function ac:getPersonId() as xs:string? {
    if ($isDevOpCMS) then
        "000000000"
    else
        if ($okta:okta-active) then
            okta:okta-user-info(xdmp:get-session-field('access_token'), 'churchAccountID')
        else security:getPersonId()
};

declare function ac:getAccountId() as xs:string? {
    if ($isDevOpCMS) then
        "000000000"
    else
        if ($okta:okta-active) then
            okta:okta-user-info(xdmp:get-session-field('access_token'), 'churchAccountID')
        else security:getAccountId()
};

declare function ac:getPersonEmail() as xs:string? {
    if ($isDevOpCMS) then
        ()
    else
        if ($okta:okta-active) then
            okta:okta-user-info(xdmp:get-session-field('access_token'), 'personalEmail')
        else security:getPersonEmail()
};
