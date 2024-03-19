// app/javascript/constants.js

// must correspond to I18n.available_locales in config/initializers/locale.rb
export const AVAILABLE_LOCALES = ["en", "de", "ja", "es", "uk"];

// must correspond to AVATAR_SIZE in config/initializers/locale.rb
export const AVATAR_SIZE = 80 // pixel

// run "localStorage.setItem('debugMode', 'true');" in browser console to enable debug messages
// run "localStorage.removeItem('debugMode');" to disable them
export const DEBUG = localStorage.getItem('debugMode') === 'true';
