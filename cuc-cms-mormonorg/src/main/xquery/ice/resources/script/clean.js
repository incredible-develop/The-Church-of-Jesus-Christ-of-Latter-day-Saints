function cleanPath(path) {
    "use strict";
    return $.trim(path).replace(/\ /g, '-').replace(/(-)\1+/g,'-').replace(/(\/)\1+/g, '/').toLowerCase().replace(/[`~!@#\$%\^\*\(\)\+={}\[\]:;'<>,\.\?\&]/g, '');
}