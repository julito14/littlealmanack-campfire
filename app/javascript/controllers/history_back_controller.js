import { Controller } from "@hotwired/stimulus"

// A back button that works like the browser's: when you got here from another page of the club, it
// goes back there. Otherwise (a page opened from a notification or a link) the link takes you up a
// level, replacing this page, so back can never bounce between two pages.
export default class extends Controller {
  back(event) {
    if ((history.state?.turbo?.restorationIndex || 0) > 0) {
      event.preventDefault()
      history.back()
    }
  }
}
