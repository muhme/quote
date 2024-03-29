# JavaScript Files

The JavaScript files are part of the Ruby on Rails (RoR) web application running the website [zitat-service.de](https://www.zitat-service.de), see [../README.md](../README.md).

JavaScript is used for Hotwire Turbo and auxiliary functions in `application.js`; and for Hotwire Stimulus in `avatar_controller.js`.

To be able to use import maps in browsers without import maps support (e.g. older iOS)
[ES Module Shims](https://github.com/guybedford/es-module-shims) is used as local copy in `public/javascripts`.

## Debugging

`console.debug` messages can be enabled on the client side in browser JavaScript console with executing:
``` 
> localStorage.setItem('debugMode', 'true');
```
and doing a page reload. And can be disabled again with executing:
```
> localStorage.removeItem('debugMode');
```
