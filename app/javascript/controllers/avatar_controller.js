/* app/javascript/controllers/avatar_controller.js
 * Hotwire Stimulus controller
 */
import { Controller } from "@hotwired/stimulus"; // https://stimulus.hotwired.dev
import { get } from "@rails/request.js"; // https://github.com/rails/request.js
import { AVAILABLE_LOCALES, AVATAR_SIZE, DEBUG } from "constants";

export default class extends Controller {
  static targets = ["login", "email", "image", "avatarHidden", "fileInput"];

  // only for debugging purpose to see Stimulus controller is connected
  connect() {
    DEBUG && console.log("avatar_controller::connect()");
  }

  // not showing a file name next to the file input button
  // - having hidden input with data-avatar-target 'fileInput'
  // - and button with data-action click -> 'clickUploadImage'
  // - called from ERB HTML <button>, fires click on hidden <input> to open browsers file selection dialog
  //
  clickUploadImage() {
    // trigger browsers file input click when the button is clicked
    this.fileInputTarget.click();
  }

  // on login field focus out update avatar image
  // - called from ERB HTML field login, only if action is :new
  // - calling Rails controller users/show_avater to generate new avatar image
  //
  updateFromLogin() {
    DEBUG &&
      console.debug(
        `avatar_controller::updateFromLogin() from ${window.location.pathname}`
      );

    // only auto-generate avatar from login name if the default image is actual used
    // (which means there was no image uploaded and no Gravatar found and no explicit avater created so far)
    const element = document.getElementById("avatar");
    DEBUG &&
      console.debug(
        `avatar_controller::updateFromLogin() avatar=${element.src.substring(
          0,
          20
        )}...`
      );
    if (element && element.src && element.src.endsWith("/0.png")) {
      const loginName = this.hasLoginTarget ? this.loginTarget.value : "";
      const locale = this._setLocale();
      DEBUG &&
        console.debug(`GET ${locale}/users/show_avatar?login=${loginName}`);
      get(`${locale}/users/show_avatar?login=${loginName}`, {
        responseKind: "turbo-stream",
      });
    }
  }

  // on email field focus out check and take Gravatar image
  // - called from ERB HTML field email, only if action is :new
  // - calling Rails controller users/show_avater to check if Gravatar exist and in this case copy the image as avatar
  // - ignoring (means overwriting avatar with Gravatar found from email address) if previous an image was uploaded or
  //   avatar explicit created
  //
  updateFromEmail() {
    DEBUG && console.debug("avatar_controller::updateFromEmail()");
    // if there was an image uploaded the selected file will be cleaned here and
    // deleted in file system by Rails user controller afterwards
    const element = document.getElementById("user_image");
    if (element) element.value = "";

    const emailAddress = this.hasEmailTarget ? this.emailTarget.value : "";
    const locale = this._setLocale();
    DEBUG &&
      console.debug(`GET ${locale}/users/show_avatar?email=${emailAddress}`);
    get(`${locale}/users/show_avatar?email=${emailAddress}`, {
      responseKind: "turbo-stream",
    });
  }

  // after selecting image file do the upload from server to client
  // - called from ERB HTML <input> after change -> 'uploadImage'
  // - resize the file to 80x80px square
  // - resize the file to 80x80px square
  // - POST request to users controller upload_avatar()
  //
  uploadImage() {
    DEBUG && console.debug(`avatar_controller::uploadImage()`);
    const input = this.fileInputTarget;
    const file = input.files[0];
    if (file) {
      // resize the file, then create FormData and append the file
      this._resizeFile(file)
        .then((resizedFile) => {
          const formData = new FormData();
          formData.append("image", resizedFile, "avatar.png"); // add a filename
          this._updateAvatarImages(resizedFile, file.name);

          // retrieve the CSRF token from the meta tag
          const csrfToken = document
            .querySelector("meta[name='csrf-token']")
            .getAttribute("content");

          // fetch the Rails route for uploading the image
          fetch(`${this._setLocale()}/users/upload_avatar`, {
            method: "POST",
            body: formData,
            credentials: "include",
            headers: {
              "X-CSRF-Token": csrfToken,
              Accept:
                "text/vnd.turbo-stream.html, text/html, application/xhtml+xml", // expect Turbo Stream or HTML application/html, text/html, application/xhtml+xml", 
            },
          })
            .then((response) => {
              if (response.ok) {
                // The Turbo Stream response will be automatically processed by Turbo

                DEBUG && console.log("image uploaded successfully");
              } else {
                throw new Error("server responded with a non-OK status");
              }
            })
            .catch((error) => console.error("error uploading image: ", error));
        })
        .catch((error) => {
          // e.g. zero bytes image or does not contain an image after file selection dialog
          // simple does nothing, TODO return status and give localized error message in Rails
          console.error("Error resizing image file:", error);
        });
    }
  }

