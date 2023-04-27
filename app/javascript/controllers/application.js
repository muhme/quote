import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus = application

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
window.myCleanField = function (id) {
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

document.addEventListener("turbo:load", () => {

  const currentLanguage = document.getElementById("current-language");
  const languageDropdown = document.getElementById("language-dropdown");
  const languageOptions = document.querySelectorAll(".language-option");

  document.querySelector("#current-language").addEventListener("click", (event) => {
    languageDropdown.classList.toggle("hidden");
  });

  languageOptions.forEach(function (option) {
    option.addEventListener("click", (event) => {
      const selectedLocale = option.getAttribute("data-locale");
      console.debug ("click event, selectedLocale=" + selectedLocale);
      const currentUrl = window.location.pathname;
      const localePattern = /(\/(de|en|es|ja|uk))/;
      let newUrl;
      currentLanguage.innerHTML = option.innerHTML.split("–")[0] + " &#x25BE;"; // e.g. 🇺🇦 UK ▾
      languageDropdown.classList.add("hidden");
      if (currentUrl.match(localePattern)) {
        // Replace existing locale segment in the URL
        newUrl = currentUrl.replace(localePattern, `/${selectedLocale}`);
      } else {
        // Insert the new locale segment at the beginning of the URL
        newUrl = `/${selectedLocale}${currentUrl}`;
      }
      // Navigate to the updated URL
      window.location.href = newUrl;
    });
  });
});

export { application }
