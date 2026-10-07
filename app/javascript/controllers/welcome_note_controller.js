import { Controller } from "@hotwired/stimulus"
import { post } from "@rails/request.js"
import { nextFrame } from "helpers/timing_helpers"

// The welcome note a new member sees once. It counts as seen as soon as it's shown, so a
// reload or a tap on one of its links doesn't bring it back. Closing it puts the cursor in
// the message box, ready for their introduction.
export default class extends Controller {
  static values = { url: String }

  async connect() {
    await nextFrame()
    if (!this.element.open) this.element.showModal()
    post(this.urlValue)
  }

  closed() {
    document.querySelector("#composer lexxy-editor")?.focus()
  }
}