  // action for avatars 'recreate' button
  // - called from ERB HTML <button>
  // - GET request to users controller recreate_avatar()
  //
  recreate() {
    DEBUG && console.debug(`avatar_controller::recreate()`);
    // if there was an image uploaded the selected file will be cleaned here and
    // deleted in file system by Rails user controller afterwards
    const element = document.getElementById("user_image");
    if (element) element.value = "";

    // const loginName = this.hasLoginTarget ? this.loginTarget.value : "";
    // directly grab the value of the login input by its DOM ID as ?it is not available from Stimulus?
    const loginName = document.getElementById("user_login")
      ? document.getElementById("user_login").value
      : "";
    const locale = this._setLocale();
    DEBUG &&
      console.debug(`GET ${locale}/users/recreate_avatar?login=${loginName}`);
    get(`${locale}/users/recreate_avatar?login=${loginName}`, {
      responseKind: "turbo-stream",
    });
  }

  // action for avatars 'copy Gravatar' button
  // - called from ERB HTML <button>
  // - GET request to users controller take_gravatar()
  //
  takeGravatar() {
    DEBUG && console.debug(`avatar_controller::takeGravatar()`);
    // if there was an image uploaded the selected file will be cleaned here and
    // deleted in file system by Rails user controller afterwards
    const element = document.getElementById("user_image");
    if (element) element.value = "";

    const email = document.getElementById("user_email")
      ? document.getElementById("user_email").value
      : "";
    const locale = this._setLocale();
    DEBUG && console.debug(`GET ${locale}/users/take_gravatar?email=${email}`);
    get(`${locale}/users/take_gravatar?email=${email}`, {
      responseKind: "turbo-stream",
    });
  }

  /*
   * Auxiliary functions
   */

  // pick up locale from actual path to be able to insert locale in URL path
  // return "" or e.g. "/en"
  //
  _setLocale() {
    let locale = "";

    // get the current pathname, e.g. "/en/users/new"
    const pathname = window.location.pathname;
    // check if the pathname starts with any of the locales
    for (let i = 0; i < AVAILABLE_LOCALES.length; i++) {
      if (pathname.startsWith(`/${AVAILABLE_LOCALES[i]}/`)) {
        locale = `/${AVAILABLE_LOCALES[i]}`;
        break;
      }
    }
    return locale;
  }

  // update all three avatar images and the hidden image and give avatar message hint with animation
  // this is needed on client side for image file upload, as this is a POST request and does not initiate any changes
  //
  _updateAvatarImages(file, name) {
    // create a FileReader to read the file
    const reader = new FileReader();

    // define the onload event handler for the FileReader
    // this function is called when the reading operation is successfully completed
    reader.onloadend = (event) => {
      // get the data URL from the event
      const dataUrl = event.target.result;

      // set the data URL as the source of the hidden image and the three avatar images
      const elementIds = [
        "avatar-big",
        "avatar",
        "avatar-small",
      ];
      elementIds.forEach((id) => {
        const element = document.getElementById(id);
        if (element) element.src = dataUrl;
      });

      // update avatar message hint simple with image file name to prevent I18N message localization
      this._updateAvatarHint(name);
    };

    // start reading the file as a Data URL
    reader.readAsDataURL(file);
  }

  // update avatar hint message including animation
  //
  _updateAvatarHint(content) {
    // if there was an error before, clean first
    const element = document.getElementById("avatar_error");
    if (element) element.innerText = "";

    const avatarHint = document.getElementById("avatar_hint");
    if (avatarHint) {
      // remove the animation class or inline style
      avatarHint.style.animation = "none";
      // trigger a reflow
      avatarHint.offsetWidth; // this is the magic trick that forces a reflow
      // re-apply the animation
      avatarHint.style.animation = "";
      // now set the new content, with HTML formatting
      avatarHint.innerHTML = content;
    }
  }

  // resize uploaded image to 80x80 PNG
  //
  _resizeFile(file) {
    return new Promise((resolve, reject) => {
      // Create an image element
      const img = new Image();
      img.src = URL.createObjectURL(file);
      img.onload = () => {
        // create a canvas, context and set 80x80px
        const canvas = document.createElement("canvas");
        const ctx = canvas.getContext("2d");
        canvas.width = AVATAR_SIZE;
        canvas.height = AVATAR_SIZE;

        // determine the smallest side of the image
        const minSide = Math.min(img.width, img.height);
        // calculate the scale to fill the avatar size
        const scale = AVATAR_SIZE / minSide;
        // calculate the source rectangle dimensions
        const srcX = (img.width - minSide) / 2; // start point for cropping on x-axis
        const srcY = (img.height - minSide) / 2; // start point for cropping on y-axis
        const srcWidth = minSide; // the width of the crop area
        const srcHeight = minSide; // the height of the crop area

        // draw the cropped and scaled image on the canvas
        ctx.drawImage(
          img,
          srcX,
          srcY,
          srcWidth,
          srcHeight,
          0,
          0,
          AVATAR_SIZE,
          AVATAR_SIZE
        );

        // convert the canvas to a Blob
        canvas.toBlob((blob) => {
          // resolve the promise with the Blob
          resolve(blob);
        }, "image/png"); // ensure the resized image is in PNG format
      };
      img.onerror = (error) => reject(error);
    });
  }
}
