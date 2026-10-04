import { Controller } from "@hotwired/stimulus"

const DEFAULT_LIST = "rooms"
const STORAGE_KEY = "sidebar-list"

// The Rooms, DMs, Threads and Members circles at the top of the menu: one list shows at a time.
// The menu reloads as people move around, so the choice is kept for the visit; a fresh start
// of the app opens on Rooms again.
export default class extends Controller {
  static targets = [ "tab", "panel" ]

  connect() {
    this.#show(this.#remembered)
  }

  select({ params: { name } }) {
    this.#show(name)
    this.#remember(name)
  }

  #show(name) {
    if (!this.panelTargets.some(panel => panel.dataset.name === name)) name = DEFAULT_LIST

    this.panelTargets.forEach(panel => panel.hidden = panel.dataset.name !== name)
    this.tabTargets.forEach(tab => tab.setAttribute("aria-expanded", tab.dataset.name === name))
  }

  get #remembered() {
    try {
      return sessionStorage.getItem(STORAGE_KEY) || DEFAULT_LIST
    } catch {
      return DEFAULT_LIST
    }
  }

  #remember(name) {
    try {
      sessionStorage.setItem(STORAGE_KEY, name)
    } catch {
      // Private browsing: the menu just starts on Rooms each time
    }
  }
}
