import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "time", "date", "datetime", "relative" ]

  initialize() {
    this.timeFormatter = new Intl.DateTimeFormat(undefined, { timeStyle: "short" })
    this.dateFormatter = new Intl.DateTimeFormat(undefined, { dateStyle: "long" })
    this.dateTimeFormatter = new Intl.DateTimeFormat(undefined, { timeStyle: "short", dateStyle: "short" })
    this.relativeFormatter = new Intl.RelativeTimeFormat(undefined, { numeric: "auto" })
    this.shortDateFormatter = new Intl.DateTimeFormat(undefined, { dateStyle: "medium" })
  }

  timeTargetConnected(target) {
    this.#formatTime(this.timeFormatter, target)
  }

  dateTargetConnected(target) {
    this.#formatTime(this.dateFormatter, target)
  }

  datetimeTargetConnected(target) {
    this.#formatTime(this.dateTimeFormatter, target)
  }

  relativeTargetConnected(target) {
    const dt = new Date(target.getAttribute("datetime"))
    target.textContent = this.#relativeTime(dt)
    target.title = this.dateTimeFormatter.format(dt)
  }

  // "just now", "5 minutes ago", "3 hours ago", "yesterday"; a plain date after a week
  #relativeTime(dt) {
    const seconds = Math.round((dt - Date.now()) / 1000)
    const minutes = Math.round(seconds / 60)
    const hours = Math.round(minutes / 60)
    const days = Math.round(hours / 24)

    if (Math.abs(seconds) < 60) return "just now"
    if (Math.abs(minutes) < 60) return this.relativeFormatter.format(minutes, "minute")
    if (Math.abs(hours) < 24) return this.relativeFormatter.format(hours, "hour")
    if (Math.abs(days) < 7) return this.relativeFormatter.format(days, "day")
    return this.shortDateFormatter.format(dt)
  }

  #formatTime(formatter, target) {
    const dt = new Date(target.getAttribute("datetime"))
    target.textContent = formatter.format(dt)
    target.title = this.dateTimeFormatter.format(dt)
  }
}
