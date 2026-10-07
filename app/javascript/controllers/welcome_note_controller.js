import { Controller } from "@hotwired/stimulus"
import { post } from "@rails/request.js"
import { nextFrame } from "helpers/timing_helpers"

// The welcome note a new member sees once. It counts as seen as soon as it's shown, so a
// reload or a tap on one of its links doesn't bring it back. Closing it puts the cursor in
// the message box, ready for their introduction.
export default class extends Controller {
  static values = { url: String }

  async connect() {
    // Already open means it came back from Turbo's page cache (going back after following one
    // of its links), not from the server: it has been seen, so it goes
    if (this.element.open) return this.forget()

    await nextFrame()
    this.element.showModal()
    post(this.urlValue)
  }

  closed() {
    document.querySelector("#composer lexxy-editor")?.focus()
  }

  // Before Turbo snapshots the page for its back button, so the note isn't saved in it
  forget() {
    this.element.remove()
  }
}
