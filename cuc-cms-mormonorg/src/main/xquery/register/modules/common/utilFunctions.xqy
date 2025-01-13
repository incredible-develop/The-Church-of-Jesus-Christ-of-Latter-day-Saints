(:-------------------------------------------------------------------------------------------------------------------------------------:
     Copyright 2012 Intellectual Reserve, Inc.  All rights reserved.  This notice may not be removed. 
 :-------------------------------------------------------------------------------------------------------------------------------------:)
xquery version "1.0-ml"; 

module namespace util = "http://lds.org/code/lpr-preview/utilFunctions";

import module namespace ldseUtil = "http://lds.org/code/shared/lds-edit/ldse-util-functions" at "../../../modules/utility-functions.xqy";
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at "../../../modules/ldse-core.xqy";

declare boundary-space preserve;

declare variable $site := "register";
declare variable $site-param := xdmp:get-request-field('site');


(:~
    Retrieves the rewrite rules from the siteProperties files

    @param $context The execution context (preview or published)
    
    @return rewriteRules as node 
:)
declare function getRewriteRules() {
    /rewriteRules
};

(:~
    Retrieves the lang and global rewrite rules from the siteProperties files

    @param $lang - ex.  eng
    
    @return rewriteRules as node 
:)
declare function getRewriteRules($lang) {
  element rewriteRules {
      /rewriteRules[@locale eq ("global", $lang)]/rule
   }
};

(:~
    Retrieves the supported languages for the site

    @param $lang 
    
    @return languages as node 
:)
declare function getLanguages($lang) {
    cts:search(/supportedLanguages,
        cts:and-query((
            core:get-filter-query(),
            cts:element-attribute-value-query(xs:QName('supportedLanguages'), xs:QName('site'), $site-param, 'exact'),
            cts:element-attribute-value-query(xs:QName('supportedLanguages'), xs:QName('application'), $site, 'exact')
        ))
    )/language
};


(:~
    Checks to see if omniture is active in the site properties file

    @return $active as boolean 
:)
declare function isOmnitureActive() {
    let $active := /siteProperties/omniture/active
    return xs:boolean($active)
};

(:~
    Retrieves the valid fileExtensions for the site

    @param $site 
    
    @return extensions as node 
:)
declare function getFileExtensions($site) {
    /fileExtensions[@application eq $site]/ext
};



