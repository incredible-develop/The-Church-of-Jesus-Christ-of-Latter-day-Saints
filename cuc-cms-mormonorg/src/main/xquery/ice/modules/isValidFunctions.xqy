xquery version "1.0-ml";

module namespace valid = "http://lds.org/code/shared/lds-edit/isValidFunctions";
import module namespace security = "http://lds.org/code/shared/common/security/security-functions" at "/shared/common/security/securityFunctions.xqy";

import module namespace settings = "http://lds.org/code/shared/lds-edit/ldse-settings" at "../../modules/ldse-settings.xqy";
import module namespace util = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../modules/utility-functions.xqy";
import module namespace ac = "http://lds.org/code/shared/lds-edit/access-control-functions" at "../../modules/access-control-functions.xqy";

declare namespace ldse = "http://lds.org/code/lds-edit";
declare namespace xhtml = "http://www.w3.org/1999/xhtml";
declare namespace its = "http://www.w3.org/2005/11/its";

declare option xdmp:mapping "true";

declare variable $DEPRECATED as empty-sequence() := util:deprecated(());

declare variable $role-mapping as element(ldse:role-mapping)? := $settings:role-mapping;


declare function valid:isContributor() as xs:boolean {
    ac:is-user()
};

(: Return true if the person is a editor no matter what locale :)
declare function valid:isEditor() as xs:boolean {
    $DEPRECATED,
    valid:isValidContentEditor((), (), () )
};

declare function valid:isValidContentEditor($deprecated-context as xs:string?, $locale as xs:string?, $url as xs:string?) as xs:boolean {
    $DEPRECATED,
    (
        let $roles as xs:string+ := 
            if ( fn:exists($role-mapping/ldse:editor/ldse:role[. ne '']) ) then (
                $role-mapping/ldse:editor/ldse:role[. ne '']
            ) else ('Edit')
        return ( some $role as xs:string in $roles satisfies valid:isValid( $role, $deprecated-context, $locale, $url) )
    )
};

(: Return true if the person is a publisher no matter what locale :)
declare function valid:isPublisher() as xs:boolean {
    $DEPRECATED,
    valid:isValidContentPublisher((), (), () )
};

declare function valid:isValidContentPublisher($deprecated-context as xs:string?, $locale as xs:string?, $url as xs:string?) as xs:boolean {
    $DEPRECATED,
    (
        let $roles as xs:string+ := 
            if ( fn:exists($role-mapping/ldse:publisher/ldse:role[. ne '']) ) then (
                $role-mapping/ldse:publisher/ldse:role[. ne '']
            ) else ('Publish')
        return ( some $role as xs:string in $roles satisfies valid:isValid( $role, $deprecated-context, $locale, $url) )
    )
};

(: Return true if the person is a admin no matter what locale :)
declare function valid:isAdmin() as xs:boolean {
    $DEPRECATED,
    valid:isValidContentAdmin((), ())
};

declare function valid:isValidContentAdmin($deprecated-context as xs:string?, $locale as xs:string?) as xs:boolean {
    $DEPRECATED,
    (
        let $roles as xs:string+ := 
            if ( fn:exists($role-mapping/ldse:admin/ldse:role[. ne '']) ) then (
                $role-mapping/ldse:admin/ldse:role[. ne '']
            ) else ('Admin')
        return ( some $role as xs:string in $roles satisfies valid:isValid( $role, $deprecated-context, $locale, ()) )
    )
};

(: Return true if the person is a super :)
declare function valid:isSuper() as xs:boolean {
    $DEPRECATED,
    valid:isValidDevSuper(())
};

(: Backwards compatible support no need to pass $locale :)
declare function valid:isValidDevSuper($deprecated-context as xs:string?, $locale as xs:string?) as xs:boolean {
    $DEPRECATED,
    valid:isValidDevSuper($deprecated-context)
};

declare function valid:isValidDevSuper($deprecated-context as xs:string?) as xs:boolean {
    $DEPRECATED,
    (
        let $roles as xs:string+ := 
            if ( fn:exists($role-mapping/ldse:super/ldse:role[. ne '']) ) then (
                $role-mapping/ldse:super/ldse:role[. ne '']
            ) else ('Super')
        return ( some $role as xs:string in $roles satisfies valid:isValid( $role, $deprecated-context, (), ()) )
    )
};

(: Return true if the person is has a role matter what locale or uri :)
declare function valid:hasRole($role-name as xs:string) as xs:boolean {
    $DEPRECATED,
    ac:has-role($role-name, (), ())
};

declare function valid:isValid($role-name as xs:string, $deprecated-context as xs:string?) as xs:boolean {
    $DEPRECATED,
    valid:isValid($role-name, $deprecated-context, (), ())
};

declare function valid:isValid($role-name as xs:string, $deprecated-context as xs:string?, $locale as xs:string?) as xs:boolean {
    $DEPRECATED,
    valid:isValid($role-name, $deprecated-context, $locale, ())
};


declare function valid:isValid($role-name as xs:string, $deprecated-context as xs:string?, $locale as xs:string?, $url as xs:string?) as xs:boolean {
    $DEPRECATED,
    ac:has-role($role-name, $locale, $url)
}; 

declare function valid:isValidSearchContributor($deprecated-context as xs:string?) as xs:boolean {
    $DEPRECATED,
    (
        let $roles as xs:string+ := 
            if ( fn:exists($role-mapping/ldse:search/ldse:role[. ne '']) ) then (
                $role-mapping/ldse:search/ldse:role[. ne '']
            ) else ('Search')
        return ( some $role as xs:string in $roles satisfies valid:isValid( $role, $deprecated-context, (), ()) )
    )
};

declare function valid:isValidSuperSearchContributor($deprecated-context as xs:string?) as xs:boolean {
    $DEPRECATED,
    (
        let $roles as xs:string+ := 
            if ( fn:exists($role-mapping/ldse:search-admin/ldse:role[. ne '']) ) then (
                $role-mapping/ldse:search-admin/ldse:role[. ne '']
            ) else ('Search Admin')
        return ( some $role as xs:string in $roles satisfies valid:isValid( $role, $deprecated-context, (), ()) )
    )
};

declare function valid:validLocales($deprecated-context as xs:string?) as xs:string* {
    $DEPRECATED,
    ac:locales()
};

declare function valid:setContributorVariables($deprecated-context as xs:string?, $locale as xs:string?, $currentPage as xs:string?) as empty-sequence() {
    let $set as xs:boolean := valid:isValidContentEditor($deprecated-context, $locale, $currentPage)
    let $set as xs:boolean := valid:isValidContentPublisher($deprecated-context, $locale, $currentPage)
    let $set as xs:boolean := valid:isValidContentAdmin($deprecated-context, $locale)
    let $set as xs:boolean := valid:isValidDevSuper($deprecated-context)
    let $set as xs:boolean := valid:isValidSearchContributor($deprecated-context)
    return (
        $DEPRECATED
    )
};
