xquery version '1.0-ml';

module namespace pf = 'http://lds.org/code/cms/pds/modules/pds-functions';

import module namespace df = 'http://lds.org/code/shared/lds-edit/dynamicForms' at '../../ice/modules/dynamicForms.xqy';
import module namespace gct = "http://lds.org/code/transforms/gl-card-transform" at '../../transforms/gl-card-transform.xqy';
import module namespace core = "http://lds.org/code/shared/lds-edit/ldse-core" at '../../modules/ldse-core.xqy';

declare function pf:init-cards() {
    let $cards as element(card)* := pf:get-published-cards()
    return pf:push-card-to-emx($cards)
};

declare function pf:get-published-cards() as element(card)* {
    cts:search(/card,
        cts:and-query((
            cts:directory-query('/published/cms/', 'infinity')
        ))
    )
};

declare function pf:push-card-to-emx(
    $card as element(card)
) {
    let $port := core:set-port(10090)
    let $json := gct:perform-transform($card, ())
    return df:push-to-emx(fn:local-name($card), $json, 'init')
};