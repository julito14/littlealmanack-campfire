import { Controller } from "@hotwired/stimulus"
import { post } from "@rails/request.js"
import { debounce } from "helpers/timing_helpers"

// On an open thread page, replies that arrive are being read: tell the server, so the thread
// doesn't turn bold in the strip. Also once the page shows (it may have come from a prefetch or
// Turbo's cache) and on coming back to it after it was hidden.
export default class extends Controller {
  static values = { url: String, repliesId: String }

  connect() {
    this.#markReadSoon()
  }

  streamRendered(event) {
    const stream = event.detail.newStream

    if (stream.getAttribute("action") === "append" && stream.getAttribute("target") === this.repliesIdValue) {
      this.#markReadSoon()
    }
  }

  visibilityChanged() {
    this.#markReadSoon()
  }

  #markReadSoon = debounce(() => {
    if (document.visibilityState === "visible") {
      post(this.urlValue)
    }
  }, 1000)
}
