import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

/* in console working if focus back in website:
   setTimeout(function() { var c = document.getElementById("category"); c != null && c.focus()  }, 3000);

/* 
// simple try all Turbo listeners
const a = [];
a.push("turbo:click", "turbo:before-visit", "turbo:visit", "turbo:submit-start", "turbo:before-fetch-request", "turbo:before-fetch-response", "turbo:submit-end", "turbo:before-cache", "turbo:before-render", "turbo:before-stream-render", "turbo:render", "turbo:load", "turbo:before-frame-render ", "turbo:frame-render", "turbo:frame-load", "turbo:frame-missing", "turbo:fetch-request-error");
a.forEach(registerListener);

function registerListener(thisEvent) {
    document.documentElement.addEventListener(thisEvent, event => {
    var c = document.getElementById("category");
    // c != null && (c.value = "");
    c != null && c.focus()
    c != null && console.debug (thisEvent);
  })   
} */

// empty e.g. category field with JavaScript (doing it with Turbo and empty array input looses focus)
window.myCleanField = function(id) {
    var c = document.getElementById(id);
    if (c != null) {
        c.value = "";
        c.focus();
        // console.debug (`${id} emptied`);
    }
}
// set focus and select all e.g. in "quotation_source" field after author is selected
// window.mySetFocus = function(id) {
//     var c = document.getElementById(id);
//     if (c != null) {
//         c.focus();
//         c.select();
//         console.debug (`${id} focus set`);
//     }
// }

export { application }
