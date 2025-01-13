/*
Stores and makes available campaign values

    const myCampaigners = [
        {
            name: 'boncom',
            id: 'cid',
            cookieName: [
                'cid',
                'CID'
            ],
            cookieDays: 365
        },
        {
            name: 'missionaryDepartment',
            id: 'mdcid',
            cookieName: [
                'mdcid',
                'MDCID'
            ],
            cookieDays: 365
        }
    ]

    const myCampaigners = Campaigners(myCampaigners);

    // Assume a ?cid=something was present...

    console.log(myCampaigners.get('boncom'));
        // => 'something'

*/
import cookies from '../cookies/browser';
import URLSearchParams from 'url-search-params';



const searchParams = new URLSearchParams(window.location.search.slice(1));



// Handles setting cookie(s) and returning values for a given campaigner.
export default class Campaigner {
    constructor({id, cookieName, cookieDays}) {

        this.cookieNames = [];
        this.id = id;
        this.cookieDays = cookieDays;


        // Since the old mormon.org applications used different cookie names, we allow for an array for cookieName
        if (Array.isArray(cookieName)) {
            this.cookieNames = cookieName;
        } else {
            this.cookieNames.push(cookieName);
        }
        // Set a cookie for each if the query string parameter is present
        if (id) {
            const paramValue = searchParams.get(id);
            if (paramValue) {
                this.cookieNames.forEach((cookieName) => cookies.set(cookieName, paramValue, cookieDays))
            }
        }
    }

    get value() {
        return cookies.get(this.cookieNames[0]);
    }
}
