import { Controller } from "@hotwired/stimulus"
import { get } from "@rails/request.js"
import { debounce } from "helpers/timing_helpers"

// Type a few letters, pick a city from the suggestions. Only a picked city counts: half-typed
// text goes back to the last choice when you leave the field, and clearing it removes the city.
export default class extends Controller {
  static targets = [ "input", "id", "list" ]
  static values = { url: String }

  #chosenLabel
  #activeIndex = -1

  connect() {
    this.#chosenLabel = this.inputTarget.value
  }

  search() {
    if (this.inputTarget.value.trim() === "") {
      this.#choose("", "")
      this.#close()
    } else {
      this.#searchSoon()
    }
  }

  navigate(event) {
    const options = this.#options

    switch (event.key) {
      case "ArrowDown":
      case "ArrowUp":
        if (options.length === 0) return
        event.preventDefault()
        this.#activeIndex = (this.#activeIndex + (event.key === "ArrowDown" ? 1 : -1) + options.length) % options.length
        this.#highlight()
        break
      case "Enter":
        if (this.listTarget.hidden) return
        event.preventDefault()
        if (options[this.#activeIndex] || options[0]) this.#pick(options[this.#activeIndex] || options[0])
        break
      case "Escape":
        this.#close()
        break
    }
  }

  leave() {
    setTimeout(() => {
      this.#close()
      this.inputTarget.value = this.#chosenLabel
    }, 150)
  }

  #searchSoon = debounce(() => this.#fetch(), 200)

  async #fetch() {
    const query = this.inputTarget.value.trim()
    if (query.length < 2) return this.#close()

    const response = await get(this.urlValue, { query: { q: query }, responseKind: "json" })
    if (response.ok && this.inputTarget.value.trim() === query) this.#show(await response.json)
  }

  #show(cities) {
    this.listTarget.replaceChildren(...cities.map(city => this.#option(city)))
    if (cities.length === 0) this.listTarget.replaceChildren(this.#emptyOption())

    this.#activeIndex = -1
    this.listTarget.hidden = false
    this.inputTarget.setAttribute("aria-expanded", "true")
  }

  #option(city) {
    const option = document.createElement("li")
    option.setAttribute("role", "option")
    option.dataset.id = city.id
    option.dataset.label = city.label

    const name = document.createElement("strong")
    name.textContent = city.name

    const place = document.createElement("span")
    place.textContent = [ city.place, city.alias && `also ${city.alias}` ].filter(Boolean).join(" · ")

    option.append(name, place)
    option.addEventListener("mousedown", event => {
      event.preventDefault()
      this.#pick(option)
    })
    return option
  }

  #emptyOption() {
    const option = document.createElement("li")
    option.className = "city-picker__none"
    option.textContent = "No city by that name. Try the nearest bigger city."
    return option
  }

  #pick(option) {
    this.#choose(option.dataset.id, option.dataset.label)
    this.#close()
  }

  #choose(id, label) {
    this.idTarget.value = id
    this.inputTarget.value = label
    this.#chosenLabel = label
  }

  #highlight() {
    this.#options.forEach((option, index) => option.setAttribute("aria-selected", index === this.#activeIndex))
  }

  #close() {
    this.listTarget.hidden = true
    this.inputTarget.setAttribute("aria-expanded", "false")
  }

  get #options() {
    return [ ...this.listTarget.querySelectorAll("[role=option]") ]
  }
}
