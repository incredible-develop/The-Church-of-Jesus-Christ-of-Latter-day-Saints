window.addEventListener('WebComponentsReady', function() {
    const element = document.querySelector('resource-reference');
    element.defineFetch((query) => {
        const url = ICE.resource.searchUrl;
        const headers = new Headers();
        headers.set('context', 'preview');
        headers.set('Accept-Language', 'eng');
        const init = { headers};
        return fetch(url + '?query=' + query, init)
            .then(response => {
                if (response.ok) { return response.json(); } else {
                    throw new
                        Error('Received status code: ' + response.status);
                }
            });
    });
});