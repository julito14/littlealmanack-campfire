module ApplicationHelper
  def page_title_tag
    tag.title @page_title || "Campfire"
  end

  def current_user_meta_tags
    unless Current.user.nil?
      safe_join [
        tag(:meta, name: "current-user-id", content: Current.user.id),
        tag(:meta, name: "current-user-name", content: Current.user.name)
      ]
    end
  end

  def custom_styles_tag
    if custom_styles = Current.account&.custom_styles
      tag.style(custom_styles.to_s.html_safe, data: { turbo_track: "reload" })
    end
  end

  def body_classes
    [ @body_class, admin_body_class, account_logo_body_class ].compact.join(" ")
  end

  # Back the way you came (history_back_controller.js). The referrer is only where it goes when
  # there's no history to go back through, like a page opened from a notification.
  def link_back(fallback: nil)
    back_url = fallback || request.referrer
    back_url = root_path if back_url.nil? || back_url == request.url
    link_back_to back_url, history: true
  end

  def link_back_to(destination, history: false)
    data = { controller: "history-back", action: "history-back#back", turbo_action: "replace" } if history

    link_to destination, class: "btn", data: data do
      image_tag("arrow-left.svg", aria: { hidden: "true" }, size: 20) +
      tag.span("Go Back", class: "for-screen-reader")
    end
  end

  private
    def admin_body_class
      "admin" if Current.user&.can_administer?
    end

    def account_logo_body_class
      "account-has-logo" if Current.account&.logo&.attached?
    end
end
